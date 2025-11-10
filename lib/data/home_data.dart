import 'package:movie_diary_app/data/diary_entry.dart';

class User {
  final String nickname;
  final String userId;

  User({required this.nickname, required this.userId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nickname: json['nickname'] as String,
      userId: json['user_id'] as String,
    );
  }
}

class HomeData {
  final User user;
  final int todayCount;
  final int totalCount;
  final List<DiaryEntry> recentEntries;

  HomeData({
    required this.user,
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
      user: User.fromJson(userJson),
      todayCount: todayCount,
      totalCount: totalCount,
      recentEntries: recentEntries,
    );
  }
}
