import 'package:movie_diary_app/services/api_service.dart';

class Movie {
  final String docId;
  final String title;
  final String director;
  final String summary;
  final String? posterUrl;
  final List<String> stillCutUrls;
  final List<String> genres;
  final String releaseDate;

  Movie({
    required this.docId,
    required this.title,
    required this.director,
    required this.summary,
    this.posterUrl,
    required this.stillCutUrls,
    required this.genres,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final poster = json['poster'] ?? json['posterUrl'];
    final stills = json['stills'];
    final genresList = json['genres'] as List<dynamic>? ?? [];

    List<String> processedStills = [];
    if (stills is List) {
      processedStills = stills
          .map((url) => ApiService.buildImageUrl(url.toString()))
          .where((url) => url != null)
          .cast<String>()
          .toList();
    }

    // Backend uses release_date (snake_case), some DTOs use releaseDate (camelCase)
    // KMDB API results might use prodYear
    String rDate = json['release_date'] ?? json['releaseDate'] ?? json['prodYear'] ?? '';
    
    // If it's an ISO string from backend (e.g. 2023-10-27T00:00:00.000Z), take only the date part
    if (rDate.contains('T')) {
      rDate = rDate.split('T').first;
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
      releaseDate: rDate,
      genres: genresList.map((e) {
        if (e is Map) {
          return e['name'].toString();
        }
        return e.toString();
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'title': title,
      'director': director,
      'plot': summary,
      'poster': ApiService.extractOriginalUrl(posterUrl),
      'stills': stillCutUrls
          .map((url) => ApiService.extractOriginalUrl(url) ?? url)
          .toList(),
      'genres': genres,
      'releaseDate': releaseDate,
    };
  }
}
