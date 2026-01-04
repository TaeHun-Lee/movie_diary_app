import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/screens/personal_diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

class PersonalDiaryScreen extends StatefulWidget {
  const PersonalDiaryScreen({super.key});

  @override
  State<PersonalDiaryScreen> createState() => _PersonalDiaryScreenState();
}

class _PersonalDiaryScreenState extends State<PersonalDiaryScreen> {
  List<dynamic> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiaries();
  }

  Future<void> _fetchDiaries() async {
    setState(() => _isLoading = true);
    try {
      final diaries = await ApiService.getPersonalDiaries();
      // Sort by date DESC
      diaries.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _diaries = diaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('다이어리 목록을 불러오는데 실패했습니다.')));
      }
    }
  }

  Future<void> _navigateToWrite([DateTime? date]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PersonalDiaryWriteScreen(initialDate: date ?? DateTime.now()),
      ),
    );

    if (result == true || result == null) {
      _fetchDiaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('개인 다이어리'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _diaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  Text(
                    '작성된 일기가 없습니다.\n오늘의 일기를 작성해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];
                final date = DateTime.parse(diary['date']);
                final content = diary['content'] ?? '';

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _navigateToWrite(date),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'yyyy년 MM월 dd일 (E)',
                              'ko_KR',
                            ).format(date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWrite(),
        backgroundColor: const Color(0xFFE50914),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
