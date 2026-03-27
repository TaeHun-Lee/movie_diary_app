import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/home_data.dart';

class HomeStatsBento extends StatelessWidget {
  final HomeData data;

  const HomeStatsBento({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: '전체 다이어리',
                value: '${data.totalCount}편',
                icon: Icons.auto_stories_rounded,
              ),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: _statCard(
                label: '이번 달',
                value: '${data.monthlyCount}편',
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingM),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: '평균 평점',
                value: data.averageRating > 0
                    ? data.averageRating.toStringAsFixed(1)
                    : '-',
                icon: Icons.star_rounded,
                valueColor: kPrimary,
              ),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: _statCard(
                label: '최다 장르',
                value: data.topGenre,
                icon: Icons.local_movies_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(kSpacingL),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(kRadiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: kSurfaceDim.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kOnSurfaceVariant),
              const SizedBox(width: kSpacingXS),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 11,
                  color: kOnSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: kHeadlineFont,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor ?? kOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}
