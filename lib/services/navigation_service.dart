import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/providers/auth_provider.dart';
import 'package:movie_diary_app/screens/login_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> handleUnauthorized() async {
    // 현재 context 가져오기
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    // Auth Provider를 통해 로그아웃 처리 (상태 초기화)
    final auth = Provider.of<Auth>(context, listen: false);
    if (auth.isLoggedIn) {
      await auth.logout();
    }

    // 로그인 화면으로 이동하고, 이전의 모든 화면을 스택에서 제거
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
