import 'package:json_annotation/json_annotation.dart';

part 'spot_list.g.dart';

/// Model representing a list (collection) of spots in the system
@JsonSerializable()
class SpotList {
  final int list_id;
  final String list_name;
  final bool is_public;

  const SpotList({
    required this.list_id,
    required this.list_name,
    required this.is_public,
  });

  /// Creates a SpotList instance from JSON data
  factory SpotList.fromJson(Map<String, dynamic> json) => _$SpotListFromJson(json);

  /// Converts this SpotList instance to JSON
  Map<String, dynamic> toJson() => _$SpotListToJson(this);

  /// Helper method to check if list is private
  bool get isPrivate => !is_public;

  /// Helper method to get list visibility status as string
  String get visibilityStatus => is_public ? 'Público' : 'Privado';

  /// Helper method to get list visibility icon
  String get visibilityIcon => is_public ? '🌐' : '🔒';

  /// Helper method to check if list name is valid (not empty)
  bool get hasValidName => list_name.trim().isNotEmpty;

  /// Helper method to get trimmed list name
  String get trimmedName => list_name.trim();

  /// Helper method to get list name with visibility indicator
  String get nameWithVisibility => '$list_name ($visibilityStatus)';

  /// Creates a copy of this list with updated fields
  SpotList copyWith({
    int? list_id,
    String? list_name,
    bool? is_public,
  }) {
    return SpotList(
      list_id: list_id ?? this.list_id,
      list_name: list_name ?? this.list_name,
      is_public: is_public ?? this.is_public,
    );
  }

  /// Creates a copy of this list with toggled privacy
  SpotList togglePrivacy() {
    return copyWith(is_public: !is_public);
  }

  /// Creates a copy of this list as public
  SpotList makePublic() {
    return copyWith(is_public: true);
  }

  /// Creates a copy of this list as private
  SpotList makePrivate() {
    return copyWith(is_public: false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpotList &&
              runtimeType == other.runtimeType &&
              list_id == other.list_id;

  @override
  int get hashCode => list_id.hashCode;

  @override
  String toString() => 'SpotList(id: $list_id, name: $list_name, public: $is_public)';
}