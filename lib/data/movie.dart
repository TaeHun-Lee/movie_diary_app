import 'package:movie_diary_app/services/api_service.dart';

class Movie {
  final String docId;
  final String title;
  final String director;
  final String summary;
  final String? posterUrl;
  final List<String> stillCutUrls;

  Movie({
    required this.docId,
    required this.title,
    required this.director,
    required this.summary,
    this.posterUrl,
    required this.stillCutUrls,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final poster = json['poster'];
    final stills = json['stills'];

    List<String> processedStills = [];
    if (stills is List) {
      processedStills = stills
          .map((url) => ApiService.buildImageUrl(url.toString()))
          .where((url) => url != null)
          .cast<String>()
          .toList();
    }

    return Movie(
      docId: json['docId'] ?? '',
      title: (json['title'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      director: json['director'] ?? '',
      summary: json['plot'] ?? '',
      posterUrl: ApiService.buildImageUrl(poster),
      stillCutUrls: processedStills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'title': title,
      'director': director,
      'plot': summary,
      'poster': posterUrl,
      'stills': stillCutUrls,
    };
  }
}
