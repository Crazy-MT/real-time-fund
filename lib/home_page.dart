import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/group_manage_page.dart';
import 'pages/settings_page.dart';
import 'providers/fund_provider.dart';
import 'models/fund.dart';
import 'widgets/fund_card.dart';
import 'widgets/add_fund_to_group_sheet.dart';
import 'widgets/holding_modals.dart';
import 'widgets/summary_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _showHoldings(BuildContext context, Fund fund) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            '${fund.name} - 前10持仓',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                        )
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context)
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: fund.holdings.isEmpty
                    ? const Center(child: Text('暂无持仓数据', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: fund.holdings.length,
                        separatorBuilder: (ctx, i) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final holding = fund.holdings[index];
                          final change = holding.change;
                          final isUp = change != null && change > 0;
                          final isDown = change != null && change < 0;
                          final color = isUp ? const Color(0xFFEF4444) : (isDown ? const Color(0xFF22C55E) : Colors.grey);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(holding.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                            subtitle: Text('${holding.code} • 占比 ${holding.weight}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            trailing: Text(
                              change != null ? '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%' : '--',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // Rebuild to update the "Add" button action
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FundProvider>(
      builder: (context, provider, child) {
        // Prepare tabs: All, Favorites, and Groups
        final List<String> tabs = ['All', 'Favorites', ...provider.groups.map((g) => g['id'] as String)];
        final List<String> tabNames = ['全部基金', '特别关注', ...provider.groups.map((g) => g['name'] as String)];

        // Initialize or update tab controller
        if (_tabController == null || _tabController!.length != tabs.length) {
            final oldIndex = _tabController?.index ?? 0; // Default to 'All' (index 0)
            _tabController?.removeListener(_handleTabChange);
            _tabController?.dispose();

            _tabController = TabController(
                length: tabs.length,
                vsync: this,
                initialIndex: oldIndex < tabs.length ? oldIndex : 0
            );
            _tabController!.addListener(_handleTabChange);
        }

        // Determine current tab context
        final currentIndex = _tabController!.index;
        final currentTabId = tabs[currentIndex];
        final isGroupTab = currentIndex >= 2;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '输入基金代码添加...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                            try {
                                await provider.addFund(value);
                                _searchController.clear();
                                setState(() {
                                    _isSearching = false;
                                });
                            } catch (e) {
                                print('Add fund failed: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('添加失败: $e')),
                                );
                            }
                        }
                    },
                  )
                : const Text('Real Time Fund', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (_isSearching)
                 IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                    });
                  },
                )
              else
                 IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (isGroupTab) {
                        // Add funds to current group
                        final group = provider.groups.firstWhere((g) => g['id'] == currentTabId);
                        final currentCodes = List<String>.from(group['codes'] ?? []);

                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => AddFundToGroupSheet(
                                allFunds: provider.funds,
                                currentGroupCodes: currentCodes,
                                onAdd: (selectedCodes) {
                                    final newCodes = [...currentCodes, ...selectedCodes];
                                    final newGroups = provider.groups.map((g) {
                                        if (g['id'] == currentTabId) {
                                            return {...g, 'codes': newCodes};
                                        }
                                        return g;
                                    }).toList();
                                    provider.updateGroups(newGroups);
                                },
                            ),
                        );
                    } else {
                        // Add new fund to library
                        setState(() {
                          _isSearching = true;
                        });
                    }
                  },
                ),
               IconButton(
                icon: provider.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh),
                onPressed: provider.loading ? null : () => provider.refreshAll(),
              ),
              PopupMenuButton<FundSortType>(
                icon: const Icon(Icons.sort),
                tooltip: '排序',
                onSelected: (type) {
                  provider.setSort(type);
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: FundSortType.defaultSort,
                      child: Row(
                        children: [
                          const Text('默认排序'),
                          if (provider.sortType == FundSortType.defaultSort)
                            const SizedBox(width: 8),
                          if (provider.sortType == FundSortType.defaultSort)
                            const Icon(Icons.check, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FundSortType.change,
                      child: Row(
                        children: [
                          const Text('涨跌幅'),
                          if (provider.sortType == FundSortType.change) ...[
                             const SizedBox(width: 8),
                             Icon(provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Colors.blue),
                          ]
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FundSortType.profit,
                      child: Row(
                        children: [
                          const Text('持有收益'),
                          if (provider.sortType == FundSortType.profit) ...[
                             const SizedBox(width: 8),
                             Icon(provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Colors.blue),
                          ]
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FundSortType.profitRate,
                      child: Row(
                        children: [
                          const Text('持有收益率'),
                          if (provider.sortType == FundSortType.profitRate) ...[
                             const SizedBox(width: 8),
                             Icon(provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Colors.blue),
                          ]
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: FundSortType.name,
                      child: Row(
                        children: [
                          const Text('名称'),
                          if (provider.sortType == FundSortType.name) ...[
                             const SizedBox(width: 8),
                             Icon(provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Colors.blue),
                          ]
                        ],
                      ),
                    ),
                  ];
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                    if (value == 'manage_groups') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GroupManagePage()),
                        );
                    } else if (value == 'settings') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                    }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'manage_groups',
                      child: Text('管理分组'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Text('设置'),
                    ),
                  ];
                },
              ),
            ],
            bottom: null,
          ),
          body: Column(
            children: [
               SummaryCard(
                totalMarketValue: provider.totalMarketValue,
                totalDailyProfit: provider.totalDailyProfit,
                totalProfit: provider.totalProfit,
                totalProfitRate: provider.totalProfitRate,
                privacyMode: provider.privacyMode,
               ),
               TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: tabNames.map((name) => Tab(text: name)).toList(),
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tabs.map((tabId) {
                      return _buildFundList(context, provider, tabId);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFundList(BuildContext context, FundProvider provider, String tabId) {
    List<Fund> funds = [];

    if (tabId == 'All') {
        funds = provider.funds;
    } else if (tabId == 'Favorites') {
        funds = provider.funds.where((f) => provider.favorites.contains(f.code)).toList();
    } else {
        // Group
        final group = provider.groups.firstWhere((g) => g['id'] == tabId, orElse: () => {});
        if (group.isNotEmpty) {
            final List<dynamic> codes = group['codes'] ?? [];
            funds = provider.funds.where((f) => codes.contains(f.code)).toList();
        }
    }

    if (funds.isEmpty) {
        return const Center(
            child: Text('暂无基金', style: TextStyle(color: Colors.grey)),
        );
    }

    return RefreshIndicator(
        onRefresh: () => provider.refreshAll(),
        child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: funds.length,
            itemBuilder: (context, index) {
                final fund = funds[index];
                return FundCard(
                    fund: fund,
                    isFavorite: provider.favorites.contains(fund.code),
                    privacyMode: provider.privacyMode,
                    onToggleFavorite: () => provider.toggleFavorite(fund.code),
                    onDelete: () => provider.removeFund(fund.code),
                    onShowHoldings: () => _showHoldings(context, fund),
                    onTap: () => _showHoldingActions(context, provider, fund),
                    onLongPress: () async {
                      final url = Uri.parse('http://fund.eastmoney.com/${fund.code}.html');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                );
            },
        ),
    );
  }

  void _showHoldingActions(BuildContext context, FundProvider provider, Fund fund) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => HoldingActionSheet(
        fund: fund,
        onBuy: () {
            // Navigator.pop(context); // Already popped in widget
            _showTradeSheet(context, provider, fund, true);
        },
        onSell: () {
            // Navigator.pop(context);
            _showTradeSheet(context, provider, fund, false);
        },
        onEdit: () {
            // Navigator.pop(context);
            _showEditSheet(context, provider, fund);
        },
        onToggleFavorite: () {
            provider.toggleFavorite(fund.code);
        },
        onClear: () {
            // Navigator.pop(context);
             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: const Text('清空持仓'),
                    content: const Text('确定要清空该基金的持仓记录吗？'),
                    actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                        TextButton(
                            onPressed: () {
                                provider.removeHolding(fund.code);
                                Navigator.pop(context);
                            },
                            child: const Text('确定', style: TextStyle(color: Colors.red))
                        ),
                    ],
                )
             );
        },
      ),
    );
  }

  void _showTradeSheet(BuildContext context, FundProvider provider, Fund fund, bool isBuy) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => TradeSheet(
              fund: fund,
              isBuy: isBuy,
              onConfirm: (deltaShare, transactionAmount) {
                  final oldShare = fund.userShare ?? 0.0;
                  final oldCost = fund.userCost ?? 0.0; // Unit cost

                  if (isBuy) {
                      final newShare = oldShare + deltaShare;
                      final newTotalCost = (oldShare * oldCost) + transactionAmount;
                      final newUnitCost = newShare > 0 ? newTotalCost / newShare : 0.0;

                      provider.updateHolding(fund.code, newUnitCost, newShare);
                  } else {
                      final newShare = oldShare - deltaShare;
                      if (newShare <= 0) {
                          provider.removeHolding(fund.code);
                      } else {
                          provider.updateHolding(fund.code, oldCost, newShare);
                      }
                  }
              },
          )
      );
  }

  void _showEditSheet(BuildContext context, FundProvider provider, Fund fund) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => HoldingEditSheet(
              fund: fund,
              holding: provider.getHolding(fund.code),
              onSave: (newShare, newUnitCost) {
                   if (newShare <= 0) {
                       provider.removeHolding(fund.code);
                   } else {
                       provider.updateHolding(fund.code, newUnitCost, newShare);
                   }
              },
          )
      );
  }
}


