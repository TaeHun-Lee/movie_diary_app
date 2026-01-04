import 'package:movie_diary_app/data/movie.dart';

class DiaryEntry {
  final int id;
  final String docId;
  final String title;
  final String? content;
  final String? place;
  final String watchedDate;
  final double rating;
  final Movie movie;
  final DateTime createdAt;
  final String authorNickname;
  final int likeCount;
  final bool isSpoiler;
  final List<String> images;

  DiaryEntry({
    required this.id,
    required this.docId,
    required this.title,
    this.content,
    this.place,
    required this.watchedDate,
    required this.rating,
    required this.movie,
    required this.createdAt,
    required this.authorNickname,
    required this.likeCount,
    required this.isSpoiler,
    required this.images,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? -1,
      docId:
          json['movie_docId'] ??
          (json['movie'] != null ? json['movie']['docId'] : ''),
      title: json['title'] ?? '',
      content: json['content'],
      place: json['place'],
      watchedDate: json['watched_at'] ?? '',
      rating: (json['rating'] == null)
          ? 0.0
          : double.parse(json['rating'].toString()),
      movie: Movie.fromJson(json['movie'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      authorNickname: json['user']?['nickname'] ?? 'Unknown',
      likeCount: (json['likes'] as List?)?.length ?? 0,
      isSpoiler: json['is_spoiler'] ?? false,
      images:
          (json['photos'] as List?)
              ?.map((p) => p['photo_url'] as String)
              .toList() ??
          [],
    );
  }
}
