import 'package:json_annotation/json_annotation.dart';

/// Enum representing the different types of posts in the system
@JsonEnum(valueField: 'value')
enum PostType {
  community('community'),
  review('review'),
  list('list');

  const PostType(this.value);

  /// The string value stored in the database
  final String value;

  /// Convert from string to enum
  static PostType fromString(String value) {
    switch (value) {
      case 'community':
        return PostType.community;
      case 'review':
        return PostType.review;
      case 'list':
        return PostType.list;
      default:
        throw ArgumentError('Unknown post type: $value');
    }
  }

  /// Convert enum to string for database storage
  @override
  String toString() => value;
}