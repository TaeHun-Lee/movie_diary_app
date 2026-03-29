import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/services/api_service.dart';

class PersonalDiaryWriteScreen extends StatefulWidget {
  final DateTime initialDate;

  const PersonalDiaryWriteScreen({super.key, required this.initialDate});

  @override
  State<PersonalDiaryWriteScreen> createState() =>
      _PersonalDiaryWriteScreenState();
}

class _PersonalDiaryWriteScreenState extends State<PersonalDiaryWriteScreen> {
  late DateTime _selectedDate;
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isDataLoaded = false;
  int? _diaryId;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadEntryForDate(_selectedDate);
  }

  Future<void> _loadEntryForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _isDataLoaded = false;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final data = await ApiService.getPersonalDiaryByDate(formattedDate);

      if (data != null) {
        _contentController.text = data['content'] ?? '';
        _diaryId = data['id'];
      } else {
        _contentController.clear();
        _diaryId = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터를 불러오는데 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDataLoaded = true;
        });
      }
    }
  }

  Future<void> _saveDiary() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await ApiService.savePersonalDiary(
        formattedDate,
        _contentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDiary() async {
    if (_diaryId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '일기 삭제',
          style: TextStyle(
            color: kOnSurface,
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '이 일기를 정말 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
          style: TextStyle(
            color: kOnSurfaceVariant,
            fontFamily: kBodyFont,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: kOnSurfaceVariant,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: kError,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deletePersonalDiary(_diaryId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: kSurfaceLowest,
              onSurface: kOnSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadEntryForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kOnSurface,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceLowest,
              borderRadius: BorderRadius.circular(kRadiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('yyyy. MM. dd').format(_selectedDate),
                  style: const TextStyle(
                    fontFamily: kHeadlineFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
              ],
            ),
          ),
        ),
        actions: [
          if (_diaryId != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: kError),
              onPressed: _deleteDiary,
            ),
        ],
      ),
      body: _isLoading && !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurfaceHigh,
                        borderRadius: BorderRadius.circular(kRadiusXL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(-4, -4),
                            blurRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(4, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _contentController,
                        style: const TextStyle(
                          color: kOnSurface,
                          fontFamily: kBodyFont,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: '오늘 하루는 어땠나요?\n기억하고 싶은 순간을 기록해보세요.',
                          hintStyle: TextStyle(
                            color: kOnSurfaceVariant.withValues(alpha: 0.4),
                            fontFamily: kBodyFont,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(kRadiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.25),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusXL),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: kHeadlineFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('기록 완료'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
