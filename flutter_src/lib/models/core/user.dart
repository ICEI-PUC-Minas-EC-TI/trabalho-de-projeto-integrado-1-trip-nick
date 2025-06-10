import 'package:json_annotation/json_annotation.dart';
import 'image.dart';

part 'user.g.dart';

/// Model representing a user in the system
@JsonSerializable()
class User {
  final int user_id;
  final String display_name;
  final String username;
  final String user_email;
  final String hash_password;
  final DateTime creation_date;
  final DateTime last_update_date;
  final String? biography;

  // Foreign key relationship with Image
  final int? profile_image_id;

  // Optional related object (for lazy loading)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Image? profile_image;

  const User({
    required this.user_id,
    required this.display_name,
    required this.username,
    required this.user_email,
    required this.hash_password,
    required this.creation_date,
    required this.last_update_date,
    this.biography,
    this.profile_image_id,
    this.profile_image,
  });

  /// Creates a User instance from JSON data
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Converts this User instance to JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Helper method to check if user has a profile image
  bool get hasProfileImage => profile_image_id != null;

  /// Helper method to get profile image URL
  String? get profileImageUrl => profile_image?.blob_url;

  /// Helper method to check if user has a biography
  bool get hasBiography => biography != null && biography!.trim().isNotEmpty;

  /// Helper method to get user initials for avatar fallback
  String get initials {
    final names = display_name.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return username[0].toUpperCase();
  }

  /// Helper method to get account age in days
  int get accountAgeInDays => DateTime.now().difference(creation_date).inDays;

  /// Creates a copy of this user with updated profile image
  User copyWithProfileImage(Image? image) {
    return User(
      user_id: user_id,
      display_name: display_name,
      username: username,
      user_email: user_email,
      hash_password: hash_password,
      creation_date: creation_date,
      last_update_date: last_update_date,
      biography: biography,
      profile_image_id: image?.image_id ?? profile_image_id,
      profile_image: image,
    );
  }

  /// Creates a copy of this user with updated fields
  User copyWith({
    int? user_id,
    String? display_name,
    String? username,
    String? user_email,
    String? hash_password,
    DateTime? creation_date,
    DateTime? last_update_date,
    String? biography,
    int? profile_image_id,
    Image? profile_image,
  }) {
    return User(
      user_id: user_id ?? this.user_id,
      display_name: display_name ?? this.display_name,
      username: username ?? this.username,
      user_email: user_email ?? this.user_email,
      hash_password: hash_password ?? this.hash_password,
      creation_date: creation_date ?? this.creation_date,
      last_update_date: last_update_date ?? this.last_update_date,
      biography: biography ?? this.biography,
      profile_image_id: profile_image_id ?? this.profile_image_id,
      profile_image: profile_image ?? this.profile_image,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              user_id == other.user_id;

  @override
  int get hashCode => user_id.hashCode;

  @override
  String toString() => 'User(id: $user_id, username: $username, email: $user_email)';
}