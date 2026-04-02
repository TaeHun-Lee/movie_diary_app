import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_diary_app/constants.dart';
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
        _comments = [newComment, ..._comments.where((comment) => comment != null)];
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
    final movie = _asMap(post['movie']);
    final createdAt = _tryParseDate(post['created_at']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          title: const Text('Post Detail'),
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
                    Text(
                      _asText(post['title'], fallback: 'Untitled'),
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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

  Widget _buildUserHeader(Map<String, dynamic> user, DateTime? createdAt) {
    final profileImage = _asText(user['profile_image']);
    final imageUrl = ApiService.buildImageUrl(profileImage);
    final hasProfileImage = imageUrl != null && profileImage.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: kSurfaceHigh,
          backgroundImage:
              hasProfileImage ? CachedNetworkImageProvider(imageUrl) : null,
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

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    if (movie.isEmpty) return const SizedBox.shrink();

    final title = _asText(movie['title'], fallback: 'Unknown title');
    final director = _asText(movie['director'], fallback: 'Unknown director');
    final releaseDate = _asText(movie['release_date'] ?? movie['releaseDate']);
    final displayDate =
        releaseDate.length >= 4 ? releaseDate.substring(0, 4) : 'Unknown year';
    final posterPath = _asText(movie['poster'] ?? movie['posterUrl']);
    final posterUrl = ApiService.buildImageUrl(posterPath);

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
              child: const Icon(
                Icons.movie_filter,
                color: kOnSurfaceVariant,
              ),
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
                'Likes $likesCount',
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
              'Comments ${_comments.length}',
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
    final visibleComments =
        _comments.where((comment) => comment != null).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (visibleComments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Be the first to add a comment.',
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
            backgroundImage:
                hasProfileImage ? CachedNetworkImageProvider(imageUrl) : null,
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
                  hintText: 'Write a comment...',
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
