import 'package:json_annotation/json_annotation.dart';
import '../enums/post_type.dart';
import 'post.dart';
import '../core/user.dart';
import '../core/spot_list.dart';

part 'list_post.g.dart';

/// Concrete implementation for list posts
@JsonSerializable()
class ListPost extends Post {
  final String title;
  final int list_id;

  // Optional related object (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final SpotList? list;

  const ListPost({
    required super.post_id,
    super.description,
    required super.user_id,
    required super.created_date,
    super.user,
    required this.title,
    required this.list_id,
    this.list,
  }) : super(type: PostType.list);

  /// Creates a ListPost instance from JSON data
  factory ListPost.fromJson(Map<String, dynamic> json) => _$ListPostFromJson(json);

  /// Converts this ListPost instance to JSON
  @override
  Map<String, dynamic> toJson() => _$ListPostToJson(this);

  /// Helper method to check if post has a valid title
  bool get hasValidTitle => title.trim().isNotEmpty;

  /// Helper method to get trimmed title
  String get trimmedTitle => title.trim();

  /// Helper method to check if post has an associated list
  bool get hasList => list != null;

  /// Helper method to get list name if list is loaded
  String? get listName => list?.list_name;

  /// Helper method to check if associated list is public
  bool? get isListPublic => list?.is_public;

  /// Helper method to check if associated list is private
  bool? get isListPrivate => list?.isPrivate;

  /// Helper method to get list visibility status
  String? get listVisibilityStatus => list?.visibilityStatus;

  /// Helper method to get list visibility icon
  String? get listVisibilityIcon => list?.visibilityIcon;

  /// Helper method to check if titles match (post title vs list name)
  bool get titleMatchesList {
    if (!hasList) return false;
    return trimmedTitle.toLowerCase() == list!.trimmedName.toLowerCase();
  }

  /// Helper method to get the most relevant title for display
  String get displayTitle {
    // If we have the list loaded, prefer the list name for consistency
    if (hasList && list!.hasValidName) {
      return list!.trimmedName;
    }
    return trimmedTitle;
  }

  /// Helper method to get title with visibility indicator
  String get titleWithVisibility {
    if (hasList) {
      return list!.nameWithVisibility;
    }
    return '$trimmedTitle (Visibilidade desconhecida)';
  }

  /// Helper method to check if this is sharing a public list
  bool get isSharingPublicList => isListPublic == true;

  /// Helper method to check if this is sharing a private list
  bool get isSharingPrivateList => isListPrivate == true;

  /// Creates a copy of this post with updated user
  @override
  ListPost copyWithUser(User? user) {
    return ListPost(
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
  ListPost copyWithList(SpotList? list) {
    return ListPost(
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

  /// Creates a copy of this post with updated title
  ListPost copyWithTitle(String newTitle) {
    if (newTitle.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    return ListPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      title: newTitle,
      list_id: list_id,
      list: list,
    );
  }

  /// Creates a copy of this post with updated fields
  ListPost copyWith({
    int? post_id,
    String? description,
    int? user_id,
    DateTime? created_date,
    User? user,
    String? title,
    int? list_id,
    SpotList? list,
  }) {
    // Validate title if provided
    if (title != null && title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    return ListPost(
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
  String toString() => 'ListPost(id: $post_id, title: $title, list_id: $list_id)';
}