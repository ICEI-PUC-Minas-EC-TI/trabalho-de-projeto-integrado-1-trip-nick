// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostImages _$PostImagesFromJson(Map<String, dynamic> json) => PostImages(
  post_id: (json['post_id'] as num).toInt(),
  image_id: (json['image_id'] as num).toInt(),
  image_order: (json['image_order'] as num).toInt(),
  is_thumbnail: json['is_thumbnail'] as bool,
  created_date:
      json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
);

Map<String, dynamic> _$PostImagesToJson(PostImages instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'image_id': instance.image_id,
      'image_order': instance.image_order,
      'is_thumbnail': instance.is_thumbnail,
      'created_date': instance.created_date?.toIso8601String(),
    };
