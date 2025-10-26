import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';

class HomeContent extends StatelessWidget {
  final HomeData data;

  const HomeContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${data.nickname}님, 안녕하세요 👋',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
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
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MovieSearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('새 영화 기록하기'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          '최근 영화 기록',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (data.recentEntries.isEmpty)
          Center(
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
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.recentEntries.length,
            itemBuilder: (context, index) {
              final entry = data.recentEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(entry.title, style: textTheme.titleMedium),
                  subtitle: Text(entry.watchedDate, style: textTheme.bodySmall),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    // Navigator.pushNamed(
                    //   context,
                    //   '/diary-detail',
                    //   arguments: entry.id,
                    // );
                  },
                ),
              );
            },
          ),
      ],
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
