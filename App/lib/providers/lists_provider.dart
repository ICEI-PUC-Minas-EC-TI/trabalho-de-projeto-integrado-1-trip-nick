import 'package:flutter/foundation.dart';
import '../models/api_responses/create_post_request.dart';
import '../models/core/spot.dart';
import '../services/posts_service.dart';
import '../utils/exceptions.dart';

/// State management for list posts
/// Handles list post creation, loading states, error handling following PostsProvider patterns
class ListPostsProvider extends ChangeNotifier {
  final PostsService _postsService = PostsService();

  // =============================================================================
  // STATE VARIABLES
  // =============================================================================

  // List post creation state
  bool _isCreatingListPost = false;
  String? _creationErrorMessage;
  CreateListPostResponse? _lastCreatedListPost;

  // List posts data
  List<Map<String, dynamic>> _userListPosts = [];
  bool _isLoadingListPosts = false;
  String? _listPostsErrorMessage;

  // Cache control
  DateTime? _lastListPostsUpdate;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // =============================================================================
  // GETTERS - UI reads these values
  // =============================================================================

  // List post creation getters
  bool get isCreatingListPost => _isCreatingListPost;
  String? get creationErrorMessage => _creationErrorMessage;
  CreateListPostResponse? get lastCreatedListPost => _lastCreatedListPost;
  bool get hasCreationError => _creationErrorMessage != null;

  // List posts data getters
  List<Map<String, dynamic>> get userListPosts => _userListPosts;
  bool get isLoadingListPosts => _isLoadingListPosts;
  String? get listPostsErrorMessage => _listPostsErrorMessage;
  bool get hasListPostsData => _userListPosts.isNotEmpty;
  bool get hasListPostsError => _listPostsErrorMessage != null;

  // =============================================================================
  // LIST POST CREATION (Main Feature)
  // =============================================================================

  /// Creates a list post with automatic public list creation
  ///
  /// This orchestrates the complete workflow:
  /// 1. Validates input data
  /// 2. Creates public list with auto-generated name
  /// 3. Adds spots to the list
  /// 4. Creates the list post
  ///
  /// Parameters:
  /// - [title]: Post title (required, max 45 chars)
  /// - [description]: Post description (optional, max 500 chars)
  /// - [userId]: ID of user creating the post
  /// - [selectedSpots]: List of spots to include (1-10 spots)
  ///
  /// Returns: true if successful, false if failed
  Future<bool> createListPost({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
  }) async {
    // Clear previous errors and start loading
    _creationErrorMessage = null;
    _isCreatingListPost = true;
    notifyListeners();

    try {
      print('ListPostsProvider: Starting list post creation...');
      print('ListPostsProvider: Title: $title');
      print('ListPostsProvider: User ID: $userId');
      print('ListPostsProvider: Selected spots: ${selectedSpots.length}');

      // Call service layer to create list post
      final response = await _postsService.createListPost(
        title: title,
        description: description,
        userId: userId,
        selectedSpots: selectedSpots,
      );

      print('ListPostsProvider: List post creation successful!');
      print('ListPostsProvider: Post ID: ${response.post_id}');
      print('ListPostsProvider: List ID: ${response.data?.list_id}');

      // Store successful response
      _lastCreatedListPost = response;
      _isCreatingListPost = false;
      notifyListeners();

      // Invalidate cache to force refresh of posts data
      _invalidateCache();

      return true;
    } catch (e) {
      print('ListPostsProvider: List post creation failed: $e');

      // Handle different types of errors with Portuguese messages
      String errorMessage = _getErrorMessage(e);

      _creationErrorMessage = errorMessage;
      _isCreatingListPost = false;
      _lastCreatedListPost = null;
      notifyListeners();

      return false;
    }
  }

  // =============================================================================
  // ERROR HANDLING
  // =============================================================================

  /// Converts exceptions to user-friendly Portuguese error messages
  String _getErrorMessage(dynamic error) {
    if (error is ValidationException) {
      return 'Dados inválidos: ${error.message}';
    } else if (error is NetworkException) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (error is ServerException) {
      // Extract meaningful error from server response
      String serverError = error.message;
      if (serverError.contains('Title is required')) {
        return 'Título é obrigatório';
      } else if (serverError.contains('spots')) {
        return 'Selecione entre 1 e 10 locais para compartilhar';
      } else if (serverError.contains('user')) {
        return 'Erro de autenticação. Faça login novamente.';
      } else if (serverError.contains('list')) {
        return 'Erro ao criar lista. Tente novamente.';
      }
      return 'Erro do servidor. Tente novamente em alguns minutos.';
    } else if (error is NotFoundException) {
      return 'Dados não encontrados. Atualize a página e tente novamente.';
    } else {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  // =============================================================================
  // VALIDATION HELPERS
  // =============================================================================

  /// Validates list post input in real-time for UI feedback
  Map<String, dynamic> validateListPostInput({
    required String title,
    String? description,
    required List<Spot> selectedSpots,
  }) {
    try {
      return _postsService.getListPostValidationSummary(
        title: title,
        description: description,
        userId: 1, // Mock user ID for validation
        selectedSpots: selectedSpots,
      );
    } catch (e) {
      return {'is_valid': false, 'error': 'Erro de validação'};
    }
  }

  /// Checks if list post form can be submitted
  bool canSubmitListPost({
    required String title,
    required List<Spot> selectedSpots,
  }) {
    if (_isCreatingListPost) return false;
    if (title.trim().isEmpty) return false;
    if (title.length > 45) return false;
    if (selectedSpots.isEmpty) return false;
    if (selectedSpots.length > 10) return false;
    return true;
  }

  // =============================================================================
  // CACHE MANAGEMENT
  // =============================================================================

  /// Invalidates cache to force refresh of data
  void _invalidateCache() {
    _lastListPostsUpdate = null;
    print('ListPostsProvider: Cache invalidated');
  }

  /// Checks if cache is still valid
  bool get _isCacheValid {
    if (_lastListPostsUpdate == null) return false;
    final timeSinceUpdate = DateTime.now().difference(_lastListPostsUpdate!);
    return timeSinceUpdate < cacheTimeout;
  }

  // =============================================================================
  // STATE MANAGEMENT HELPERS
  // =============================================================================

  /// Clears creation error message
  void clearCreationError() {
    if (_creationErrorMessage != null) {
      _creationErrorMessage = null;
      notifyListeners();
    }
  }

  /// Clears last created list post
  void clearLastCreatedListPost() {
    if (_lastCreatedListPost != null) {
      _lastCreatedListPost = null;
      notifyListeners();
    }
  }

  /// Resets all creation state
  void resetCreationState() {
    _creationErrorMessage = null;
    _lastCreatedListPost = null;
    _isCreatingListPost = false;
    notifyListeners();
  }

  // =============================================================================
  // DEBUGGING AND LOGGING HELPERS
  // =============================================================================

  /// Gets current state summary for debugging
  Map<String, dynamic> getStateDebugInfo() {
    return {
      'isCreatingListPost': _isCreatingListPost,
      'hasCreationError': hasCreationError,
      'creationErrorMessage': _creationErrorMessage,
      'lastCreatedPostId': _lastCreatedListPost?.post_id,
      'lastCreatedListId': _lastCreatedListPost?.data?.list_id,
      'userListPostsCount': _userListPosts.length,
      'isLoadingListPosts': _isLoadingListPosts,
      'cacheValid': _isCacheValid,
      'lastUpdate': _lastListPostsUpdate?.toIso8601String(),
    };
  }

  /// Logs current state for debugging
  void logCurrentState() {
    print('ListPostsProvider State: ${getStateDebugInfo()}');
  }
}
