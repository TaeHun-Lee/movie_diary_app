import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/movie_detail_screen.dart';
import 'package:movie_diary_app/screens/community_feed_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieSearchScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MovieSearchScreen({super.key, this.onBack});

  @override
  State<MovieSearchScreen> createState() => MovieSearchScreenState();
}

class MovieSearchScreenState extends State<MovieSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void reset() {
    // 탭 리셋 시 필요한 로직
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    if (query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final results = await ApiService.searchMovies(query);
      setState(() {
        _movies = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영화 검색에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: const CustomAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMovieSearchTab(),
                  const CommunityFeedScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: kSurfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: kPrimaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: kOnSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: '영화 검색'),
          Tab(text: '커뮤니티'),
        ],
      ),
    );
  }

  Widget _buildMovieSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            controller: _searchController,
            decoration: neuInputDecoration(
              hint: '영화 제목을 입력하세요...',
              prefix: const Icon(Icons.search_rounded),
            ),
            onSubmitted: _onSearch,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _movies.isEmpty
                  ? _buildInitialState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: _movies.length,
                      itemBuilder: (context, index) => _buildMovieCard(_movies[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 80, color: kSurfaceDim),
          const SizedBox(height: 20),
          Text(
            _lastQuery.isEmpty ? '궁금한 영화를 검색해보세요!' : '검색 결과가 없습니다.',
            style: TextStyle(color: kOnSurfaceVariant.withValues(alpha: 0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movie: movie),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (movie.posterUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ApiService.buildImageUrl(movie.posterUrl)!,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie.director} | ${movie.releaseDate.substring(0, 4)}',
                      style: TextStyle(color: kOnSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: movie.genres.take(3).map((g) => Chip(
                        label: Text(g, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Neuromorphic 인셋 입력 필드 데코레이션 헬퍼
  // ─────────────────────────────────────────────────────────────
  InputDecoration neuInputDecoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? label,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: kSurfaceHigh,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: kPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }
}
