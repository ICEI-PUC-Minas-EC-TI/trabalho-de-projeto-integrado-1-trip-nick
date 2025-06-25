import 'dart:convert';
import '../models/api_responses/create_post_request.dart';
import '../models/core/spot.dart';
import '../services/api_service.dart';
import '../services/lists_service.dart';
import '../utils/exceptions.dart';
import '../utils/constants.dart';
import '../utils/post_constants.dart';

/// Service for managing posts operations
///
/// This service handles:
/// - Creating community posts (with automatic hidden list creation)
/// - Creating review posts
/// - Creating list posts
/// - Retrieving posts
/// - Deleting posts
/// - Managing the complex workflow of community post creation
class PostsService {
  /// Singleton instance
  static final PostsService _instance = PostsService._internal();

  /// Factory constructor returns singleton
  factory PostsService() => _instance;

  /// Private constructor
  PostsService._internal();

  /// Reference to the API service
  ApiService get _apiService => ApiService();

  /// Reference to the lists service
  ListsService get _listsService => ListsService();

  // =============================================================================
  // COMMUNITY POST CREATION (Main Workflow)
  // =============================================================================

  /// Creates a community post with automatic hidden list creation
  ///
  /// This is the main method for creating community posts. It orchestrates:
  /// 1. Creates a hidden list for the spots
  /// 2. Adds all selected spots to the hidden list
  /// 3. Creates the community post that references the hidden list
  ///
  /// Parameters:
  /// - [title]: Post title (max 45 characters)
  /// - [description]: Post description (optional, max 500 characters)
  /// - [userId]: ID of the user creating the post
  /// - [selectedSpots]: List of spots to include in the post (1-10 spots)
  ///
  /// Returns:
  /// - [CreateCommunityPostResponse]: Complete response with post and list details
  ///
  /// Throws:
  /// - [ValidationException]: If request data is invalid
  /// - [ApiException]: For API-related errors during any step
  /// - [NetworkException]: For network connectivity issues
  Future<CreateCommunityPostResponse> createCommunityPost({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
  }) async {
    try {
      // Step 1: Validate input data
      _validateCommunityPostInput(title, description, userId, selectedSpots);

      // Step 2: Create hidden list for the spots
      final listResponse = await _createHiddenListForPost(title);
      final listId = listResponse.list_id!;

      try {
        // Step 3: Add all spots to the hidden list
        await _addSpotsToHiddenList(listId, selectedSpots);

        // Step 4: Create the actual community post
        final postResponse = await _createCommunityPostRecord(
          title: title,
          description: description,
          userId: userId,
          listId: listId,
        );

        // Step 5: Return comprehensive response
        return CreateCommunityPostResponse(
          success: true,
          post_id: postResponse['post_id'],
          list_id: listId,
          message: PostConstants.postCreatedSuccess,
          data: CommunityPostData(
            post_id: postResponse['post_id'],
            type: 'community',
            title: title,
            description: description,
            user_id: userId,
            created_date: DateTime.parse(postResponse['created_date']),
            list_id: listId,
            spots_count: selectedSpots.length,
          ),
        );
      } catch (e) {
        // If post creation fails after list creation, clean up the list
        await _cleanupFailedPostCreation(listId);
        rethrow;
      }
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create community post: ${e.toString()}');
    }
  }

  // =============================================================================
  // OTHER POST TYPES (Future Implementation)
  // =============================================================================

  /// Creates a review post for a specific spot
  ///
  /// Parameters:
  /// - [spotId]: ID of the spot being reviewed
  /// - [rating]: Rating from 1-5 stars
  /// - [description]: Review description (optional)
  /// - [userId]: ID of the user creating the review
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with post details
  Future<Map<String, dynamic>> createReviewPost({
    required int spotId,
    required int rating,
    String? description,
    required int userId,
  }) async {
    try {
      // Validate input
      if (spotId <= 0) {
        throw ServerException('Valid spot ID is required');
      }
      if (rating < 1 || rating > 5) {
        throw ServerException('Rating must be between 1 and 5');
      }
      if (userId <= 0) {
        throw ServerException('Valid user ID is required');
      }
      if (description != null &&
          description.length > PostConstants.maxDescriptionLength) {
        throw ServerException('Description too long');
      }

      // Create request data
      final requestData = {
        'type': 'review',
        'description': description,
        'user_id': userId,
        'spot_id': spotId,
        'rating': rating,
      };

      // Make API call
      final response = await _apiService.post(
        ApiConstants.postsEndpoint,
        body: requestData,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create review post: ${e.toString()}');
    }
  }

  /// Creates a list post (sharing an existing list)
  ///
  /// Parameters:
  /// - [title]: Post title
  /// - [listId]: ID of the existing list to share
  /// - [description]: Post description (optional)
  /// - [userId]: ID of the user creating the post
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with post details
  Future<Map<String, dynamic>> createListPost({
    required String title,
    required int listId,
    String? description,
    required int userId,
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty || title.length > PostConstants.maxTitleLength) {
        throw ServerException('Invalid title');
      }
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }
      if (userId <= 0) {
        throw ServerException('Valid user ID is required');
      }
      if (description != null &&
          description.length > PostConstants.maxDescriptionLength) {
        throw ServerException('Description too long');
      }

      // Create request data
      final requestData = {
        'type': 'list',
        'title': title.trim(),
        'description': description,
        'user_id': userId,
        'list_id': listId,
      };

      // Make API call
      final response = await _apiService.post(
        ApiConstants.postsEndpoint,
        body: requestData,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create list post: ${e.toString()}');
    }
  }

  // =============================================================================
  // POST RETRIEVAL
  // =============================================================================

  /// Gets posts with optional filtering and pagination
  ///
  /// Parameters:
  /// - [page]: Page number (default 1)
  /// - [limit]: Number of posts per page (default 20, max 100)
  /// - [userId]: Filter by user ID (optional)
  /// - [type]: Filter by post type ('community', 'review', 'list') (optional)
  /// - [includeImages]: Whether to include image URLs (default true)
  /// - [includeStats]: Whether to include statistics (default false)
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with posts and pagination info
  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int limit = 20,
    int? userId,
    String? type,
    bool includeImages = true,
    bool includeStats = false,
  }) async {
    try {
      // Validate parameters
      if (page < 1) {
        throw ServerException('Page must be 1 or greater');
      }
      if (limit < 1 || limit > 100) {
        throw ServerException('Limit must be between 1 and 100');
      }
      if (type != null && !['community', 'review', 'list'].contains(type)) {
        throw ServerException('Invalid post type');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'includeImages': includeImages.toString(),
        'includeStats': includeStats.toString(),
      };

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      // Make API call
      final response = await _apiService.get(
        ApiConstants.postsEndpoint,
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to get posts: ${e.toString()}');
    }
  }

  /// Gets a specific post by ID
  ///
  /// Parameters:
  /// - [postId]: ID of the post to retrieve
  /// - [includeImages]: Whether to include image URLs
  /// - [includeStats]: Whether to include statistics
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with post details
  Future<Map<String, dynamic>> getPostById({
    required int postId,
    bool includeImages = true,
    bool includeStats = false,
  }) async {
    try {
      if (postId <= 0) {
        throw ServerException('Valid post ID is required');
      }

      // Build query parameters
      final queryParams = {
        'includeImages': includeImages.toString(),
        'includeStats': includeStats.toString(),
      };

      // Make API call
      final response = await _apiService.get(
        '${ApiConstants.postsEndpoint}/$postId',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to get post: ${e.toString()}');
    }
  }

  // =============================================================================
  // POST DELETION
  // =============================================================================

  /// Deletes a post
  ///
  /// Parameters:
  /// - [postId]: ID of the post to delete
  /// - [softDelete]: Whether to soft delete (mark as deleted) instead of hard delete
  /// - [dryRun]: If true, returns what would be deleted without actually deleting
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with deletion details
  Future<Map<String, dynamic>> deletePost({
    required int postId,
    bool softDelete = false,
    bool dryRun = false,
  }) async {
    try {
      if (postId <= 0) {
        throw ServerException('Valid post ID is required');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (softDelete) queryParams['softDelete'] = 'true';
      if (dryRun) queryParams['dryRun'] = 'true';

      // Make API call
      final response = await _apiService.delete(
        '${ApiConstants.postsEndpoint}/$postId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException(
        'Failed to delete post: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Validates community post input data
  void _validateCommunityPostInput(
    String title,
    String? description,
    int userId,
    List<Spot> selectedSpots,
  ) {
    final List<String> errors = [];

    // Validate title
    if (!PostConstants.isValidTitleLength(title)) {
      errors.add(
        'Title is required and must be ${PostConstants.maxTitleLength} characters or less',
      );
    }

    // Validate description
    if (!PostConstants.isValidDescriptionLength(description)) {
      errors.add(
        'Description must be ${PostConstants.maxDescriptionLength} characters or less',
      );
    }

    // Validate user ID
    if (userId <= 0) {
      errors.add('Valid user ID is required');
    }

    // Validate spots
    if (!PostConstants.isValidSpotsCount(selectedSpots)) {
      errors.add(
        'Must have between ${PostConstants.minSpotsPerPost} and ${PostConstants.maxSpotsPerPost} spots',
      );
    }

    // Check for duplicate spots
    final spotIds = selectedSpots.map((spot) => spot.spot_id).toList();
    if (spotIds.toSet().length != spotIds.length) {
      errors.add('Duplicate spots are not allowed');
    }

    if (errors.isNotEmpty) {
      throw ServerException(
        'Invalid community post data: ${errors.join(', ')}',
      );
    }
  }

  /// Creates a hidden list for the community post
  Future<CreateListResponse> _createHiddenListForPost(String postTitle) async {
    try {
      return await _listsService.createHiddenListForPost(postTitle: postTitle);
    } catch (e) {
      throw ServerException(
        'Failed to create hidden list for community post: ${e.toString()}',
      );
    }
  }

  /// Adds all selected spots to the hidden list
  Future<void> _addSpotsToHiddenList(
    int listId,
    List<Spot> selectedSpots,
  ) async {
    try {
      final spotIds = selectedSpots.map((spot) => spot.spot_id).toList();
      await _listsService.addMultipleSpotsToList(
        listId: listId,
        spotIds: spotIds,
      );
    } catch (e) {
      throw ServerException(
        'Failed to add spots to hidden list: ${e.toString()}',
      );
    }
  }

  /// Creates the community post record in the database
  Future<Map<String, dynamic>> _createCommunityPostRecord({
    required String title,
    String? description,
    required int userId,
    required int listId,
  }) async {
    try {
      // Create request data for community post
      final requestData = {
        'type': 'community',
        'title': title.trim(),
        'description': description?.trim(),
        'user_id': userId,
        'list_id': listId,
      };

      // Make API call to create post
      final response = await _apiService.post(
        ApiConstants.postsEndpoint,
        body: requestData,
      );

      // Flexible response parsing to handle different formats
      int? postId;
      String? createdDateStr;

      // Debug: Print the actual response for troubleshooting
      print('Post creation API response: $response');

      // Try to extract post_id from different possible locations
      if (response.containsKey('post_id')) {
        postId = response['post_id'] as int?;
      } else if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        postId = data['post_id'] as int?;
      }

      // Try to extract created_date from different possible locations
      if (response.containsKey('created_date')) {
        createdDateStr = response['created_date'] as String?;
      } else if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        createdDateStr = data['created_date'] as String?;
      }

      // Validate we got the essential data
      if (postId == null) {
        throw ServerException(
          'Missing post_id in API response. Response: ${response.toString()}',
        );
      }

      if (createdDateStr == null) {
        throw ServerException(
          'Missing created_date in API response. Response: ${response.toString()}',
        );
      }

      // Create a normalized response for return
      return {
        'post_id': postId,
        'created_date': createdDateStr,
        'success': response['success'] ?? true,
        'message': response['message'] ?? 'Post created successfully',
      };
    } catch (e) {
      throw ServerException(
        'Failed to create community post record: ${e.toString()}',
      );
    }
  }

  /// Cleans up after a failed community post creation
  ///
  /// If the post creation fails after the hidden list has been created,
  /// this method attempts to clean up the orphaned list.
  Future<void> _cleanupFailedPostCreation(int listId) async {
    try {
      await _listsService.deleteList(
        listId: listId,
        force: true, // Force deletion since there are no posts yet
      );
    } catch (e) {
      // Log the cleanup failure but don't throw - the original error is more important
      print(
        'Warning: Failed to cleanup orphaned list $listId after post creation failure: $e',
      );
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Validates post title according to business rules
  ///
  /// Parameters:
  /// - [title]: The post title to validate
  ///
  /// Returns:
  /// - [List<String>]: List of validation errors (empty if valid)
  List<String> validatePostTitle(String title) {
    final List<String> errors = [];

    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      errors.add('Post title cannot be empty');
    }

    if (trimmed.length > PostConstants.maxTitleLength) {
      errors.add(
        'Post title must be ${PostConstants.maxTitleLength} characters or less',
      );
    }

    if (trimmed.length < 3) {
      errors.add('Post title must be at least 3 characters');
    }

    // Check for inappropriate content (basic example)
    final inappropriate = ['spam', 'test123', 'hate'];
    if (inappropriate.any((word) => trimmed.toLowerCase().contains(word))) {
      errors.add('Post title contains inappropriate content');
    }

    return errors;
  }

  /// Validates post description according to business rules
  ///
  /// Parameters:
  /// - [description]: The post description to validate (can be null)
  ///
  /// Returns:
  /// - [List<String>]: List of validation errors (empty if valid)
  List<String> validatePostDescription(String? description) {
    final List<String> errors = [];

    if (description != null) {
      if (description.length > PostConstants.maxDescriptionLength) {
        errors.add(
          'Post description must be ${PostConstants.maxDescriptionLength} characters or less',
        );
      }

      // Check for inappropriate content (basic example)
      final inappropriate = ['spam', 'hate', 'scam'];
      if (inappropriate.any(
        (word) => description.toLowerCase().contains(word),
      )) {
        errors.add('Post description contains inappropriate content');
      }
    }

    return errors;
  }

  /// Validates spot selection for community posts
  ///
  /// Parameters:
  /// - [spots]: List of selected spots
  ///
  /// Returns:
  /// - [List<String>]: List of validation errors (empty if valid)
  List<String> validateSpotSelection(List<Spot> spots) {
    final List<String> errors = [];

    if (spots.isEmpty) {
      errors.add('At least ${PostConstants.minSpotsPerPost} spot is required');
    }

    if (spots.length > PostConstants.maxSpotsPerPost) {
      errors.add('Maximum ${PostConstants.maxSpotsPerPost} spots allowed');
    }

    // Check for duplicate spots
    final spotIds = spots.map((spot) => spot.spot_id).toSet();
    if (spotIds.length != spots.length) {
      errors.add('Duplicate spots are not allowed');
    }

    // Validate individual spots
    for (final spot in spots) {
      if (spot.spot_id <= 0) {
        errors.add('Invalid spot detected');
        break;
      }
    }

    return errors;
  }

  /// Checks if a post title is valid
  ///
  /// Parameters:
  /// - [title]: The post title to check
  ///
  /// Returns:
  /// - [bool]: True if the title is valid
  bool isValidPostTitle(String title) {
    return validatePostTitle(title).isEmpty;
  }

  /// Checks if a post description is valid
  ///
  /// Parameters:
  /// - [description]: The post description to check (can be null)
  ///
  /// Returns:
  /// - [bool]: True if the description is valid
  bool isValidPostDescription(String? description) {
    return validatePostDescription(description).isEmpty;
  }

  /// Checks if spot selection is valid for community posts
  ///
  /// Parameters:
  /// - [spots]: List of selected spots
  ///
  /// Returns:
  /// - [bool]: True if the spot selection is valid
  bool isValidSpotSelection(List<Spot> spots) {
    return validateSpotSelection(spots).isEmpty;
  }

  /// Gets the maximum number of spots allowed per community post
  ///
  /// Returns:
  /// - [int]: Maximum spots per post
  int get maxSpotsPerPost => PostConstants.maxSpotsPerPost;

  /// Gets the minimum number of spots required per community post
  ///
  /// Returns:
  /// - [int]: Minimum spots per post
  int get minSpotsPerPost => PostConstants.minSpotsPerPost;

  /// Gets the maximum title length
  ///
  /// Returns:
  /// - [int]: Maximum title length
  int get maxTitleLength => PostConstants.maxTitleLength;

  /// Gets the maximum description length
  ///
  /// Returns:
  /// - [int]: Maximum description length
  int get maxDescriptionLength => PostConstants.maxDescriptionLength;

  // =============================================================================
  // DEBUGGING AND LOGGING HELPERS
  // =============================================================================

  /// Logs the community post creation workflow for debugging
  ///
  /// Parameters:
  /// - [step]: Current step in the workflow
  /// - [data]: Additional data to log
  void _logWorkflowStep(String step, Map<String, dynamic> data) {
    print('Community Post Creation - $step: $data');
  }

  /// Creates a summary of a community post creation request for logging
  ///
  /// Parameters:
  /// - [title]: Post title
  /// - [description]: Post description
  /// - [userId]: User ID
  /// - [spots]: Selected spots
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: Summary data for logging
  Map<String, dynamic> _createRequestSummary({
    required String title,
    String? description,
    required int userId,
    required List<Spot> spots,
  }) {
    return {
      'title': title,
      'description_length': description?.length ?? 0,
      'user_id': userId,
      'spots_count': spots.length,
      'spot_ids': spots.map((s) => s.spot_id).toList(),
      'spot_categories': spots.map((s) => s.category).toSet().toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
