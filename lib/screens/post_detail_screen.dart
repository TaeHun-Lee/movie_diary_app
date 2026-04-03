import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  dynamic _post;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _hasChanged = false;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }

  String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  List<String> _extractPhotoUrls(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          final photo = _asMap(item);
          final path = _asText(photo['photo_url']);
          return ApiService.buildImageUrl(path) ?? path;
        })
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _fetchPostDetails() async {
    setState(() => _isLoading = true);

    try {
      final postResponse = await ApiService.dio.get('/posts/${widget.postId}');
      final comments = await ApiService.getComments(widget.postId);
      final isLiked = await ApiService.getLikeStatus(widget.postId);

      setState(() {
        _post = postResponse.data['data'];
        _comments = comments.where((comment) => comment != null).toList();
        _isLiked = isLiked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load post details.')),
      );
    }
  }

  Future<void> _toggleLike() async {
    final post = _asMap(_post);
    final originalIsLiked = _isLiked;
    final originalLikesCount = (post['likes_count'] as num?)?.toInt() ?? 0;

    setState(() {
      _isLiked = !_isLiked;
      post['likes_count'] = _isLiked
          ? originalLikesCount + 1
          : originalLikesCount - 1;
      _post = post;
      _hasChanged = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.toggleLike(widget.postId);

      final actualIsLiked = await ApiService.getLikeStatus(widget.postId);
      final postResponse = await ApiService.dio.get('/posts/${widget.postId}');

      if (!mounted) return;
      setState(() {
        _isLiked = actualIsLiked;
        _post = postResponse.data['data'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = originalIsLiked;
        post['likes_count'] = originalLikesCount;
        _post = post;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like status.')),
      );
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final newComment = await ApiService.createComment(widget.postId, content);
      _commentController.clear();

      setState(() {
        _comments = [
          newComment,
          ..._comments.where((comment) => comment != null),
        ];
        _isSubmitting = false;
        _hasChanged = true;
      });

      if (mounted) {
        Provider.of<PostProvider>(
          context,
          listen: false,
        ).updateCommentCount(widget.postId, _comments.length);
      }

      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final post = _asMap(_post);
    final user = _asMap(post['user']);
    final movie = Movie.fromJson(_asMap(post['movie']));
    final createdAt = _tryParseDate(post['created_at']);
    final watchedAt = _tryParseDate(post['watched_at']);
    final rating = _tryParseDouble(post['rating']);
    final place = _asText(post['place']);
    final photoUrls = _extractPhotoUrls(post['photos']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          title: Text(_asText(post['title'], fallback: 'Untitled')),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(user, createdAt),
                    const SizedBox(height: 20),
                    _buildMovieCard(movie),
                    const SizedBox(height: 24),
                    _buildDiaryOverview(
                      watchedAt: watchedAt,
                      place: place,
                      rating: rating,
                      isSpoiler: post['is_spoiler'] == true,
                    ),
                    if (photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildPhotoSection(photoUrls),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      '다이어리 내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kOnSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _asText(post['content']),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInteractionBar(post),
                    const Divider(height: 48),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryOverview({
    required DateTime? watchedAt,
    required String place,
    required double? rating,
    required bool isSpoiler,
  }) {
    final metaItems = <Widget>[
      _buildMetaItem(
        icon: Icons.calendar_today_rounded,
        label: '관람일',
        value: watchedAt != null
            ? DateFormat('yyyy.MM.dd').format(watchedAt)
            : '기록 없음',
      ),
      _buildMetaItem(
        icon: Icons.location_on_outlined,
        label: '관람 장소',
        value: place.isNotEmpty ? place : '기록 없음',
      ),
      _buildMetaItem(
        icon: Icons.star_rounded,
        label: '별점',
        value: rating != null ? rating.toStringAsFixed(1) : '기록 없음',
      ),
    ];

    if (isSpoiler) {
      metaItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kError.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: kError),
              SizedBox(width: 8),
              Text(
                '스포일러 포함',
                style: TextStyle(color: kError, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: metaItems);
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    double minWidth = 0,
  }) {
    final resolvedMinWidth = icon == Icons.star_rounded ? 80.0 : minWidth;

    return Container(
      constraints: BoxConstraints(minWidth: resolvedMinWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: kOnSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(List<String> photoUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사진',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kOnSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final imageUrl = photoUrls[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 160,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 160,
                    height: 120,
                    color: kSurfaceHigh,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(Map<String, dynamic> user, DateTime? createdAt) {
    final profileImage = _asText(user['profile_image']);
    final imageUrl = ApiService.buildImageUrl(profileImage);
    final hasProfileImage = imageUrl != null && profileImage.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: kSurfaceHigh,
          backgroundImage: hasProfileImage
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          child: !hasProfileImage
              ? const Icon(Icons.person, color: kOnSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _asText(user['nickname'], fallback: 'Unknown user'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              createdAt != null
                  ? DateFormat('yyyy.MM.dd HH:mm').format(createdAt)
                  : 'Unknown date',
              style: TextStyle(
                color: kOnSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMovieCard(Movie movie) {
    if (movie.title.isEmpty &&
        movie.director.isEmpty &&
        movie.releaseDate.isEmpty &&
        (movie.posterUrl ?? '').isEmpty) {
      return const SizedBox.shrink();
    }

    final title = movie.title.isNotEmpty ? movie.title : 'Unknown title';
    final director = movie.director.isNotEmpty
        ? movie.director
        : 'Unknown director';
    final displayDate = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : 'Unknown year';
    final posterUrl = movie.posterUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (posterUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 75,
                  color: kSurfaceHigh,
                  child: const Icon(
                    Icons.movie_filter,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 75,
              decoration: BoxDecoration(
                color: kSurfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_filter, color: kOnSurfaceVariant),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$director | $displayDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar(Map<String, dynamic> post) {
    final likesCount = (post['likes_count'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isLiked ? kError : kOnSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '좋아요 $likesCount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isLiked ? kError : kOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: kOnSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              '댓글 ${_comments.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    final visibleComments = _comments
        .where((comment) => comment != null)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '댓글',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (visibleComments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '첫 번째 댓글을 작성해보세요.',
                style: TextStyle(color: kOnSurfaceVariant),
              ),
            ),
          )
        else
          ...visibleComments.map(_buildCommentItem),
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    final commentMap = _asMap(comment);
    final user = _asMap(commentMap['user']);
    final createdAt = _tryParseDate(commentMap['created_at']);
    final profileImage = _asText(user['profile_image']);
    final imageUrl = ApiService.buildImageUrl(profileImage);
    final hasProfileImage = imageUrl != null && profileImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kSurfaceHigh,
            backgroundImage: hasProfileImage
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: !hasProfileImage
                ? const Icon(Icons.person, size: 18, color: kOnSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _asText(user['nickname'], fallback: 'Unknown user'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      createdAt != null
                          ? DateFormat('MM.dd HH:mm').format(createdAt)
                          : 'Unknown time',
                      style: TextStyle(
                        color: kOnSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _asText(commentMap['content']),
                  style: const TextStyle(fontSize: 14, color: kOnSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kSurfaceHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _commentController,
                readOnly: _isSubmitting,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimary,
                  ),
                )
              : IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded, color: kPrimary),
                ),
        ],
      ),
    );
  }
}
