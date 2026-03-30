import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/api_service.dart';

class PostRepository {
  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int limit = 10,
    String? keyword,
    String? genre,
    String? dateFrom,
    String? dateTo,
  }) async {
    return await ApiService.getPosts(
      page: page,
      limit: limit,
      keyword: keyword,
      genre: genre,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<List<DiaryEntry>> getMyPosts() async {
    return await ApiService.getMyPosts();
  }

  Future<HomeData> fetchHomeData() async {
    return await ApiService.fetchHomeData();
  }

  Future<void> createPost({
    required String docId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    required Movie movie,
    String? location,
    bool isSpoiler = false,
    List<String>? photoUrls,
  }) async {
    await ApiService.createPost(
      docId: docId,
      title: title,
      content: content,
      rating: rating,
      watchedAt: watchedAt,
      movie: movie,
      location: location,
      isSpoiler: isSpoiler,
      photoUrls: photoUrls,
    );
  }

  Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    String? location,
    bool? isSpoiler,
    List<String>? photoUrls,
  }) async {
    await ApiService.updatePost(
      postId: postId,
      title: title,
      content: content,
      rating: rating,
      watchedAt: watchedAt,
      location: location,
      isSpoiler: isSpoiler,
      photoUrls: photoUrls,
    );
  }

  Future<void> deletePost(int postId) async {
    await ApiService.deletePost(postId);
  }

  // Comments
  Future<List<dynamic>> getComments(int postId) async {
    return await ApiService.getComments(postId);
  }

  Future<Map<String, dynamic>> createComment(int postId, String content) async {
    return await ApiService.createComment(postId, content);
  }

  Future<void> deleteComment(int commentId) async {
    await ApiService.deleteComment(commentId);
  }

  // Likes
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    return await ApiService.toggleLike(postId);
  }

  Future<bool> getLikeStatus(int postId) async {
    return await ApiService.getLikeStatus(postId);
  }
}
