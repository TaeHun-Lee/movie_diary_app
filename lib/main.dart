import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  // ApiService 인스턴스를 생성하여 인터셉터를 활성화합니다.
  ApiService.initialize();
  runApp(
    ChangeNotifierProvider(create: (context) => Auth(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Movie Diary',
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
          titleSmall: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontWeight: FontWeight.w700),
          bodySmall: TextStyle(fontWeight: FontWeight.w700),
          labelLarge: TextStyle(fontWeight: FontWeight.w700),
          labelMedium: TextStyle(fontWeight: FontWeight.w700),
          labelSmall: TextStyle(fontWeight: FontWeight.w700),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccessToken();
  }

  Future<void> _checkAccessToken() async {
    final auth = Provider.of<Auth>(context, listen: false);
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null) {
      auth.login(accessToken);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final auth = Provider.of<Auth>(context);
    if (auth.isLoggedIn) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
