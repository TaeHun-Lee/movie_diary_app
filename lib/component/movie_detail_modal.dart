import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

Future<dynamic> showMovieDetailModal(BuildContext context, Movie movie) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _MovieDetailSheet(movie: movie),
  );
}

class _MovieDetailSheet extends StatefulWidget {
  final Movie movie;
  const _MovieDetailSheet({required this.movie});

  @override
  State<_MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends State<_MovieDetailSheet> {
  late Future<List<DiaryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = ApiService.getMyReviewsForMovie(widget.movie.docId);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: screenH * 0.88,
          decoration: BoxDecoration(
            color: kSurfaceLowest.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── 드래그 핸들 ───────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kOutlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── 스크롤 영역 ────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 포스터
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.55,
                            child: widget.movie.posterUrl != null
                                ? Image.network(
                                    widget.movie.posterUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _posterPlaceholder(context),
                                  )
                                : _posterPlaceholder(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 장르 칩
                      if (widget.movie.genres.isNotEmpty &&
                          widget.movie.genres.first.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.movie.genres.map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: kPrimaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                g,
                                style: const TextStyle(
                                  fontFamily: kBodyFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 14),

                      // 제목
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontFamily: kHeadlineFont,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kOnSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 감독 / 연도
                      Text(
                        widget.movie.releaseDate.length >= 4
                            ? '${widget.movie.releaseDate.substring(0, 4)} · ${widget.movie.director}'
                            : '감독: ${widget.movie.director}',
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14,
                          color: kOnSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 줄거리
                      if (widget.movie.summary.isNotEmpty) ...[
                        const Text(
                          '줄거리',
                          style: TextStyle(
                            fontFamily: kHeadlineFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.movie.summary,
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 14,
                            color: kOnSurfaceVariant.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 내 다이어리 목록
                      _buildDiaryEntries(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // ── 고정 버튼 ─────────────────────────
              Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: kSurfaceLowest.withValues(alpha: 0.96),
                  border: Border(
                    top: BorderSide(
                      color: kOutlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiaryWriteScreen(movie: widget.movie),
                          ),
                        );
                        if (result == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '이 영화로 기록하기',
                        style: TextStyle(
                          fontFamily: kHeadlineFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterPlaceholder(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
      height: 280,
      color: kSurfaceHigh,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: kOnSurfaceVariant, size: 48),
      ),
    );
  }

  Widget _buildDiaryEntries() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = snapshot.data!;
        final avg = entries.fold<double>(0, (s, e) => s + e.rating) /
            entries.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: kOutlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '내 다이어리',
                  style: TextStyle(
                    fontFamily: kHeadlineFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.star_rounded, color: kPrimary, size: 16),
                Text(
                  ' ${avg.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(2).map((entry) {
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryWriteScreen(entryToEdit: entry),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _entriesFuture = ApiService.getMyReviewsForMovie(
                          widget.movie.docId);
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kSurfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kOutlineVariant.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 2),
                            Text(
                              entry.watchedDate,
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 12,
                                color: kOnSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: kPrimary, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            entry.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 12,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: kOnSurfaceVariant.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
