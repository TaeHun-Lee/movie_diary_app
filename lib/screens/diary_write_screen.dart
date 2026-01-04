import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  const DiaryWriteScreen({super.key, this.movie, this.entryToEdit})
    : assert(
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
      print('DEBUG: Movie Genres: ${_currentMovie.genres}');
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
      locale: const Locale('ko', 'KR'), // Force Korean
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914), // Red for emphasis
              onPrimary: Colors.white,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
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
    final appBarTitle = isEditing
        ? '${_currentMovie.title} 다이어리 수정'
        : '${_currentMovie.title} 다이어리 작성';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      resizeToAvoidBottomInset:
          true, // Allow keyboard to push up inputs but maybe not buttons if they are fixed. Fixed buttons often hide behind keyboard. We'll see.
      // Usually resizing body works well.
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Movie Info (Poster + Title/Director) - Dark Background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Vertically centered
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              (_currentMovie.posterUrl != null &&
                                  _currentMovie.posterUrl!.isNotEmpty)
                              ? Image.network(
                                  _currentMovie.posterUrl!,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 50,
                                        height: 75,
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.movie,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 50,
                                  height: 75,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentMovie.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_currentMovie.releaseDate.split("-")[0]} / ${_currentMovie.director}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildGenreChips(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Rating (Star Indicator + Slider)
                  _buildLabel('평점'),
                  const SizedBox(height: 2),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildStarRating(_rating),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withAlpha(32),
                            activeTickMarkColor: Colors.transparent,
                            inactiveTickMarkColor: Colors.transparent,
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8.0,
                            ),
                          ),
                          child: Slider(
                            value: _rating,
                            min: 0,
                            max: 10,
                            divisions: 20,
                            onChanged: (val) {
                              setState(() {
                                _rating = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3.5. Diary Title Input
                  _buildLabel('제목'),
                  const SizedBox(height: 2),
                  _buildTextField(
                    controller: _titleController,
                    hintText: '제목을 입력해주세요.',
                  ),
                  const SizedBox(height: 12),

                  // 4. Date & Location (Dark Inputs)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('관람일'),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E), // Dark Fill
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_watchedAt),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('관람 장소'),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _locationController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: '장소 입력',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2C2C2E),
                                suffixIcon: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. Content (Review) - Dark Input
                  _buildLabel('내용'),
                  const SizedBox(height: 2),
                  _buildTextField(
                    controller: _contentController,
                    hintText: '리뷰를 작성해주세요.',
                    maxLines: 8,
                  ),
                  const SizedBox(height: 12),

                  // 6. Photo Section (Carousel)
                  _buildLabel('사진 추가'),
                  const SizedBox(height: 2),
                  _buildPhotoSection(),
                  const SizedBox(height: 12),

                  // 7. Spoiler Checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSpoiler = !_isSpoiler;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isSpoiler,
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          side: BorderSide(color: Colors.grey[500]!),
                          onChanged: (val) {
                            setState(() {
                              _isSpoiler = val ?? false;
                            });
                          },
                        ),
                        const Text(
                          '스포일러 포함',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Space before bottom buttons
                ],
              ),
            ),
          ),

          // 8. Fixed Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              border: Border(top: BorderSide(color: Color(0xFF2C2C2E))),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE50914)),
                  )
                : (isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                text: '수정하기',
                                onPressed: _saveDiary,
                                backgroundColor: const Color(0xFFE50914), // Red
                                textColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildButton(
                                text: '삭제하기',
                                onPressed: _deleteDiary,
                                backgroundColor: Colors.grey[800]!,
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: _buildButton(
                            text: '저장하기',
                            onPressed: _saveDiary,
                            backgroundColor: const Color(0xFFE50914), // Red
                            textColor: Colors.white,
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }

  Widget _buildStarRating(double rating) {
    // rating is 0-10. Convert to 0-5 stars.
    double starValue = rating / 2;
    int fullStars = starValue.floor();
    bool hasHalfStar = (starValue - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.white, size: 28);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.white, size: 28);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[800], size: 28);
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
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _currentMovie.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914), // Red
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            genre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
          // Add Button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: const Icon(Icons.add_a_photo, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          // Existing Photos
          ..._existingPhotoUrls.asMap().entries.map((entry) {
            int idx = entry.key;
            String url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ApiService.buildImageUrl(url) ?? '',
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 100,
                        color: Colors.grey[800],
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ApiService.buildImageUrl(url) ?? 'Null URL',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                error.toString(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _existingPhotoUrls.removeAt(idx);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // New picked images
          ..._pickedImages.asMap().entries.map((entry) {
            int idx = entry.key;
            XFile file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            file.path,
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(file.path),
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickedImages.removeAt(idx);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
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
        // 홈 화면으로 이동 (스택 초기화)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
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
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('삭제 확인', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 이 다이어리를 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
          // 홈 화면으로 이동 (스택 초기화)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
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
