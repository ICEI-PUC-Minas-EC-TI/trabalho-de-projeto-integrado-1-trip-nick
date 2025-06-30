// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewPost _$ReviewPostFromJson(Map<String, dynamic> json) => ReviewPost(
  post_id: (json['post_id'] as num).toInt(),
  description: json['description'] as String?,
  user_id: (json['user_id'] as num).toInt(),
  created_date: DateTime.parse(json['created_date'] as String),
  spot_id: (json['spot_id'] as num).toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ReviewPostToJson(ReviewPost instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'description': instance.description,
      'user_id': instance.user_id,
      'created_date': instance.created_date.toIso8601String(),
      'spot_id': instance.spot_id,
      'rating': instance.rating,
    };
