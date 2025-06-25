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

  Future<CreateReviewPostResponse> createReviewPost({
    required int spotId,
    required int rating,
    String? description,
    required int userId,
  }) async {
    try {
      // Step 1: Validate input data
      _validateReviewPostInput(spotId, rating, description, userId);

      // Step 2: Create the review post request
      final request = CreateReviewPostRequest.fromFormData(
        spotId: spotId,
        rating: rating,
        description: description,
        userId: userId,
      );

      print('PostsService: Creating review post for spot $spotId');

      // Step 3: Create request data (using existing pattern)
      final requestData = {
        'type': 'review',
        'description': request.description,
        'user_id': request.user_id,
        'spot_id': request.spot_id,
        'rating': request.rating,
      };

      // Step 4: Make API call (using existing _apiService pattern)
      final response = await _apiService.post(
        ApiConstants.postsEndpoint,
        body: requestData,
      );

      print('PostsService: Review post API response: ${response.toString()}');

      // Step 5: Extract response data (following existing pattern)
      int? postId;
      String? createdDateStr;

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

      // Step 6: Return comprehensive response
      return CreateReviewPostResponse(
        success: true,
        post_id: postId,
        message: 'Avaliação criada com sucesso',
        data: ReviewPostData(
          post_id: postId,
          type: 'review',
          description: request.description,
          user_id: request.user_id,
          created_date: DateTime.parse(createdDateStr),
          spot_id: request.spot_id,
          rating: request.rating,
        ),
      );
    } catch (e) {
      print('PostsService: Error creating review post: $e');

      if (e is NetworkException ||
          e is ServerException ||
          e is ValidationException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create review post: ${e.toString()}');
    }
  }

  // =============================================================================
  // REVIEW POST VALIDATION (Add these new methods)
  // =============================================================================

  /// Validates review post input data
  ///
  /// Throws [ValidationException] if data is invalid
  void _validateReviewPostInput(
    int spotId,
    int rating,
    String? description,
    int userId,
  ) {
    // Validate spot ID
    if (spotId <= 0) {
      throw const ValidationException('ID do local é obrigatório');
    }

    // Validate rating
    if (rating < 1 || rating > 5) {
      throw const ValidationException(
        'Avaliação deve ser entre 1 e 5 estrelas',
      );
    }

    // Validate user ID
    if (userId <= 0) {
      throw const ValidationException('ID do usuário é obrigatório');
    }

    // Validate description length
    if (description != null && description.length > 500) {
      throw const ValidationException(
        'Comentário não pode ter mais de 500 caracteres',
      );
    }

    print('PostsService: Review post validation passed');
  }

  /// Get review post validation summary
  Map<String, dynamic> getReviewPostValidationSummary({
    required int spotId,
    required int rating,
    String? description,
    required int userId,
  }) {
    return {
      'valid_spot_id': spotId > 0,
      'valid_rating': rating >= 1 && rating <= 5,
      'valid_user_id': userId > 0,
      'valid_description': description == null || description.length <= 500,
      'description_length': description?.length ?? 0,
      'is_valid':
          spotId > 0 &&
          rating >= 1 &&
          rating <= 5 &&
          userId > 0 &&
          (description == null || description.length <= 500),
    };
  }

  // =============================================================================
  // LIST POST CREATION (New Feature)
  // =============================================================================

  /// Creates a list post with automatic public list creation
  ///
  /// This is the main method for creating list posts. It orchestrates:
  /// 1. Creates a public list with auto-generated name
  /// 2. Adds all selected spots to the public list
  /// 3. Creates the list post that references the public list
  ///
  /// Parameters:
  /// - [title]: Post title (max 45 characters)
  /// - [description]: Post description (optional, max 500 characters)
  /// - [userId]: ID of the user creating the post
  /// - [selectedSpots]: List of spots to include in the list (1-10 spots)
  ///
  /// Returns:
  /// - [CreateListPostResponse]: Complete response with post and list details
  ///
  /// Throws:
  /// - [ValidationException]: If request data is invalid
  /// - [ApiException]: For API-related errors during any step
  /// - [NetworkException]: For network connectivity issues
  Future<CreateListPostResponse> createListPost({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
  }) async {
    try {
      // Step 1: Validate input data
      _validateListPostInput(title, description, userId, selectedSpots);

      // Step 2: Create public list with auto-generated name
      final listResponse = await _createPublicListForPost(title);
      final listId = listResponse.list_id!;

      _logWorkflowStep('List created', {
        'list_id': listId,
        'list_name': listResponse.data?.list_name,
      });

      // Step 3: Add all selected spots to the public list
      await _addSpotsToPublicList(listId, selectedSpots);

      _logWorkflowStep('Spots added to list', {
        'list_id': listId,
        'spots_count': selectedSpots.length,
      });

      // Step 4: Create the list post record in the database
      final postResponse = await _createListPostRecord(
        title: title,
        description: description,
        userId: userId,
        listId: listId,
      );

      _logWorkflowStep('List post created', {
        'success': postResponse['success'],
        'post_id': postResponse['post_id'],
      });

      // Step 5: Build and return complete response
      final response = CreateListPostResponse(
        success: true,
        post_id: postResponse['post_id'],
        message: postResponse['message'] ?? 'List post created successfully',
        data: ListPostData(
          post_id: postResponse['post_id'],
          type: 'list',
          title: title,
          description: description,
          user_id: userId,
          created_date: DateTime.now(),
          list_id: listId,
          list_name: listResponse.data?.list_name ?? 'Generated List',
          is_public: true,
          spots_count: selectedSpots.length,
        ),
      );

      _logWorkflowStep('Workflow completed', {
        'post_id': response.post_id,
        'list_id': listId,
        'spots_count': selectedSpots.length,
      });

      return response;
    } catch (e) {
      _logWorkflowStep('Workflow failed', {
        'error': e.toString(),
        'step': 'createListPost',
      });

      if (e is ValidationException ||
          e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create list post: ${e.toString()}');
    }
  }

  // =============================================================================
  // LIST POST VALIDATION
  // =============================================================================

  /// Validates list post input data
  void _validateListPostInput(
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
      throw ServerException('Invalid list post data: ${errors.join(', ')}');
    }

    print('PostsService: List post validation passed');
  }

  /// Get list post validation summary
  Map<String, dynamic> getListPostValidationSummary({
    required String title,
    String? description,
    required int userId,
    required List<Spot> selectedSpots,
  }) {
    return {
      'valid_title': PostConstants.isValidTitleLength(title),
      'valid_description': PostConstants.isValidDescriptionLength(description),
      'valid_user_id': userId > 0,
      'valid_spots_count': PostConstants.isValidSpotsCount(selectedSpots),
      'title_length': title.length,
      'description_length': description?.length ?? 0,
      'spots_count': selectedSpots.length,
      'has_duplicate_spots':
          selectedSpots.map((s) => s.spot_id).toSet().length !=
          selectedSpots.length,
      'is_valid':
          PostConstants.isValidTitleLength(title) &&
          PostConstants.isValidDescriptionLength(description) &&
          userId > 0 &&
          PostConstants.isValidSpotsCount(selectedSpots) &&
          selectedSpots.map((s) => s.spot_id).toSet().length ==
              selectedSpots.length,
    };
  }

  // =============================================================================
  // PRIVATE HELPER METHODS FOR LIST POSTS
  // =============================================================================

  /// Creates a public list for the list post
  Future<CreateListResponse> _createPublicListForPost(String postTitle) async {
    try {
      // Generate auto-generated list name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final listName = 'List_Post_$timestamp';

      return await _listsService.createList(
        listName: listName,
        isPublic: true, // List posts always use public lists
      );
    } catch (e) {
      throw ServerException(
        'Failed to create public list for list post: ${e.toString()}',
      );
    }
  }

  /// Adds all selected spots to the public list
  Future<void> _addSpotsToPublicList(
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
        'Failed to add spots to public list: ${e.toString()}',
      );
    }
  }

  /// Creates the list post record in the database
  Future<Map<String, dynamic>> _createListPostRecord({
    required String title,
    String? description,
    required int userId,
    required int listId,
  }) async {
    try {
      final request = CreateListPostRequest(
        title: title,
        description: description,
        user_id: userId,
        list_id: listId,
      );

      // Validate request
      final validationErrors = request.validate();
      if (validationErrors.isNotEmpty) {
        throw ServerException(
          'Invalid list post data: ${validationErrors.join(', ')}',
        );
      }

      // Make API call to create the list post
      final response = await _apiService.post(
        ApiConstants.postsEndpoint,
        body: request.toJson(),
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        'Failed to create list post record: ${e.toString()}',
      );
    }
  }

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
