import 'package:movie_diary_app/data/diary_entry.dart';

class User {
  final int id;
  final String nickname;
  final String userId;
  final String? profileImage;

  User({
    required this.id,
    required this.nickname,
    required this.userId,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nickname: json['nickname'] as String,
      userId: json['user_id'] as String,
      profileImage: json['profile_image'] as String?,
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
    Map<String, dynamic> userJson,
    List<dynamic> postsJson,
  ) {
    final recentEntries = postsJson.map((e) => DiaryEntry.fromJson(e)).toList();

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
