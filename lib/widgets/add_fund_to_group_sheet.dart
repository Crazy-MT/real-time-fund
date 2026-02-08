import 'package:flutter/material.dart';
import '../models/fund.dart';

class AddFundToGroupSheet extends StatefulWidget {
  final List<Fund> allFunds;
  final List<String> currentGroupCodes;
  final Function(List<String>) onAdd;

  const AddFundToGroupSheet({
    super.key,
    required this.allFunds,
    required this.currentGroupCodes,
    required this.onAdd,
  });

  @override
  State<AddFundToGroupSheet> createState() => _AddFundToGroupSheetState();
}

class _AddFundToGroupSheetState extends State<AddFundToGroupSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final availableFunds = widget.allFunds
        .where((f) => !widget.currentGroupCodes.contains(f.code))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '添加基金到分组',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: availableFunds.isEmpty
                ? const Center(child: Text('没有可添加的基金'))
                : ListView.builder(
                    itemCount: availableFunds.length,
                    itemBuilder: (context, index) {
                      final fund = availableFunds[index];
                      final isSelected = _selected.contains(fund.code);
                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(fund.code);
                              } else {
                                _selected.remove(fund.code);
                              }
                            });
                          },
                        ),
                        title: Text(fund.name),
                        subtitle: Text(fund.code),
                        onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(fund.code);
                              } else {
                                _selected.add(fund.code);
                              }
                            });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      widget.onAdd(_selected.toList());
                      Navigator.pop(context);
                    },
              child: Text('添加 (${_selected.length})'),
            ),
          ),
        ],
      ),
    );
  }
}
