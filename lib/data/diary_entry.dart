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
  final String? authorProfileImage;
  final int likeCount;
  final int commentCount;
  final bool isSpoiler;
  final bool isLiked;
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
    this.authorProfileImage,
    required this.likeCount,
    required this.commentCount,
    required this.isSpoiler,
    this.isLiked = false,
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
      authorProfileImage: json['user']?['profile_image'],
      likeCount: json['likes_count'] ?? (json['likes'] as List?)?.length ?? 0,
      commentCount: (json['comments'] as List?)?.length ?? 0,
      isSpoiler: json['is_spoiler'] ?? false,
      isLiked: json['is_liked'] ?? false,
      images:
          (json['photos'] as List?)
              ?.map((p) => p['photo_url'] as String)
              .toList() ??
          [],
    );
  }

  DiaryEntry copyWith({
    int? id,
    String? docId,
    String? title,
    String? content,
    String? place,
    String? watchedDate,
    double? rating,
    Movie? movie,
    DateTime? createdAt,
    String? authorNickname,
    String? authorProfileImage,
    int? likeCount,
    int? commentCount,
    bool? isSpoiler,
    bool? isLiked,
    List<String>? images,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      title: title ?? this.title,
      content: content ?? this.content,
      place: place ?? this.place,
      watchedDate: watchedDate ?? this.watchedDate,
      rating: rating ?? this.rating,
      movie: movie ?? this.movie,
      createdAt: createdAt ?? this.createdAt,
      authorNickname: authorNickname ?? this.authorNickname,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      isLiked: isLiked ?? this.isLiked,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_docId': docId,
      'title': title,
      'content': content,
      'place': place,
      'watched_at': watchedDate,
      'rating': rating,
      'movie': movie.toJson(),
      'created_at': createdAt.toIso8601String(),
      'user': {
        'nickname': authorNickname,
        'profile_image': authorProfileImage,
      },
      'likes_count': likeCount,
      'comments': List.generate(commentCount, (_) => {}),
      'is_spoiler': isSpoiler,
      'is_liked': isLiked,
      'photos': images.map((url) => {'photo_url': url}).toList(),
    };
  }
}
