import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

Future<dynamic> showMovieDetailModal(BuildContext context, Movie movie) {
  return showDialog(
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
    _diaryEntriesFuture = ApiService.findTop10ForMovieByDocId(
      widget.movie.docId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: widget.movie.posterUrl != null
                ? Image.network(
                    widget.movie.posterUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 300,
                        child: Center(
                          child: Icon(Icons.movie_creation_outlined, size: 100),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 300,
                    color: Colors.grey,
                    child: const Center(
                      child: Text(
                        'No Poster Available',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.movie.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '감독: ${widget.movie.director}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildGenreChips(context),
          const SizedBox(height: 16),
          Text(
            widget.movie.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildDiaryEntriesList(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              // 모달을 닫지 않고, 작성 화면으로 이동하여 결과를 기다린다.
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryWriteScreen(movie: widget.movie),
                ),
              );

              // 작성 화면에서 true를 반환했다면, 모달도 true를 반환하며 닫힌다.
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
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
          return Center(
            child: Text(
              '다이어리를 불러오는 중 오류가 발생했습니다.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                '현재 이 영화에 작성된 다이어리가 존재하지 않습니다.\n처음으로 작성해보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final entries = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 다이어리',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
        return Chip(
          label: Text(genre),
          backgroundColor: Colors.grey[200],
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }
}
