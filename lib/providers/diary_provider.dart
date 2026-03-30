import 'package:flutter/material.dart';
import 'package:movie_diary_app/repositories/diary_repository.dart';

class DiaryProvider with ChangeNotifier {
  final DiaryRepository _diaryRepository = DiaryRepository();
  List<dynamic> _personalDiaries = [];
  bool _isLoading = false;
  DateTime? _lastFetchTime;

  List<dynamic> get personalDiaries => _personalDiaries;
  bool get isLoading => _isLoading;

  bool get _shouldFetch =>
      _personalDiaries.isEmpty ||
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > const Duration(minutes: 5);

  Future<void> fetchPersonalDiaries({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldFetch) return;

    _isLoading = true;
    notifyListeners();

    try {
      final diaries = await _diaryRepository.getPersonalDiaries();
      // Sort by date DESC
      diaries.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      _personalDiaries = diaries;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching personal diaries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 일기 저장 후 로컬 상태 업데이트
  Future<void> saveDiary(String date, String content) async {
    try {
      await _diaryRepository.savePersonalDiary(date, content);
      // 저장 후 전체 목록 다시 불러오기 (캐시 무효화)
      await fetchPersonalDiaries(forceRefresh: true);
    } catch (e) {
      debugPrint('Error saving diary: $e');
      rethrow;
    }
  }

  // 일기 삭제 후 로컬 상태 업데이트
  Future<void> deleteDiary(int id) async {
    try {
      await _diaryRepository.deletePersonalDiary(id);
      _personalDiaries.removeWhere((d) => d['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting diary: $e');
      rethrow;
    }
  }

  void clear() {
    _personalDiaries = [];
    _lastFetchTime = null;
    notifyListeners();
  }
}
