import '../models/api_responses/spots_response.dart';
import '../models/core/spot.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Service for all spots-related API operations
class SpotsService {
  final ApiService _apiService = ApiService();

  /// Get list of spots with optional filtering and pagination
  /// This calls GET /api/spots from your Azure API
  Future<SpotsListResponse> getSpots({
    int page = 1,
    int limit = 20,
    String? category,
    String? country,
    String? city,
    String? search,
    String orderBy = 'created_date',
    String order = 'desc',
    bool includeImages = true,
    bool includeStats = false,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'orderBy': orderBy,
      'order': order,
      'includeImages': includeImages.toString(),
      'includeStats': includeStats.toString(),
    };

    // Add optional filters
    if (category != null) queryParams['category'] = category;
    if (country != null) queryParams['country'] = country;
    if (city != null) queryParams['city'] = city;
    if (search != null) queryParams['search'] = search;

    // Make the API call
    final response = await _apiService.get(
      ApiConstants.spotsEndpoint,
      queryParameters: queryParams,
    );

    // Convert response to our model
    return SpotsListResponse.fromJson(response);
  }

  /// Get a single spot by ID
  /// This calls GET /api/spots/{id} from your Azure API
  Future<SpotResponse> getSpotById(
    int spotId, {
    bool includeImages = true,
  }) async {
    final queryParams = <String, String>{
      'includeImages': includeImages.toString(),
    };

    final response = await _apiService.get(
      '${ApiConstants.spotsEndpoint}/$spotId',
      queryParameters: queryParams,
    );

    return SpotResponse.fromJson(response);
  }

  /// Get trending spots (newest spots for now)
  /// Later we can add more sophisticated trending logic
  Future<List<Spot>> getTrendingSpots({int limit = 10}) async {
    final response = await getSpots(
      limit: limit,
      orderBy: 'created_date',
      order: 'desc',
      includeImages: true,
    );

    return response.spots;
  }

  /// Get spots by category for filtering
  Future<List<Spot>> getSpotsByCategory(
    String category, {
    int limit = 20,
  }) async {
    final response = await getSpots(
      limit: limit,
      category: category,
      includeImages: true,
    );

    return response.spots;
  }

  /// Search spots by name, description, or location
  Future<List<Spot>> searchSpots(String searchTerm, {int limit = 20}) async {
    if (searchTerm.trim().isEmpty) {
      return []; // Return empty list for empty search
    }

    final response = await getSpots(
      limit: limit,
      search: searchTerm,
      includeImages: true,
    );

    return response.spots;
  }
}
