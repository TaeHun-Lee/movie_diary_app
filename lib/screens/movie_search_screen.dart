import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/movie_detail_modal.dart';
import 'package:movie_diary_app/data/movie.dart';
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
  final int _limit = 100;

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
    if (_searchController.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _errorMessage = null;
      _startCount = 0;
      _movies = []; // Clear previous results
    });

    try {
      final movies = await ApiService.searchMovies(
        _searchController.text,
        startCount: 0,
      );
      setState(() {
        _movies = movies;
        _startCount = movies.length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('영화 검색에 실패했습니다.')));
      }
      setState(() {
        _errorMessage = '영화 검색에 실패했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMovies() async {
    setState(() {
      _isLoadingMore = true;
    });

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
    } catch (e) {
      // Quietly fail or show small indicator? quiet for now.
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          '영화 검색',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Custom Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Dark Grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors
                      .transparent, // Ensure TextField itself is transparent
                  hintText: '영화 제목...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon:
                      _searchController.text.isNotEmpty ||
                          _searchPerformed // Show clear button if text exists or was searched
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _movies = [];
                              _searchPerformed = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none, // Remove global borders
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _searchMovies(),
                textInputAction: TextInputAction.search,
              ),
            ),

            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : _searchPerformed && _movies.isEmpty
                  ? const Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _movies.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _movies.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }
                        final movie = _movies[index];
                        return _buildMovieCard(movie);
                      },
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
        final result = await showMovieDetailModal(context, movie);
        if (result == true && context.mounted) {
          // Handle result if needed
          // Navigator.pop(context, true); // Don't pop if tab based
        }
      },
      child: Container(
        height: 140, // Fixed height for consistency
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C), // Card background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Movie Poster (Left) with Padding
            Padding(
              padding: const EdgeInsets.all(8.0), // Added padding around image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  8,
                ), // Rounded all corners inside padding
                child: SizedBox(
                  width: 90, // Slightly smaller to fit padding
                  height: double.infinity,
                  child: movie.posterUrl != null
                      ? Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white54,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.white54),
                        ),
                ),
              ),
            ),

            // Movie Info (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Director & Year (Assuming Director + placeholder year if not available)
                    Text(
                      movie
                          .director, // + ' / 2019' (Year is not in Movie model yet)
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Rating (Faked for KMDB as it might not be in search result, using random/placeholder or if API provides it)
                    // The Movie model does NOT have rating. The design shows "4.8 (Kmdb)".
                    // Since we don't have rating in Movie model from search, we can either hide it or show a placeholder.
                    // For now, I'll omit it or show a placeholder if desired.
                    // Let's check the design. It shows "4.8 (Kmdb)".
                    // I will check the Movie model again.
                    // Movie model: docId, title, director, summary, posterUrl, stillCutUrls, genres.
                    // No rating. I will omit the star rating row for now or put a dummy one if strictly requested, but better to omit if data is missing.
                    // Wait, the previous screen (Home) had 'DiaryEntry' which has 'rating' (user rating).
                    // This is 'Movie Search', returning 'Movie' objects from API. External API movies usually don't have 'my rating'.
                    // Maybe it's 'average rating'? The design implies it.
                    // I will add the Star icon but with a static text or just Director/Genre for now to keep it real.
                    // Actually, the user asked to "Implement Search Result List Item Style".
                    // I will replicate the STYLE.
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '0.0', // Removed (Kmdb)
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
