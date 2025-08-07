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
}
