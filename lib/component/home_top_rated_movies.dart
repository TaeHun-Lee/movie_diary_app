import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';

class HomeTopRatedMovies extends StatelessWidget {
  final List<RatedMovie> movies;
  final List<DiaryEntry> recentEntries;
  final VoidCallback? onRefresh;

  const HomeTopRatedMovies({
    super.key,
    required this.movies,
    required this.recentEntries,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kSpacingXL),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final rm = movies[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < movies.length - 1 ? kSpacingM : 0),
            child: GestureDetector(
              onTap: () async {
                // 해당 영화의 다이어리로 이동
                final entry = recentEntries.firstWhere(
                  (e) => e.movie.docId == rm.movie.docId,
                );
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryWriteScreen(entryToEdit: entry),
                  ),
                );
                if (result == true) onRefresh?.call();
              },
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadiusL),
                          boxShadow: [
                            BoxShadow(
                              color: kSurfaceDim.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            rm.movie.posterUrl != null
                                ? Hero(
                                    tag: 'movie-poster-${rm.movie.docId}',
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(kRadiusL),
                                      child: CachedNetworkImage(
                                        imageUrl: rm.movie.posterUrl!,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        placeholder: (_, __) =>
                                            Container(color: kSurfaceHigh),
                                        errorWidget: (_, __, ___) =>
                                            Container(color: kSurfaceHigh),
                                      ),
                                    ),
                                  )
                                : Container(color: kSurfaceHigh),

                            // Bottom gradient
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Rating badge
                            Positioned(
                              bottom: kSpacingS,
                              left: kSpacingS,
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 13),
                                  const SizedBox(width: 2),
                                  Text(
                                    rm.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontFamily: kHeadlineFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: kSpacingS),

                    // Movie title
                    Text(
                      rm.movie.title,
                      style: const TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kOnSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
