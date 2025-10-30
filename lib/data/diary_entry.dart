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

  DiaryEntry({
    required this.id,
    required this.docId,
    required this.title,
    this.content,
    this.place,
    required this.watchedDate,
    required this.rating,
    required this.movie,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? -1,
      docId: json['movie_docId'] ?? (json['movie'] != null ? json['movie']['docId'] : ''),
      title: json['title'] ?? '',
      content: json['content'],
      place: json['place'],
      watchedDate: json['watched_at'] ?? '',
      rating: (json['rating'] == null) ? 0.0 : double.parse(json['rating'].toString()),
      movie: Movie.fromJson(json['movie'] ?? {}),
    );
  }
}
