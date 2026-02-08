import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalMarketValue;
  final double totalDailyProfit;
  final double totalProfit;
  final double totalProfitRate;
  final bool privacyMode;

  const SummaryCard({
    super.key,
    required this.totalMarketValue,
    required this.totalDailyProfit,
    required this.totalProfit,
    this.totalProfitRate = 0.0,
    this.privacyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Theme.of(context).colorScheme.background,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Text('总资产', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              privacyMode ? '****' : currencyFormat.format(totalMarketValue),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto', // Better for numbers
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildItem(
                    context, 
                    '当日盈亏', 
                    totalDailyProfit,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white10),
                Expanded(
                  child: _buildItem(
                    context, 
                    '持有收益', 
                    totalProfit,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white10),
                Expanded(
                  child: _buildItem(
                    context, 
                    '持有收益率', 
                    totalProfitRate,
                    isRate: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String label, double value, {bool isRate = false}) {
    final color = value > 0 
        ? const Color(0xFFFF4D4F) // Red
        : value < 0 
            ? const Color(0xFF52C41A) // Green
            : Colors.white70;
    
    final prefix = value > 0 ? '+' : '';
    final formatted = isRate 
        ? '${value.toStringAsFixed(2)}%'
        : NumberFormat.currency(symbol: '', decimalDigits: 2).format(value);

    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          privacyMode ? '****' : '$prefix$formatted',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: privacyMode ? Colors.white : color,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
