import 'package:movie_diary_app/services/api_service.dart';

class DiaryRepository {
  Future<List<dynamic>> getPersonalDiaries() async {
    return await ApiService.getPersonalDiaries();
  }

  Future<Map<String, dynamic>?> getPersonalDiaryByDate(String date) async {
    return await ApiService.getPersonalDiaryByDate(date);
  }

  Future<void> savePersonalDiary(String date, String content) async {
    await ApiService.savePersonalDiary(date, content);
  }

  Future<void> deletePersonalDiary(int id) async {
    await ApiService.deletePersonalDiary(id);
  }
}
