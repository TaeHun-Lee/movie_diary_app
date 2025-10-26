import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

void showMovieDetailModal(BuildContext context, Movie movie) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
    _diaryEntriesFuture = ApiService.getPostsForMovie(widget.movie.docId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              widget.movie.posterUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: Icon(Icons.movie_creation_outlined, size: 100),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.movie.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '감독: ${widget.movie.director}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            widget.movie.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildDiaryEntriesList(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the modal
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryWriteScreen(movie: widget.movie),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('이 영화로 기록하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryEntriesList() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _diaryEntriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const SizedBox.shrink(); // Don't show anything on error
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if empty
        }

        final entries = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 다이어리',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(entry.title),
                    subtitle: Text(entry.watchedDate),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to diary detail screen
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
