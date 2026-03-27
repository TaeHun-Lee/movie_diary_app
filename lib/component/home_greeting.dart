import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';

class HomeGreeting extends StatelessWidget {
  final String nickname;

  const HomeGreeting({
    super.key,
    required this.nickname,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '늦은 밤이에요';
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '안녕하세요';
    return '좋은 저녁이에요';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}, $nickname님!',
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14,
            color: kOnSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        const Text(
          'For Your Archive',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: kOnSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
