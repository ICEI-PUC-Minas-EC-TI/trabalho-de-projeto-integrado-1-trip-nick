import 'package:json_annotation/json_annotation.dart';

part 'create_post_request.g.dart';

/// Request model for creating a community post
///
/// This model represents the data needed to create a community post,
/// which includes creating a hidden list for the spots and then
/// creating the actual post that references that list.
@JsonSerializable()
class CreateCommunityPostRequest {
  /// Post title (max 45 characters)
  final String title;

  /// Post description (optional, max 500 characters)
  final String? description;

  /// User ID creating the post
  final int user_id;

  /// List of spot IDs to include in this post
  final List<int> spot_ids;

  const CreateCommunityPostRequest({
    required this.title,
    this.description,
    required this.user_id,
    required this.spot_ids,
  });

  /// Creates a CreateCommunityPostRequest from JSON data
  factory CreateCommunityPostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCommunityPostRequestFromJson(json);

  /// Converts this request to JSON
  Map<String, dynamic> toJson() => _$CreateCommunityPostRequestToJson(this);

  /// Validates the request data
  List<String> validate() {
    List<String> errors = [];

    // Validate title
    if (title.trim().isEmpty) {
      errors.add('Title is required');
    } else if (title.length > 45) {
      errors.add('Title must be 45 characters or less');
    }

    // Validate description
    if (description != null && description!.length > 500) {
      errors.add('Description must be 500 characters or less');
    }

    // Validate user_id
    if (user_id <= 0) {
      errors.add('Valid user ID is required');
    }

    // Validate spot_ids
    if (spot_ids.isEmpty) {
      errors.add('At least one spot is required');
    } else if (spot_ids.length > 10) {
      errors.add('Maximum 10 spots allowed');
    }

    // Check for duplicate spot IDs
    if (spot_ids.toSet().length != spot_ids.length) {
      errors.add('Duplicate spots are not allowed');
    }

    // Check for invalid spot IDs
    if (spot_ids.any((id) => id <= 0)) {
      errors.add('All spot IDs must be valid positive integers');
    }

    return errors;
  }

  /// Checks if the request is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'CreateCommunityPostRequest(title: $title, user_id: $user_id, spots: ${spot_ids.length})';
  }
}

/// Response model for community post creation
@JsonSerializable()
class CreateCommunityPostResponse {
  /// Indicates if the operation was successful
  final bool success;

  /// The created post ID
  final int? post_id;

  /// The created list ID (hidden list containing the spots)
  final int? list_id;

  /// Success or error message
  final String? message;

  /// Error details (if any)
  final String? error;

  /// Additional data about the created post
  final CommunityPostData? data;

  const CreateCommunityPostResponse({
    required this.success,
    this.post_id,
    this.list_id,
    this.message,
    this.error,
    this.data,
  });

  /// Creates a CreateCommunityPostResponse from JSON data
  factory CreateCommunityPostResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateCommunityPostResponseFromJson(json);

  /// Converts this response to JSON
  Map<String, dynamic> toJson() => _$CreateCommunityPostResponseToJson(this);

  @override
  String toString() {
    return 'CreateCommunityPostResponse(success: $success, post_id: $post_id, message: $message)';
  }
}

/// Detailed data about the created community post
@JsonSerializable()
class CommunityPostData {
  /// Post ID
  final int post_id;

  /// Post type (should be 'community')
  final String type;

  /// Post title
  final String title;

  /// Post description
  final String? description;

  /// User ID who created the post
  final int user_id;

  /// When the post was created
  final DateTime created_date;

  /// The hidden list ID containing the spots
  final int list_id;

  /// Number of spots in the post
  final int spots_count;

  const CommunityPostData({
    required this.post_id,
    required this.type,
    required this.title,
    this.description,
    required this.user_id,
    required this.created_date,
    required this.list_id,
    required this.spots_count,
  });

  /// Creates CommunityPostData from JSON data
  factory CommunityPostData.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostDataFromJson(json);

  /// Converts this data to JSON
  Map<String, dynamic> toJson() => _$CommunityPostDataToJson(this);

  @override
  String toString() {
    return 'CommunityPostData(post_id: $post_id, title: $title, spots_count: $spots_count)';
  }
}

/// Request model for creating a list (used internally for community posts)
@JsonSerializable()
class CreateListRequest {
  /// List name (max 45 characters)
  final String list_name;

  /// Whether the list is public (false for community post hidden lists)
  final bool is_public;

  const CreateListRequest({required this.list_name, required this.is_public});

  /// Creates a CreateListRequest from JSON data
  factory CreateListRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateListRequestFromJson(json);

  /// Converts this request to JSON
  Map<String, dynamic> toJson() => _$CreateListRequestToJson(this);

  /// Validates the request data
  List<String> validate() {
    List<String> errors = [];

    // Validate list_name
    if (list_name.trim().isEmpty) {
      errors.add('List name is required');
    } else if (list_name.length > 45) {
      errors.add('List name must be 45 characters or less');
    }

    return errors;
  }

  /// Checks if the request is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'CreateListRequest(list_name: $list_name, is_public: $is_public)';
  }
}

/// Response model for list creation
@JsonSerializable()
class CreateListResponse {
  /// Indicates if the operation was successful
  final bool success;

  /// The created list ID
  final int? list_id;

  /// Success or error message
  final String? message;

  /// Error details (if any)
  final String? error;

  /// Additional data about the created list
  final ListData? data;

  const CreateListResponse({
    required this.success,
    this.list_id,
    this.message,
    this.error,
    this.data,
  });

  /// Creates a CreateListResponse from JSON data
  factory CreateListResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateListResponseFromJson(json);

  /// Converts this response to JSON
  Map<String, dynamic> toJson() => _$CreateListResponseToJson(this);

  @override
  String toString() {
    return 'CreateListResponse(success: $success, list_id: $list_id, message: $message)';
  }
}

/// Data about a created list
@JsonSerializable()
class ListData {
  /// List ID
  final int list_id;

  /// List name
  final String list_name;

  /// Whether the list is public
  final bool is_public;

  const ListData({
    required this.list_id,
    required this.list_name,
    required this.is_public,
  });

  /// Creates ListData from JSON data
  factory ListData.fromJson(Map<String, dynamic> json) =>
      _$ListDataFromJson(json);

  /// Converts this data to JSON
  Map<String, dynamic> toJson() => _$ListDataToJson(this);

  @override
  String toString() {
    return 'ListData(list_id: $list_id, list_name: $list_name, is_public: $is_public)';
  }
}

/// Request model for adding a spot to a list
@JsonSerializable()
class AddSpotToListRequest {
  /// Spot ID to add
  final int spot_id;

  /// Optional thumbnail image ID for this association
  final int? list_thumbnail_id;

  const AddSpotToListRequest({required this.spot_id, this.list_thumbnail_id});

  /// Creates an AddSpotToListRequest from JSON data
  factory AddSpotToListRequest.fromJson(Map<String, dynamic> json) =>
      _$AddSpotToListRequestFromJson(json);

  /// Converts this request to JSON
  Map<String, dynamic> toJson() => _$AddSpotToListRequestToJson(this);

  /// Validates the request data
  List<String> validate() {
    List<String> errors = [];

    // Validate spot_id
    if (spot_id <= 0) {
      errors.add('Valid spot ID is required');
    }

    // Validate list_thumbnail_id if provided
    if (list_thumbnail_id != null && list_thumbnail_id! <= 0) {
      errors.add('Thumbnail ID must be a positive integer if provided');
    }

    return errors;
  }

  /// Checks if the request is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'AddSpotToListRequest(spot_id: $spot_id, list_thumbnail_id: $list_thumbnail_id)';
  }
}
