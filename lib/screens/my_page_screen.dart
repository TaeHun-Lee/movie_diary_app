import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/providers/home_provider.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/screens/account_settings_screen.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/screens/my_diary_list_screen.dart';
import 'package:movie_diary_app/screens/personal_diary_screen.dart';
import 'package:movie_diary_app/screens/profile_edit_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => MyPageScreenState();
}

class MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refresh();
    });
  }

  Future<void> refresh() async {
    await Future.wait([
      context.read<HomeProvider>().fetchHomeData(forceRefresh: true),
      context.read<PostProvider>().fetchMyPosts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, PostProvider>(
      builder: (context, homeProvider, postProvider, child) {
        final homeData = homeProvider.homeData;
        final isLoading = homeProvider.isLoading && homeData == null;

        return Scaffold(
          backgroundColor: kSurface,
          appBar: const CustomAppBar(),
          body: SafeArea(
            top: false,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : homeData == null
                ? const Center(
                    child: Text(
                      'Failed to load profile.',
                      style: TextStyle(fontFamily: kBodyFont, color: kError),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileSection(
                          homeData: homeData,
                          onProfileUpdated: refresh,
                        ),
                        const SizedBox(height: 32),
                        _StatsSection(myPosts: postProvider.myPosts),
                        const SizedBox(height: 48),
                        _MenuSection(
                          homeData: homeData,
                          onRefresh: refresh,
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final HomeData homeData;
  final Future<void> Function() onProfileUpdated;

  const _ProfileSection({
    required this.homeData,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = ApiService.buildImageUrl(homeData.user.profileImage);

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurfaceHigh,
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
                homeData.user.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kOnSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                homeData.user.userId,
                style: const TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 14,
                  color: kOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileEditScreen(user: homeData.user),
              ),
            );
            if (result == true) {
              await onProfileUpdated();
            }
          },
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<DiaryEntry> myPosts;

  const _StatsSection({required this.myPosts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${myPosts.length}',
            label: '리뷰',
            color: kPrimary,
          ),
          Container(
            width: 1,
            height: 40,
            color: kOutlineVariant.withValues(alpha: 0.3),
          ),
          _StatItem(
            value: _averageRating(myPosts),
            label: '평균 평점',
            color: kOnSurface,
          ),
          Container(
            width: 1,
            height: 40,
            color: kOutlineVariant.withValues(alpha: 0.3),
          ),
          _StatItem(
            value: _favoriteGenre(myPosts),
            label: '선호 장르',
            color: kOnSurface,
          ),
        ],
      ),
    );
  }

  static String _averageRating(List<DiaryEntry> posts) {
    if (posts.isEmpty) return '0.0';
    final sum = posts.fold<double>(0, (acc, post) => acc + post.rating);
    return (sum / posts.length).toStringAsFixed(1);
  }

  static String _favoriteGenre(List<DiaryEntry> posts) {
    if (posts.isEmpty) return '-';
    final counts = <String, int>{};
    for (final post in posts) {
      for (final genre in post.movie.genres) {
        counts[genre] = (counts[genre] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '-';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: kBodyFont,
            fontSize: 12,
            color: kOnSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final HomeData homeData;
  final Future<void> Function() onRefresh;

  const _MenuSection({
    required this.homeData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          icon: Icons.search_rounded,
          label: '내 다이어리',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDiaryListScreen()),
            );
            await onRefresh();
          },
        ),
        _MenuItem(
          icon: Icons.book_rounded,
          label: '개인 일기',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalDiaryScreen()),
            );
          },
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          label: '계정 설정',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountSettingsScreen(user: homeData.user),
              ),
            );
          },
        ),
        _MenuItem(
          icon: Icons.logout_rounded,
          label: '로그아웃',
          color: kError,
          onTap: () async {
            await _logout(context);
          },
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorage.clearTokens();
    if (!context.mounted) return;
    context.read<Auth>().logout();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                  color: color == kError ? kError : kOnSurface,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: kOnSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
