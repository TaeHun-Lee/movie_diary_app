import 'package:flutter/material.dart';
import 'package:movie_diary_app/services/token_storage.dart';

class Auth with ChangeNotifier {
  String? _token;

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  void login(String token) {
    _token = token;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    await TokenStorage.clearAccessToken();
    notifyListeners();
  }
}
