// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
  image_id: (json['image_id'] as num).toInt(),
  image_name: json['image_name'] as String?,
  blob_url: json['blob_url'] as String?,
  content_type: json['content_type'] as String?,
  file_size: (json['file_size'] as num?)?.toInt(),
  created_date:
      json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
);

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
  'image_id': instance.image_id,
  'image_name': instance.image_name,
  'blob_url': instance.blob_url,
  'content_type': instance.content_type,
  'file_size': instance.file_size,
  'created_date': instance.created_date?.toIso8601String(),
};
