import 'package:json_annotation/json_annotation.dart';
import '../enums/post_type.dart';
import '../core/user.dart';
import '../core/spot_list.dart';
import '../posts/post.dart';

part 'community_post.g.dart';
// =============================================================================
// COMMUNITY POST CONCRETE CLASS
// =============================================================================

/// Concrete implementation for community posts
@JsonSerializable()
class CommunityPost extends Post {
  final String title;
  final int list_id;

  // Optional related object (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final SpotList? list;

  const CommunityPost({
    required super.post_id,
    super.description,
    required super.user_id,
    required super.created_date,
    super.user,
    required this.title,
    required this.list_id,
    this.list,
  }) : super(type: PostType.community);

  /// Creates a CommunityPost instance from JSON data
  factory CommunityPost.fromJson(Map<String, dynamic> json) => _$CommunityPostFromJson(json);

  /// Converts this CommunityPost instance to JSON
  @override
  Map<String, dynamic> toJson() => _$CommunityPostToJson(this);

  /// Helper method to check if post has an associated list
  bool get hasList => list != null;

  /// Helper method to get list name if list is loaded
  String? get listName => list?.list_name;

  /// Helper method to check if associated list is public
  bool? get isListPublic => list?.is_public;

  /// Creates a copy of this post with updated user
  @override
  CommunityPost copyWithUser(User? user) {
    return CommunityPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      title: title,
      list_id: list_id,
      list: list,
    );
  }

  /// Creates a copy of this post with updated list
  CommunityPost copyWithList(SpotList? list) {
    return CommunityPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      title: title,
      list_id: list_id,
      list: list,
    );
  }

  /// Creates a copy of this post with updated fields
  CommunityPost copyWith({
    int? post_id,
    String? description,
    int? user_id,
    DateTime? created_date,
    User? user,
    String? title,
    int? list_id,
    SpotList? list,
  }) {
    return CommunityPost(
      post_id: post_id ?? this.post_id,
      description: description ?? this.description,
      user_id: user_id ?? this.user_id,
      created_date: created_date ?? this.created_date,
      user: user ?? this.user,
      title: title ?? this.title,
      list_id: list_id ?? this.list_id,
      list: list ?? this.list,
    );
  }

  @override
  String toString() => 'CommunityPost(id: $post_id, title: $title, list_id: $list_id)';
}