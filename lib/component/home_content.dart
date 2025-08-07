import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/home_data.dart';

class HomeContent extends StatelessWidget {
  final HomeData data;

  const HomeContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.nickname}님, 안녕하세요 👋',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('오늘 작성', data.todayCount),
                  _buildSummaryItem('총 기록', data.totalCount),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create-diary');
            },
            icon: Icon(Icons.add),
            label: Text('새 영화 기록하기'),
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(48)),
          ),
          const SizedBox(height: 20),

          Text(
            '최근 영화 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: data.recentEntries.length,
              itemBuilder: (context, index) {
                final entry = data.recentEntries[index];
                return ListTile(
                  title: Text(entry.title),
                  subtitle: Text(entry.watchedDate),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/diary-detail',
                      arguments: entry.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}
