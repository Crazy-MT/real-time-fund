import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/fund_provider.dart';
import 'login_page.dart';
import 'account_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = Supabase.instance.client.auth.currentUser;
          
          return Consumer<FundProvider>(
            builder: (context, provider, child) {
              return ListView(
                children: [
                  _buildSectionHeader(context, '账号'),
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(user != null ? (user.email ?? '已登录') : '登录 / 注册'),
                    subtitle: user != null ? const Text('管理个人信息') : const Text('同步数据到云端'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (user != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountPage()),
                        );
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }
                    },
                  ),

                  _buildSectionHeader(context, '常规'),
                  SwitchListTile(
                    title: const Text('隐私模式'),
                    subtitle: const Text('隐藏所有金额显示'),
                    value: provider.privacyMode,
                    onChanged: (value) => provider.setPrivacyMode(value),
                  ),
                  ListTile(
                    title: const Text('自动刷新间隔'),
                    subtitle: Text(_getRefreshText(provider.refreshInterval)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRefreshDialog(context, provider),
                  ),

                  if (user != null) ...[
                    _buildSectionHeader(context, '数据同步'),
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: const Text('立即备份到云端'),
                      subtitle: const Text('手动上传当前数据'),
                      onTap: () => _handleManualBackup(context, provider),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: const Text('从云端恢复数据'),
                      subtitle: const Text('覆盖本地数据'),
                      onTap: () => _handleManualRestore(context, provider),
                    ),
                  ],
                  
                  _buildSectionHeader(context, '关于'),
                  ListTile(
                    title: const Text('支持作者'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSupportDialog(context),
                  ),
                  ListTile(
                    title: const Text('版本'),
                    trailing: const Text('1.0.0'),
                  ),
                ],
              );
            },
          );
        }
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('请我喝杯咖啡 ☕️'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('如果觉得好用，欢迎打赏支持！'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Image.asset('assets/weixin.png', width: 100, height: 100),
                    const SizedBox(height: 8),
                    const Text('微信支付', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Image.asset('assets/zhifubao.png', width: 100, height: 100),
                    const SizedBox(height: 8),
                    const Text('支付宝', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getRefreshText(int ms) {
    if (ms <= 0) return '手动刷新';
    if (ms < 60000) return '${ms ~/ 1000}秒';
    return '${ms ~/ 60000}分钟';
  }

  void _showRefreshDialog(BuildContext context, FundProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择刷新间隔'),
          children: [
            _buildRadioItem(context, provider, 5000, '5秒'),
            _buildRadioItem(context, provider, 10000, '10秒'),
            _buildRadioItem(context, provider, 30000, '30秒'),
            _buildRadioItem(context, provider, 60000, '1分钟'),
            _buildRadioItem(context, provider, 0, '手动刷新'),
          ],
        );
      },
    );
  }

  Widget _buildRadioItem(BuildContext context, FundProvider provider, int value, String label) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: provider.refreshInterval,
      onChanged: (int? newValue) {
        if (newValue != null) {
          provider.setRefreshInterval(newValue);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _handleManualBackup(BuildContext context, FundProvider provider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在备份...')),
      );
      await provider.syncToCloud();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
      }
    }
  }

  Future<void> _handleManualRestore(BuildContext context, FundProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('这将使用云端数据覆盖本地所有设置和数据，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在恢复...')),
          );
        }
        await provider.fetchCloudConfig();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('恢复成功')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('恢复失败: $e')),
          );
        }
      }
    }
  }
}
