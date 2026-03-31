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
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';

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
      backgroundColor: kSurface,
      appBar: const CustomAppBar(),
      body: SafeArea(
        top: false,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimary),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text(
                  '데이터를 불러오는데 실패했습니다.',
                  style: TextStyle(fontFamily: kBodyFont, color: kError),
                ),
              );
            } else if (snapshot.hasData) {
              _homeData = snapshot.data!['homeData'];
              _myPosts = snapshot.data!['myPosts'];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 32),
                    _buildStatsSection(),
                    const SizedBox(height: 48),
                    _buildMenuSection(),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text('데이터가 없습니다.',
                    style: TextStyle(fontFamily: kBodyFont, color: kOnSurfaceVariant)),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final profileImageUrl = _homeData?.user.profileImage != null
        ? ApiService.buildImageUrl(_homeData!.user.profileImage)
        : null;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurfaceHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: profileImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(profileImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: profileImageUrl == null
              ? const Icon(Icons.person, size: 40, color: kOnSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _homeData?.user.nickname ?? '닉네임',
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kOnSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _homeData?.user.userId ?? 'ID',
                style: const TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 14,
                  color: kOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
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
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '프로필 편집',
              style: TextStyle(
                fontFamily: kHeadlineFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${_myPosts?.length ?? 0}',
            '총 리뷰',
            color: kPrimary,
          ),
          Container(
            width: 1,
            height: 40,
            color: kOutlineVariant.withValues(alpha: 0.3),
          ),
          _buildStatItem(_calculateAverageRating(), '평균 별점',
              isRating: true, color: kOnSurface),
          Container(
            width: 1,
            height: 40,
            color: kOutlineVariant.withValues(alpha: 0.3),
          ),
          _buildStatItem(_calculateFavoriteGenre(), '최애 장르',
              color: kOnSurface),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label, {
    Color color = kOnSurface,
    bool isRating = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRating)
              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 22),
            if (isRating) const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: kHeadlineFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: kBodyFont,
            fontSize: 12,
            color: kOnSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(Icons.search_rounded, '내 다이어리 검색', () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyDiaryListScreen()),
          );
          if (mounted) {
            setState(() {
              _loadData = _fetchData();
            });
          }
        }),
        _buildMenuItem(Icons.book_rounded, '개인 다이어리', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalDiaryScreen(),
            ),
          );
        }),
        _buildMenuItem(Icons.settings_outlined, '계정 설정', () {
          if (_homeData == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AccountSettingsScreen(user: _homeData!.user),
            ),
          );
        }),
        _buildMenuItem(Icons.logout_rounded, '로그아웃', _logout, isDestructive: true),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? kError : kPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kHeadlineFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? kError : kOnSurface,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: kOnSurfaceVariant, size: 20),
              ],
            ),
          ),
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
      // Safely access movie and genres
      final genres = post.movie.genres;
      for (final genre in genres) {
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
        backgroundColor: kSurfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.w800,
            color: kOnSurface,
          ),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(
            fontFamily: kBodyFont,
            color: kOnSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w600,
                color: kOnSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '확인',
              style: TextStyle(
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w700,
                color: kError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await TokenStorage.clearTokens();
      if (!mounted) return;
      Provider.of<Auth>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
