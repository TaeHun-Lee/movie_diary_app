import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String userId, String password) async {
    return await ApiService.login(userId: userId, password: password);
  }

  Future<Map<String, dynamic>> register({
    required String userId,
    required String password,
    required String nickname,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    return await ApiService.register(
      userId,
      password,
      nickname,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
  }

  Future<void> logout() async {
    await TokenStorage.clearAccessToken();
    await TokenStorage.clearRefreshToken();
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    return await ApiService.getUserInfo(userId);
  }

  Future<void> updateProfile(int id, Map<String, dynamic> data) async {
    await ApiService.updateProfile(id, data);
  }

  Future<void> deleteAccount(int id) async {
    await ApiService.deleteUser(id);
  }

  Future<String?> getSecurityQuestion(String userId) async {
    return await ApiService.getSecurityQuestion(userId);
  }

  Future<void> resetPassword(String userId, String answer, String newPassword) async {
    await ApiService.resetPassword(userId, answer, newPassword);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ApiService.changePassword(oldPassword, newPassword);
  }
}
