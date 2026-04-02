import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/screens/main_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DiaryWriteScreen extends StatefulWidget {
  final Movie? movie;
  final DiaryEntry? entryToEdit;
  final String? heroTag;

  const DiaryWriteScreen({
    super.key,
    this.movie,
    this.entryToEdit,
    this.heroTag,
  }) : assert(
          movie != null || entryToEdit != null,
          'Either movie or entryToEdit must be provided',
        );

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;
  bool _isSpoiler = false;
  DateTime _watchedAt = DateTime.now();
  late Movie _currentMovie;
  /* Photo State */
  final List<XFile> _pickedImages = [];
  final List<String> _existingPhotoUrls = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      // 수정 모드
      _titleController.text = widget.entryToEdit!.title;
      _contentController.text = widget.entryToEdit!.content ?? '';
      _rating = widget.entryToEdit!.rating;
      _watchedAt = DateTime.parse(widget.entryToEdit!.watchedDate);
      _locationController.text = widget.entryToEdit!.place ?? '';
      _isSpoiler = widget.entryToEdit!.isSpoiler;
      _currentMovie = widget.entryToEdit!.movie;
      if (widget.entryToEdit!.images.isNotEmpty) {
        _existingPhotoUrls.addAll(widget.entryToEdit!.images);
      }
    } else if (widget.movie != null) {
      // 작성 모드
      _currentMovie = widget.movie!;
      debugPrint('DEBUG: Movie Genres: ${_currentMovie.genres}');
      _titleController.text = _currentMovie.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(pickedFiles);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _watchedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != _watchedAt) {
      setState(() {
        _watchedAt = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entryToEdit != null;

    return Scaffold(
      backgroundColor: kSurface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? '다이어리 수정' : '다이어리 작성',
          style: const TextStyle(
            fontFamily: kHeadlineFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 영화 정보 카드 ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSurfaceLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kSurfaceDim.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 6,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (_currentMovie.posterUrl != null &&
                                  _currentMovie.posterUrl!.isNotEmpty)
                              ? (widget.heroTag != null
                                  ? Hero(
                                      tag: widget.heroTag!,
                                      child: CachedNetworkImage(
                                        imageUrl: _currentMovie.posterUrl!,
                                        width: 56,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            _miniPoster(),
                                        errorWidget: (_, __, ___) =>
                                            _miniPoster(),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: _currentMovie.posterUrl!,
                                      width: 56,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          _miniPoster(),
                                      errorWidget: (_, __, ___) =>
                                          _miniPoster(),
                                    ))
                              : _miniPoster(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentMovie.title,
                                style: const TextStyle(
                                  fontFamily: kHeadlineFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: kOnSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_currentMovie.releaseDate.split("-")[0]} · ${_currentMovie.director}',
                                style: TextStyle(
                                  fontFamily: kBodyFont,
                                  fontSize: 12,
                                  color: kOnSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildGenreChips(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 평점 슬라이더 ────────────────────
                  _buildLabel('평점'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: kSurfaceLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kSurfaceDim.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 6,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: kHeadlineFont,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                            const Text(
                              ' / 10',
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 14,
                                color: kOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(_rating),
                        Slider(
                          value: _rating,
                          min: 0,
                          max: 10,
                          divisions: 20,
                          onChanged: (val) => setState(() => _rating = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 제목 ─────────────────────────────
                  _buildLabel('제목'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hintText: '다이어리 제목을 입력해주세요.',
                  ),
                  const SizedBox(height: 16),

                  // ── 관람일 + 장소 (2열) ──────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('관람일'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: kSurfaceHigh,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0D000000),
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 4,
                                      offset: Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: kPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy-MM-dd')
                                          .format(_watchedAt),
                                      style: const TextStyle(
                                        fontFamily: kBodyFont,
                                        color: kOnSurface,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('관람 장소'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _locationController,
                              hintText: '장소 입력',
                              suffixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: kPrimary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 내용 ─────────────────────────────
                  _buildLabel('내용'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contentController,
                    hintText: '영화 감상을 자유롭게 작성해주세요.',
                    maxLines: 7,
                  ),
                  const SizedBox(height: 16),

                  // ── 사진 추가 ─────────────────────────
                  _buildLabel('사진 추가'),
                  const SizedBox(height: 8),
                  _buildPhotoSection(),
                  const SizedBox(height: 16),

                  // ── 스포일러 토글 ─────────────────────
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isSpoiler = !_isSpoiler),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isSpoiler
                            ? kPrimary.withValues(alpha: 0.08)
                            : kSurfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isSpoiler
                              ? kPrimary.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSpoiler
                                ? Icons.warning_amber_rounded
                                : Icons.warning_amber_outlined,
                            color: _isSpoiler ? kPrimary : kOnSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '스포일러 포함',
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isSpoiler ? kPrimary : kOnSurface,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isSpoiler,
                            onChanged: (val) =>
                                setState(() => _isSpoiler = val),
                            activeThumbColor: kPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── 고정 하단 버튼 ───────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: kSurfaceLowest,
              border: Border(
                top: BorderSide(
                    color: kOutlineVariant.withValues(alpha: 0.2)),
              ),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : isEditing
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildActionButton(
                              text: '수정하기',
                              onPressed: _saveDiary,
                              isPrimary: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _buildActionButton(
                              text: '삭제',
                              onPressed: _deleteDiary,
                              isPrimary: false,
                            ),
                          ),
                        ],
                      )
                    : _buildActionButton(
                        text: '저장하기',
                        onPressed: _saveDiary,
                        isPrimary: true,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _miniPoster() {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: kSurfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.movie_outlined,
          color: kOnSurfaceVariant, size: 24),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: kBodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kOnSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceHigh,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: kBodyFont,
          color: kOnSurface,
          fontSize: 14,
        ),
        cursorColor: kPrimary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: kOnSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: kPrimary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: kHeadlineFont,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: kError.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: kHeadlineFont,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kError,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStarRating(double rating) {
    final starValue = rating / 2;
    final fullStars = starValue.floor();
    final hasHalf = (starValue - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return const Icon(Icons.star_rounded, color: kPrimary, size: 28);
        } else if (i == fullStars && hasHalf) {
          return const Icon(Icons.star_half_rounded, color: kPrimary, size: 28);
        } else {
          return const Icon(Icons.star_outline_rounded,
              color: kSurfaceDim, size: 28);
        }
      }),
    );
  }

  // _buildGenreChips removed from here if it's already at end of file.
  // Wait, I need to make sure I don't duplicate it.
  // I am replacing `build` and helpers. I should check if `_buildGenreChips` was inside the range I am deleting.
  // In previous file state, `_buildGenreChips` was at the very end of class.
  // I will check carefully.
  // I'll call `view_file` first to be safe. This tool call is just planning but I can't plan without viewing.

  Widget _buildGenreChips(BuildContext context) {
    if (_currentMovie.genres.isEmpty) {
      return Text(
        '장르 정보 없음',
        style: TextStyle(
          fontFamily: kBodyFont,
          color: kOnSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _currentMovie.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kSecondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            genre,
            style: const TextStyle(
              fontFamily: kBodyFont,
              color: kOnSecondaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 사진 추가 버튼
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: kSurfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kOutlineVariant.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: kPrimary, size: 26),
                  SizedBox(height: 4),
                  Text(
                    '사진 추가',
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 10,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 기존 사진
          ..._existingPhotoUrls.asMap().entries.map((entry) {
            final idx = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ApiService.buildImageUrl(url) ?? '',
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 100,
                        color: kSurfaceHigh,
                        child: const Icon(Icons.broken_image_outlined,
                            color: kOnSurfaceVariant),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _existingPhotoUrls.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: kOnSurface.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // 새로 선택한 이미지
          ..._pickedImages.asMap().entries.map((entry) {
            final idx = entry.key;
            final file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(file.path,
                            width: 80, height: 100, fit: BoxFit.cover)
                        : Image.file(File(file.path),
                            width: 80, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _pickedImages.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: kOnSurface.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveDiary() async {
    // Title is needed? User design had title input. I removed it from layout steps 1-8?
    // Wait, user instructions:
    // 2. Movie Title (Text)
    // 3. Rating
    // 4. Date/Loc
    // 5. Review Content
    // 6. Photo
    // 7. Spoiler
    // ... WHERE IS DIARY TITLE?
    // User instruction 2 says "Movie Title...".
    // User instruction 5 says "Review content input".
    // It seems "Diary Title" input is MISSING in the user's new list.
    // However, the backend REQUIREs a title.
    // I will use "Movie Title" or a default "Review" as the title if not provided, OR I should keep the Title input?
    // User Step 2: "Movie Title part styling..." (This implies Display).
    // User Step 5: "Review Content input".
    // I will implicitly assume the "Content" is the main part. I will Auto-fill Title with "Movie Title" or "Review" and hide the input if user didn't ask for it.
    // OR I can use the first few words of Content.
    // I'll set Title = Movie Title by default if not present.
    // Wait, I should probably keep Title input if it was there? "1234" in previous image was title.
    // But the NEW request 1-8 doesn't list "Diary Title Input".
    // It lists "Movie Title part" (Display).
    // Then "Rating", "Date/Loc", "Content".
    // I will HIDE the Title input and use `_currentMovie.title` as the default title for the post.

    String titleToSave = _titleController.text;
    if (titleToSave.isEmpty) {
      titleToSave = '${_currentMovie.title} 리뷰'; // Default title
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> photoUrls = [..._existingPhotoUrls];
      for (var imageFile in _pickedImages) {
        final uploadedUrl = await ApiService.uploadPhoto(imageFile);
        if (uploadedUrl != null) {
          photoUrls.add(uploadedUrl);
        }
      }

      if (widget.entryToEdit != null) {
        // 수정 모드
        await ApiService.updatePost(
          postId: widget.entryToEdit!.id,
          title: titleToSave,
          content: _contentController.text,
          rating: _rating,
          watchedAt: _watchedAt,
          location: _locationController.text,
          isSpoiler: _isSpoiler,
          photoUrls: photoUrls,
        );
      } else {
        // 작성 모드
        await ApiService.createPost(
          docId: _currentMovie.docId,
          title: titleToSave,
          content: _contentController.text,
          rating: _rating,
          watchedAt: _watchedAt,
          location: _locationController.text,
          movie: _currentMovie,
          isSpoiler: _isSpoiler,
          photoUrls: photoUrls,
        );
      }

      if (mounted) {
        // 부모 화면으로 돌아가며 갱신 필요 알림
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entryToEdit != null
                  ? '다이어리 수정에 실패했습니다.'
                  : '다이어리 저장에 실패했습니다.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDiary() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceLowest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '삭제 확인',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
          ),
        ),
        content: const Text(
          '정말로 이 다이어리를 삭제하시겠습니까?',
          style: TextStyle(
            fontFamily: kBodyFont,
            color: kOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소',
                style: TextStyle(color: kOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제',
                style: TextStyle(
                    color: kError, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.deletePost(widget.entryToEdit!.id);

        if (mounted) {
          // 부모 화면으로 돌아가며 갱신 필요 알림
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('다이어리 삭제에 실패했습니다.')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
