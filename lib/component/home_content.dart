import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/component/home_greeting.dart';
import 'package:movie_diary_app/component/home_featured_card.dart';
import 'package:movie_diary_app/component/home_stats_bento.dart';
import 'package:movie_diary_app/component/home_top_rated_movies.dart';
import 'package:movie_diary_app/component/home_calendar_heatmap.dart';
import 'package:movie_diary_app/component/home_diary_card.dart';
import 'package:movie_diary_app/component/home_empty_state.dart';

class HomeContent extends StatelessWidget {
  final HomeData data;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearchTap;
  final VoidCallback? onDiaryTabTap;

  const HomeContent({
    super.key,
    required this.data,
    this.onRefresh,
    this.onSearchTap,
    this.onDiaryTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      color: kPrimary,
      backgroundColor: kSurfaceLowest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacingXXL, kSpacingXL, 0),
              child: HomeGreeting(nickname: data.user.nickname),
            ),
          ),

          // 2. Featured Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacingXXL, kSpacingXL, 0),
              child: HomeFeaturedCard(
                latestEntry: data.recentEntries.isNotEmpty ? data.recentEntries.first : null,
                onSearchTap: onSearchTap,
                onRefresh: onRefresh,
              ),
            ),
          ),

          // 3. Stats Bento Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacing3XL, kSpacingXL, 0),
              child: HomeStatsBento(data: data),
            ),
          ),

          // 4. Top Rated Movies (조건부)
          if (data.topRatedMovies.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacing3XL, kSpacingXL, 0),
                child: _buildSectionHeader(
                  '내가 사랑한 영화',
                  onTap: onDiaryTabTap,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: kSpacingL),
                child: HomeTopRatedMovies(
                  movies: data.topRatedMovies,
                  recentEntries: data.recentEntries,
                  onRefresh: onRefresh,
                ),
              ),
            ),
          ],

          // 5. Calendar Heatmap
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacing3XL, kSpacingXL, 0),
              child: HomeCalendarHeatmap(
                heatmap: data.monthlyHeatmap,
                entries: data.recentEntries,
                onRefresh: onRefresh,
              ),
            ),
          ),

          // 6. Recent Diary Entries
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacing3XL, kSpacingXL, 0),
              child: _buildSectionHeader(
                '최근 기록',
                onTap: onDiaryTabTap,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacingL, kSpacingXL, kSpacingNav),
              child: data.recentEntries.isEmpty
                  ? const HomeEmptyState()
                  : Column(
                      children: data.recentEntries
                          .take(5)
                          .map((e) => HomeDiaryCard(entry: e, onRefresh: onRefresh))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Header Helper
  // ─────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  '전체보기',
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 12,
                    color: kOnSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: kOnSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
