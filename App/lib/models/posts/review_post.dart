import 'package:json_annotation/json_annotation.dart';
import '../enums/post_type.dart';
import 'post.dart';
import '../core/user.dart';
import '../core/spot.dart';

part 'review_post.g.dart';

/// Concrete implementation for review posts
@JsonSerializable()
class ReviewPost extends Post {
  final int spot_id;
  final double? rating;

  // Optional related object (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Spot? spot;

  const ReviewPost({
    required super.post_id,
    super.description,
    required super.user_id,
    required super.created_date,
    super.user,
    required this.spot_id,
    this.rating,
    this.spot,
  }) : super(type: PostType.review);

  /// Creates a ReviewPost instance from JSON data
  factory ReviewPost.fromJson(Map<String, dynamic> json) => _$ReviewPostFromJson(json);

  /// Converts this ReviewPost instance to JSON
  @override
  Map<String, dynamic> toJson() => _$ReviewPostToJson(this);

  /// Implementation of abstract title getter - uses spot name or fallback
  @override
  String get title => spot?.spot_name ?? 'Review for Spot #$spot_id';

  /// Helper method to check if review has a rating
  bool get hasRating => rating != null;

  /// Helper method to check if rating is valid (1-5 range)
  bool get hasValidRating => rating != null && rating! >= 1.0 && rating! <= 5.0;

  /// Helper method to get rating as integer for star display
  int get ratingAsInt => rating?.round() ?? 0;

  /// Helper method to get rating stars as string
  String get ratingStars {
    if (!hasValidRating) return '☆☆☆☆☆';

    final fullStars = ratingAsInt;
    final emptyStars = 5 - fullStars;

    return '${'★' * fullStars}${'☆' * emptyStars}';
  }

  /// Helper method to get rating description
  String get ratingDescription {
    if (!hasValidRating) return 'Sem avaliação';

    switch (ratingAsInt) {
      case 1:
        return 'Muito ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente';
      default:
        return 'Avaliação inválida';
    }
  }

  /// Helper method to check if review has an associated spot
  bool get hasSpot => spot != null;

  /// Helper method to get spot name if spot is loaded
  String? get spotName => spot?.spot_name;

  /// Helper method to get spot location if spot is loaded
  String? get spotLocation => spot?.fullLocation;

  /// Helper method to get spot category if spot is loaded
  String? get spotCategory => spot?.category;

  /// Helper method to check if this is a positive review (4+ stars)
  bool get isPositiveReview => hasValidRating && rating! >= 4.0;

  /// Helper method to check if this is a negative review (2 or less stars)
  bool get isNegativeReview => hasValidRating && rating! <= 2.0;

  /// Helper method to get review sentiment
  String get reviewSentiment {
    if (isPositiveReview) return 'Positiva';
    if (isNegativeReview) return 'Negativa';
    return 'Neutra';
  }

  /// Creates a copy of this post with updated user
  @override
  ReviewPost copyWithUser(User? user) {
    return ReviewPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      spot_id: spot_id,
      rating: rating,
      spot: spot,
    );
  }

  /// Creates a copy of this post with updated spot
  ReviewPost copyWithSpot(Spot? spot) {
    return ReviewPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      spot_id: spot_id,
      rating: rating,
      spot: spot,
    );
  }

  /// Creates a copy of this post with validated rating
  ReviewPost copyWithRating(double? newRating) {
    // Validate rating range
    if (newRating != null && (newRating < 1.0 || newRating > 5.0)) {
      throw ArgumentError('Rating must be between 1.0 and 5.0');
    }

    return ReviewPost(
      post_id: post_id,
      description: description,
      user_id: user_id,
      created_date: created_date,
      user: user,
      spot_id: spot_id,
      rating: newRating,
      spot: spot,
    );
  }

  /// Creates a copy of this post with updated fields
  ReviewPost copyWith({
    int? post_id,
    String? description,
    int? user_id,
    DateTime? created_date,
    User? user,
    int? spot_id,
    double? rating,
    Spot? spot,
  }) {
    // Validate rating if provided
    if (rating != null && (rating < 1.0 || rating > 5.0)) {
      throw ArgumentError('Rating must be between 1.0 and 5.0');
    }

    return ReviewPost(
      post_id: post_id ?? this.post_id,
      description: description ?? this.description,
      user_id: user_id ?? this.user_id,
      created_date: created_date ?? this.created_date,
      user: user ?? this.user,
      spot_id: spot_id ?? this.spot_id,
      rating: rating ?? this.rating,
      spot: spot ?? this.spot,
    );
  }

  @override
  String toString() => 'ReviewPost(id: $post_id, spot_id: $spot_id, rating: $rating)';
}