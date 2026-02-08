import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fund_provider.dart';

class GroupManagePage extends StatefulWidget {
  const GroupManagePage({super.key});

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  late List<Map<String, dynamic>> _localGroups;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FundProvider>(context, listen: false);
    // Deep copy to allow local editing before save
    _localGroups = provider.groups.map((g) => Map<String, dynamic>.from(g)).toList();
  }

  void _save() {
    final provider = Provider.of<FundProvider>(context, listen: false);
    provider.updateGroups(_localGroups);
    Navigator.pop(context);
  }

  void _addGroup() {
    setState(() {
      _localGroups.add({
        'id': 'group_${DateTime.now().millisecondsSinceEpoch}',
        'name': '新分组',
        'codes': [],
      });
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _localGroups.removeAt(index);
    });
  }

  void _renameGroup(int index, String newName) {
    setState(() {
      _localGroups[index]['name'] = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理分组'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _localGroups.removeAt(oldIndex);
            _localGroups.insert(newIndex, item);
          });
        },
        children: [
          for (int index = 0; index < _localGroups.length; index++)
            ListTile(
              key: Key(_localGroups[index]['id']),
              title: TextFormField(
                initialValue: _localGroups[index]['name'],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (value) => _renameGroup(index, value),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeGroup(index),
              ),
              leading: const Icon(Icons.drag_handle),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
}
