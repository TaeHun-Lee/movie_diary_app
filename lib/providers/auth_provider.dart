import 'package:flutter/material.dart';
import 'package:movie_diary_app/repositories/auth_repository.dart';

class Auth with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  String? _token;

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  void login(String token) {
    _token = token;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _token = null;
    notifyListeners();
  }
}
