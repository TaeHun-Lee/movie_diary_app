class DiaryEntry {
  final int id;
  final String title;
  final String watchedDate;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.watchedDate,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      watchedDate: json['watchedDate'],
    );
  }
}
