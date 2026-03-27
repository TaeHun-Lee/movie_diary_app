import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kSurfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 32,
              color: kOnSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: kSpacingL),
          const Text(
            '아직 작성된 다이어리가 없습니다.',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 14,
              color: kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          Text(
            '영화를 검색하고 첫 번째 다이어리를 작성해보세요!',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 12,
              color: kOnSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
