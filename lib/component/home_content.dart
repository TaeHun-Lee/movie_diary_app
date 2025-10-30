import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';

class HomeContent extends StatelessWidget {
  final HomeData data;
  final VoidCallback? onRefresh;

  const HomeContent({super.key, required this.data, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. 닉네임 null 체크 강화
        Text(
          '${data.nickname}님, 안녕하세요 👋',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        _buildNewDiaryButton(context),
        const SizedBox(height: 32),
        Text(
          '최근 영화 기록',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRecentEntriesGrid(context),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              context,
              '오늘 작성',
              data.todayCount.toString(),
              Icons.edit_note_outlined,
            ),
            const SizedBox(height: 50, child: VerticalDivider()),
            _buildSummaryItem(
              context,
              '총 기록',
              data.totalCount.toString(),
              Icons.collections_bookmark_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDiaryButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FilledButton.icon(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MovieSearchScreen()),
        );
        if (result == true) {
          onRefresh?.call();
        }
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('새 영화 기록하기'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: textTheme.titleMedium,
      ),
    );
  }

  Widget _buildRecentEntriesGrid(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (data.recentEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            '아직 작성된 기록이 없어요.\n첫 영화 기록을 남겨보세요!',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.recentEntries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final entry = data.recentEntries[index];
        // 2. entry.movie 객체와 posterUrl null 체크 강화
        final posterUrl = entry.movie.posterUrl;

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryWriteScreen(entryToEdit: entry),
                ),
              );
              if (result == true) {
                onRefresh?.call();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: colorScheme.surfaceContainerHighest,
                    // 3. 포스터 URL이 비어있거나 유효하지 않을 경우 안전한 위젯 표시
                    child: (posterUrl.isNotEmpty)
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  size: 48,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 4. 제목이 null일 경우 기본값 표시
                  child: Text(
                    entry.title,
                    style: textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
