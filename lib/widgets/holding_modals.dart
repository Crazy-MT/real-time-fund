import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fund.dart';
import '../providers/fund_provider.dart';
import 'package:intl/intl.dart';

// Holding Action Sheet
class HoldingActionSheet extends StatelessWidget {
  final Fund fund;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  final VoidCallback onToggleFavorite;

  const HoldingActionSheet({
    super.key,
    required this.fund,
    required this.onBuy,
    required this.onSell,
    required this.onEdit,
    required this.onClear,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 8),
                  const Text('持仓操作', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(fund.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('#${fund.code}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onBuy();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                  child: const Text('加仓'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSell();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('减仓'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onToggleFavorite();
              },
              child: const Text('特别关注 / 取消关注'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              child: const Text('编辑持仓'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => GroupSelectionSheet(fundCode: fund.code),
                );
              },
              child: const Text('设置分组'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onClear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[900],
              ),
              child: const Text('清空持仓'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Trade Sheet (Buy/Sell)
class TradeSheet extends StatefulWidget {
  final Fund fund;
  final bool isBuy;
  final Function(double share, double cost) onConfirm;

  const TradeSheet({
    super.key,
    required this.fund,
    required this.isBuy,
    required this.onConfirm,
  });

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  final _amountController = TextEditingController();
  final _feeController = TextEditingController(text: '0.12'); // Default fee
  final _shareController = TextEditingController();

  // Buy specific
  DateTime _date = DateTime.now();
  bool _isAfter3pm = false;
  double? _calcShare;

  // Common
  late double _price;

  @override
  void initState() {
    super.initState();
    _price = widget.fund.currentNav;
    if (_price <= 0) _price = 1.0; // Fallback

    _isAfter3pm = DateTime.now().hour >= 15;

    _amountController.addListener(_calculateShare);
    _feeController.addListener(_calculateShare);
  }

  void _calculateShare() {
    if (!widget.isBuy) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = double.tryParse(_feeController.text) ?? 0;

    if (amount > 0 && _price > 0) {
      final netAmount = amount / (1 + fee / 100);
      setState(() {
        _calcShare = netAmount / _price;
      });
    } else {
      setState(() {
        _calcShare = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(widget.isBuy ? '📥' : '📤', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(widget.isBuy ? '加仓' : '减仓', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.fund.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('#${widget.fund.code}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          if (widget.isBuy) ...[
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '加仓金额 (¥)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '买入费率 (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '加仓日期',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('交易时段: '),
                ChoiceChip(
                  label: const Text('15:00前'),
                  selected: !_isAfter3pm,
                  onSelected: (val) => setState(() => _isAfter3pm = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('15:00后'),
                  selected: _isAfter3pm,
                  onSelected: (val) => setState(() => _isAfter3pm = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isAfter3pm ? '将在下一个交易日确认份额' : '将在当日确认份额',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_calcShare != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('预计确认份额'),
                    Text('${_calcShare!.toStringAsFixed(2)} 份', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ]
          ] else ...[
            TextField(
              controller: _shareController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '卖出份额',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isBuy) {
                      final amount = double.tryParse(_amountController.text);
                      if (amount == null || _calcShare == null) return;
                      // Calculate average cost update logic handled by parent or provider?
                      // The modal should return the new share and cost impact?
                      // For simplicity, we just pass share and price, let provider handle logic
                      // Actually, the provider logic needs old holding info to update average cost.
                      // We will handle the math in provider or here.
                      // Let's pass the calculated share and total cost (amount)
                      // Wait, onConfirm signature is (share, cost).
                      // Cost here implies Unit Cost or Total Cost?
                      // In HoldingEditModal, it returns (finalShare, finalUnitCost).
                      // Let's align: onConfirm(deltaShare, transactionAmount) might be better?
                      // Or just return the values needed.

                      // For Buy:
                      // Share = _calcShare
                      // Cost (Total) = amount
                      // We need to mix this with existing holding.
                      // Let's do the mixing in the parent/provider.
                      // Here we return what happened.

                      // But wait, the interface is generic.
                      // Let's change onConfirm to dynamic or handle logic here?
                      // Best to keep widget dumb.
                      // But the parent needs to know if it was buy or sell.
                      // The parent knows because it passed `isBuy`.

                      // For Buy: return (share, totalCost)
                      widget.onConfirm(_calcShare!, amount);
                    } else {
                      final share = double.tryParse(_shareController.text);
                      if (share == null) return;
                      // For Sell: return (share, 0) - cost doesn't change unit cost, but total cost reduces
                      // Actually sell reduces share, realizes profit. Unit cost stays same.
                      widget.onConfirm(share, 0);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Holding Edit Sheet
class HoldingEditSheet extends StatefulWidget {
  final Fund fund;
  final Map<String, dynamic>? holding;
  final Function(double share, double cost) onSave;

  const HoldingEditSheet({
    super.key,
    required this.fund,
    this.holding,
    required this.onSave,
  });

  @override
  State<HoldingEditSheet> createState() => _HoldingEditSheetState();
}

class _HoldingEditSheetState extends State<HoldingEditSheet> {
  bool _isAmountMode = true;

  final _amountController = TextEditingController();
  final _profitController = TextEditingController();
  final _shareController = TextEditingController();
  final _costController = TextEditingController();

  late double _nav;

  @override
  void initState() {
    super.initState();

    // Referencing JS project's HoldingEditModal logic
    // FundService already ensures dwjz is the latest confirmed NAV (prioritizing Tencent data)
    // User instruction: strictly use confirmed NAV (dwjz/currentNav).

    _nav = widget.fund.currentNav;

    if (_nav <= 0) _nav = 1.0;

    if (widget.holding != null) {
      final share = (widget.holding!['share'] ?? 0).toDouble();
      final cost = (widget.holding!['cost'] ?? 0).toDouble();

      _shareController.text = share.toString();
      _costController.text = cost.toString();

      final amount = share * _nav;
      final profit = (_nav - cost) * share;

      _amountController.text = amount.toStringAsFixed(2);
      _profitController.text = profit.toStringAsFixed(2);
    }
  }

  void _switchMode(bool isAmount) {
    if (_isAmountMode == isAmount) return;

    setState(() {
      _isAmountMode = isAmount;
      if (isAmount) {
        // Share/Cost -> Amount/Profit
        final share = double.tryParse(_shareController.text) ?? 0;
        final cost = double.tryParse(_costController.text) ?? 0;
        final amount = share * _nav;
        final profit = (_nav - cost) * share;
        _amountController.text = amount.toStringAsFixed(2);
        _profitController.text = profit.toStringAsFixed(2);
      } else {
        // Amount/Profit -> Share/Cost
        final amount = double.tryParse(_amountController.text) ?? 0;
        final profit = double.tryParse(_profitController.text) ?? 0;
        if (_nav > 0) {
          final share = amount / _nav;
          final principal = amount - profit;
          final cost = share > 0 ? principal / share : 0;
          _shareController.text = share.toStringAsFixed(2);
          _costController.text = cost.toStringAsFixed(4);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  const Text('设置持仓', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.fund.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text('#${widget.fund.code}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('最新净值', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_nav.toStringAsFixed(4), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isAmountMode ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('按金额', style: TextStyle(fontWeight: _isAmountMode ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isAmountMode ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('按份额', style: TextStyle(fontWeight: !_isAmountMode ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isAmountMode) ...[
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '持有金额',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _profitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: '持有收益 (可为负)',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            TextField(
              controller: _shareController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '持有份额',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '持仓成本价',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    double finalShare = 0;
                    double finalCost = 0;

                    if (_isAmountMode) {
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      final profit = double.tryParse(_profitController.text) ?? 0;
                      if (_nav > 0) {
                        finalShare = amount / _nav;
                        final principal = amount - profit;
                        finalCost = finalShare > 0 ? principal / finalShare : 0;
                      }
                    } else {
                      finalShare = double.tryParse(_shareController.text) ?? 0;
                      finalCost = double.tryParse(_costController.text) ?? 0;
                    }

                    widget.onSave(finalShare, finalCost);
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GroupSelectionSheet extends StatefulWidget {
  final String fundCode;

  const GroupSelectionSheet({super.key, required this.fundCode});

  @override
  State<GroupSelectionSheet> createState() => _GroupSelectionSheetState();
}

class _GroupSelectionSheetState extends State<GroupSelectionSheet> {
  final Set<String> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FundProvider>(context, listen: false);
    for (var group in provider.groups) {
      final List<dynamic> codes = group['codes'] ?? [];
      if (codes.contains(widget.fundCode)) {
        _selectedGroupIds.add(group['id']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FundProvider>(context);
    final groups = provider.groups;

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('设置分组', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            const Expanded(child: Center(child: Text('暂无分组，请先在主页添加分组')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final groupId = group['id'] as String;
                  final isSelected = _selectedGroupIds.contains(groupId);

                  return CheckboxListTile(
                    title: Text(group['name'] as String),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedGroupIds.add(groupId);
                        } else {
                          _selectedGroupIds.remove(groupId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                provider.setFundGroups(widget.fundCode, _selectedGroupIds.toList());
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
