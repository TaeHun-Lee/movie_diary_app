import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MovieRepository {
  Future<List<Movie>> searchMovies(String title, {int startCount = 0}) async {
    return await ApiService.searchMovies(title, startCount: startCount);
  }

  Future<List<DiaryEntry>> getMyReviewsForMovie(String docId) async {
    return await ApiService.getMyReviewsForMovie(docId);
  }

  String? buildImageUrl(String? imagePath) {
    return ApiService.buildImageUrl(imagePath);
  }

  String? extractOriginalUrl(String? imageUrl) {
    return ApiService.extractOriginalUrl(imageUrl);
  }
}
