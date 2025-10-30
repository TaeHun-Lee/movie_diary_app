import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/api_service.dart';

class DiaryWriteScreen extends StatefulWidget {
  final Movie? movie;
  final DiaryEntry? entryToEdit;

  const DiaryWriteScreen({super.key, this.movie, this.entryToEdit}) :
    assert(movie != null || entryToEdit != null, 'Either movie or entryToEdit must be provided');

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;
  DateTime _watchedAt = DateTime.now();
  late Movie _currentMovie;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      // 수정 모드
      _titleController.text = widget.entryToEdit!.title;
      _contentController.text = widget.entryToEdit!.content ?? ''; // content가 null일 수 있음
      _rating = widget.entryToEdit!.rating;
      _watchedAt = DateTime.parse(widget.entryToEdit!.watchedDate);
      _locationController.text = widget.entryToEdit!.place ?? ''; // place가 null일 수 있음
      _currentMovie = widget.entryToEdit!.movie;
    } else if (widget.movie != null) {
      // 작성 모드
      _currentMovie = widget.movie!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _watchedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('영화 제목: ${_currentMovie.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('감독: ${_currentMovie.director}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('스틸컷', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentMovie.stillCutUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.network(_currentMovie.stillCutUrls[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '다이어리 제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            const Text('영화 점수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _rating,
              onChanged: (newRating) {
                setState(() {
                  _rating = newRating;
                });
              },
              min: 0,
              max: 10,
              divisions: 20,
              label: _rating.toStringAsFixed(1),
            ),
            const SizedBox(height: 16),
            const Text('본 날짜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(DateFormat('yyyy-MM-dd').format(_watchedAt)),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '장소 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDiary,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? '수정하기' : '저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDiary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.entryToEdit != null) {
        // 수정 모드
        await ApiService.updatePost(
          postId: widget.entryToEdit!.id,
          title: _titleController.text,
          content: _contentController.text,
          rating: _rating,
          watchedAt: _watchedAt,
          location: _locationController.text,
        );
      } else {
        // 작성 모드
        await ApiService.createPost(
          docId: _currentMovie.docId,
          title: _titleController.text,
          content: _contentController.text,
          rating: _rating,
          watchedAt: _watchedAt,
          location: _locationController.text,
          movie: _currentMovie,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.entryToEdit != null ? '다이어리 수정에 실패했습니다: $e' : '다이어리 저장에 실패했습니다: $e')),
        );
      }
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

