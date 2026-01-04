import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int? _diaryId; // If exists, needed for delete.

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
      // Handle error cleanly
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('데이터를 불러오는데 실패했습니다.')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      // handled by ApiService but we can show snackbar if needed (already handled there)
      // Wait, ApiService helper throws Exception.
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
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('삭제', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인', style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deletePersonalDiary(_diaryId!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914),
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: _pickDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          if (_diaryId != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteDiary,
            ),
        ],
      ),
      body: _isLoading && !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: '오늘 하루는 어땠나요?',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '저장',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
