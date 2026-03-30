import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider Tests', () {
    test('initial state should be logged out', () {
      final auth = Auth();
      expect(auth.isLoggedIn, false);
      expect(auth.token, null);
    });

    test('login should update token and notify listeners', () {
      final auth = Auth();
      var notifyCount = 0;
      auth.addListener(() => notifyCount++);

      auth.login('test_token');

      expect(auth.isLoggedIn, true);
      expect(auth.token, 'test_token');
      expect(notifyCount, 1);
    });

    test('logout should clear token and notify listeners', () async {
      final auth = Auth();
      auth.login('test_token');
      
      var notifyCount = 0;
      auth.addListener(() => notifyCount++);

      await auth.logout();

      expect(auth.isLoggedIn, false);
      expect(auth.token, null);
      expect(notifyCount, 1);
      expect(await TokenStorage.getAccessToken(), null);
    });
  });
}
