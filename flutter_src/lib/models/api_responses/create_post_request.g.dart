// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCommunityPostRequest _$CreateCommunityPostRequestFromJson(
  Map<String, dynamic> json,
) => CreateCommunityPostRequest(
  title: json['title'] as String,
  description: json['description'] as String?,
  user_id: (json['user_id'] as num).toInt(),
  spot_ids:
      (json['spot_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
);

Map<String, dynamic> _$CreateCommunityPostRequestToJson(
  CreateCommunityPostRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'user_id': instance.user_id,
  'spot_ids': instance.spot_ids,
};

CreateCommunityPostResponse _$CreateCommunityPostResponseFromJson(
  Map<String, dynamic> json,
) => CreateCommunityPostResponse(
  success: json['success'] as bool,
  post_id: (json['post_id'] as num?)?.toInt(),
  list_id: (json['list_id'] as num?)?.toInt(),
  message: json['message'] as String?,
  error: json['error'] as String?,
  data:
      json['data'] == null
          ? null
          : CommunityPostData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateCommunityPostResponseToJson(
  CreateCommunityPostResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'post_id': instance.post_id,
  'list_id': instance.list_id,
  'message': instance.message,
  'error': instance.error,
  'data': instance.data,
};

CommunityPostData _$CommunityPostDataFromJson(Map<String, dynamic> json) =>
    CommunityPostData(
      post_id: (json['post_id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      user_id: (json['user_id'] as num).toInt(),
      created_date: DateTime.parse(json['created_date'] as String),
      list_id: (json['list_id'] as num).toInt(),
      spots_count: (json['spots_count'] as num).toInt(),
    );

Map<String, dynamic> _$CommunityPostDataToJson(CommunityPostData instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'user_id': instance.user_id,
      'created_date': instance.created_date.toIso8601String(),
      'list_id': instance.list_id,
      'spots_count': instance.spots_count,
    };

CreateListRequest _$CreateListRequestFromJson(Map<String, dynamic> json) =>
    CreateListRequest(
      list_name: json['list_name'] as String,
      is_public: json['is_public'] as bool,
    );

Map<String, dynamic> _$CreateListRequestToJson(CreateListRequest instance) =>
    <String, dynamic>{
      'list_name': instance.list_name,
      'is_public': instance.is_public,
    };

CreateListResponse _$CreateListResponseFromJson(Map<String, dynamic> json) =>
    CreateListResponse(
      success: json['success'] as bool,
      list_id: (json['list_id'] as num?)?.toInt(),
      message: json['message'] as String?,
      error: json['error'] as String?,
      data:
          json['data'] == null
              ? null
              : ListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateListResponseToJson(CreateListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'list_id': instance.list_id,
      'message': instance.message,
      'error': instance.error,
      'data': instance.data,
    };

ListData _$ListDataFromJson(Map<String, dynamic> json) => ListData(
  list_id: (json['list_id'] as num).toInt(),
  list_name: json['list_name'] as String,
  is_public: json['is_public'] as bool,
);

Map<String, dynamic> _$ListDataToJson(ListData instance) => <String, dynamic>{
  'list_id': instance.list_id,
  'list_name': instance.list_name,
  'is_public': instance.is_public,
};

AddSpotToListRequest _$AddSpotToListRequestFromJson(
  Map<String, dynamic> json,
) => AddSpotToListRequest(
  spot_id: (json['spot_id'] as num).toInt(),
  list_thumbnail_id: (json['list_thumbnail_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$AddSpotToListRequestToJson(
  AddSpotToListRequest instance,
) => <String, dynamic>{
  'spot_id': instance.spot_id,
  'list_thumbnail_id': instance.list_thumbnail_id,
};
