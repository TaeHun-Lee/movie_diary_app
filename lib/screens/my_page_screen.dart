import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:movie_diary_app/screens/my_diary_list_screen.dart';
import 'package:movie_diary_app/screens/personal_diary_screen.dart';
import 'package:movie_diary_app/screens/profile_edit_screen.dart';
import 'package:movie_diary_app/screens/account_settings_screen.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Future<Map<String, dynamic>>? _loadData;
  HomeData? _homeData;
  List<DiaryEntry>? _myPosts;

  @override
  void initState() {
    super.initState();
    _loadData = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final homeData = await ApiService.fetchHomeData();
      final myPosts = await ApiService.getMyPosts();
      return {'homeData': homeData, 'myPosts': myPosts};
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (mounted) {
        // Silently fail or log?
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '데이터를 불러오는데 실패했습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (snapshot.hasData) {
            _homeData = snapshot.data!['homeData'];
            _myPosts = snapshot.data!['myPosts'];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 30),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  _buildMenuSection(),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.white)),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey[800],
          backgroundImage: _homeData?.user.profileImage != null
              ? NetworkImage(
                  ApiService.buildImageUrl(_homeData!.user.profileImage)!,
                )
              : null,
          child: _homeData?.user.profileImage == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white.withOpacity(0.5),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _homeData?.user.nickname ?? '닉네임',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _homeData?.user.userId ?? 'ID',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            if (_homeData == null) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileEditScreen(user: _homeData!.user),
              ),
            );
            if (result == true) {
              setState(() {
                _loadData = _fetchData();
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('프로필 편집', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Darker grey for stats box
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${_myPosts?.length ?? 0}',
            '총 리뷰',
            color: const Color(0xFFE50914),
          ),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _buildStatItem(_calculateAverageRating(), '평균 별점', isRating: true),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _buildStatItem(_calculateFavoriteGenre(), '최애 장르'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label, {
    Color color = Colors.white,
    bool isRating = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRating) const Icon(Icons.star, color: Colors.white, size: 20),
            if (isRating) const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(Icons.search, '내 다이어리 검색', () async {
          // Show My Diary List in a new screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyDiaryListScreen()),
          );
          // Refresh MyPage stats when returning
          if (mounted) {
            setState(() {
              _loadData = _fetchData();
            });
          }
        }),
        _buildMenuItem(Icons.book, '개인 다이어리', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalDiaryScreen(),
            ),
          );
        }),
        _buildMenuItem(Icons.settings_outlined, '계정 설정', () {
          if (_homeData == null) return; // Ensure data is loaded
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AccountSettingsScreen(user: _homeData!.user),
            ),
          );
        }),

        _buildMenuItem(Icons.logout, '로그아웃', _logout),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateFavoriteGenre() {
    if (_myPosts == null || _myPosts!.isEmpty) {
      return '-';
    }
    final genreCounts = <String, int>{};
    for (final post in _myPosts!) {
      // Assuming post.movie.genres is List<String>
      for (final genre in post.movie.genres) {
        if (genre.isNotEmpty) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
    }
    if (genreCounts.isEmpty) return '-';

    var favoriteGenre = '';
    var maxCount = 0;
    genreCounts.forEach((genre, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteGenre = genre;
      }
    });
    return favoriteGenre.isNotEmpty ? favoriteGenre : '-';
  }

  String _calculateAverageRating() {
    if (_myPosts == null || _myPosts!.isEmpty) return '0.0';
    double sum = 0;
    for (var post in _myPosts!) {
      sum += post.rating;
    }
    return (sum / _myPosts!.length).toStringAsFixed(1);
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인', style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await TokenStorage.clearTokens();
      Provider.of<Auth>(context, listen: false).logout();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
