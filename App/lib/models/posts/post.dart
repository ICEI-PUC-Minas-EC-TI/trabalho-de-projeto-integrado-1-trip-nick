import 'package:json_annotation/json_annotation.dart';
import '../enums/post_type.dart';
import '../core/user.dart';
import '../core/spot_list.dart';
import 'community_post.dart';
import 'list_post.dart';
import 'review_post.dart';

// =============================================================================
// ABSTRACT BASE POST CLASS
// =============================================================================

abstract class Post {
  final int post_id;
  final String? description;
  final int user_id;
  final DateTime created_date;
  final PostType type;

  // Optional related objects (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final User? user;

  const Post({
    required this.post_id,
    this.description,
    required this.user_id,
    required this.created_date,
    required this.type,
    this.user,
  });

  /// Factory constructor to create the appropriate post subtype from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    final type = PostType.fromString(json['type'] as String);

    switch (type) {
      case PostType.community:
        return CommunityPost.fromJson(json);
      case PostType.review:
        return ReviewPost.fromJson(json);
      case PostType.list:
        return ListPost.fromJson(json);
    }
  }

  /// Converts this Post instance to JSON
  Map<String, dynamic> toJson();

  /// Helper method to check if post has a description
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  /// Helper method to get trimmed description
  String? get trimmedDescription => description?.trim();

  /// Helper method to get post age in days
  int get ageInDays => DateTime.now().difference(created_date).inDays;

  /// Helper method to get post age in hours
  int get ageInHours => DateTime.now().difference(created_date).inHours;

  /// Helper method to check if post is recent (less than 24 hours)
  bool get isRecent => ageInHours < 24;

  /// Helper method to get user display name if user is loaded
  String? get authorName => user?.display_name;

  /// Helper method to get user username if user is loaded
  String? get authorUsername => user?.username;

  /// Abstract method to get post title (implemented differently by each subtype)
  String get title;

  /// Abstract method to copy post with updated user
  Post copyWithUser(User? user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Post &&
              runtimeType == other.runtimeType &&
              post_id == other.post_id;

  @override
  int get hashCode => post_id.hashCode;

  @override
  String toString() => 'Post(id: $post_id, type: $type, user_id: $user_id)';
}