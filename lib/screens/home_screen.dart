import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/home_content.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? accessToken;
  const HomeScreen({super.key, required this.accessToken});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;
  String? nickname;
  int? todayCount;
  int? totalCount;
  List<Map<String, dynamic>>? recentEntries;
  late Future<HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _homeDataFuture = ApiService.fetchHomeData(widget.accessToken!);
  }

  Future<void> _loadUserData() async {
    try {
      userId = await TokenStorage.getUserId();

      await ApiService.getUserInfo(userId!).then((response) {
        userId = response['user_id'];
        nickname = response['nickname'];
      });

      if (userId == null || nickname == null) {
        throw Exception('사용자 정보가 없습니다. 다시 로그인해주세요.');
      }
    } catch (e) {
      setState(() {
        userId = null;
        nickname = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: ${e.toString()}')));
    }
  }

  Future<void> _logout() async {
    // 서버 요청도 추가하고 싶으면 여기에 API 호출 추가 가능
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    if (!mounted) return;
    // 로그인 화면으로 이동
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
            return HomeContent(data: data);
          }
        },
      ),
    );
  }
}
