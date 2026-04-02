import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/providers/diary_provider.dart';
import 'package:movie_diary_app/providers/home_provider.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/services/connectivity_service.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 배포 모드(Release)에서는 상대 경로('')를 사용하여 Nginx 프록시를 태움
  static final String baseUrl = (kIsWeb && kReleaseMode)
      ? ''
      : dotenv.env['BASE_URL']!;

  // Dio 인스턴스 생성
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  static bool _isRefreshing = false;
  static final List<void Function(String)> _refreshQueue = [];
  
  static const String _homeDataCacheKey = 'cached_home_data';

  // 클래스 생성 시 인터셉터 설정
  ApiService();

  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 토큰이 필요한 요청에 대해 헤더에 토큰 추가
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/register') &&
              !options.path.contains('/auth/refresh')) {
            final token = await TokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options); // 요청 계속 진행
        },
        onError: (DioException e, handler) async {
          final path = e.requestOptions.path;

          // 401 에러 발생 시 토큰 갱신 시도
          if (e.response?.statusCode == 401 &&
              !path.contains('/auth/login') &&
              !path.contains('/auth/register') &&
              !path.contains('/auth/security-question') &&
              !path.contains('/auth/reset-password') &&
              !path.contains('/auth/change-password')) {
            
            if (path.contains('/auth/refresh')) {
              // 리프레시 토큰 자체가 만료된 경우
              NavigationService.handleUnauthorized();
              return handler.reject(e);
            }

            if (_isRefreshing) {
              // 이미 토큰 갱신 중이면 큐에 추가
              _refreshQueue.add((String newToken) async {
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                try {
                  final response = await _dio.fetch(e.requestOptions);
                  handler.resolve(response);
                } catch (err) {
                  handler.reject(err as DioException);
                }
              });
              return;
            }

            _isRefreshing = true;
            final refreshToken = await TokenStorage.getRefreshToken();

            if (refreshToken == null) {
              _isRefreshing = false;
              NavigationService.handleUnauthorized();
              return handler.reject(e);
            }

            try {
              // 토큰 갱신 요청
              final success = await _refreshToken(refreshToken);
              if (success) {
                final newToken = await TokenStorage.getAccessToken();
                _isRefreshing = false;
                
                // 큐에 있는 요청들 처리
                for (var callback in _refreshQueue) {
                  callback(newToken!);
                }
                _refreshQueue.clear();

                // 원래 요청 재시도
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              } else {
                _isRefreshing = false;
                NavigationService.handleUnauthorized();
                return handler.reject(e);
              }
            } catch (err) {
              _isRefreshing = false;
              NavigationService.handleUnauthorized();
              return handler.reject(e);
            }
          }
          return handler.next(e); // 다른 에러는 계속 전파
        },
      ),
    );
  }

  static Future<bool> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data['data'];
      await TokenStorage.saveAccessToken(data['access_token']);
      await TokenStorage.saveRefreshToken(data['refresh_token']);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Dio 인스턴스를 외부에서 접근할 수 있도록 getter 제공
  static Dio get dio => _dio;

  static Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService().isConnected();
    if (!isConnected) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
        error: '네트워크 연결이 끊겼습니다.',
      );
    }
  }

  static Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
  }) async {
    try {
      await _checkConnectivity();
      final response = await _dio.post(
        '/auth/login',
        data: {'user_id': userId, 'password': password},
      );
      final data = response.data['data'];
      await TokenStorage.saveAccessToken(data['access_token']);
      await TokenStorage.saveRefreshToken(data['refresh_token']);
      return data;
    } on DioException catch (e) {
      _handleDioError(e, '로그인에 실패했습니다');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/users/$userId');
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, '사용자 정보를 가져오는데 실패했습니다');
    }
  }

  static Future<Map<String, dynamic>> register(
    String userId,
    String password,
    String nickname, {
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      await _checkConnectivity();
      final data = {
        'user_id': userId,
        'password': password,
        'nickname': nickname,
      };
      if (securityQuestion != null) {
        data['security_question'] = securityQuestion;
      }
      if (securityAnswer != null) {
        data['security_answer'] = securityAnswer;
      }

      final response = await _dio.post('/auth/register', data: data);
      final dataResponse = response.data['data'];
      await TokenStorage.saveAccessToken(dataResponse['access_token']);
      await TokenStorage.saveRefreshToken(dataResponse['refresh_token']);
      return dataResponse;
    } on DioException catch (e) {
      _handleDioError(e, '회원가입에 실패했습니다');
    }
  }

  static Future<String?> uploadPhoto(XFile file) async {
    try {
      await _checkConnectivity();
      String fileName = file.name;
      FormData formData;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });
      }

      final response = await _dio.post('/uploads', data: formData);
      return response.data['data']['url'];
    } on DioException catch (e) {
      _handleDioError(e, '사진 업로드에 실패했습니다');
    }
  }

  static Future<String?> getSecurityQuestion(String userId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/auth/security-question/$userId');
      return response.data['data']['question'];
    } on DioException catch (e) {
      // User not found or no question set
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        throw Exception('사용자를 찾을 수 없거나 보안 질문이 설정되지 않았습니다.');
      }
      _handleDioError(e, '보안 질문을 가져오는데 실패했습니다');
    }
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await _checkConnectivity();
      await _dio.post(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('기존 비밀번호가 일치하지 않습니다.');
      }
      _handleDioError(e, '비밀번호 변경에 실패했습니다.');
    }
  }

  static Future<void> resetPassword(
    String userId,
    String securityAnswer,
    String newPassword,
  ) async {
    try {
      await _checkConnectivity();
      await _dio.post(
        '/auth/reset-password',
        data: {
          'user_id': userId,
          'security_answer': securityAnswer,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        throw Exception('비밀번호 재설정에 실패했습니다. 답변이 틀렸을 수 있습니다.');
      }
      _handleDioError(e, '비밀번호 재설정에 실패했습니다.');
    }
  }

  static Future<HomeData> fetchHomeData() async {
    try {
      await _checkConnectivity();
      // 두 API 요청을 동시에 보냄
      final responses = await Future.wait([
        _dio.get('/auth/me'),
        _dio.get('/posts/my'),
      ]);

      final userJson = responses[0].data['data'];
      final postsJson = responses[1].data['data'] as List;

      final homeData = HomeData.fromJson(userJson, postsJson);
      
      // 캐시 저장
      await _saveHomeDataToCache(homeData);
      
      return homeData;
    } on DioException catch (e) {
      // 오프라인이거나 에러 발생 시 캐시 시도
      final cached = await _loadHomeDataFromCache();
      if (cached != null) {
        return cached;
      }
      _handleDioError(e, '홈 데이터를 불러오는데 실패했습니다.');
    }
  }

  static Future<void> _saveHomeDataToCache(HomeData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homeDataCacheKey, jsonEncode(data.toJson()));
  }

  static Future<HomeData?> _loadHomeDataFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_homeDataCacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        return HomeData.fromJson(decoded['user'], decoded['posts']);
      }
    } catch (e) {
      // Ignore cache loading errors
    }
    return null;
  }

  static Future<void> _refreshGlobalState({
    bool refreshHome = false,
    bool refreshPosts = false,
    bool refreshPersonalDiaries = false,
  }) async {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    final futures = <Future<void>>[];

    if (refreshHome) {
      futures.add(
        Provider.of<HomeProvider>(
          context,
          listen: false,
        ).fetchHomeData(forceRefresh: true),
      );
    }

    if (refreshPosts) {
      futures.add(
        Provider.of<PostProvider>(
          context,
          listen: false,
        ).refreshAfterMutation(),
      );
    }

    if (refreshPersonalDiaries) {
      futures.add(
        Provider.of<DiaryProvider>(
          context,
          listen: false,
        ).fetchPersonalDiaries(forceRefresh: true),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  static Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int limit = 10,
    String? keyword,
    String? genre,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get(
        '/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (keyword != null) 'keyword': keyword,
          if (genre != null) 'genre': genre,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, '게시글 목록을 가져오는데 실패했습니다');
    }
  }

  // Comments
  static Future<List<dynamic>> getComments(int postId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/comments/post/$postId');
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, '댓글을 불러오는데 실패했습니다');
    }
  }

  static Future<Map<String, dynamic>> createComment(int postId, String content) async {
    try {
      await _checkConnectivity();
      final response = await _dio.post(
        '/comments',
        data: {'post_id': postId, 'content': content},
      );
      await _refreshGlobalState(refreshHome: true, refreshPosts: true);
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, '댓글 작성에 실패했습니다');
    }
  }

  static Future<void> deleteComment(int commentId) async {
    try {
      await _checkConnectivity();
      await _dio.delete('/comments/$commentId');
      await _refreshGlobalState(refreshHome: true, refreshPosts: true);
    } on DioException catch (e) {
      _handleDioError(e, '댓글 삭제에 실패했습니다');
    }
  }

  // Likes
  static Future<Map<String, dynamic>> toggleLike(int postId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.post('/likes/toggle/$postId');
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, '좋아요 처리 중 오류가 발생했습니다');
    }
  }

  static Future<bool> getLikeStatus(int postId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/likes/status/$postId');
      return response.data['data'] as bool;
    } on DioException catch (e) {
      _handleDioError(e, '좋아요 상태를 가져오는데 실패했습니다');
    }
  }

  static Future<List<DiaryEntry>> getMyPosts() async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/posts/my');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, '내가 쓴 다이어리를 불러오는데 실패했습니다.');
    }
  }

  static Future<List<Movie>> searchMovies(
    String title, {
    int startCount = 0,
  }) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get(
        '/movies/search',
        queryParameters: {'title': title, 'startCount': startCount},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Movie.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, '영화 검색에 실패했습니다');
    }
  }

  static Future<List<DiaryEntry>> getMyReviewsForMovie(String docId) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/posts/movie/doc/$docId/my-reviews');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      _handleDioError(e, '리뷰 목록을 가져오는데 실패했습니다');
    }
  }

  static Future<void> createPost({
    required String docId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    required Movie movie,
    String? location,
    bool isSpoiler = false,
    List<String>? photoUrls,
  }) async {
    try {
      await _checkConnectivity();
      await _dio.post(
        '/posts',
        data: {
          'title': title,
          'content': content,
          'rating': rating,
          'watched_at': watchedAt.toIso8601String(),
          'movie': movie.toJson(),
          'is_spoiler': isSpoiler,
          if (location != null && location.isNotEmpty) 'place': location,
          if (photoUrls != null) 'photo_urls': photoUrls,
        },
      );
      await _refreshGlobalState(refreshHome: true, refreshPosts: true);
    } on DioException catch (e) {
      _handleDioError(e, '게시글 작성에 실패했습니다');
    }
  }

  static Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    String? location,
    bool? isSpoiler,
    List<String>? photoUrls,
  }) async {
    try {
      await _checkConnectivity();
      await _dio.patch(
        '/posts/$postId',
        data: {
          'title': title,
          'content': content,
          'rating': rating,
          'watched_at': watchedAt.toIso8601String(),
          if (location != null && location.isNotEmpty) 'place': location,
          if (isSpoiler != null) 'is_spoiler': isSpoiler,
          if (photoUrls != null) 'photo_urls': photoUrls,
        },
      );
      await _refreshGlobalState(refreshHome: true, refreshPosts: true);
    } on DioException catch (e) {
      _handleDioError(e, '게시글 수정에 실패했습니다');
    }
  }

  static Future<void> deletePost(int postId) async {
    try {
      await _checkConnectivity();
      await _dio.delete('/posts/$postId');
      await _refreshGlobalState(refreshHome: true, refreshPosts: true);
    } on DioException catch (e) {
      _handleDioError(e, '게시글 삭제에 실패했습니다');
    }
  }

  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    imagePath = imagePath.trim();

    // 1. 이미 프록시 URL인 경우 중복 처리 방지
    if (imagePath.contains('/movies/image?url=')) {
      if (imagePath.contains('localhost') && baseUrl.contains('10.0.2.2')) {
        return imagePath.replaceFirst('localhost', '10.0.2.2');
      }
      return imagePath;
    }

    // 2. 내부 서버(업로드 이미지)인 경우 프록시 타지 않고 호스트만 보정
    if (imagePath.contains('localhost') || imagePath.contains('10.0.2.2')) {
      if (imagePath.contains('localhost') && baseUrl.contains('10.0.2.2')) {
        return imagePath.replaceFirst('localhost', '10.0.2.2');
      }
      return imagePath;
    }

    // 3. 외부 URL인 경우 프록시 URL 생성
    if (imagePath.startsWith('http')) {
      final String proxyUrl = '$baseUrl/movies/image?url=';
      return '$proxyUrl${Uri.encodeQueryComponent(imagePath)}';
    }

    // 4. 상대 경로인 경우 Base URL 붙이기
    return '$baseUrl$imagePath';
  }

  static String? extractOriginalUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.contains('url=')) {
      final uri = Uri.parse(imageUrl);
      final originalUrl = uri.queryParameters['url'];
      if (originalUrl != null) {
        return originalUrl;
      }
    }
    return imageUrl;
  }

  // 프로필 업데이트
  static Future<void> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      await _checkConnectivity();
      await _dio.patch('/users/$id', data: data);
    } on DioException catch (e) {
      _handleDioError(e, '프로필 수정에 실패했습니다.');
    }
  }

  // 회원 탈퇴
  static Future<void> deleteUser(int id) async {
    try {
      await _checkConnectivity();
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      _handleDioError(e, '회원 탈퇴에 실패했습니다.');
    }
  }

  // Personal Diary
  static Future<void> savePersonalDiary(String date, String content) async {
    try {
      await _checkConnectivity();
      // Backend create handles upsert logic
      await _dio.post(
        '/personal-diary',
        data: {'date': date, 'content': content},
      );
      await _refreshGlobalState(refreshPersonalDiaries: true);
    } on DioException catch (e) {
      _handleDioError(e, '일기 저장에 실패했습니다.');
    }
  }

  static Future<List<dynamic>> getPersonalDiaries() async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/personal-diary');
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      _handleDioError(e, '일기 목록을 불러오는데 실패했습니다.');
    }
  }

  static Future<Map<String, dynamic>?> getPersonalDiaryByDate(
    String date,
  ) async {
    try {
      await _checkConnectivity();
      final response = await _dio.get('/personal-diary/date/$date');
      return response.data['data'];
    } on DioException {
      return null;
    }
  }

  static Future<void> deletePersonalDiary(int id) async {
    try {
      await _checkConnectivity();
      await _dio.delete('/personal-diary/$id');
      await _refreshGlobalState(refreshPersonalDiaries: true);
    } on DioException catch (e) {
      _handleDioError(e, '일기 삭제에 실패했습니다.');
    }
  }

  // DioException 처리를 위한 헬퍼 함수
  static Never _handleDioError(DioException e, String message) {
    String errorMsg = message;
    
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      errorMsg = '네트워크 연결 상태를 확인해주세요.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMsg = '서버 응답 시간이 초과되었습니다.';
    } else if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final serverMessage = e.response?.data?['message'];
      
      if (statusCode == 500) {
        errorMsg = '서버 내부 오류가 발생했습니다.';
      } else if (serverMessage != null) {
        errorMsg = serverMessage.toString();
      }
    }
    
    throw Exception(errorMsg);
  }
}
