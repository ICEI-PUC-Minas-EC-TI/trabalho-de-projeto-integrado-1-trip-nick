import 'package:json_annotation/json_annotation.dart';
import 'image.dart';

part 'spot.g.dart';

/// Model representing a tourist spot/location in the system
@JsonSerializable()
class Spot {
  final int spot_id;
  final String spot_name;
  final String country;
  final String city;
  final String category;
  final String? description;
  final DateTime? created_date;

  // Foreign key relationship with Image
  final int? spot_image_id;

  // NEW: Direct image URL fields from API
  final String? spot_image_url;
  final String? spot_image_name;
  final String? spot_image_content_type;
  final int? spot_image_file_size;

  // Optional related object (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Image? spot_image;

  const Spot({
    required this.spot_id,
    required this.spot_name,
    required this.country,
    required this.city,
    required this.category,
    this.description,
    this.created_date,
    this.spot_image_id,
    this.spot_image_url,
    this.spot_image_name,
    this.spot_image_content_type,
    this.spot_image_file_size,
    this.spot_image,
  });

  /// Creates a Spot instance from JSON data
  factory Spot.fromJson(Map<String, dynamic> json) => _$SpotFromJson(json);

  /// Converts this Spot instance to JSON
  Map<String, dynamic> toJson() => _$SpotToJson(this);

  /// Helper method to check if spot has an image
  bool get hasImage => spot_image_id != null;

  /// UPDATED: Get spot image URL (prioritizes direct URL from API)
  String? get imageUrl {
    // First try the direct URL from API response
    if (spot_image_url != null && spot_image_url!.isNotEmpty) {
      return spot_image_url;
    }

    // Fallback to related object URL (if lazy loaded)
    return spot_image?.blob_url;
  }

  /// Helper method to check if spot has a valid image URL
  bool get hasValidImageUrl => imageUrl != null && imageUrl!.isNotEmpty;

  /// Helper method to check if spot has a description
  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;

  /// Helper method to get full location string
  String get fullLocation => '$city, $country';

  /// Helper method to get location with category
  String get locationWithCategory => '$fullLocation • $category';

  /// Helper method to check if spot is in a specific country
  bool isInCountry(String countryName) =>
      country.toLowerCase() == countryName.toLowerCase();

  /// Helper method to check if spot is in a specific city
  bool isInCity(String cityName) =>
      city.toLowerCase() == cityName.toLowerCase();

  /// Helper method to check if spot belongs to a specific category
  bool isCategory(String categoryName) =>
      category.toLowerCase() == categoryName.toLowerCase();

  /// Helper method to get spot age in days since creation
  int? get ageInDays =>
      created_date != null
          ? DateTime.now().difference(created_date!).inDays
          : null;

  /// NEW: Helper method to get image file size in MB
  double? get imageSizeInMB {
    if (spot_image_file_size == null) return null;
    return spot_image_file_size! / (1024.0 * 1024.0);
  }

  /// NEW: Helper method to check image format
  bool get isImageJpeg =>
      spot_image_content_type?.toLowerCase().contains('jpeg') == true;
  bool get isImagePng =>
      spot_image_content_type?.toLowerCase().contains('png') == true;
  bool get isImageWebp =>
      spot_image_content_type?.toLowerCase().contains('webp') == true;

  /// Creates a copy of this spot with updated image
  Spot copyWithImage(Image? image) {
    return Spot(
      spot_id: spot_id,
      spot_name: spot_name,
      country: country,
      city: city,
      category: category,
      description: description,
      created_date: created_date,
      spot_image_id: image?.image_id ?? spot_image_id,
      spot_image_url: image?.blob_url ?? spot_image_url,
      spot_image_name: image?.image_name ?? spot_image_name,
      spot_image_content_type: image?.content_type ?? spot_image_content_type,
      spot_image_file_size: image?.file_size ?? spot_image_file_size,
      spot_image: image,
    );
  }

  /// Creates a copy of this spot with updated fields
  Spot copyWith({
    int? spot_id,
    String? spot_name,
    String? country,
    String? city,
    String? category,
    String? description,
    DateTime? created_date,
    int? spot_image_id,
    String? spot_image_url,
    String? spot_image_name,
    String? spot_image_content_type,
    int? spot_image_file_size,
    Image? spot_image,
  }) {
    return Spot(
      spot_id: spot_id ?? this.spot_id,
      spot_name: spot_name ?? this.spot_name,
      country: country ?? this.country,
      city: city ?? this.city,
      category: category ?? this.category,
      description: description ?? this.description,
      created_date: created_date ?? this.created_date,
      spot_image_id: spot_image_id ?? this.spot_image_id,
      spot_image_url: spot_image_url ?? this.spot_image_url,
      spot_image_name: spot_image_name ?? this.spot_image_name,
      spot_image_content_type:
          spot_image_content_type ?? this.spot_image_content_type,
      spot_image_file_size: spot_image_file_size ?? this.spot_image_file_size,
      spot_image: spot_image ?? this.spot_image,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Spot &&
          runtimeType == other.runtimeType &&
          spot_id == other.spot_id;

  @override
  int get hashCode => spot_id.hashCode;

  @override
  String toString() =>
      'Spot(id: $spot_id, name: $spot_name, location: $fullLocation)';
}
