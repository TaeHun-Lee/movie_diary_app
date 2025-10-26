class Diary {
  final String movieTitle;
  final String movieDirector;
  final List<String> movieStills;
  final String title;
  final String content;
  final double rating;
  final String? location;

  Diary({
    required this.movieTitle,
    required this.movieDirector,
    required this.movieStills,
    required this.title,
    required this.content,
    required this.rating,
    this.location,
  });
}
