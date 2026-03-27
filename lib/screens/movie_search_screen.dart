import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/movie_detail_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MovieSearchScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MovieSearchScreen({super.key, this.onBack});

  @override
  State<MovieSearchScreen> createState() => MovieSearchScreenState();
}

class MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Movie> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _searchPerformed = false;
  String? _errorMessage;
  int _startCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreMovies();
    }
  }

  void reset() {
    _searchController.clear();
    setState(() {
      _movies = [];
      _searchPerformed = false;
      _errorMessage = null;
      _isLoading = false;
      _isLoadingMore = false;
      _startCount = 0;
    });
  }

  Future<void> _searchMovies() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _errorMessage = null;
      _startCount = 0;
      _movies = [];
    });

    try {
      final movies =
          await ApiService.searchMovies(query, startCount: 0);
      setState(() {
        _movies = movies;
        _startCount = movies.length;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영화 검색에 실패했습니다.')),
        );
      }
      setState(() => _errorMessage = '영화 검색에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMovies() async {
    setState(() => _isLoadingMore = true);
    try {
      final movies = await ApiService.searchMovies(
        _searchController.text,
        startCount: _startCount,
      );
      if (movies.isNotEmpty) {
        setState(() {
          _movies.addAll(movies);
          _startCount += movies.length;
        });
      }
    } catch (_) {
      // 조용히 실패
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '시네마 탐색',
                    style: TextStyle(
                      fontFamily: kHeadlineFont,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: kOnSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 검색 바 (Neuromorphic) ─────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: kSurfaceHigh,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 5,
                                offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontFamily: kBodyFont,
                              color: kOnSurface,
                              fontSize: 15,
                            ),
                            cursorColor: kPrimary,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: '영화 제목으로 검색...',
                              hintStyle: TextStyle(
                                color:
                                    kOnSurfaceVariant.withValues(alpha: 0.55),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: kOnSurfaceVariant,
                                size: 22,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded,
                                              color: kOnSurfaceVariant,
                                              size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _movies = [];
                                              _searchPerformed = false;
                                            });
                                          },
                                        )
                                      : null,
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
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
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                            ),
                            onSubmitted: (_) => _searchMovies(),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 검색 버튼
                      GestureDetector(
                        onTap: _searchMovies,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: kPrimaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 결과 영역 ──────────────────────────
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: kError),
        ),
      );
    }
    if (!_searchPerformed) {
      return _buildInitialState();
    }
    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: kOnSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              '"${_searchController.text}" 검색 결과가 없습니다.',
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 14,
                color: kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: _movies.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == _movies.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: kPrimary),
            ),
          );
        }
        return _buildMovieCard(_movies[index]);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kSurfaceHigh,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kSurfaceDim.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    offset: Offset(-3, -3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_filter_outlined,
                size: 36,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '영화 제목을 검색해보세요',
              style: TextStyle(
                fontFamily: kHeadlineFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '좋아하는 영화를 찾고\n다이어리를 작성해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 13,
                color: kOnSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kSurfaceDim.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 포스터
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 90,
                height: 130,
                child: movie.posterUrl != null
                    ? Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _posterPlaceholder(),
                      )
                    : _posterPlaceholder(),
              ),
            ),

            // 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 장르 칩
                    if (movie.genres.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: movie.genres.take(2).map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kSecondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              g,
                              style: const TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kOnSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (movie.genres.isNotEmpty) const SizedBox(height: 8),

                    // 제목
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 감독
                    Text(
                      movie.director,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 12,
                        color: kOnSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (movie.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        movie.summary,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 12,
                          color: kOnSurfaceVariant.withValues(alpha: 0.65),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 화살표
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right_rounded,
                  color: kOnSurfaceVariant.withValues(alpha: 0.4), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: kSurfaceHigh,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: kOnSurfaceVariant, size: 32),
      ),
    );
  }
}
