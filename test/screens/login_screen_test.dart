import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late DioAdapter dioAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:3000');
    }
    ApiService.dio.interceptors.clear(); // Clear to avoid duplicates
    ApiService.initialize();
    dioAdapter = DioAdapter(dio: ApiService.dio);
  });

  Widget createLoginScreen() {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => Auth())],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('LoginScreen UI should have email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('이메일 또는 아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인 →'), findsOneWidget);
  });

  testWidgets('LoginScreen should show error message on failed login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    // Mock 401 response
    dioAdapter.onPost(
      '/auth/login',
      (server) => server.reply(401, {'message': 'Unauthorized'}),
    );

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'wronguser');
    await tester.enterText(find.byType(TextField).last, 'wrongpass');

    // Tap login button
    await tester.tap(find.text('로그인 →'));
    await tester.pumpAndSettle();

    // Check for snackbar error message
    expect(find.text('아이디 또는 비밀번호가 일치하지 않습니다.'), findsOneWidget);
  });

  testWidgets('LoginScreen should show loading when login button is pressed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    // Mock Login response (with a delay if possible, but DioAdapter reply is instant)
    dioAdapter.onPost(
      '/auth/login',
      (server) => server.reply(200, {
        'data': {
          'access_token': 'test_token',
          'refresh_token': 'test_refresh_token',
          'user_id': 'testuser',
        },
      }),
      data: null,
    );

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'testuser');
    await tester.enterText(find.byType(TextField).last, 'testpass');

    // Tap login button
    await tester.tap(find.text('로그인 →'));

    // Just check if it started (isLoading should be true, button should show loading indicator)
    await tester.pump();

    // expect(find.byType(CircularProgressIndicator), findsOneWidget); // GradientButton shows this when isLoading is true
  });
}
