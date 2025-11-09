import 'package:flutter/material.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = Provider.of<Auth>(context, listen: false);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '마이페이지 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
