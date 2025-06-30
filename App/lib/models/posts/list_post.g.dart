// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListPost _$ListPostFromJson(Map<String, dynamic> json) => ListPost(
  post_id: (json['post_id'] as num).toInt(),
  description: json['description'] as String?,
  user_id: (json['user_id'] as num).toInt(),
  created_date: DateTime.parse(json['created_date'] as String),
  title: json['title'] as String,
  list_id: (json['list_id'] as num).toInt(),
);

Map<String, dynamic> _$ListPostToJson(ListPost instance) => <String, dynamic>{
  'post_id': instance.post_id,
  'description': instance.description,
  'user_id': instance.user_id,
  'created_date': instance.created_date.toIso8601String(),
  'title': instance.title,
  'list_id': instance.list_id,
};
