import 'package:flutter/material.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/repositories/post_repository.dart';

class HomeProvider with ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  HomeData? _homeData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // 데이터 캐싱 시간 설정 (예: 5분)
  bool get _shouldFetch =>
      _homeData == null ||
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > const Duration(minutes: 5);

  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldFetch) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _homeData = await _postRepository.fetchHomeData();
      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching home data: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _homeData = null;
    _lastFetchTime = null;
    _errorMessage = null;
    notifyListeners();
  }
}
