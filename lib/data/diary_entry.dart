class DiaryEntry {
  final int id;
  final String docId;
  final String title;
  final String watchedDate;

  DiaryEntry({
    required this.id,
    required this.docId,
    required this.title,
    required this.watchedDate,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? -1,
      docId: json['docId'] ?? '',
      title: json['title'] ?? '',
      watchedDate: json['watchedDate'] ?? '',
    );
  }
}
