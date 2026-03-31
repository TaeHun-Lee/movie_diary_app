import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MyDiaryListScreen extends StatefulWidget {
  const MyDiaryListScreen({super.key});

  @override
  State<MyDiaryListScreen> createState() => _MyDiaryListScreenState();
}

class _MyDiaryListScreenState extends State<MyDiaryListScreen> {
  // Original Data
  List<DiaryEntry> _allPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter State
  String _searchQuery = '';
  final List<String> _selectedGenres = [];
  DateTimeRange? _selectedDateRange;
  List<DiaryEntry> _filteredPosts = [];

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadPosts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await ApiService.getMyPosts();
      if (!mounted) return;
      setState(() {
        _allPosts = posts;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '데이터를 불러오는데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final matchesTitle =
            post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            post.movie.title.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesGenre = true;
        if (_selectedGenres.isNotEmpty) {
          final movieGenres = post.movie.genres;
          matchesGenre = _selectedGenres.any((sg) => movieGenres.contains(sg));
        }

        bool matchesDate = true;
        if (_selectedDateRange != null) {
          DateTime? watchedDate;
          try {
            String cleanDate = post.watchedDate
                .replaceAll('.', '-')
                .replaceAll('/', '-')
                .trim();
            cleanDate = cleanDate.split(' ').first;
            watchedDate = DateTime.tryParse(cleanDate);
          } catch (_) {}

          if (watchedDate != null) {
            final start = _selectedDateRange!.start;
            final end = _selectedDateRange!.end;
            final dateOnly = DateTime(
              watchedDate.year,
              watchedDate.month,
              watchedDate.day,
            );
            final startOnly = DateTime(start.year, start.month, start.day);
            final endOnly = DateTime(end.year, end.month, end.day);

            matchesDate =
                dateOnly.compareTo(startOnly) >= 0 &&
                dateOnly.compareTo(endOnly) <= 0;
          } else {
            matchesDate = false;
          }
        }
        return matchesTitle && matchesGenre && matchesDate;
      }).toList();
    });
  }

  List<String> _getAvailableGenres() {
    final Set<String> genres = {};
    for (var post in _allPosts) {
      for (var genre in post.movie.genres) {
        genres.add(genre);
      }
    }
    return genres.toList()..sort();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
      _applyFilters();
    });
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
            scaffoldBackgroundColor: kSurface,
            appBarTheme: const AppBarTheme(
              backgroundColor: kSurface,
              elevation: 0,
              iconTheme: IconThemeData(color: kOnSurface),
              titleTextStyle: TextStyle(
                color: kOnSurface,
                fontSize: 20,
                fontFamily: kHeadlineFont,
                fontWeight: FontWeight.bold,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                textStyle: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: kBodyFont),
              labelLarge: TextStyle(fontFamily: kHeadlineFont),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableGenres = _getAvailableGenres();

    return Scaffold(
      backgroundColor: kSurface,
      appBar: const CustomAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              color: kSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Movie Archive",
                    style: TextStyle(
                      fontFamily: kHeadlineFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: kSurfaceHigh,
                      borderRadius: BorderRadius.circular(kRadiusL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: kOnSurface,
                        fontFamily: kBodyFont,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '제목 검색',
                        hintStyle: TextStyle(
                          color: kOnSurfaceVariant.withValues(alpha: 0.5),
                          fontFamily: kBodyFont,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: kOnSurfaceVariant,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDateRange(context),
                    borderRadius: BorderRadius.circular(kRadiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: kPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          if (_selectedDateRange != null) ...[
                            Text(
                              "${_selectedDateRange!.start.year}.${_selectedDateRange!.start.month.toString().padLeft(2, '0')}.${_selectedDateRange!.start.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                color: kOnSurface,
                                fontFamily: kHeadlineFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                "~",
                                style: TextStyle(
                                  color: kOnSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              "${_selectedDateRange!.end.year}.${_selectedDateRange!.end.month.toString().padLeft(2, '0')}.${_selectedDateRange!.end.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                color: kOnSurface,
                                fontFamily: kHeadlineFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              "날짜 범위 선택",
                              style: TextStyle(
                                color: kOnSurfaceVariant,
                                fontFamily: kHeadlineFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (availableGenres.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: availableGenres.map((genre) {
                          final isSelected = _selectedGenres.contains(genre);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(genre),
                              selected: isSelected,
                              onSelected: (_) => _toggleGenre(genre),
                              backgroundColor: kSurfaceHigh,
                              selectedColor: kSecondaryContainer,
                              checkmarkColor: kOnSecondaryContainer,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? kOnSecondaryContainer
                                    : kOnSurfaceVariant,
                                fontFamily: kBodyFont,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide.none,
                              ),
                              showCheckmark: isSelected,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: kSurfaceDim,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: kOnSurfaceVariant,
                              fontFamily: kBodyFont,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredPosts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_filter_rounded,
                            color: kSurfaceDim,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(
                              color: kOnSurfaceVariant,
                              fontFamily: kBodyFont,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: kSurfaceLowest,
                            borderRadius: BorderRadius.circular(kRadiusXL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                offset: const Offset(0, 6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(kRadiusXL),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DiaryWriteScreen(entryToEdit: post),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadPosts();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'post_${post.id}',
                                        child: Container(
                                          width: 80,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              kRadiusL,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              kRadiusL,
                                            ),
                                            child: post.movie.posterUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl:
                                                        ApiService.buildImageUrl(
                                                          post.movie.posterUrl,
                                                        )!,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Shimmer.fromColors(
                                                          baseColor:
                                                              kSurfaceHigh,
                                                          highlightColor:
                                                              kSurfaceLowest,
                                                          child: Container(
                                                            color: kSurfaceHigh,
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => Container(
                                                          color: kSurfaceHigh,
                                                          child: const Icon(
                                                            Icons.movie_rounded,
                                                            color: kSurfaceDim,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    color: kSurfaceHigh,
                                                    child: const Icon(
                                                      Icons.movie_rounded,
                                                      color: kSurfaceDim,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: kHeadlineFont,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: kOnSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              post.movie.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: kBodyFont,
                                                fontSize: 14,
                                                color: kOnSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text(
                                                  post.watchedDate,
                                                  style: TextStyle(
                                                    fontFamily: kBodyFont,
                                                    fontSize: 12,
                                                    color: kOnSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: kPrimaryGradient,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star_rounded,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        post.rating.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
