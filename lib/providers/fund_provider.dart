import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fund.dart';
import '../services/fund_service.dart';
import '../main.dart'; // Import main.dart to access rootScaffoldMessengerKey

enum FundSortType {
  defaultSort,
  name,
  change,
  profit,
  profitRate,
}

class FundProvider with ChangeNotifier {
  List<Fund> _funds = [];
  Set<String> _favorites = {};
  List<Map<String, dynamic>> _groups = [];
  Map<String, Map<String, dynamic>> _holdings = {};
  Set<String> _collapsedCodes = {};
  int _refreshMs = 30000;
  bool _privacyMode = false;
  Timer? _timer;
  bool _loading = false;
  
  FundSortType _sortType = FundSortType.defaultSort;
  bool _sortAscending = false;

  // Sync Logic
  Timer? _syncDebounce;
  bool _skipSync = false;

  List<Fund> get funds => _funds;
  Set<String> get favorites => _favorites;
  List<Map<String, dynamic>> get groups => _groups;
  Map<String, Map<String, dynamic>> get holdings => _holdings;
  bool get loading => _loading;
  bool get privacyMode => _privacyMode;
  int get refreshInterval => _refreshMs;
  
  FundSortType get sortType => _sortType;
  bool get sortAscending => _sortAscending;

  double get totalMarketValue {
    return _funds.fold(0.0, (sum, f) => sum + f.userMarketValue);
  }

  double get totalDailyProfit {
    return _funds.fold(0.0, (sum, f) => sum + f.todayProfit);
  }

  double get totalProfit {
    return _funds.fold(0.0, (sum, f) => sum + f.userProfit);
  }

  double get totalProfitRate {
    final totalCost = _funds.fold(0.0, (sum, f) => sum + (f.userCost ?? 0.0) * (f.userShare ?? 0.0));
    if (totalCost == 0) return 0.0;
    return (totalProfit / totalCost) * 100;
  }

  FundProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadLocalConfig();
    _startTimer();

    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        fetchCloudConfig();
      }
    });

    // Initial fetch if logged in
    if (Supabase.instance.client.auth.currentUser != null) {
      fetchCloudConfig();
    }
  }

  void _updateFundsWithHoldings() {
    _funds = _funds.map((f) {
      final holding = _holdings[f.code];
      if (holding != null) {
        return f.copyWith(
          userCost: (holding['cost'] as num?)?.toDouble(),
          userShare: (holding['share'] as num?)?.toDouble(),
        );
      }
      return f;
    }).toList();
    _sortFunds();
  }

  void _sortFunds() {
    if (_sortType == FundSortType.defaultSort) return;

    _funds.sort((a, b) {
      int result = 0;
      switch (_sortType) {
        case FundSortType.name:
          result = a.name.compareTo(b.name);
          break;
        case FundSortType.change:
          // Sort by displayGrowth
          result = a.displayGrowth.compareTo(b.displayGrowth);
          break;
        case FundSortType.profit:
          // Sort by userProfit
          result = a.userProfit.compareTo(b.userProfit);
          break;
        case FundSortType.profitRate:
          // Sort by userProfitRate
          result = a.userProfitRate.compareTo(b.userProfitRate);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
  }

  void setSort(FundSortType type) {
    if (_sortType == type) {
      if (_sortType == FundSortType.defaultSort) return;
      _sortAscending = !_sortAscending;
    } else {
      _sortType = type;
      if (type == FundSortType.name) {
        _sortAscending = true; // A-Z default
      } else {
        _sortAscending = false; // High-Low default for numbers
      }
    }
    _sortFunds();
    notifyListeners();
  }

  Future<void> _loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load holdings first
    final savedHoldings = prefs.getString('holdings');
    if (savedHoldings != null) {
      _holdings = Map<String, Map<String, dynamic>>.from(jsonDecode(savedHoldings));
    }

    // Load funds
    final savedFunds = prefs.getString('funds');
    if (savedFunds != null) {
      final List<dynamic> jsonList = jsonDecode(savedFunds);
      _funds = jsonList.map((j) => Fund.fromJson(j)).toList();
    }

    // Load favorites
    final savedFavs = prefs.getStringList('favorites');
    if (savedFavs != null) {
      _favorites = savedFavs.toSet();
    }

    // Load groups
    final savedGroups = prefs.getString('groups');
    if (savedGroups != null) {
      _groups = List<Map<String, dynamic>>.from(jsonDecode(savedGroups));
    }

    // Load settings
    _refreshMs = prefs.getInt('refreshMs') ?? 30000;
    _privacyMode = prefs.getBool('privacyMode') ?? false;

    _updateFundsWithHoldings();
    notifyListeners();
    _startTimer(); // Restart timer with loaded interval
    refreshAll();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_refreshMs > 0) {
      _timer = Timer.periodic(Duration(milliseconds: _refreshMs), (timer) {
        refreshAll();
      });
    }
  }

  void setPrivacyMode(bool value) {
    _privacyMode = value;
    _saveSettings();
    notifyListeners();
  }

  void setRefreshInterval(int ms) {
    _refreshMs = ms;
    _saveSettings();
    _startTimer();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('refreshMs', _refreshMs);
    prefs.setBool('privacyMode', _privacyMode);
    _scheduleSync();
  }

  Future<void> refreshAll() async {
    if (_funds.isEmpty) return;
    
    _loading = true;
    notifyListeners();

    try {
      final updatedFunds = await Future.wait(
        _funds.map((f) => FundService.fetchFundData(f.code))
      );
      
      _funds = updatedFunds;
      _updateFundsWithHoldings();
      _saveFunds();
    } catch (e) {
      print('Refresh failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addFund(String code) async {
    try {
      final fund = await FundService.fetchFundData(code);
      // Remove existing if any
      _funds.removeWhere((f) => f.code == code);
      _funds.add(fund);
      _updateFundsWithHoldings();
      _saveFunds();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  void removeFund(String code) {
    _funds.removeWhere((f) => f.code == code);
    _favorites.remove(code);
    _holdings.remove(code);
    // Remove from groups
    for (var group in _groups) {
      List<dynamic> codes = group['codes'];
      codes.remove(code);
    }
    
    _saveAll();
    notifyListeners();
  }

  void toggleFavorite(String code) {
    if (_favorites.contains(code)) {
      _favorites.remove(code);
    } else {
      _favorites.add(code);
    }
    _saveFavorites();
    notifyListeners();
  }

  void updateGroups(List<Map<String, dynamic>> newGroups) {
    _groups = newGroups;
    _saveGroups();
    notifyListeners();
  }

  void setFundGroups(String fundCode, List<String> groupIds) {
    for (var group in _groups) {
      final String groupId = group['id'];
      final List<dynamic> codes = group['codes'];
      
      if (groupIds.contains(groupId)) {
        if (!codes.contains(fundCode)) {
          codes.add(fundCode);
        }
      } else {
        codes.remove(fundCode);
      }
    }
    _saveGroups();
    notifyListeners();
  }

  Future<void> updateHolding(String code, double cost, double share) async {
    if (share <= 0) {
      _holdings.remove(code);
    } else {
      _holdings[code] = {
        'cost': cost,
        'share': share,
      };
    }
    await _saveHoldings();
    _updateFundsWithHoldings();
    notifyListeners();
  }

  Future<void> removeHolding(String code) async {
    _holdings.remove(code);
    await _saveHoldings();
    _updateFundsWithHoldings();
    notifyListeners();
  }

  Future<void> _saveHoldings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('holdings', jsonEncode(_holdings));
    _scheduleSync();
  }

  Map<String, dynamic>? getHolding(String code) {
    return _holdings[code];
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('groups', jsonEncode(_groups));
    _scheduleSync();
  }


  Future<void> _saveFunds() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('funds', jsonEncode(_funds.map((f) => f.toJson()).toList()));
    _scheduleSync();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', _favorites.toList());
    _scheduleSync();
  }

  Future<void> _saveAll() async {
    await _saveFunds();
    await _saveFavorites();
    await _saveGroups();
    await _saveHoldings();
    await _saveSettings();
  }

  // Sync Implementation
  
  void _scheduleSync() {
    if (_skipSync) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_syncDebounce?.isActive ?? false) _syncDebounce!.cancel();
    
    _syncDebounce = Timer(const Duration(seconds: 2), () {
      syncToCloud();
    });
  }

  Future<void> syncToCloud() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final payload = _collectLocalPayload();
    
    try {
      await Supabase.instance.client.from('user_configs').upsert({
        'user_id': user.id,
        'config': payload,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Sync successful');
      
      // Show hint using global key
      if (rootScaffoldMessengerKey.currentState != null) {
        rootScaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(
            content: Text('同步成功'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Sync failed: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _collectLocalPayload() {
    return {
      'funds': _funds.map((f) => f.toJson()).toList(),
      'favorites': _favorites.toList(),
      'groups': _groups,
      'holdings': _holdings,
      'settings': {
        'refreshMs': _refreshMs,
        'privacyMode': _privacyMode,
      }
    };
  }

  Future<void> fetchCloudConfig() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user_configs')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response['config'] != null) {
        await _applyCloudConfig(response['config']);
      }
    } catch (e) {
      print('Fetch cloud config failed: $e');
    }
  }

  Future<void> _applyCloudConfig(Map<String, dynamic> config) async {
    _skipSync = true; // Prevent triggering sync when applying cloud config
    
    try {
      if (config['funds'] != null) {
        final List<dynamic> fundsJson = config['funds'];
        _funds = fundsJson.map((j) => Fund.fromJson(j)).toList();
      }
      
      if (config['favorites'] != null) {
        _favorites = Set<String>.from(config['favorites']);
      }
      
      if (config['groups'] != null) {
        _groups = List<Map<String, dynamic>>.from(config['groups']);
      }
      
      if (config['holdings'] != null) {
        _holdings = Map<String, Map<String, dynamic>>.from(config['holdings']);
      }
      
      if (config['settings'] != null) {
        final settings = config['settings'];
        _refreshMs = settings['refreshMs'] ?? 30000;
        _privacyMode = settings['privacyMode'] ?? false;
      }

      _updateFundsWithHoldings();
      await _saveAll(); // Save to local storage
      notifyListeners();
      refreshAll(); // Refresh market data
    } finally {
      _skipSync = false;
    }
  }
}
