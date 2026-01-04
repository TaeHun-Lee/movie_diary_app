import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/home_content.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  Future<HomeData> _fetchHomeData() async {
    try {
      return await ApiService.fetchHomeData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('홈 데이터를 불러오는데 실패했습니다.')));
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: SafeArea(
        child: FutureBuilder<HomeData>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('데이터를 불러오지 못했습니다.'));
            } else {
              final data = snapshot.data!;
              return HomeContent(
                data: data,
                onRefresh: refresh,
                onSearchTap: widget.onSearchTap,
              );
            }
          },
        ),
      ),
    );
  }
}
