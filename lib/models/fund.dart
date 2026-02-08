class Fund {
  final String code;
  final String name;
  final String? dwjz; // 单位净值
  final String? gsz; // 估算值
  final String? gszzl; // 估算增长率
  final String? gztime; // 估值时间
  final String? jzrq; // 净值日期
  final String? zzl; // 增长率 (Real growth rate from Tencent)
  final double estPricedCoverage; // 估值覆盖率 (Not directly available, usually inferred or 1.0 if valid)
  final List<FundHolding> holdings;
  final double? userCost;
  final double? userShare;

  // Computed properties
  double get estimatedGrowth => double.tryParse(gszzl ?? '0') ?? 0.0;
  double get actualGrowth => double.tryParse(zzl ?? '0') ?? 0.0;
  
  // Display growth: use estimated (valuation) if available, otherwise actual (confirmed/Tencent)
  double get displayGrowth {
    if (gszzl != null && gszzl!.isNotEmpty) {
      return estimatedGrowth;
    }
    return actualGrowth;
  }

  double get currentNav => double.tryParse(dwjz ?? '0') ?? 0.0;
  double get estimatedNav => double.tryParse(gsz ?? '0') ?? 0.0;

  double get userMarketValue {
    if (userShare == null || userShare == 0) return 0.0;
    // User requested to strictly use confirmed NAV, ignoring estimated NAV
    return currentNav * userShare!;
  }

  double get userProfit {
    if (userShare == null || userShare == 0 || userCost == null) return 0.0;
    return userMarketValue - (userCost! * userShare!);
  }

  double get userProfitRate {
    if (userShare == null || userShare == 0 || userCost == null || userCost == 0) return 0.0;
    return (userProfit / (userCost! * userShare!)) * 100;
  }
  
  double get todayProfit {
      if (userShare == null || userShare == 0) return 0.0;

      // Strict check for today's data (Original Project Logic)
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final bool hasTodayData = jzrq == todayStr;
      final bool hasTodayValuation = gztime != null && gztime!.startsWith(todayStr);
      
      if (!hasTodayData && !hasTodayValuation) {
         return 0.0;
       }
       
       if (hasTodayData) {
          // If confirmed data is out, use actualGrowth (zzl)
          double rate = actualGrowth;
          // Fallback to estimatedGrowth if actualGrowth is 0 (consistent with JS)
          if (rate == 0 && estimatedGrowth != 0) {
              rate = estimatedGrowth;
          }
          
          if (rate == 0) return 0.0;
          
          // Profit = CurrentValue - BaseValue
          // BaseValue = CurrentValue / (1 + rate/100)
          return userMarketValue - (userMarketValue / (1 + rate / 100));
       } else {
          // Only valuation is available
          // userMarketValue is based on T-1 NAV (since hasTodayData is false)
          // Profit = T-1 Value * estimatedGrowth / 100
          if (estimatedGrowth != 0) {
            return userMarketValue * estimatedGrowth / 100;
          }
          return 0.0;
       }
  }

  Fund({
    required this.code,
    required this.name,
    this.dwjz,
    this.gsz,
    this.gszzl,
    this.gztime,
    this.jzrq,
    this.zzl,
    this.estPricedCoverage = 1.0,
    this.holdings = const [],
    this.userCost,
    this.userShare,
  });

  Fund copyWith({
    String? code,
    String? name,
    String? dwjz,
    String? gsz,
    String? gszzl,
    String? gztime,
    String? jzrq,
    String? zzl,
    double? estPricedCoverage,
    List<FundHolding>? holdings,
    double? userCost,
    double? userShare,
  }) {
    return Fund(
      code: code ?? this.code,
      name: name ?? this.name,
      dwjz: dwjz ?? this.dwjz,
      gsz: gsz ?? this.gsz,
      gszzl: gszzl ?? this.gszzl,
      gztime: gztime ?? this.gztime,
      jzrq: jzrq ?? this.jzrq,
      zzl: zzl ?? this.zzl,
      estPricedCoverage: estPricedCoverage ?? this.estPricedCoverage,
      holdings: holdings ?? this.holdings,
      userCost: userCost ?? this.userCost,
      userShare: userShare ?? this.userShare,
    );
  }

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      dwjz: json['dwjz'],
      gsz: json['gsz'],
      gszzl: json['gszzl'],
      gztime: json['gztime'],
      jzrq: json['jzrq'],
      zzl: json['zzl'],
      estPricedCoverage: json['estPricedCoverage']?.toDouble() ?? 1.0,
      holdings: (json['holdings'] as List?)
              ?.map((h) => FundHolding.fromJson(h))
              .toList() ??
          [],
      userCost: json['userCost']?.toDouble(),
      userShare: json['userShare']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'dwjz': dwjz,
      'gsz': gsz,
      'gszzl': gszzl,
      'gztime': gztime,
      'jzrq': jzrq,
      'zzl': zzl,
      'estPricedCoverage': estPricedCoverage,
      'holdings': holdings.map((h) => h.toJson()).toList(),
      'userCost': userCost,
      'userShare': userShare,
    };
  }
}

class FundHolding {
  final String code;
  final String name;
  final String weight;
  final double? change; // 涨跌幅

  FundHolding({
    required this.code,
    required this.name,
    required this.weight,
    this.change,
  });

  factory FundHolding.fromJson(Map<String, dynamic> json) {
    return FundHolding(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      weight: json['weight'] ?? '',
      change: json['change']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'weight': weight,
      'change': change,
    };
  }
}
