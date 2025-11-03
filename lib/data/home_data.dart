import 'package:movie_diary_app/data/diary_entry.dart';

class HomeData {
  final String nickname;
  final int todayCount;
  final int totalCount;
  final List<DiaryEntry> recentEntries;

  HomeData({
    required this.nickname,
    required this.todayCount,
    required this.totalCount,
    required this.recentEntries,
  });

  factory HomeData.fromJson(
      Map<String, dynamic> userJson, List<dynamic> postsJson) {
    final recentEntries =
        postsJson.map((e) => DiaryEntry.fromJson(e)).toList();

    final totalCount = recentEntries.length;
    final now = DateTime.now();
    final todayCount = recentEntries.where((entry) {
      final createdAt = entry.createdAt;
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;

    return HomeData(
      nickname: userJson['nickname'] ?? '사용자',
      todayCount: todayCount,
      totalCount: totalCount,
      recentEntries: recentEntries,
    );
  }
}
