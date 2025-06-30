// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotList _$SpotListFromJson(Map<String, dynamic> json) => SpotList(
  list_id: (json['list_id'] as num).toInt(),
  list_name: json['list_name'] as String,
  is_public: json['is_public'] as bool,
);

Map<String, dynamic> _$SpotListToJson(SpotList instance) => <String, dynamic>{
  'list_id': instance.list_id,
  'list_name': instance.list_name,
  'is_public': instance.is_public,
};
