import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/providers/post_provider.dart';
import 'package:movie_diary_app/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

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

  Future<void> _fetchPostDetails() async {
    setState(() => _isLoading = true);
    try {
      final post = await ApiService.dio.get('/posts/${widget.postId}');
      final comments = await ApiService.getComments(widget.postId);
      final isLiked = await ApiService.getLikeStatus(widget.postId);

      setState(() {
        _post = post.data['data'];
        _comments = comments;
        _isLiked = isLiked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 정보를 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    // 1. 낙관적 UI 적용: 즉시 상태 변경
    final originalIsLiked = _isLiked;
    final originalLikesCount = _post['likes_count'];
    
    setState(() {
      _isLiked = !_isLiked;
      _post['likes_count'] = _isLiked ? originalLikesCount + 1 : originalLikesCount - 1;
      _hasChanged = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.toggleLike(widget.postId);
      
      // 서버 데이터와 동기화 (선택 사항이지만 안전을 위해 수행)
      final actualIsLiked = await ApiService.getLikeStatus(widget.postId);
      final postResponse = await ApiService.dio.get('/posts/${widget.postId}');
      
      if (mounted) {
        setState(() {
          _isLiked = actualIsLiked;
          _post['likes_count'] = postResponse.data['data']['likes_count'];
        });
      }
    } catch (e) {
      // 2. 에러 발생 시 원래 상태로 롤백
      if (mounted) {
        setState(() {
          _isLiked = originalIsLiked;
          _post['likes_count'] = originalLikesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    
    try {
      final response = await ApiService.createComment(widget.postId, content);
      final newComment = response.data['data'];
      
      _commentController.clear();
      
      setState(() {
        // 전체 목록을 다시 가져오는 대신 새 댓글을 리스트 맨 앞에 추가
        _comments.insert(0, newComment);
        _isSubmitting = false;
        _hasChanged = true;
      });

      // PostProvider 업데이트
      if (mounted) {
        Provider.of<PostProvider>(context, listen: false)
            .updateCommentCount(widget.postId, _comments.length);
      }
      
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
        );
      }
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

    final user = _post['user'];
    final movie = _post['movie'];
    final createdAt = DateTime.parse(_post['created_at']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          title: const Text('다이어리 상세'),
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
                      _post['title'],
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _post['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInteractionBar(),
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

  Widget _buildUserHeader(dynamic user, DateTime createdAt) {
    final profileImage = user['profile_image'];
    final hasProfileImage = profileImage != null && profileImage.toString().isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: kSurfaceHigh,
          backgroundImage: hasProfileImage
              ? CachedNetworkImageProvider(ApiService.buildImageUrl(profileImage)!)
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
              user['nickname'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(createdAt),
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

  Widget _buildMovieCard(dynamic movie) {
    if (movie == null) return const SizedBox.shrink();
    
    final title = movie['title'] ?? '제목 없음';
    final director = movie['director'] ?? '감독 정보 없음';
    final releaseDate = movie['release_date'] ?? movie['releaseDate'] ?? '';
    final displayDate = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '연도 미상';
    final posterUrl = movie['poster'] ?? movie['posterUrl'];

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
                imageUrl: ApiService.buildImageUrl(posterUrl)!,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 75,
                  color: kSurfaceHigh,
                  child: const Icon(Icons.movie_filter, color: kOnSurfaceVariant),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$director | $displayDate',
                  style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? kError : kOnSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '좋아요 ${_post['likes_count']}',
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
            const Icon(Icons.chat_bubble_outline_rounded, color: kOnSurfaceVariant, size: 22),
            const SizedBox(width: 6),
            Text(
              '댓글 ${_comments.length}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: kOnSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '댓글',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '첫 번째 댓글을 남겨보세요!',
                style: TextStyle(color: kOnSurfaceVariant),
              ),
            ),
          )
        else
          ..._comments.map((comment) => _buildCommentItem(comment)),
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    final user = comment['user'];
    final createdAt = DateTime.parse(comment['created_at']);
    final profileImage = user['profile_image'];
    final hasProfileImage = profileImage != null && profileImage.toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kSurfaceHigh,
            backgroundImage: hasProfileImage
                ? CachedNetworkImageProvider(ApiService.buildImageUrl(profileImage)!)
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
                      user['nickname'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM.dd HH:mm').format(createdAt),
                      style: TextStyle(color: kOnSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['content'],
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
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
