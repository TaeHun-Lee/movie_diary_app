import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';

class HomeFeaturedCard extends StatelessWidget {
  final DiaryEntry? latestEntry;
  final VoidCallback? onSearchTap;
  final VoidCallback? onRefresh;

  const HomeFeaturedCard({
    super.key,
    this.latestEntry,
    this.onSearchTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (latestEntry == null) {
      return _buildFeaturedEmptyCTA();
    }

    final entry = latestEntry!;

    // 스틸컷 우선, 없으면 포스터
    final bgUrl = entry.movie.stillCutUrls.isNotEmpty
        ? entry.movie.stillCutUrls.first
        : entry.movie.posterUrl;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryWriteScreen(
              entryToEdit: entry,
              heroTag: 'diary-hero-${entry.id}',
            ),
          ),
        );
        if (result == true) onRefresh?.call();
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusXL),
          boxShadow: [
            BoxShadow(
              color: kSurfaceDim.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (bgUrl != null)
              Hero(
                tag: 'diary-hero-${entry.id}',
                child: CachedNetworkImage(
                  imageUrl: bgUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (_, __) => Container(color: kSurfaceHigh),
                  errorWidget: (_, __, ___) => Container(color: kSurfaceHigh),
                ),
              )
            else
              Container(color: kSurfaceHigh),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Top-left label
            Positioned(
              top: kSpacingL,
              left: kSpacingL,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(kRadiusS),
                ),
                child: const Text(
                  '최근 기록',
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

            // Glass panel (bottom)
            Positioned(
              bottom: kSpacingL,
              left: kSpacingL,
              right: kSpacingL,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadiusL),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(kSpacingL),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(kRadiusL),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rating + date
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              entry.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: kHeadlineFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '·  ${entry.watchedDate}',
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpacingS),

                        // Movie title
                        Text(
                          entry.movie.title,
                          style: const TextStyle(
                            fontFamily: kHeadlineFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Review preview
                        if (entry.content != null &&
                            entry.content!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${entry.content!.trim()}"',
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Chevron indicator
            Positioned(
              top: kSpacingL,
              right: kSpacingL,
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedEmptyCTA() {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(kRadiusXL),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: kSpacingL),
              const Text(
                '어떤 영화를 보셨나요?',
                style: TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                '영화를 검색하고 첫 기록을 남겨보세요',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
