// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListSpot _$ListSpotFromJson(Map<String, dynamic> json) => ListSpot(
  list_id: (json['list_id'] as num).toInt(),
  spot_id: (json['spot_id'] as num).toInt(),
  created_date:
      json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
  list_thumbnail_id: (json['list_thumbnail_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$ListSpotToJson(ListSpot instance) => <String, dynamic>{
  'list_id': instance.list_id,
  'spot_id': instance.spot_id,
  'created_date': instance.created_date?.toIso8601String(),
  'list_thumbnail_id': instance.list_thumbnail_id,
};
