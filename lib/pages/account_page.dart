import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('账号信息')),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('邮箱'),
              subtitle: Text(user.email ?? '未知'),
            ),
            ListTile(
              leading: const Icon(Icons.perm_identity),
              title: const Text('用户ID'),
              subtitle: Text(user.id),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('退出登录'),
              ),
            ),
          ] else ...[
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('未登录'),
             )
          ],
        ],
      ),
    );
  }
}
