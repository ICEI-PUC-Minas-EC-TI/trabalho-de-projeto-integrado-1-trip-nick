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
    this.spot_image,
  });

  /// Creates a Spot instance from JSON data
  factory Spot.fromJson(Map<String, dynamic> json) => _$SpotFromJson(json);

  /// Converts this Spot instance to JSON
  Map<String, dynamic> toJson() => _$SpotToJson(this);

  /// Helper method to check if spot has an image
  bool get hasImage => spot_image_id != null;

  /// Helper method to get spot image URL
  String? get imageUrl => spot_image?.blob_url;

  /// Helper method to check if spot has a description
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

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
  int? get ageInDays => created_date?.let((date) =>
  DateTime.now().difference(date).inDays);

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
  String toString() => 'Spot(id: $spot_id, name: $spot_name, location: $fullLocation)';
}

/// Extension to add convenient null-safe operations
extension SpotExtensions on DateTime? {
  T? let<T>(T Function(DateTime) transform) {
    return this != null ? transform(this!) : null;
  }
}