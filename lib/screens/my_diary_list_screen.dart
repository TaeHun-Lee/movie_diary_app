import 'package:flutter/material.dart';
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
    _selectedDateRange = DateTimeRange(start: now, end: now);
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await ApiService.getMyPosts();
      setState(() {
        _allPosts = posts;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        // 1. Title Search
        final matchesTitle =
            post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            post.movie.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // 2. Genre Filter
        bool matchesGenre = true;
        if (_selectedGenres.isNotEmpty) {
          final movieGenres = post.movie.genres;
          matchesGenre = _selectedGenres.any((sg) => movieGenres.contains(sg));
        }

        // 3. Date Range Filter
        bool matchesDate = true;
        if (_selectedDateRange != null) {
          DateTime? watchedDate;
          try {
            String cleanDate = post.watchedDate
                .replaceAll('.', '-')
                .replaceAll('/', '-')
                .trim();
            cleanDate = cleanDate.replaceAll(' ', '-');
            watchedDate = DateTime.parse(cleanDate);
          } catch (_) {}

          if (watchedDate != null) {
            // Check if watchedDate is within the range [start, end]
            // We compare only Year, Month, Day to avoid time issues
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

  // Get all unique genres from the loaded posts
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE50914),
              ),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(color: Colors.white),
              headlineMedium: TextStyle(color: Colors.white),
              headlineSmall: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Colors.white),
              labelLarge: TextStyle(color: Colors.white),
              labelMedium: TextStyle(color: Colors.white),
              labelSmall: TextStyle(color: Colors.white),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('내 다이어리', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Search
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '제목 검색',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Range Picker Row
                InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedDateRange != null) ...[
                          Text(
                            "${_selectedDateRange!.start.year}/${_selectedDateRange!.start.month.toString().padLeft(2, '0')}/${_selectedDateRange!.start.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "~",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${_selectedDateRange!.end.year}/${_selectedDateRange!.end.month.toString().padLeft(2, '0')}/${_selectedDateRange!.end.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                        ] else ...[
                          const Text(
                            "날짜 선택",
                            style: TextStyle(color: Colors.white),
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
                            backgroundColor: const Color(0xFF1E1E1E),
                            selectedColor: const Color(0xFFE50914),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFFE50914)
                                    : Colors.grey[800]!,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // List Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _filteredPosts.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = _filteredPosts[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: post.movie.posterUrl != null
                                ? Image.network(
                                    post.movie.posterUrl!,
                                    width: 50,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 75,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 75,
                                    color: Colors.grey,
                                  ),
                          ),
                          title: Text(
                            post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            post.movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                ' ${post.rating}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DiaryWriteScreen(entryToEdit: post),
                              ),
                            );
                            if (result == true) {
                              _loadPosts(); // Reload to reflect changes
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
