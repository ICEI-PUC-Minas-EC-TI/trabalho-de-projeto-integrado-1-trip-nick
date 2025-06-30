import 'package:flutter/foundation.dart';
import '../models/core/spot.dart';
import '../services/spots_service.dart';
import '../utils/exceptions.dart';

/// State management for spots data
/// Handles loading, error states, and data caching
class SpotsProvider extends ChangeNotifier {
  final SpotsService _spotsService = SpotsService();

  // State variables
  List<Spot> _trendingSpots = [];
  List<Spot> _allSpots = [];
  bool _isLoadingTrending = false;
  bool _isLoadingSpots = false;
  String? _errorMessage;

  // Cache control
  DateTime? _lastTrendingUpdate;
  DateTime? _lastSpotsUpdate;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // Getters - UI reads these values
  List<Spot> get trendingSpots => _trendingSpots;
  List<Spot> get allSpots => _allSpots;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingSpots => _isLoadingSpots;
  String? get errorMessage => _errorMessage;
  bool get hasTrendingData => _trendingSpots.isNotEmpty;
  bool get hasError => _errorMessage != null;

  /// Load trending spots (newest spots)
  /// Called by Trending Screen
  Future<void> loadTrendingSpots({bool forceRefresh = false}) async {
    // Check if we have fresh cached data
    if (!forceRefresh && _hasFreshTrendingData()) {
      return; // Use cached data
    }

    _isLoadingTrending = true;
    _errorMessage = null;
    notifyListeners(); // Tell UI "I'm loading!"

    try {
      final spots = await _spotsService.getTrendingSpots(limit: 10);

      _trendingSpots = spots;
      _lastTrendingUpdate = DateTime.now();
      _isLoadingTrending = false;
      _errorMessage = null;

      notifyListeners(); // Tell UI "I have new data!"
    } catch (e) {
      _isLoadingTrending = false;
      _errorMessage = _getErrorMessage(e);

      notifyListeners(); // Tell UI "Something went wrong!"

      // Log error for debugging
      debugPrint('Error loading trending spots: $e');
    }
  }

  /// Load all spots with pagination (for future use)
  Future<void> loadSpots({
    int page = 1,
    int limit = 20,
    String? category,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && page == 1 && _hasFreshSpotsData()) {
      return; // Use cached data for first page
    }

    _isLoadingSpots = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _spotsService.getSpots(
        page: page,
        limit: limit,
        category: category,
      );

      if (page == 1) {
        // First page - replace all data
        _allSpots = response.spots;
      } else {
        // Additional pages - append data
        _allSpots.addAll(response.spots);
      }

      _lastSpotsUpdate = DateTime.now();
      _isLoadingSpots = false;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _isLoadingSpots = false;
      _errorMessage = _getErrorMessage(e);

      notifyListeners();
      debugPrint('Error loading spots: $e');
    }
  }

  /// Search for spots
  Future<List<Spot>> searchSpots(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    try {
      return await _spotsService.searchSpots(searchTerm);
    } catch (e) {
      debugPrint('Error searching spots: $e');
      return [];
    }
  }

  /// Get spots by category
  Future<List<Spot>> getSpotsByCategory(String category) async {
    try {
      return await _spotsService.getSpotsByCategory(category);
    } catch (e) {
      debugPrint('Error loading spots by category: $e');
      return [];
    }
  }

  /// Refresh trending spots (pull-to-refresh)
  Future<void> refreshTrendingSpots() async {
    await loadTrendingSpots(forceRefresh: true);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if trending data is fresh (within cache timeout)
  bool _hasFreshTrendingData() {
    if (_lastTrendingUpdate == null) return false;
    return DateTime.now().difference(_lastTrendingUpdate!) < cacheTimeout;
  }

  /// Check if spots data is fresh
  bool _hasFreshSpotsData() {
    if (_lastSpotsUpdate == null) return false;
    return DateTime.now().difference(_lastSpotsUpdate!) < cacheTimeout;
  }

  /// Convert exceptions to user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Verifique sua conexão com a internet';
    } else if (error is ServerException) {
      return 'Erro no servidor. Tente novamente mais tarde';
    } else if (error is NotFoundException) {
      return 'Nenhum spot encontrado';
    } else if (error is TimeoutException) {
      return 'Tempo limite esgotado. Tente novamente';
    } else {
      return 'Algo deu errado. Tente novamente';
    }
  }

  /// Get trending spots for a specific category (helper method)
  List<Spot> getTrendingByCategory(String category) {
    return _trendingSpots
        .where((spot) => spot.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get unique categories from trending spots
  List<String> getTrendingCategories() {
    final categories =
        _trendingSpots.map((spot) => spot.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
