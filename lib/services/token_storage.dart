import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _nicknameKey = 'nickname';

  static Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> _clearString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<bool> _hasString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  static Future<void> saveAccessToken(String token) async {
    await _saveString(_accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    return _getString(_accessTokenKey);
  }

  static Future<void> clearAccessToken() async {
    await _clearString(_accessTokenKey);
  }

  static Future<bool> hasAccessToken() async {
    return _hasString(_accessTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _saveString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    return _getString(_userIdKey);
  }

  static Future<void> clearUser() async {
    await _clearString(_userIdKey);
  }

  static Future<bool> hasUser() async {
    return _hasString(_userIdKey);
  }

  static Future<void> saveNickname(String nickname) async {
    await _saveString(_nicknameKey, nickname);
  }

  static Future<String?> getNickname() async {
    return _getString(_nicknameKey);
  }

  static Future<void> clearNickname() async {
    await _clearString(_nicknameKey);
  }

  static Future<bool> hasNickname() async {
    return _hasString(_nicknameKey);
  }
}