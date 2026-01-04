import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';

class HomeContent extends StatefulWidget {
  final HomeData data;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearchTap;

  const HomeContent({
    super.key,
    required this.data,
    this.onRefresh,
    this.onSearchTap,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    // 1. Extract Unique Genres
    final allGenres =
        widget.data.recentEntries.expand((e) => e.movie.genres).toSet().toList()
          ..sort();
    final categories = ['전체', ...allGenres];

    // 2. Filter Entries
    final filteredEntries = _selectedGenre == '전체'
        ? widget.data.recentEntries
        : widget.data.recentEntries
              .where((e) => e.movie.genres.contains(_selectedGenre))
              .toList();

    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GestureDetector(
            onTap: () async {
              if (widget.onSearchTap != null) {
                widget.onSearchTap!();
              } else {
                // 검색 화면으로 이동
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MovieSearchScreen(),
                  ),
                );
                if (result == true) {
                  widget.onRefresh?.call();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Dark grey for search bar
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '영화 검색...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Category Chips (Dynamic)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryChip(
                  category,
                  isSelected: category == _selectedGenre,
                ),
              );
            }).toList(),
          ),
        ),

        // 3. Movie Grid
        Expanded(child: _buildMovieGrid(filteredEntries)),
      ],
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGenre = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE51937) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<dynamic> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('저장된 영화가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52, // Shortened height (increased ratio)
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildMovieCard(context, entry);
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, dynamic entry) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryWriteScreen(entryToEdit: entry),
          ),
        );
        if (result == true) {
          widget.onRefresh?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Card background color
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias, // Clip image to radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with Padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  10,
                  10,
                  0,
                ), // Increased padding
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Inner radius
                    image: DecorationImage(
                      image: NetworkImage(entry.movie.posterUrl ?? ''),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                    color: Colors.grey[800],
                  ),
                  child: entry.movie.posterUrl == null
                      ? const Center(
                          child: Icon(Icons.movie, color: Colors.white54),
                        )
                      : null,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Star Rating (Scaled 10 -> 5)
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        double scaledRating =
                            entry.rating / 2; // Scale 0-10 to 0-5

                        IconData icon = Icons.star_border;
                        Color color = Colors.grey;

                        if (scaledRating >= index + 1) {
                          icon = Icons.star;
                          color = Colors.amber;
                        } else if (scaledRating > index) {
                          icon = Icons.star_half;
                          color = Colors.amber;
                        }

                        return Icon(icon, color: color, size: 12);
                      }),
                      const SizedBox(width: 4),
                      Text(
                        entry.rating.toString(), // Keep original score label
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Genre Tags (Horizontal List)
                  if (entry.movie.genres.isNotEmpty)
                    SizedBox(
                      height: 16,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entry.movie.genres.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final genre = entry.movie.genres[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE51937),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9, // Slightly smaller
                                fontWeight: FontWeight.bold,
                                height: 1.1, // Tight height
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 16), // Maintain height if no genres?
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
