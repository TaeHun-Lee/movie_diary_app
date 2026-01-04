import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/screens/register_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:movie_diary_app/constants.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryDarkColor,
          primary: kPrimaryDarkColor,
          secondary: kAccentGoldColor,
        ),
        useMaterial3: true,
        // 텍스트 필드 기본 테마 설정
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: kPrimaryDarkColor.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccentGoldColor, width: 2),
          ),
          labelStyle: TextStyle(color: kTextDarkColor.withValues(alpha: 0.6)),
          prefixIconColor: kPrimaryDarkColor,
        ),
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
      },
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
