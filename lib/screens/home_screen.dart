import 'package:flutter/material.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/component/home_content.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  Future<HomeData> _fetchHomeData() async {
    return ApiService.fetchHomeData();
  }

  Future<void> _refreshHomeData() async {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  Future<void> _logout() async {
    final auth = Provider.of<Auth>(context, listen: false);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movie Diary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: FutureBuilder<HomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('데이터를 불러오지 못했습니다.'));
          } else {
            final data = snapshot.data!;
            return HomeContent(data: data, onRefresh: _refreshHomeData);
          }
        },
      ),
    );
  }
}
