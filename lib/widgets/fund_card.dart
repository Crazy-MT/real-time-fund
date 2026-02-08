import 'package:flutter/material.dart';
import '../models/fund.dart';

class FundCard extends StatelessWidget {
  final Fund fund;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onShowHoldings;
  final bool privacyMode;

  const FundCard({
    super.key,
    required this.fund,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onDelete,
    this.onTap,
    this.onLongPress,
    this.onShowHoldings,
    this.privacyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on growth
    // Red for positive, Green for negative (Chinese market convention)
    final double growth = fund.displayGrowth;
    final bool isUp = growth >= 0;
    final Color color = isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E); // Red-500, Green-500
    
    // Format values
    final String growthStr = '${growth > 0 ? '+' : ''}${growth.toStringAsFixed(2)}%';
    final String estimatedVal = fund.gsz ?? '--';
    final String valuationTime = fund.gztime ?? '--';
    final String navDate = fund.jzrq ?? '--';

    // Holding Info
    final bool hasHolding = fund.userShare != null && fund.userShare! > 0;
    final double profit = fund.userProfit;
    final double profitRate = fund.userProfitRate;
    final double todayProfit = fund.todayProfit;
    final double marketValue = fund.userMarketValue;
    final Color profitColor = profit >= 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return Dismissible(
      key: Key(fund.code),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("确认删除"),
              content: Text("确定要删除基金 ${fund.name} 吗？"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("删除", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (onDelete != null) onDelete!();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 0,
        color: Colors.white.withOpacity(0.05), // Glassy feel
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fund.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                        fund.code,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                            fontFamily: 'Monospace'
                                        ),
                                    ),
                                ),
                                if (fund.holdings.isNotEmpty) ...[
                                   const SizedBox(width: 8),
                                   GestureDetector(
                                     onTap: onShowHoldings,
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                       decoration: BoxDecoration(
                                           color: Colors.blue.withOpacity(0.2),
                                           borderRadius: BorderRadius.circular(4),
                                           border: Border.all(color: Colors.blue.withOpacity(0.5), width: 0.5)
                                       ),
                                       child: const Text(
                                           '重仓',
                                           style: TextStyle(
                                               fontSize: 10,
                                               color: Colors.blueAccent,
                                           ),
                                       ),
                                     ),
                                   ),
                                ],
                                if (isFavorite) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                ]
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          growthStr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontFamily: 'Roboto', // Better for numbers
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fund.gsz != null && fund.gsz!.isNotEmpty
                              ? '估算: ${fund.gsz}'
                              : '净值: ${fund.dwjz ?? '--'} (${fund.jzrq != null && fund.jzrq!.length >= 5 ? fund.jzrq!.substring(5) : '--'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasHolding) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '持有金额',
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                privacyMode ? '****' : marketValue.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '持有收益',
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                privacyMode ? '****' : '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: privacyMode ? Colors.white : profitColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '持有收益率',
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                privacyMode ? '****' : '${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: privacyMode ? Colors.white : profitColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '今日收益',
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                privacyMode ? '****' : '${todayProfit >= 0 ? '+' : ''}${todayProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: privacyMode ? Colors.white : (todayProfit >= 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.05),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '净值 ($navDate): ${fund.dwjz ?? '--'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      valuationTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
