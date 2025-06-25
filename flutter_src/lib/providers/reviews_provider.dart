import 'package:flutter/foundation.dart';
import '../models/api_responses/create_post_request.dart';
import '../services/posts_service.dart';
import '../utils/exceptions.dart';

/// State management for review posts
/// Handles review creation, loading states, error handling following PostsProvider patterns
class ReviewsProvider extends ChangeNotifier {
  final PostsService _postsService = PostsService();

  // =============================================================================
  // STATE VARIABLES
  // =============================================================================

  // Review creation state
  bool _isCreatingReview = false;
  String? _creationErrorMessage;
  CreateReviewPostResponse? _lastCreatedReview;

  // Reviews data
  List<Map<String, dynamic>> _userReviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsErrorMessage;

  // Cache control
  DateTime? _lastReviewsUpdate;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // =============================================================================
  // GETTERS - UI reads these values
  // =============================================================================

  // Review creation getters
  bool get isCreatingReview => _isCreatingReview;
  String? get creationErrorMessage => _creationErrorMessage;
  CreateReviewPostResponse? get lastCreatedReview => _lastCreatedReview;
  bool get hasCreationError => _creationErrorMessage != null;

  // Reviews data getters
  List<Map<String, dynamic>> get userReviews => _userReviews;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsErrorMessage => _reviewsErrorMessage;
  bool get hasReviewsData => _userReviews.isNotEmpty;
  bool get hasReviewsError => _reviewsErrorMessage != null;

  // =============================================================================
  // REVIEW CREATION (Main Feature)
  // =============================================================================

  /// Creates a review post for a specific spot
  ///
  /// Parameters:
  /// - [spotId]: ID of the spot being reviewed (required)
  /// - [rating]: Rating from 1-5 stars (required)
  /// - [description]: Review description (optional)
  /// - [userId]: ID of user creating the review (required)
  ///
  /// Returns: true if successful, false if failed
  Future<bool> createReviewPost({
    required int spotId,
    required int rating,
    String? description,
    required int userId,
  }) async {
    if (_isCreatingReview) {
      debugPrint('ReviewsProvider: Review creation already in progress');
      return false;
    }

    try {
      // Clear previous errors
      _creationErrorMessage = null;
      _isCreatingReview = true;
      notifyListeners();

      debugPrint(
        'ReviewsProvider: Creating review for spot $spotId with rating $rating',
      );

      // Call the service to create review post
      final response = await _postsService.createReviewPost(
        spotId: spotId,
        rating: rating,
        description: description,
        userId: userId,
      );

      // Success - store the result
      _lastCreatedReview = response;
      _isCreatingReview = false;

      debugPrint(
        'ReviewsProvider: Review created successfully - ID: ${response.post_id}',
      );

      // Invalidate cache so fresh data is loaded next time
      _lastReviewsUpdate = null;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ReviewsProvider: Error creating review: $e');

      _isCreatingReview = false;

      // Convert exceptions to user-friendly messages (Portuguese)
      if (e is NetworkException) {
        _creationErrorMessage =
            'Erro de conexão. Verifique sua internet e tente novamente.';
      } else if (e is ServerException) {
        _creationErrorMessage =
            'Erro no servidor. Tente novamente em alguns minutos.';
      } else if (e is ValidationException) {
        _creationErrorMessage = e.message;
      } else if (e is NotFoundException) {
        _creationErrorMessage = 'Local não encontrado. Tente novamente.';
      } else {
        _creationErrorMessage = 'Erro inesperado. Tente novamente.';
      }

      notifyListeners();
      return false;
    }
  }

  // =============================================================================
  // ERROR HANDLING
  // =============================================================================

  /// Clear any creation error message
  void clearCreationError() {
    if (_creationErrorMessage != null) {
      _creationErrorMessage = null;
      notifyListeners();
    }
  }

  /// Clear any reviews error message
  void clearReviewsError() {
    if (_reviewsErrorMessage != null) {
      _reviewsErrorMessage = null;
      notifyListeners();
    }
  }

  // =============================================================================
  // VALIDATION HELPERS
  // =============================================================================

  /// Validate rating value
  String? validateRating(int? rating) {
    if (rating == null || rating < 1 || rating > 5) {
      return 'Selecione uma avaliação de 1 a 5 estrelas';
    }
    return null;
  }

  /// Validate description length
  String? validateDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Comentário não pode ter mais de 500 caracteres';
    }
    return null;
  }

  /// Check if review data is valid for submission
  bool isValidReviewData({
    required int? spotId,
    required int? rating,
    String? description,
    required int? userId,
  }) {
    return spotId != null &&
        spotId > 0 &&
        rating != null &&
        rating >= 1 &&
        rating <= 5 &&
        userId != null &&
        userId > 0 &&
        (description == null || description.length <= 500);
  }

  /// Get character count text for description
  String getDescriptionCharacterCount(String? description) {
    final length = description?.length ?? 0;
    return '$length / 500 caracteres';
  }

  /// Check if description is approaching limit
  bool isDescriptionNearLimit(String? description) {
    final length = description?.length ?? 0;
    return length > 400; // Show warning when over 400 chars
  }

  // =============================================================================
  // SUCCESS STATE MANAGEMENT
  // =============================================================================

  /// Mark that the success state has been acknowledged (for navigation)
  void acknowledgeReviewCreation() {
    _lastCreatedReview = null;
    notifyListeners();
  }

  /// Check if we should show success message
  bool get shouldShowSuccessMessage => _lastCreatedReview != null;

  /// Get success message text
  String get successMessage => 'Avaliação enviada com sucesso!';

  // =============================================================================
  // CACHE MANAGEMENT
  // =============================================================================

  /// Check if we have fresh reviews data
  bool _hasFreshReviewsData() {
    if (_lastReviewsUpdate == null) return false;
    return DateTime.now().difference(_lastReviewsUpdate!) < cacheTimeout;
  }

  /// Force refresh of reviews data
  void invalidateReviewsCache() {
    _lastReviewsUpdate = null;
    notifyListeners();
  }

  // =============================================================================
  // DEVELOPMENT AND DEBUGGING HELPERS
  // =============================================================================

  /// Get current state summary for debugging
  Map<String, dynamic> getStateDebugInfo() {
    return {
      'isCreatingReview': _isCreatingReview,
      'hasCreationError': hasCreationError,
      'creationErrorMessage': _creationErrorMessage,
      'isLoadingReviews': _isLoadingReviews,
      'hasReviewsError': hasReviewsError,
      'reviewsErrorMessage': _reviewsErrorMessage,
      'userReviewsCount': _userReviews.length,
      'hasFreshCache': _hasFreshReviewsData(),
      'lastUpdate': _lastReviewsUpdate?.toIso8601String(),
      'lastCreatedReviewId': _lastCreatedReview?.post_id,
    };
  }

  /// Reset all state (for testing or logout)
  void resetState() {
    _isCreatingReview = false;
    _creationErrorMessage = null;
    _lastCreatedReview = null;
    _userReviews.clear();
    _isLoadingReviews = false;
    _reviewsErrorMessage = null;
    _lastReviewsUpdate = null;
    notifyListeners();
  }
}
