import 'package:json_annotation/json_annotation.dart';
import '../core/spot.dart';

part 'spots_response.g.dart';

/// Response model for GET /api/spots (single spot)
@JsonSerializable()
class SpotResponse {
  final bool success;
  final Spot spot;

  const SpotResponse({required this.success, required this.spot});

  factory SpotResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SpotResponseToJson(this);
}

/// Response model for GET /api/spots (multiple spots with pagination)
@JsonSerializable()
class SpotsListResponse {
  final bool success;
  final List<Spot> spots;
  final PaginationInfo? pagination;
  final QueryInfo? query_info;

  const SpotsListResponse({
    required this.success,
    required this.spots,
    this.pagination,
    this.query_info,
  });

  factory SpotsListResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SpotsListResponseToJson(this);
}

/// Pagination information from API
@JsonSerializable()
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int total_pages;
  final bool has_next;
  final bool has_previous;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.total_pages,
    required this.has_next,
    required this.has_previous,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}

/// Query information from API
@JsonSerializable()
class QueryInfo {
  final String ordered_by;
  final String order_direction;
  final bool includes_images;
  final bool includes_stats;

  const QueryInfo({
    required this.ordered_by,
    required this.order_direction,
    required this.includes_images,
    required this.includes_stats,
  });

  factory QueryInfo.fromJson(Map<String, dynamic> json) =>
      _$QueryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$QueryInfoToJson(this);
}
