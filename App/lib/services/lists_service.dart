import 'dart:convert';
import '../models/api_responses/create_post_request.dart';
import '../services/api_service.dart';
import '../utils/exceptions.dart';
import '../utils/constants.dart';

/// Service for managing lists operations
///
/// This service handles:
/// - Creating lists (both hidden lists for community posts and regular lists)
/// - Adding spots to lists
/// - Removing spots from lists
/// - Retrieving list contents
/// - Deleting lists
class ListsService {
  /// Singleton instance
  static final ListsService _instance = ListsService._internal();

  /// Factory constructor returns singleton
  factory ListsService() => _instance;

  /// Private constructor
  ListsService._internal();

  /// Reference to the API service
  ApiService get _apiService => ApiService();

  // =============================================================================
  // LIST CREATION
  // =============================================================================

  /// Creates a new list
  ///
  /// Parameters:
  /// - [listName]: Name of the list (max 45 characters)
  /// - [isPublic]: Whether the list should be public (true) or private (false)
  ///
  /// Returns:
  /// - [CreateListResponse]: Response containing list_id and details
  ///
  /// Throws:
  /// - [ValidationException]: If request data is invalid
  /// - [ApiException]: For API-related errors
  /// - [NetworkException]: For network connectivity issues
  Future<CreateListResponse> createList({
    required String listName,
    required bool isPublic,
  }) async {
    try {
      // Create and validate request
      final request = CreateListRequest(
        list_name: listName.trim(),
        is_public: isPublic,
      );

      // Validate request data
      final validationErrors = request.validate();
      if (validationErrors.isNotEmpty) {
        throw ServerException(
          'Invalid list data: ${validationErrors.join(', ')}',
        );
      }

      // Make API call
      final response = await _apiService.post(
        ApiConstants.listsEndpoint,
        body: request.toJson(),
      );

      // Parse and return response
      return CreateListResponse.fromJson(response);
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to create list: ${e.toString()}');
    }
  }

  /// Creates a hidden list for a community post
  ///
  /// This is a specialized version of createList that:
  /// - Uses auto-generated names
  /// - Sets privacy to false (hidden from public lists)
  /// - Is optimized for community post workflow
  ///
  /// Parameters:
  /// - [postTitle]: Title of the post (used to generate list name)
  ///
  /// Returns:
  /// - [CreateListResponse]: Response with the created hidden list details
  Future<CreateListResponse> createHiddenListForPost({
    required String postTitle,
  }) async {
    try {
      // Generate a descriptive but hidden list name
      final listName = _generateHiddenListName(postTitle);

      return await createList(
        listName: listName,
        isPublic: false, // Hidden lists are always private
      );
    } catch (e) {
      throw ServerException(
        'Failed to create hidden list for post: ${e.toString()}',
      );
    }
  }

  // =============================================================================
  // SPOT MANAGEMENT
  // =============================================================================

  /// Adds a spot to an existing list
  ///
  /// Parameters:
  /// - [listId]: ID of the list to add the spot to
  /// - [spotId]: ID of the spot to add
  /// - [thumbnailId]: Optional thumbnail image ID for this association
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with association details
  ///
  /// Throws:
  /// - [ValidationException]: If request data is invalid
  /// - [ConflictException]: If spot is already in the list
  /// - [NotFoundException]: If list or spot doesn't exist
  /// - [ApiException]: For other API-related errors
  Future<Map<String, dynamic>> addSpotToList({
    required int listId,
    required int spotId,
    int? thumbnailId,
  }) async {
    try {
      // Validate input
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }
      if (spotId <= 0) {
        throw ServerException('Valid spot ID is required');
      }
      if (thumbnailId != null && thumbnailId <= 0) {
        throw ServerException('Thumbnail ID must be positive if provided');
      }

      // Create request
      final request = AddSpotToListRequest(
        spot_id: spotId,
        list_thumbnail_id: thumbnailId,
      );

      // Validate request
      final validationErrors = request.validate();
      if (validationErrors.isNotEmpty) {
        throw ServerException(
          'Invalid spot-to-list data: ${validationErrors.join(', ')}',
        );
      }

      // Make API call
      final response = await _apiService.post(
        '${ApiConstants.listsEndpoint}/$listId/spots',
        body: request.toJson(),
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to add spot to list: ${e.toString()}');
    }
  }

  /// Adds multiple spots to a list in batch
  ///
  /// This method adds multiple spots to a list efficiently.
  /// If any spot fails to add, the entire operation is considered failed.
  ///
  /// Parameters:
  /// - [listId]: ID of the list to add spots to
  /// - [spotIds]: List of spot IDs to add
  ///
  /// Returns:
  /// - [List<Map<String, dynamic>>]: List of responses for each spot added
  ///
  /// Throws:
  /// - [ValidationException]: If any spot data is invalid
  /// - [ApiException]: If any spot fails to be added
  Future<List<Map<String, dynamic>>> addMultipleSpotsToList({
    required int listId,
    required List<int> spotIds,
  }) async {
    try {
      // Validate input
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }
      if (spotIds.isEmpty) {
        throw ServerException('At least one spot ID is required');
      }
      if (spotIds.any((id) => id <= 0)) {
        throw ServerException('All spot IDs must be positive');
      }

      // Remove duplicates
      final uniqueSpotIds = spotIds.toSet().toList();

      // Add spots one by one
      final List<Map<String, dynamic>> results = [];

      for (int i = 0; i < uniqueSpotIds.length; i++) {
        final spotId = uniqueSpotIds[i];

        try {
          final result = await addSpotToList(listId: listId, spotId: spotId);
          results.add(result);
        } catch (e) {
          // If adding any spot fails, we consider the whole operation failed
          throw ServerException(
            'Failed to add spot $spotId to list (${i + 1}/${uniqueSpotIds.length}): ${e.toString()}',
          );
        }
      }

      return results;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        'Failed to add multiple spots to list: ${e.toString()}',
      );
    }
  }

  /// Removes a spot from a list
  ///
  /// Parameters:
  /// - [listId]: ID of the list to remove the spot from
  /// - [spotId]: ID of the spot to remove
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with removal details
  ///
  /// Throws:
  /// - [ValidationException]: If request data is invalid
  /// - [NotFoundException]: If list, spot, or association doesn't exist
  /// - [ApiException]: For other API-related errors
  Future<Map<String, dynamic>> removeSpotFromList({
    required int listId,
    required int spotId,
  }) async {
    try {
      // Validate input
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }
      if (spotId <= 0) {
        throw ServerException('Valid spot ID is required');
      }

      // Make API call
      final response = await _apiService.delete(
        '${ApiConstants.listsEndpoint}/$listId/spots/$spotId',
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to remove spot from list: ${e.toString()}');
    }
  }

  // =============================================================================
  // LIST RETRIEVAL
  // =============================================================================

  /// Gets the contents of a list
  ///
  /// Parameters:
  /// - [listId]: ID of the list to retrieve
  /// - [orderBy]: How to order the results ('added_date', 'spot_name', 'city', 'category')
  /// - [orderDirection]: 'asc' or 'desc'
  /// - [includeImages]: Whether to include image URLs in the response
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with list contents and metadata
  ///
  /// Throws:
  /// - [ValidationException]: If parameters are invalid
  /// - [NotFoundException]: If list doesn't exist
  /// - [ApiException]: For other API-related errors
  Future<Map<String, dynamic>> getListContents({
    required int listId,
    String orderBy = 'added_date',
    String orderDirection = 'desc',
    bool includeImages = true,
  }) async {
    try {
      // Validate input
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }

      final validOrderBy = ['added_date', 'spot_name', 'city', 'category'];
      if (!validOrderBy.contains(orderBy)) {
        throw ServerException('Invalid orderBy parameter');
      }

      final validOrderDirection = ['asc', 'desc'];
      if (!validOrderDirection.contains(orderDirection)) {
        throw ServerException('Invalid order direction');
      }

      // Build query parameters
      final queryParams = {
        'orderBy': orderBy,
        'order': orderDirection,
        'includeImages': includeImages.toString(),
      };

      // Make API call
      final response = await _apiService.get(
        '${ApiConstants.listsEndpoint}/$listId/spots',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to get list contents: ${e.toString()}');
    }
  }

  // =============================================================================
  // LIST DELETION
  // =============================================================================

  /// Deletes a list and all its associations
  ///
  /// Parameters:
  /// - [listId]: ID of the list to delete
  /// - [force]: Whether to force deletion even if list has associated posts
  /// - [dryRun]: If true, returns what would be deleted without actually deleting
  ///
  /// Returns:
  /// - [Map<String, dynamic>]: API response with deletion details
  ///
  /// Throws:
  /// - [ValidationException]: If list ID is invalid
  /// - [ConflictException]: If list has posts and force=false
  /// - [NotFoundException]: If list doesn't exist
  /// - [ApiException]: For other API-related errors
  Future<Map<String, dynamic>> deleteList({
    required int listId,
    bool force = false,
    bool dryRun = false,
  }) async {
    try {
      // Validate input
      if (listId <= 0) {
        throw ServerException('Valid list ID is required');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (force) queryParams['force'] = 'true';
      if (dryRun) queryParams['dryRun'] = 'true';

      // Make API call
      final response = await _apiService.delete(
        '${ApiConstants.listsEndpoint}/$listId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response;
    } catch (e) {
      if (e is NetworkException ||
          e is ServerException ||
          e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to delete list: ${e.toString()}');
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Generates a hidden list name for a community post
  ///
  /// The list name is based on the post title but truncated to fit
  /// within database constraints (45 characters max).
  ///
  /// Parameters:
  /// - [postTitle]: The title of the community post
  ///
  /// Returns:
  /// - [String]: Generated list name that won't exceed database limits
  String _generateHiddenListName(String postTitle) {
    const String suffix = ' - Spots';
    const int maxLength = 45; // Database constraint

    // Calculate available space for title
    final int availableSpace = maxLength - suffix.length;

    // Truncate title if necessary
    String truncatedTitle = postTitle.trim();
    if (truncatedTitle.length > availableSpace) {
      truncatedTitle = '${truncatedTitle.substring(0, availableSpace - 3)}...';
    }

    return '$truncatedTitle$suffix';
  }

  /// Validates a list name according to business rules
  ///
  /// Parameters:
  /// - [listName]: The list name to validate
  ///
  /// Returns:
  /// - [List<String>]: List of validation errors (empty if valid)
  List<String> validateListName(String listName) {
    final List<String> errors = [];

    final trimmed = listName.trim();

    if (trimmed.isEmpty) {
      errors.add('List name cannot be empty');
    }

    if (trimmed.length > 45) {
      errors.add('List name must be 45 characters or less');
    }

    if (trimmed.length < 3) {
      errors.add('List name must be at least 3 characters');
    }

    // Check for inappropriate content (basic example)
    final inappropriate = ['spam', 'test123', 'asdf'];
    if (inappropriate.any((word) => trimmed.toLowerCase().contains(word))) {
      errors.add('List name contains inappropriate content');
    }

    return errors;
  }

  /// Checks if a list name is valid
  ///
  /// Parameters:
  /// - [listName]: The list name to check
  ///
  /// Returns:
  /// - [bool]: True if the list name is valid
  bool isValidListName(String listName) {
    return validateListName(listName).isEmpty;
  }
}
