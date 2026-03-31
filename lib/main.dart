import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/providers/home_provider.dart';
import 'package:movie_diary_app/providers/diary_provider.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import 'package:movie_diary_app/screens/login_screen.dart';
import 'package:movie_diary_app/screens/register_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:movie_diary_app/providers/navigation_provider.dart';
import 'package:movie_diary_app/services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService().initialize();
  await dotenv.load(fileName: ".env");
  ApiService.initialize();

  // 상태바 투명하게 (Glassmorphic 앱바와 어울리도록)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(create: (_) => Auth()),
          legacy_provider.ChangeNotifierProvider(create: (_) => PostProvider()),
          legacy_provider.ChangeNotifierProvider(create: (_) => HomeProvider()),
          legacy_provider.ChangeNotifierProvider(create: (_) => NavigationProvider()),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => DiaryProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
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
      theme: _buildTheme(),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kBodyFont, // NotoSansKR (한글 기본)
      scaffoldBackgroundColor: kSurface,
      colorScheme: ColorScheme.light(
        primary: kPrimary,
        onPrimary: Colors.white,
        primaryContainer: kPrimaryEnd,
        onPrimaryContainer: Colors.white,
        secondary: kSecondary,
        onSecondary: Colors.white,
        secondaryContainer: kSecondaryContainer,
        onSecondaryContainer: kOnSecondaryContainer,
        surface: kSurface,
        onSurface: kOnSurface,
        surfaceContainerLowest: kSurfaceLowest,
        surfaceContainerLow: kSurfaceLow,
        surfaceContainer: kSurfaceContainer,
        surfaceContainerHigh: kSurfaceHigh,
        outline: kOutlineVariant,
        error: kError,
        onError: Colors.white,
      ),

      // ── AppBar ─────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: kOnSurface),
        titleTextStyle: TextStyle(
          fontFamily: kHeadlineFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: kOnSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Input Fields (Neuromorphic Inset) ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: kPrimary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
          color: kOnSurfaceVariant.withValues(alpha: 0.6),
          fontFamily: kBodyFont,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: kOnSurfaceVariant,
          fontFamily: kBodyFont,
        ),
        prefixIconColor: kOnSurfaceVariant,
        suffixIconColor: kOnSurfaceVariant,
      ),

      // ── Elevated Button ─────────────────────
      // 그라디언트는 각 화면에서 직접 Container + GestureDetector 또는
      // GradientButton 위젯으로 처리합니다.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kPrimary,
          textStyle: const TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Chip ────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: kSurfaceHigh,
        labelStyle: const TextStyle(
          fontFamily: kBodyFont,
          fontSize: 12,
          color: kOnSurfaceVariant,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── BottomNavigationBar ─────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: kPrimary,
        unselectedItemColor: kOnSurfaceVariant,
        selectedLabelStyle: TextStyle(
          fontFamily: kBodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontFamily: kBodyFont, fontSize: 11),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Slider ──────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: kPrimary,
        inactiveTrackColor: kSurfaceDim,
        thumbColor: kPrimary,
        overlayColor: kPrimary.withValues(alpha: 0.12),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),

      // ── Card ────────────────────────────────
      cardTheme: CardThemeData(
        color: kSurfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // ── SnackBar ────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kOnSurface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: kBodyFont,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Date Picker ─────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: kSurfaceLowest,
        headerBackgroundColor: kPrimary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return kOnSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kPrimary;
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(kPrimary),
        todayBorder: const BorderSide(color: kPrimary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 공통 그라디언트 버튼 위젯
// ─────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  kPrimary.withValues(alpha: 0.5),
                  kPrimaryEnd.withValues(alpha: 0.5),
                ],
              )
            : kPrimaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Neuromorphic 인셋 입력 필드 데코레이션 헬퍼
// ─────────────────────────────────────────────────────────────
InputDecoration neuInputDecoration({
  String? hint,
  Widget? prefix,
  Widget? suffix,
  String? label,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: label,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: kSurfaceHigh,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: kPrimary.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// 인증 상태 체크
// ─────────────────────────────────────────────────────────────
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
    final auth = legacy_provider.Provider.of<Auth>(context, listen: false);
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
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final auth = legacy_provider.Provider.of<Auth>(context);
    if (auth.isLoggedIn) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
