import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/repositories/post_repository.dart';

// --- Riverpod State Definition ---

class PostState {
  final List<DiaryEntry> allPosts;
  final List<DiaryEntry> myPosts;
  final List<DiaryEntry> popularPosts;
  final bool isLoadingAll;
  final bool isLoadingMy;
  final bool isLoadingPopular;
  final bool hasMore;
  final int currentPage;
  final String? error;

  PostState({
    this.allPosts = const [],
    this.myPosts = const [],
    this.popularPosts = const [],
    this.isLoadingAll = false,
    this.isLoadingMy = false,
    this.isLoadingPopular = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  PostState copyWith({
    List<DiaryEntry>? allPosts,
    List<DiaryEntry>? myPosts,
    List<DiaryEntry>? popularPosts,
    bool? isLoadingAll,
    bool? isLoadingMy,
    bool? isLoadingPopular,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PostState(
      allPosts: allPosts ?? this.allPosts,
      myPosts: myPosts ?? this.myPosts,
      popularPosts: popularPosts ?? this.popularPosts,
      isLoadingAll: isLoadingAll ?? this.isLoadingAll,
      isLoadingMy: isLoadingMy ?? this.isLoadingMy,
      isLoadingPopular: isLoadingPopular ?? this.isLoadingPopular,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class PostNotifier extends Notifier<PostState> {
  final PostRepository _postRepository = PostRepository();

  @override
  PostState build() {
    return PostState();
  }

  // 커뮤니티 피드 게시물 가져오기
  Future<void> fetchAllPosts({
    String? keyword,
    String? genre,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        hasMore: true,
        allPosts: [],
        isLoadingAll: true,
        error: null,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoadingAll: true, error: null);
    }

    try {
      final result = await _postRepository.getPosts(
        page: state.currentPage,
        keyword: keyword,
        genre: (genre == null || genre == '전체') ? null : genre,
      );

      final List<dynamic> data = result['posts'] ?? result['items'] ?? [];
      final int lastPage = result['lastPage'] ?? 1;

      final newPosts = data.map((json) => DiaryEntry.fromJson(json)).toList();

      final updatedPosts = refresh
          ? newPosts
          : [...state.allPosts, ...newPosts];

      state = state.copyWith(
        allPosts: updatedPosts,
        hasMore: state.currentPage < lastPage,
        currentPage: state.currentPage + 1,
        isLoadingAll: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAll: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // 내 게시물 가져오기 (메모리 캐시 적용)
  Future<void> fetchMyPosts() async {
    state = state.copyWith(isLoadingMy: true, error: null);

    try {
      final posts = await _postRepository.getMyPosts();
      state = state.copyWith(myPosts: posts, isLoadingMy: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingMy: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // 인기 게시물 가져오기
  Future<void> fetchPopularPosts() async {
    state = state.copyWith(isLoadingPopular: true);

    try {
      final result = await _postRepository.getPosts(limit: 10);
      final List<dynamic> data = result['posts'] ?? result['items'] ?? [];
      final posts = data.map((json) => DiaryEntry.fromJson(json)).toList();
      state = state.copyWith(popularPosts: posts, isLoadingPopular: false);
    } catch (e) {
      state = state.copyWith(isLoadingPopular: false);
    }
  }

  // 좋아요 토글 (즉시 반영 로직)
  Future<void> toggleLike(int postId) async {
    final oldState = state;

    // 로컬에서 먼저 업데이트 (Optimistic Update)
    state = state.copyWith(
      allPosts: _updatePostLikeLocally(state.allPosts, postId),
      myPosts: _updatePostLikeLocally(state.myPosts, postId),
      popularPosts: _updatePostLikeLocally(state.popularPosts, postId),
    );

    try {
      final result = await _postRepository.toggleLike(postId);
      final bool isLiked = result['is_liked'] ?? result['isLiked'] ?? false;
      final int likesCount = result['likes_count'] ?? result['likesCount'] ?? 0;

      // 서버 응답으로 정확한 상태 동기화
      state = state.copyWith(
        allPosts: _syncPostLikeWithServer(state.allPosts, postId, isLiked, likesCount),
        myPosts: _syncPostLikeWithServer(state.myPosts, postId, isLiked, likesCount),
        popularPosts: _syncPostLikeWithServer(state.popularPosts, postId, isLiked, likesCount),
      );
    } catch (e) {
      // 실패 시 롤백
      state = oldState;
      debugPrint('Error toggling like: $e');
    }
  }

  List<DiaryEntry> _updatePostLikeLocally(List<DiaryEntry> posts, int postId) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return posts;

    final updatedPosts = List<DiaryEntry>.from(posts);
    final oldPost = updatedPosts[index];
    
    // 현재 상태의 반대로 가설적 업데이트
    updatedPosts[index] = oldPost.copyWith(
      isLiked: !oldPost.isLiked,
      likeCount: oldPost.isLiked ? oldPost.likeCount - 1 : oldPost.likeCount + 1,
    );

    return updatedPosts;
  }

  List<DiaryEntry> _syncPostLikeWithServer(List<DiaryEntry> posts, int postId, bool isLiked, int likesCount) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return posts;

    final updatedPosts = List<DiaryEntry>.from(posts);
    updatedPosts[index] = updatedPosts[index].copyWith(
      isLiked: isLiked,
      likeCount: likesCount,
    );
    return updatedPosts;
  }

  // 게시물 삭제 (즉시 반영)
  Future<void> deletePost(int postId) async {
    final oldState = state;

    state = state.copyWith(
      allPosts: state.allPosts.where((p) => p.id != postId).toList(),
      myPosts: state.myPosts.where((p) => p.id != postId).toList(),
      popularPosts: state.popularPosts.where((p) => p.id != postId).toList(),
    );

    try {
      await _postRepository.deletePost(postId);
    } catch (e) {
      state = oldState; // 실패 시 롤백
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  void clear() {
    state = PostState();
  }
}

final postStateProvider = NotifierProvider<PostNotifier, PostState>(() {
  return PostNotifier();
});

// --- Legacy Provider Definition ---

class PostProvider with ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  List<DiaryEntry> _allPosts = [];
  List<DiaryEntry> _myPosts = [];
  List<DiaryEntry> _popularPosts = [];

  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  bool _isLoadingPopular = false;

  String? _errorAll;
  String? _errorMy;

  int _currentPage = 1;
  bool _hasMore = true;

  List<DiaryEntry> get allPosts => _allPosts;
  List<DiaryEntry> get myPosts => _myPosts;
  List<DiaryEntry> get popularPosts => _popularPosts;

  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get hasMore => _hasMore;

  String? get errorAll => _errorAll;
  String? get errorMy => _errorMy;
  bool get hasErrorAll => _errorAll != null;

  // 커뮤니티 피드 게시물 가져오기 (초기 로드 또는 새로고침)
  Future<void> fetchAllPosts({
    String? keyword,
    String? genre,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _allPosts = [];
    }

    if (!_hasMore && !refresh) return;

    _isLoadingAll = true;
    _errorAll = null;
    notifyListeners();

    try {
      final result = await _postRepository.getPosts(
        page: _currentPage,
        keyword: keyword,
        genre: genre == '전체' ? null : genre,
      );

      final List<dynamic> data = result['posts'] ?? result['items'] ?? [];
      final int lastPage = result['lastPage'] ?? 1;

      final newPosts = data.map((json) => DiaryEntry.fromJson(json)).toList();

      if (refresh) {
        _allPosts = newPosts;
      } else {
        _allPosts.addAll(newPosts);
      }

      _hasMore = _currentPage < lastPage;
      _currentPage++;
    } catch (e) {
      debugPrint('Error fetching all posts: $e');
      _errorAll = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  // 내 게시물 가져오기
  Future<void> fetchMyPosts() async {
    _isLoadingMy = true;
    _errorMy = null;
    notifyListeners();

    try {
      _myPosts = await _postRepository.getMyPosts();
    } catch (e) {
      debugPrint('Error fetching my posts: $e');
      _errorMy = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
  }

  // 인기 게시물 가져오기
  Future<void> fetchPopularPosts() async {
    _isLoadingPopular = true;
    notifyListeners();

    try {
      final result = await _postRepository.getPosts(limit: 10);
      final List<dynamic> data = result['posts'] ?? result['items'] ?? [];
      _popularPosts = data.map((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching popular posts: $e');
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  // 좋아요 토글 및 로컬 상태 업데이트
  Future<void> toggleLike(int postId) async {
    try {
      final result = await _postRepository.toggleLike(postId);
      final bool isLiked = result['is_liked'] ?? result['isLiked'] ?? false;
      final int newCount = result['likes_count'] ?? result['likesCount'] ?? 0;

      // 모든 리스트에서 해당 포스트의 좋아요 상태 업데이트
      _updatePostLikeStatus(_allPosts, postId, isLiked, newCount);
      _updatePostLikeStatus(_myPosts, postId, isLiked, newCount);
      _updatePostLikeStatus(_popularPosts, postId, isLiked, newCount);

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  void _updatePostLikeStatus(
    List<DiaryEntry> posts,
    int postId,
    bool isLiked,
    int newCount,
  ) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      posts[index] = posts[index].copyWith(
        isLiked: isLiked,
        likeCount: newCount,
      );
    }
  }

  // 게시물 삭제 후 로컬 상태 업데이트
  Future<void> deletePost(int postId) async {
    try {
      await _postRepository.deletePost(postId);
      _allPosts.removeWhere((p) => p.id == postId);
      _myPosts.removeWhere((p) => p.id == postId);
      _popularPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  // 캐시 초기화 (로그아웃 시 등)
  void clear() {
    _allPosts = [];
    _myPosts = [];
    _popularPosts = [];
    notifyListeners();
  }
}
