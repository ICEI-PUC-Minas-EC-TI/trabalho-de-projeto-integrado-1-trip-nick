import 'package:json_annotation/json_annotation.dart';

part 'image.g.dart';

/// Model representing an image stored in the system
@JsonSerializable()
class Image {
  final int image_id;
  final String? image_name;
  final String? blob_url;
  final String? content_type;
  final int? file_size;
  final DateTime? created_date;

  const Image({
    required this.image_id,
    this.image_name,
    this.blob_url,
    this.content_type,
    this.file_size,
    this.created_date,
  });

  /// Creates an Image instance from JSON data
  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  /// Converts this Image instance to JSON
  Map<String, dynamic> toJson() => _$ImageToJson(this);

  /// Helper method to check if image has a valid URL
  bool get hasValidUrl => blob_url != null && blob_url!.isNotEmpty;

  /// Helper method to get file size in KB
  double? get fileSizeInKB => file_size != null ? file_size! / 1024.0 : null;

  /// Helper method to get file size in MB
  double? get fileSizeInMB => file_size != null ? file_size! / (1024.0 * 1024.0) : null;

  /// Helper method to check if image is a specific content type
  bool isContentType(String type) => content_type?.toLowerCase() == type.toLowerCase();

  /// Helper method to check if image is a JPEG
  bool get isJpeg => isContentType('image/jpeg');

  /// Helper method to check if image is a PNG
  bool get isPng => isContentType('image/png');

  /// Helper method to check if image is a WebP
  bool get isWebp => isContentType('image/webp');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Image &&
              runtimeType == other.runtimeType &&
              image_id == other.image_id;

  @override
  int get hashCode => image_id.hashCode;

  @override
  String toString() => 'Image(id: $image_id, name: $image_name, url: $blob_url)';
}