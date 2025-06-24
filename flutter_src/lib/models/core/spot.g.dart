// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spot _$SpotFromJson(Map<String, dynamic> json) => Spot(
  spot_id: (json['spot_id'] as num).toInt(),
  spot_name: json['spot_name'] as String,
  country: json['country'] as String,
  city: json['city'] as String,
  category: json['category'] as String,
  description: json['description'] as String?,
  created_date:
      json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
  spot_image_id: (json['spot_image_id'] as num?)?.toInt(),
  spot_image_url: json['spot_image_url'] as String?,
  spot_image_name: json['spot_image_name'] as String?,
  spot_image_content_type: json['spot_image_content_type'] as String?,
  spot_image_file_size: (json['spot_image_file_size'] as num?)?.toInt(),
);

Map<String, dynamic> _$SpotToJson(Spot instance) => <String, dynamic>{
  'spot_id': instance.spot_id,
  'spot_name': instance.spot_name,
  'country': instance.country,
  'city': instance.city,
  'category': instance.category,
  'description': instance.description,
  'created_date': instance.created_date?.toIso8601String(),
  'spot_image_id': instance.spot_image_id,
  'spot_image_url': instance.spot_image_url,
  'spot_image_name': instance.spot_image_name,
  'spot_image_content_type': instance.spot_image_content_type,
  'spot_image_file_size': instance.spot_image_file_size,
};
