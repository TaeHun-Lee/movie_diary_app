import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/screens/post_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:movie_diary_app/data/diary_entry.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedGenre;
  String _keyword = '';

  final List<String> _genres = [
    '전체',
    '액션',
    '코미디',
    '드라마',
    '멜로/로맨스',
    '스릴러',
    '공포',
    'SF',
    '애니메이션',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchAllPosts(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    await context.read<PostProvider>().fetchAllPosts(
      keyword: _keyword.isEmpty ? null : _keyword,
      genre: _selectedGenre == '전체' ? null : _selectedGenre,
      refresh: refresh,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchPosts();
    }
  }

  void _onSearch() {
    setState(() {
      _keyword = _searchController.text;
    });
    _fetchPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          _buildHeader(),
          _buildGenreFilter(),
          Expanded(
            child: Consumer<PostProvider>(
              builder: (context, postProvider, child) {
                if (postProvider.hasErrorAll && postProvider.allPosts.isEmpty) {
                  return _buildErrorState(postProvider.errorAll!);
                }

                final posts = postProvider.allPosts;
                final isLoading = postProvider.isLoadingAll;

                return RefreshIndicator(
                  onRefresh: () => _fetchPosts(refresh: true),
                  color: kPrimary,
                  child: posts.isEmpty && !isLoading
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                          itemCount: posts.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == posts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: kPrimary,
                                  ),
                                ),
                              );
                            }
                            return _buildPostCard(posts[index]);
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '다이어리 내용, 제목, 영화 검색...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: (_) => _onSearch(),
        ),
      ),
    );
  }

  Widget _buildGenreFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = (_selectedGenre ?? '전체') == genre;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedGenre = genre);
                  _fetchPosts(refresh: true);
                }
              },
              selectedColor: kPrimary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? kPrimary : kOnSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(DiaryEntry post) {
    final movie = post.movie;
    final createdAt = post.createdAt;
    final rating = post.rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: post.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: kSurfaceHigh,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorNickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy.MM.dd').format(createdAt),
                              style: TextStyle(
                                color: kOnSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: kPrimary,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((movie.posterUrl ?? '').isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: ApiService.buildImageUrl(
                              movie.posterUrl,
                            )!,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFamily: kHeadlineFont,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              movie.title,
                              style: TextStyle(
                                color: kPrimary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.content ?? '',
                              style: const TextStyle(
                                color: kOnSurface,
                                fontSize: 13,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: kSurfaceHigh),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: kError.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: kOnSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 80, color: kSurfaceDim),
          const SizedBox(height: 20),
          Text(
            '검색 결과가 없습니다.\n다른 키워드로 검색해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kOnSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: kSurfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 30,
                color: kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 14,
                color: kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _fetchPosts(refresh: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                    fontFamily: kHeadlineFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
