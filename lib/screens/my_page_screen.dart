import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _loadData;
  HomeData? _homeData;
  List<DiaryEntry>? _myPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final homeData = await ApiService.fetchHomeData();
      final myPosts = await ApiService.getMyPosts();
      return {'homeData': homeData, 'myPosts': myPosts};
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
              // TODO: 회원 탈퇴 기능 구현
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'logout', child: Text('로그아웃')),
              const PopupMenuItem<String>(
                value: 'delete_account',
                child: Text('회원 탈퇴'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('데이터를 불러오는데 실패했습니다: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _homeData = snapshot.data!['homeData'];
            _myPosts = snapshot.data!['myPosts'];
            return _buildMyPageContent();
          } else {
            return const Center(child: Text('데이터가 없습니다.'));
          }
        },
      ),
    );
  }

  Widget _buildMyPageContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildActivitySummary(),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '내가 쓴 다이어리'),
                  Tab(text: '내가 쓴 댓글'),
                  Tab(text: '좋아요 한 다이어리'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPostsList(),
          const Center(child: Text('준비 중인 기능입니다.')),
          const Center(child: Text('준비 중인 기능입니다.')),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          // backgroundImage: NetworkImage('...'), // 프로필 이미지 URL
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _homeData?.user.nickname ?? '사용자',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(_homeData?.user.userId ?? ''),
          ],
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () {
            // 프로필 수정 화면으로 이동
          },
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    final favoriteGenre = _calculateFavoriteGenre();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              '${_myPosts?.length ?? 0}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('작성한 다이어리'),
          ],
        ),
        const Column(
          children: [
            Text(
              '0', // TODO: 댓글 수
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('내가 남긴 댓글'),
          ],
        ),
        Column(
          children: [
            Text(
              favoriteGenre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('최애 장르'),
          ],
        ),
      ],
    );
  }

  String _calculateFavoriteGenre() {
    if (_myPosts == null || _myPosts!.isEmpty) {
      return 'N/A';
    }

    final genreCounts = <String, int>{};
    for (final post in _myPosts!) {
      for (final genre in post.movie.genres) {
        if (genre.isNotEmpty) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
    }

    if (genreCounts.isEmpty) {
      return 'N/A';
    }

    String favoriteGenre = '';
    int maxCount = 0;
    genreCounts.forEach((genre, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteGenre = genre;
      }
    });

    return favoriteGenre;
  }

  Widget _buildMyPostsList() {
    if (_myPosts == null || _myPosts!.isEmpty) {
      return const Center(child: Text('작성한 다이어리가 없습니다.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _myPosts!.length,
      itemBuilder: (context, index) {
        final post = _myPosts![index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryWriteScreen(entryToEdit: post),
                ),
              );
              // 수정/삭제 후 돌아왔을 때 화면을 새로고침
              if (result == true) {
                setState(() {
                  _loadData = _fetchData();
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.movie.posterUrl != null)
                    Image.network(
                      post.movie.posterUrl!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.movie, size: 80),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.movie.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(post.rating.toStringAsFixed(1)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '관람일: ${DateFormat('yyyy.MM.dd').format(DateTime.parse(post.watchedDate))}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 토큰 및 인증 상태 클리어
      await TokenStorage.clearTokens();
      Provider.of<Auth>(context, listen: false).logout();

      // 로그인 화면으로 이동하고 이전 기록 모두 삭제
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
