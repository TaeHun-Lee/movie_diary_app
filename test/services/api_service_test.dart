import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late DioAdapter dioAdapter;

  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Load .env
    await dotenv.load(fileName: '.env');

    // Initialize ApiService
    ApiService.initialize();

    // Setup DioAdapter
    dioAdapter = DioAdapter(dio: ApiService.dio);
  });

  group('ApiService Login/Register Tests', () {
    test('login should return user data and save tokens', () async {
      const userId = 'testuser';
      const password = 'password123';
      final responseData = {
        'data': {
          'user_id': userId,
          'access_token': 'mock_access_token',
          'refresh_token': 'mock_refresh_token',
          'nickname': 'Tester',
        },
      };

      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, responseData),
        data: {'user_id': userId, 'password': password},
      );

      final result = await ApiService.login(userId: userId, password: password);

      expect(result['user_id'], userId);
      expect(await TokenStorage.getAccessToken(), 'mock_access_token');
      expect(await TokenStorage.getRefreshToken(), 'mock_refresh_token');
    });

    test('register should return user data and save tokens', () async {
      const userId = 'newuser';
      const password = 'password123';
      const nickname = 'NewTester';
      final responseData = {
        'data': {
          'user_id': userId,
          'access_token': 'mock_access_token_reg',
          'refresh_token': 'mock_refresh_token_reg',
          'nickname': nickname,
        },
      };

      dioAdapter.onPost(
        '/auth/register',
        (server) => server.reply(200, responseData),
        data: {'user_id': userId, 'password': password, 'nickname': nickname},
      );

      final result = await ApiService.register(userId, password, nickname);

      expect(result['user_id'], userId);
      expect(await TokenStorage.getAccessToken(), 'mock_access_token_reg');
    });
  });

  group('ApiService User/Diary Tests', () {
    test('getUserInfo should return user data', () async {
      const userId = 'testuser';
      final responseData = {
        'data': {
          'id': 1,
          'user_id': userId,
          'nickname': 'Tester',
          'profile_image': null,
        },
      };

      dioAdapter.onGet(
        '/users/$userId',
        (server) => server.reply(200, responseData),
      );

      final result = await ApiService.getUserInfo(userId);

      expect(result['user_id'], userId);
      expect(result['nickname'], 'Tester');
    });

    test('getPosts should return posts data', () async {
      final responseData = {
        'data': {
          'items': [
            {
              'id': 1,
              'title': 'Test Post',
              'content': 'Test Content',
              'rating': 4.5,
              'movie': {
                'docId': 'M123',
                'title': 'Test Movie',
                'director': 'Test Director',
                'plot': 'Test Plot',
                'poster': null,
                'stills': [],
                'genres': ['Action'],
                'releaseDate': '2024',
              },
              'user': {'nickname': 'Tester'},
              'likes': [],
              'is_spoiler': false,
              'photos': [],
              'watched_at': '2024-03-29T00:00:00Z',
              'created_at': '2024-03-29T00:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 10,
        },
      };

      dioAdapter.onGet(
        '/posts',
        (server) => server.reply(200, responseData),
        queryParameters: {'page': 1, 'limit': 10},
      );

      final result = await ApiService.getPosts(page: 1, limit: 10);

      expect(result['items'].length, 1);
      expect(result['items'][0]['title'], 'Test Post');
    });
  });

  group('ApiService Personal Diary Tests', () {
    test('savePersonalDiary should call POST /personal-diary', () async {
      const date = '2024-03-29';
      const content = 'Today I watched a movie.';

      dioAdapter.onPost(
        '/personal-diary',
        (server) => server.reply(200, {
          'data': {'id': 1, 'date': date, 'content': content},
        }),
        data: {'date': date, 'content': content},
      );

      await ApiService.savePersonalDiary(date, content);
      // No exception means success
    });

    test('getPersonalDiaries should return list of diaries', () async {
      final responseData = {
        'data': [
          {'id': 1, 'date': '2024-03-29', 'content': 'Test diary'},
        ],
      };

      dioAdapter.onGet(
        '/personal-diary',
        (server) => server.reply(200, responseData),
      );

      final result = await ApiService.getPersonalDiaries();

      expect(result.length, 1);
      expect(result[0]['content'], 'Test diary');
    });
  });
}
