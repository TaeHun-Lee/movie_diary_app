import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/constants.dart';

Future<dynamic> showMovieDetailModal(BuildContext context, Movie movie) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // Darker backdrop
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: const Color(
          0xFFEBEBF0,
        ), // Light background like design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _MovieDetailContent(movie: movie),
          ),
        ),
      );
    },
  );
}

class _MovieDetailContent extends StatefulWidget {
  final Movie movie;

  const _MovieDetailContent({required this.movie});

  @override
  State<_MovieDetailContent> createState() => _MovieDetailContentState();
}

class _MovieDetailContentState extends State<_MovieDetailContent> {
  late Future<List<DiaryEntry>> _diaryEntriesFuture;

  @override
  void initState() {
    super.initState();
    _diaryEntriesFuture = ApiService.getMyReviewsForMovie(widget.movie.docId);
  }

  @override
  Widget build(BuildContext context) {
    // Styles are manually defined in children widgets to override dark theme

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Poster Image - Large and Centered
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: widget.movie.posterUrl != null
                        ? Image.network(
                            widget.movie.posterUrl!,
                            width: MediaQuery.of(context).size.width * 0.6,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: 300,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.movie,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.movie.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Director & Year
              Text(
                widget.movie.releaseDate.length >= 4
                    ? '${widget.movie.releaseDate.substring(0, 4)} / ${widget.movie.director}'
                    : '감독: ${widget.movie.director}',
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Genres
              _buildGenreChips(context),
              const SizedBox(height: 16),

              // Summary
              Text(
                widget.movie.summary.isNotEmpty
                    ? widget.movie.summary
                    : "줄거리 정보가 없습니다.",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Rating moved to My Diary section
              const SizedBox(height: 24),

              // My Diary List (Simplified)
              _buildDiaryEntriesList(),
            ],
          ),
        ),

        // Bottom Button (Floating style or pinned to bottom)
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryWriteScreen(movie: widget.movie),
                  ),
                );

                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF2C2C2C,
                ), // Dark Button on Light Modal
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '이 영화로 기록하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    if (widget.movie.genres.isEmpty ||
        (widget.movie.genres.length == 1 &&
            widget.movie.genres.first.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: widget.movie.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: kPrimaryRedColor),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Text(
            genre,
            style: const TextStyle(
              color: kPrimaryRedColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiaryEntriesList() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _diaryEntriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Hide section if no entries, or show minimal text
          return const SizedBox.shrink();
        }

        final entries = snapshot.data!;

        double averageRating = 0.0;
        if (entries.isNotEmpty) {
          double total = 0;
          for (var entry in entries) {
            total += entry.rating;
          }
          averageRating = total / entries.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(), // Separator
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '내 다이어리',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                Text(
                  ' ${averageRating.toStringAsFixed(1)})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length > 2 ? 2 : entries.length, // Show max 2
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    title: Text(
                      entry.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      entry.watchedDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DiaryWriteScreen(entryToEdit: entry),
                        ),
                      );
                      // Refresh list
                      if (mounted) {
                        setState(() {
                          _diaryEntriesFuture = ApiService.getMyReviewsForMovie(
                            widget.movie.docId,
                          );
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
