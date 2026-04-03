import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const double _bottomCtaTopPadding = 16;
  static const double _bottomCtaButtonVerticalPadding = 16;
  static const double _bottomContentSpacing = 24;

  late Future<List<DiaryEntry>> _entriesFuture;
  bool _plotExpanded = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = ApiService.getMyReviewsForMovie(widget.movie.docId);
  }

  void _refreshEntries() {
    setState(() {
      _entriesFuture = ApiService.getMyReviewsForMovie(widget.movie.docId);
    });
  }

  // 히어로 배경 이미지 URL 결정: 포스터 우선 (고해상도), 없으면 스틸컷
  String? get _heroImageUrl {
    if (widget.movie.posterUrl != null) {
      return widget.movie.posterUrl;
    }
    if (widget.movie.stillCutUrls.isNotEmpty) {
      return widget.movie.stillCutUrls.first;
    }
    return null;
  }

  String get _yearText {
    if (widget.movie.releaseDate.length >= 4) {
      return widget.movie.releaseDate.substring(0, 4);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final bottomOverlayHeight =
        _bottomCtaTopPadding +
        (_bottomCtaButtonVerticalPadding * 2) +
        24 +
        bottomSafeArea +
        16;

    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // -- Hero SliverAppBar --
              _buildHeroAppBar(context),

              // -- 줄거리 --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: _buildPlotSection(),
                ),
              ),

              // -- 스틸컷 갤러리 (패딩 없이 화면 끝까지 스크롤) --
              if (widget.movie.stillCutUrls.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: _buildStillCutsSection(),
                  ),
                ),

              // -- 내 다이어리 --
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    32,
                    24,
                    bottomOverlayHeight + _bottomContentSpacing,
                  ),
                  child: _buildMyDiarySection(),
                ),
              ),
            ],
          ),

          // -- 하단 고정 CTA --
          _buildBottomCTA(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Hero AppBar (스틸컷/포스터 배경 + 글래스모픽 카드)
  // ─────────────────────────────────────────────
  SliverAppBar _buildHeroAppBar(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      stretch: true,
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지 (Hero 애니메이션 적용)
            if (_heroImageUrl != null)
              Hero(
                tag: 'movie-poster-${widget.movie.docId}',
                child: CachedNetworkImage(
                  imageUrl: _heroImageUrl!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (_, __) =>
                      Container(color: kSurfaceHigh),
                  errorWidget: (_, __, ___) =>
                      Container(color: kSurfaceHigh),
                ),
              )
            else
              Container(color: kSurfaceHigh),

            // 하단 그래디언트
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      kSurface.withValues(alpha: 0.4),
                      kSurface,
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // 글래스모픽 정보 카드
            Positioned(
              left: 20,
              right: 20,
              bottom: 0,
              child: _buildGlassCard(screenW),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: kSurfaceLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: kOnSurface, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(double screenW) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurfaceLowest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 장르 칩
              if (widget.movie.genres.isNotEmpty &&
                  widget.movie.genres.first.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.movie.genres.map((g) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        g,
                        style: const TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              if (widget.movie.genres.isNotEmpty) const SizedBox(height: 10),

              // 제목
              Text(
                widget.movie.title,
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kOnSurface,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // 메타 정보 (연도 / 감독)
              Row(
                children: [
                  if (_yearText.isNotEmpty) ...[
                    _buildMetaChip(Icons.calendar_today_rounded, _yearText),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: _buildMetaChip(
                      Icons.movie_creation_outlined,
                      widget.movie.director,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 13,
              color: kOnSurfaceVariant.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 줄거리 섹션 (접기/펼치기)
  // ─────────────────────────────────────────────
  Widget _buildPlotSection() {
    if (widget.movie.summary.isEmpty) return const SizedBox.shrink();

    final isLong = widget.movie.summary.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '줄거리',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _plotExpanded || !isLong
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.movie.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 14,
              color: kOnSurfaceVariant.withValues(alpha: 0.85),
              height: 1.7,
            ),
          ),
          secondChild: Text(
            widget.movie.summary,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 14,
              color: kOnSurfaceVariant.withValues(alpha: 0.85),
              height: 1.7,
            ),
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _plotExpanded = !_plotExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _plotExpanded ? '접기' : '더 보기',
                  style: const TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                Icon(
                  _plotExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: kPrimary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 스틸컷 갤러리
  // ─────────────────────────────────────────────
  Widget _buildStillCutsSection() {
    final stills = widget.movie.stillCutUrls;
    if (stills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (좌측 패딩만)
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              const Text(
                '스틸컷',
                style: TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stills.length}장',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 13,
                  color: kOnSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 가로 스크롤 (화면 전체 너비 사용)
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: stills.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < stills.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, stills, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 260,
                      child: Image.network(
                        stills[index],
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Container(
                          width: 260,
                          color: kSurfaceHigh,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: kOnSurfaceVariant, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 내 다이어리 섹션
  // ─────────────────────────────────────────────
  Widget _buildMyDiarySection() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
            ),
          );
        }

        final entries = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 섹션 헤더
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
                if (entries.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
              ],
            ),

            // 통계 카드 (리뷰가 있을 때만)
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildReviewStats(entries),
            ],

            const SizedBox(height: 16),

            // 리뷰 목록 또는 빈 상태
            if (entries.isEmpty)
              _buildEmptyDiaryState()
            else
              ...entries.map((entry) => _buildDiaryEntryCard(entry)),
          ],
        );
      },
    );
  }

  Widget _buildReviewStats(List<DiaryEntry> entries) {
    final avg =
        entries.fold<double>(0, (s, e) => s + e.rating) / entries.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kSurfaceDim.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(2, 3),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 평균 평점
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: kPrimary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kOnSurface,
                      ),
                    ),
                    Text(
                      ' / 10',
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 13,
                        color: kOnSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '내 평균 평점',
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    color: kOnSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 36,
            color: kOutlineVariant.withValues(alpha: 0.2),
          ),

          // 관람 횟수
          Expanded(
            child: Column(
              children: [
                Text(
                  '${entries.length}회',
                  style: const TextStyle(
                    fontFamily: kHeadlineFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '관람 기록',
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    color: kOnSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDiaryState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSurfaceHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 28,
              color: kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '아직 이 영화에 대한 기록이 없습니다',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 13,
              color: kOnSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 버튼을 눌러 첫 다이어리를 작성해보세요',
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

  Widget _buildDiaryEntryCard(DiaryEntry entry) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryWriteScreen(entryToEdit: entry),
          ),
        );
        if (result == true && mounted) _refreshEntries();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kSurfaceDim.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(2, 3),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 6,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (제목 + 평점)
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      fontFamily: kHeadlineFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kOnSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        entry.rating.toStringAsFixed(1),
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

            const SizedBox(height: 8),

            // 관람일 + 스포일러
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: kOnSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text(
                  entry.watchedDate,
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 12,
                    color: kOnSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                if (entry.isSpoiler) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '스포일러',
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kError,
                      ),
                    ),
                  ),
                ],
                if (entry.place != null && entry.place!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.place_outlined,
                      size: 13,
                      color: kOnSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      entry.place!,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 12,
                        color: kOnSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // 리뷰 내용 미리보기
            if (entry.content != null && entry.content!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.content!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 13,
                  color: kOnSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // 사진 미리보기
            if (entry.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.images.length > 4 ? 4 : entry.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 3 && entry.images.length > 4) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kSurfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '+${entry.images.length - 3}',
                            style: const TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    final imageUrl = entry.images[index].startsWith('http')
                        ? entry.images[index]
                        : '${ApiService.baseUrl}${entry.images[index]}';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: kSurfaceHigh,
                            child: const Icon(Icons.broken_image_outlined,
                                size: 18, color: kOnSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 하단 고정 CTA 버튼
  // ─────────────────────────────────────────────
  Widget _buildBottomCTA(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: _bottomCtaTopPadding,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kSurface.withValues(alpha: 0.0),
              kSurface.withValues(alpha: 0.8),
              kSurface,
            ],
            stops: const [0.0, 0.3, 0.5],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryWriteScreen(movie: widget.movie),
                  ),
                );
                if (result == true && mounted) {
                  _refreshEntries();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: _bottomCtaButtonVerticalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      '이 영화로 기록하기',
                      style: TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 풀스크린 이미지 갤러리
// ─────────────────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // 이미지 페이저
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 페이지 인디케이터
            if (widget.images.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
