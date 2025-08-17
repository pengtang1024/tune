import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/data/services/persistence_service.dart';

class AccountTab extends ConsumerStatefulWidget {
  const AccountTab({super.key});

  @override
  ConsumerState<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<AccountTab> {
  final _usernameController = TextEditingController();
  bool _autoLogin = false;
  bool _savePassword = false;

  @override
  void initState() {
    super.initState();
    _loadAccountSettings();
  }

  Future<void> _loadAccountSettings() async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    
    final username = persistenceService.getString('account_username') ?? '';
    final autoLogin = persistenceService.getBool('account_auto_login') ?? false;
    final savePassword = persistenceService.getBool('account_save_password') ?? false;
    
    setState(() {
      _usernameController.text = username;
      _autoLogin = autoLogin;
      _savePassword = savePassword;
    });
  }

  Future<void> _saveAccountSettings() async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    
    await persistenceService.setString('account_username', _usernameController.text);
    await persistenceService.setBool('account_auto_login', _autoLogin);
    await persistenceService.setBool('account_save_password', _savePassword);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账号设置已保存')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '账号设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('自动登录'),
            value: _autoLogin,
            onChanged: (value) {
              setState(() {
                _autoLogin = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('保存密码'),
            value: _savePassword,
            onChanged: (value) {
              setState(() {
                _savePassword = value ?? false;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveAccountSettings,
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }
}