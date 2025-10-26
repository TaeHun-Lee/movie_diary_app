class Movie {
  final String docId;
  final String title;
  final String director;
  final String summary;
  final String posterUrl;
  final List<String> stillCutUrls;

  Movie({
    required this.docId,
    required this.title,
    required this.director,
    required this.summary,
    required this.posterUrl,
    required this.stillCutUrls,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final poster = json['poster'];
    final stills = json['stills'];
    const String proxyUrl = 'http://localhost:3000/movies/image?url=';

    List<String> processedStills = [];
    if (stills is List) {
      processedStills = stills
          .map((url) => '$proxyUrl${Uri.encodeQueryComponent(url.toString())}')
          .toList();
    }

    return Movie(
      docId: json['docId'] ?? '',
      title: json['title'] ?? '',
      director: json['director'] ?? '',
      summary: json['plot'] ?? '',
      posterUrl:
          poster != null ? '$proxyUrl${Uri.encodeQueryComponent(poster)}' : '',
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
