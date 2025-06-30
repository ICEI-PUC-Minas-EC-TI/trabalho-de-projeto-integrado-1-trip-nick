// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  user_id: (json['user_id'] as num).toInt(),
  display_name: json['display_name'] as String,
  username: json['username'] as String,
  user_email: json['user_email'] as String,
  hash_password: json['hash_password'] as String,
  creation_date: DateTime.parse(json['creation_date'] as String),
  last_update_date: DateTime.parse(json['last_update_date'] as String),
  biography: json['biography'] as String?,
  profile_image_id: (json['profile_image_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'user_id': instance.user_id,
  'display_name': instance.display_name,
  'username': instance.username,
  'user_email': instance.user_email,
  'hash_password': instance.hash_password,
  'creation_date': instance.creation_date.toIso8601String(),
  'last_update_date': instance.last_update_date.toIso8601String(),
  'biography': instance.biography,
  'profile_image_id': instance.profile_image_id,
};
