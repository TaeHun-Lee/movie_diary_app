import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/constants.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다이어리 목록을 불러오는데 실패했습니다.')),
        );
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
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text(
          'Personal Archive',
          style: TextStyle(
            fontFamily: kHeadlineFont,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: kOnSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : _diaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 80,
                    color: kSurfaceDim,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '작성된 일기가 없습니다.\n오늘의 소중한 순간을 기록해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kOnSurfaceVariant.withValues(alpha: 0.7),
                      fontFamily: kBodyFont,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];
                final date = DateTime.parse(diary['date']);
                final content = diary['content'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: kSurfaceLowest,
                    borderRadius: BorderRadius.circular(kRadiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, 6),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusXL),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToWrite(date),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat(
                                      'yyyy. MM. dd',
                                      'ko_KR',
                                    ).format(date),
                                    style: const TextStyle(
                                      color: kOnSurface,
                                      fontFamily: kHeadlineFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('(E)', 'ko_KR').format(date),
                                    style: TextStyle(
                                      color: kOnSurfaceVariant.withValues(alpha: 0.5),
                                      fontFamily: kHeadlineFont,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: kOnSurfaceVariant.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                content,
                                style: const TextStyle(
                                  color: kOnSurface,
                                  fontFamily: kBodyFont,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.25),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToWrite(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
