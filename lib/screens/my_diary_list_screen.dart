import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/screens/diary_write_screen.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MyDiaryListScreen extends StatefulWidget {
  const MyDiaryListScreen({super.key});

  @override
  State<MyDiaryListScreen> createState() => MyDiaryListScreenState();
}

class MyDiaryListScreenState extends State<MyDiaryListScreen> {
  String _searchQuery = '';
  final List<String> _selectedGenres = [];
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PostProvider>().fetchMyPosts();
    });
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    await context.read<PostProvider>().fetchMyPosts();
  }

  List<String> _availableGenres(List<DiaryEntry> posts) {
    final genres = <String>{};
    for (final post in posts) {
      genres.addAll(post.movie.genres.where((genre) => genre.isNotEmpty));
    }
    final result = genres.toList();
    result.sort();
    return result;
  }

  List<DiaryEntry> _filteredPosts(List<DiaryEntry> posts) {
    return posts.where((post) {
      final matchesQuery =
          post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.movie.title.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesGenre = _selectedGenres.isEmpty ||
          _selectedGenres.any((genre) => post.movie.genres.contains(genre));

      bool matchesDate = true;
      if (_selectedDateRange != null) {
        final cleanDate = post.watchedDate
            .replaceAll('.', '-')
            .replaceAll('/', '-')
            .trim()
            .split(' ')
            .first;
        final watchedDate = DateTime.tryParse(cleanDate);
        if (watchedDate == null) {
          matchesDate = false;
        } else {
          final target = DateTime(
            watchedDate.year,
            watchedDate.month,
            watchedDate.day,
          );
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
          );
          matchesDate =
              target.compareTo(start) >= 0 && target.compareTo(end) <= 0;
        }
      }

      return matchesQuery && matchesGenre && matchesDate;
    }).toList();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
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
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final posts = postProvider.myPosts;
        final filteredPosts = _filteredPosts(posts);
        final genres = _availableGenres(posts);

        return Scaffold(
          backgroundColor: kSurface,
          appBar: const CustomAppBar(),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                _Header(
                  controller: _searchController,
                  selectedDateRange: _selectedDateRange,
                  genres: genres,
                  selectedGenres: _selectedGenres,
                  onPickDateRange: () => _pickDateRange(context),
                  onToggleGenre: _toggleGenre,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    color: kPrimary,
                    child: _DiaryBody(
                      postProvider: postProvider,
                      filteredPosts: filteredPosts,
                      onUpdated: refresh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final DateTimeRange? selectedDateRange;
  final List<String> genres;
  final List<String> selectedGenres;
  final VoidCallback onPickDateRange;
  final ValueChanged<String> onToggleGenre;

  const _Header({
    required this.controller,
    required this.selectedDateRange,
    required this.genres,
    required this.selectedGenres,
    required this.onPickDateRange,
    required this.onToggleGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      color: kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 영화 아카이브',
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
            ),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search titles',
                prefixIcon: Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onPickDateRange,
            borderRadius: BorderRadius.circular(kRadiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSurfaceLowest,
                borderRadius: BorderRadius.circular(kRadiusM),
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
                  if (selectedDateRange != null)
                    Text(
                      '${selectedDateRange!.start.year}.${selectedDateRange!.start.month.toString().padLeft(2, '0')}.${selectedDateRange!.start.day.toString().padLeft(2, '0')} ~ ${selectedDateRange!.end.year}.${selectedDateRange!.end.month.toString().padLeft(2, '0')}.${selectedDateRange!.end.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: kOnSurface,
                        fontFamily: kHeadlineFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (genres.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: genres.map((genre) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(genre),
                      selected: selectedGenres.contains(genre),
                      onSelected: (_) => onToggleGenre(genre),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiaryBody extends StatelessWidget {
  final PostProvider postProvider;
  final List<DiaryEntry> filteredPosts;
  final Future<void> Function() onUpdated;

  const _DiaryBody({
    required this.postProvider,
    required this.filteredPosts,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (postProvider.isLoadingMy && postProvider.myPosts.isEmpty) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: kSurfaceHigh,
            highlightColor: kSurfaceLowest,
            child: Container(
              height: 134,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadiusXL),
              ),
            ),
          );
        },
      );
    }

    if (postProvider.errorMy != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Text(
                postProvider.errorMy!,
                style: const TextStyle(
                  color: kError,
                  fontFamily: kBodyFont,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (filteredPosts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(
              child: Text(
                'No diary entries found.',
                style: TextStyle(
                  color: kOnSurfaceVariant,
                  fontFamily: kBodyFont,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return _DiaryCard(
          post: post,
          onUpdated: onUpdated,
        );
      },
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry post;
  final Future<void> Function() onUpdated;

  const _DiaryCard({
    required this.post,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
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
                  builder: (_) => DiaryWriteScreen(entryToEdit: post),
                ),
              );
              if (result == true) {
                await onUpdated();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'post_${post.id}',
                    child: SizedBox(
                      width: 80,
                      height: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusL),
                        child: post.movie.posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: ApiService.buildImageUrl(
                                      post.movie.posterUrl,
                                    ) ??
                                    '',
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: kSurfaceHigh,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: kSurfaceHigh,
                                  child: const Icon(Icons.movie_rounded),
                                ),
                              )
                            : Container(
                                color: kSurfaceHigh,
                                child: const Icon(Icons.movie_rounded),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kHeadlineFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 13,
                            color: kOnSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: kPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: kHeadlineFont,
                                fontWeight: FontWeight.w700,
                                color: kOnSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post.content ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 13,
                            height: 1.5,
                            color: kOnSurfaceVariant.withValues(alpha: 0.85),
                          ),
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
  }
}
