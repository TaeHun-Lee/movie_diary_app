import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'user_id': userId,
      'profile_image': profileImage,
    };
  }
}

class RatedMovie {
  final Movie movie;
  final double rating;

  RatedMovie({required this.movie, required this.rating});
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

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'posts': recentEntries.map((e) => e.toJson()).toList(),
    };
  }

  // ── Computed Properties (lazy, 1회만 계산) ──

  late final int monthlyCount = () {
    final now = DateTime.now();
    return recentEntries.where((e) {
      return e.createdAt.year == now.year && e.createdAt.month == now.month;
    }).length;
  }();

  late final double averageRating = () {
    if (recentEntries.isEmpty) return 0.0;
    return recentEntries.fold<double>(0, (s, e) => s + e.rating) /
        recentEntries.length;
  }();

  late final String topGenre = () {
    if (recentEntries.isEmpty) return '-';
    final counts = <String, int>{};
    for (final e in recentEntries) {
      for (final g in e.movie.genres) {
        if (g.isNotEmpty) counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '-';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }();

  late final List<RatedMovie> topRatedMovies = () {
    final best = <String, RatedMovie>{};
    for (final e in recentEntries) {
      if (e.rating >= 8.0) {
        final existing = best[e.movie.docId];
        if (existing == null || e.rating > existing.rating) {
          best[e.movie.docId] = RatedMovie(movie: e.movie, rating: e.rating);
        }
      }
    }
    final list = best.values.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }();

  late final Map<int, int> monthlyHeatmap = () {
    final now = DateTime.now();
    final map = <int, int>{};
    for (final e in recentEntries) {
      final date = DateTime.tryParse(e.watchedDate);
      if (date != null && date.year == now.year && date.month == now.month) {
        map[date.day] = (map[date.day] ?? 0) + 1;
      }
    }
    return map;
  }();

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
