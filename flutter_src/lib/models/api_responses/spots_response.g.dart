// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spots_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotResponse _$SpotResponseFromJson(Map<String, dynamic> json) => SpotResponse(
  success: json['success'] as bool,
  spot: Spot.fromJson(json['spot'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SpotResponseToJson(SpotResponse instance) =>
    <String, dynamic>{'success': instance.success, 'spot': instance.spot};

SpotsListResponse _$SpotsListResponseFromJson(Map<String, dynamic> json) =>
    SpotsListResponse(
      success: json['success'] as bool,
      spots:
          (json['spots'] as List<dynamic>)
              .map((e) => Spot.fromJson(e as Map<String, dynamic>))
              .toList(),
      pagination:
          json['pagination'] == null
              ? null
              : PaginationInfo.fromJson(
                json['pagination'] as Map<String, dynamic>,
              ),
      query_info:
          json['query_info'] == null
              ? null
              : QueryInfo.fromJson(json['query_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpotsListResponseToJson(SpotsListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'spots': instance.spots,
      'pagination': instance.pagination,
      'query_info': instance.query_info,
    };

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) =>
    PaginationInfo(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      total_pages: (json['total_pages'] as num).toInt(),
      has_next: json['has_next'] as bool,
      has_previous: json['has_previous'] as bool,
    );

Map<String, dynamic> _$PaginationInfoToJson(PaginationInfo instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'total_pages': instance.total_pages,
      'has_next': instance.has_next,
      'has_previous': instance.has_previous,
    };

QueryInfo _$QueryInfoFromJson(Map<String, dynamic> json) => QueryInfo(
  ordered_by: json['ordered_by'] as String,
  order_direction: json['order_direction'] as String,
  includes_images: json['includes_images'] as bool,
  includes_stats: json['includes_stats'] as bool,
);

Map<String, dynamic> _$QueryInfoToJson(QueryInfo instance) => <String, dynamic>{
  'ordered_by': instance.ordered_by,
  'order_direction': instance.order_direction,
  'includes_images': instance.includes_images,
  'includes_stats': instance.includes_stats,
};
