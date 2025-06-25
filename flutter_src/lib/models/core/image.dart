/// Fixed Image model with proper JSON parsing
///
/// Replace your existing Image.fromJson method with this one:

class Image {
  final int? image_id;
  final String? image_name;
  final String? blob_url;
  final String? thumbnail_url;
  final String? content_type;
  final int? file_size;
  final DateTime? created_date;

  const Image({
    this.image_id,
    this.image_name,
    this.blob_url,
    this.thumbnail_url,
    this.content_type,
    this.file_size,
    this.created_date,
  });

  /// Creates an Image from JSON response with proper type handling
  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      // Fix: Handle both string and int for image_id
      image_id: _parseToInt(json['image_id']),
      image_name: json['image_name'] as String?,
      blob_url: json['blob_url'] as String?,
      thumbnail_url: json['thumbnail_url'] as String?,
      content_type: json['content_type'] as String?,
      // Fix: Handle both string and int for file_size
      file_size: _parseToInt(json['file_size']),
      created_date:
          json['created_date'] != null
              ? DateTime.parse(json['created_date'])
              : null,
    );
  }

  /// Helper method to safely parse int from dynamic value
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Converts Image to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'image_id': image_id,
      'image_name': image_name,
      'blob_url': blob_url,
      'thumbnail_url': thumbnail_url,
      'content_type': content_type,
      'file_size': file_size,
      'created_date': created_date?.toIso8601String(),
    };
  }

  /// Creates a copy of this Image with updated fields
  Image copyWith({
    int? image_id,
    String? image_name,
    String? blob_url,
    String? thumbnail_url,
    String? content_type,
    int? file_size,
    DateTime? created_date,
  }) {
    return Image(
      image_id: image_id ?? this.image_id,
      image_name: image_name ?? this.image_name,
      blob_url: blob_url ?? this.blob_url,
      thumbnail_url: thumbnail_url ?? this.thumbnail_url,
      content_type: content_type ?? this.content_type,
      file_size: file_size ?? this.file_size,
      created_date: created_date ?? this.created_date,
    );
  }

  /// Checks if this image has a valid blob URL
  bool get hasValidUrl => blob_url != null && blob_url!.isNotEmpty;

  /// Checks if this image has a thumbnail
  bool get hasThumbnail => thumbnail_url != null && thumbnail_url!.isNotEmpty;

  /// Gets the display URL (thumbnail if available, otherwise full image)
  String? get displayUrl => hasThumbnail ? thumbnail_url : blob_url;

  /// Gets file size in a human-readable format
  String get formattedFileSize {
    if (file_size == null) return 'Unknown size';

    final bytes = file_size!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'Image(id: $image_id, name: $image_name, size: $formattedFileSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Image && other.image_id == image_id;
  }

  @override
  int get hashCode => image_id.hashCode;
}
