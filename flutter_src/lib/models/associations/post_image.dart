import 'package:json_annotation/json_annotation.dart';
import '../posts/post.dart';
import '../core/image.dart';

part 'post_image.g.dart';

/// Association model representing the relationship between posts and their images
///
/// DATABASE TABLE MAPPING:
/// This class maps to the 'Post_Images' table which stores:
/// - post_id: Links to the Post table (which post this image belongs to)
/// - image_id: Links to the Images table (which image is being attached)
/// - image_order: The sequence/position of this image in the post (1st, 2nd, 3rd, etc.)
/// - is_thumbnail: Whether this specific image is the main thumbnail for the post
/// - created_date: When this image was added to the post
///
/// RELATIONSHIP EXPLANATION:
/// - ONE Post can have MANY Images (one-to-many from Post perspective)
/// - ONE Image can belong to MANY Posts (one-to-many from Image perspective)
/// - This creates a MANY-TO-MANY relationship between Posts and Images
/// - PostImages is the "junction table" that connects them
/// - Each PostImages record represents: "Image X is attached to Post Y at position Z"
@JsonSerializable()
class PostImages {
  /// Foreign key to Post table - which post this image belongs to
  final int post_id;

  /// Foreign key to Images table - which image is being attached
  final int image_id;

  /// The order/position of this image in the post (1 = first image, 2 = second, etc.)
  final int image_order;

  /// Whether this image is the main thumbnail for the post
  /// Database constraint ensures only ONE thumbnail per post
  final bool is_thumbnail;

  /// When this image was added to this post
  final DateTime? created_date;

  // Optional related objects (for lazy loading)
  /// The actual Post object this image belongs to (loaded separately)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Post? post;

  /// The actual Image object being attached (loaded separately)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Image? image;

  const PostImages({
    required this.post_id,
    required this.image_id,
    required this.image_order,
    required this.is_thumbnail,
    this.created_date,
    this.post,
    this.image,
  });

  /// Creates a PostImages instance from JSON data
  factory PostImages.fromJson(Map<String, dynamic> json) => _$PostImagesFromJson(json);

  /// Converts this PostImages instance to JSON
  Map<String, dynamic> toJson() => _$PostImagesToJson(this);

  // =============================================================================
  // RELATIONSHIP HELPERS - Understanding the connections
  // =============================================================================

  /// Helper method to check if related objects are loaded
  bool get hasLoadedPost => post != null;
  bool get hasLoadedImage => image != null;
  bool get isFullyLoaded => hasLoadedPost && hasLoadedImage;

  /// Helper to get the image URL if image is loaded
  String? get imageUrl => image?.blob_url;

  /// Helper to get the post title if post is loaded
  String? get postTitle => post?.title;

  /// Helper to get the post type if post is loaded
  String? get postType => post?.type.value;

  // =============================================================================
  // IMAGE ORDERING AND THUMBNAIL LOGIC
  // =============================================================================

  /// Helper to check if this is the main thumbnail for the post
  bool get isThumbnail => is_thumbnail;

  /// Helper to check if this is a regular image (not thumbnail)
  bool get isRegularImage => !is_thumbnail;

  /// Helper to check if this is the first image in order
  bool get isFirstImage => image_order == 1;

  /// Helper to check if this is positioned before another PostImages
  bool isOrderedBefore(PostImages other) => image_order < other.image_order;

  /// Helper to check if this is positioned after another PostImages
  bool isOrderedAfter(PostImages other) => image_order > other.image_order;

  // =============================================================================
  // IMAGE METADATA HELPERS (if image is loaded)
  // =============================================================================

  /// Helper to get image file size if image is loaded
  double? get imageSizeInMB => image?.fileSizeInMB;

  /// Helper to check image content type if image is loaded
  bool get isJpeg => image?.isJpeg ?? false;
  bool get isPng => image?.isPng ?? false;
  bool get isWebp => image?.isWebp ?? false;

  /// Helper to get image name if image is loaded
  String? get imageName => image?.image_name;

  // =============================================================================
  // TIME-BASED HELPERS
  // =============================================================================

  /// Helper to get age in days since image was added to post
  int? get ageInDays => created_date?.let((date) =>
  DateTime.now().difference(date).inDays);

  /// Helper to check if image was recently added (less than 7 days)
  bool get isRecentlyAdded => ageInDays != null && ageInDays! < 7;

  // =============================================================================
  // COPY METHODS FOR LAZY LOADING
  // =============================================================================

  /// Creates a copy with the Post object loaded
  PostImages copyWithPost(Post? post) {
    return PostImages(
      post_id: post_id,
      image_id: image_id,
      image_order: image_order,
      is_thumbnail: is_thumbnail,
      created_date: created_date,
      post: post,
      image: image,
    );
  }

  /// Creates a copy with the Image object loaded
  PostImages copyWithImage(Image? image) {
    return PostImages(
      post_id: post_id,
      image_id: image_id,
      image_order: image_order,
      is_thumbnail: is_thumbnail,
      created_date: created_date,
      post: post,
      image: image,
    );
  }

  /// Creates a copy with both Post and Image objects loaded
  PostImages copyWithBoth({Post? post, Image? image}) {
    return PostImages(
      post_id: post_id,
      image_id: image_id,
      image_order: image_order,
      is_thumbnail: is_thumbnail,
      created_date: created_date,
      post: post ?? this.post,
      image: image ?? this.image,
    );
  }

  /// Creates a copy with updated order position
  PostImages copyWithOrder(int newOrder) {
    if (newOrder < 1) {
      throw ArgumentError('Image order must be 1 or greater');
    }

    return PostImages(
      post_id: post_id,
      image_id: image_id,
      image_order: newOrder,
      is_thumbnail: is_thumbnail,
      created_date: created_date,
      post: post,
      image: image,
    );
  }

  /// Creates a copy with updated thumbnail status
  PostImages copyWithThumbnailStatus(bool isThumbnail) {
    return PostImages(
      post_id: post_id,
      image_id: image_id,
      image_order: image_order,
      is_thumbnail: isThumbnail,
      created_date: created_date,
      post: post,
      image: image,
    );
  }

  /// Creates a copy of this association with updated fields
  PostImages copyWith({
    int? post_id,
    int? image_id,
    int? image_order,
    bool? is_thumbnail,
    DateTime? created_date,
    Post? post,
    Image? image,
  }) {
    return PostImages(
      post_id: post_id ?? this.post_id,
      image_id: image_id ?? this.image_id,
      image_order: image_order ?? this.image_order,
      is_thumbnail: is_thumbnail ?? this.is_thumbnail,
      created_date: created_date ?? this.created_date,
      post: post ?? this.post,
      image: image ?? this.image,
    );
  }

  // =============================================================================
  // EQUALITY AND DEBUGGING
  // =============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PostImages &&
              runtimeType == other.runtimeType &&
              post_id == other.post_id &&
              image_id == other.image_id;

  @override
  int get hashCode => Object.hash(post_id, image_id);

  @override
  String toString() =>
      'PostImages(post_id: $post_id, image_id: $image_id, order: $image_order, thumbnail: $is_thumbnail)';
}

/// Extension for null-safe DateTime operations
extension PostImagesDateExtensions on DateTime? {
  T? let<T>(T Function(DateTime) transform) {
    return this != null ? transform(this!) : null;
  }
}