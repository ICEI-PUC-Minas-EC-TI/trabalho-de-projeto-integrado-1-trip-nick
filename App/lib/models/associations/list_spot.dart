import 'package:json_annotation/json_annotation.dart';
import '../core/spot_list.dart';
import '../core/spot.dart';
import '../core/image.dart';

part 'list_spot.g.dart';

/// Association model representing the relationship between lists and spots
/// Corresponds to the List_has_Spot table in the database
@JsonSerializable()
class ListSpot {
  final int list_id;
  final int spot_id;
  final DateTime? created_date;
  final int? list_thumbnail_id;

  // Optional related objects (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final SpotList? list;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Spot? spot;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Image? list_thumbnail;

  const ListSpot({
    required this.list_id,
    required this.spot_id,
    this.created_date,
    this.list_thumbnail_id,
    this.list,
    this.spot,
    this.list_thumbnail,
  });

  /// Creates a ListSpot instance from JSON data
  factory ListSpot.fromJson(Map<String, dynamic> json) => _$ListSpotFromJson(json);

  /// Converts this ListSpot instance to JSON
  Map<String, dynamic> toJson() => _$ListSpotToJson(this);

  /// Helper method to check if association has a thumbnail
  bool get hasThumbnail => list_thumbnail_id != null;

  /// Helper method to get thumbnail URL
  String? get thumbnailUrl => list_thumbnail?.blob_url;

  /// Helper method to check if related objects are loaded
  bool get hasLoadedList => list != null;
  bool get hasLoadedSpot => spot != null;
  bool get hasLoadedThumbnail => list_thumbnail != null;

  /// Helper method to check if all related objects are loaded
  bool get isFullyLoaded => hasLoadedList && hasLoadedSpot;

  /// Helper method to get spot name if spot is loaded
  String? get spotName => spot?.spot_name;

  /// Helper method to get spot location if spot is loaded
  String? get spotLocation => spot?.fullLocation;

  /// Helper method to get spot category if spot is loaded
  String? get spotCategory => spot?.category;

  /// Helper method to get list name if list is loaded
  String? get listName => list?.list_name;

  /// Helper method to check if list is public (if list is loaded)
  bool? get isListPublic => list?.is_public;

  /// Helper method to get association age in days
  int? get ageInDays => ListSpotDateExtensions(created_date)?.let((date) =>
  DateTime.now().difference(date).inDays);

  /// Helper method to check if association is recent (less than 7 days)
  bool get isRecentlyAdded => ageInDays != null && ageInDays! < 7;

  /// Creates a copy with updated list
  ListSpot copyWithList(SpotList? list) {
    return ListSpot(
      list_id: list_id,
      spot_id: spot_id,
      created_date: created_date,
      list_thumbnail_id: list_thumbnail_id,
      list: list,
      spot: spot,
      list_thumbnail: list_thumbnail,
    );
  }

  /// Creates a copy with updated spot
  ListSpot copyWithSpot(Spot? spot) {
    return ListSpot(
      list_id: list_id,
      spot_id: spot_id,
      created_date: created_date,
      list_thumbnail_id: list_thumbnail_id,
      list: list,
      spot: spot,
      list_thumbnail: list_thumbnail,
    );
  }

  /// Creates a copy with updated thumbnail
  ListSpot copyWithThumbnail(Image? thumbnail) {
    return ListSpot(
      list_id: list_id,
      spot_id: spot_id,
      created_date: created_date,
      list_thumbnail_id: thumbnail?.image_id ?? list_thumbnail_id,
      list: list,
      spot: spot,
      list_thumbnail: thumbnail,
    );
  }

  /// Creates a copy with all related objects loaded
  ListSpot copyWithAllRelated({
    SpotList? list,
    Spot? spot,
    Image? thumbnail,
  }) {
    return ListSpot(
      list_id: list_id,
      spot_id: spot_id,
      created_date: created_date,
      list_thumbnail_id: list_thumbnail_id,
      list: list ?? this.list,
      spot: spot ?? this.spot,
      list_thumbnail: thumbnail ?? this.list_thumbnail,
    );
  }

  /// Creates a copy of this association with updated fields
  ListSpot copyWith({
    int? list_id,
    int? spot_id,
    DateTime? created_date,
    int? list_thumbnail_id,
    SpotList? list,
    Spot? spot,
    Image? list_thumbnail,
  }) {
    return ListSpot(
      list_id: list_id ?? this.list_id,
      spot_id: spot_id ?? this.spot_id,
      created_date: created_date ?? this.created_date,
      list_thumbnail_id: list_thumbnail_id ?? this.list_thumbnail_id,
      list: list ?? this.list,
      spot: spot ?? this.spot,
      list_thumbnail: list_thumbnail ?? this.list_thumbnail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ListSpot &&
              runtimeType == other.runtimeType &&
              list_id == other.list_id &&
              spot_id == other.spot_id;

  @override
  int get hashCode => Object.hash(list_id, spot_id);

  @override
  String toString() => 'ListSpot(list_id: $list_id, spot_id: $spot_id)';
}

/// Extension for null-safe DateTime operations (reused from Spot model)
extension ListSpotDateExtensions on DateTime? {
  T? let<T>(T Function(DateTime) transform) {
    return this != null ? transform(this!) : null;
  }
}