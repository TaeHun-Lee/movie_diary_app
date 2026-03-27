import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';

class HomeDiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback? onRefresh;

  const HomeDiaryCard({
    super.key,
    required this.entry,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryWriteScreen(
              entryToEdit: entry,
              heroTag: 'diary-poster-${entry.id}',
            ),
          ),
        );
        if (result == true) onRefresh?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: kSpacingL),
        padding: const EdgeInsets.all(kSpacingL),
        decoration: BoxDecoration(
          color: kSurfaceLowest,
          borderRadius: BorderRadius.circular(kRadiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: kSurfaceDim.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Poster thumbnail
            Container(
              width: 72,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusL),
                color: kSurfaceHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: entry.movie.posterUrl != null
                  ? Hero(
                      tag: 'diary-poster-${entry.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusL),
                        child: CachedNetworkImage(
                          imageUrl: entry.movie.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _posterPlaceholder(),
                          errorWidget: (_, __, ___) => _posterPlaceholder(),
                        ),
                      ),
                    )
                  : _posterPlaceholder(),
            ),

            const SizedBox(width: kSpacingL),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Diary title
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontFamily: kHeadlineFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kOnSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Movie title
                  Text(
                    entry.movie.title,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 12,
                      color: kOnSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kSpacingS),

                  // Rating + date (통일된 숫자 표기)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: kPrimary, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        entry.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: kHeadlineFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(width: kSpacingS),
                      Text(
                        entry.watchedDate,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 10,
                          color: kOnSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  // Content preview
                  if (entry.content != null &&
                      entry.content!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.content!.trim(),
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 11,
                        color: kOnSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Rating badge (gradient)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(kRadiusS),
              ),
              child: Text(
                entry.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: kSurfaceHigh,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          color: kOnSurfaceVariant.withValues(alpha: 0.3),
          size: 28,
        ),
      ),
    );
  }
}
