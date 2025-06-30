/// API Configuration and App Constants
class ApiConstants {
  static const String baseUrl = 'https://tripnick-api.azurewebsites.net/api';

  // API Endpoints
  static const String spotsEndpoint = '/spots';
  static const String postsEndpoint = '/posts';
  static const String listsEndpoint = '/lists';

  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// App-wide constants
class AppConstants {
  static const Map<String, String> categoryPlaceholders = {
    'Praia':
        'https://images.unsplash.com/photo-1483683804023-6ccdb62f86ef?w=400&h=300&fit=crop',
    'Cachoeira':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
    'Montanha':
        'https://images.unsplash.com/photo-1464822759844-d150baec95b4?w=400&h=300&fit=crop',
    'Parque Nacional':
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=300&fit=crop',
    'Centro Histórico':
        'https://images.unsplash.com/photo-1518105779142-d975f22f1b0a?w=400&h=300&fit=crop',
    'Museu':
        'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop',
    'Igreja':
        'https://images.unsplash.com/photo-1520637836862-4d197d17c92a?w=400&h=300&fit=crop',
    'Mirante':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
    'Trilha':
        'https://images.unsplash.com/photo-1501436513145-30f24e19fcc4?w=400&h=300&fit=crop',
    'Lagoa':
        'https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=400&h=300&fit=crop',
    'Rio':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
    'Gruta':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
    'default':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400&h=300&fit=crop',
  };

  /// Get appropriate placeholder image for a category
  static String getPlaceholderImage(String category) {
    return categoryPlaceholders[category] ?? categoryPlaceholders['default']!;
  }

  /// Get image URL with fallback strategy
  static String getImageUrlWithFallback(String? imageUrl, String category) {
    // If we have a valid image URL, use it
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    // Otherwise, use category-appropriate placeholder
    return getPlaceholderImage(category);
  }

  // Error messages
  static const String networkErrorMessage =
      'Verifique sua conexão com a internet';
  static const String serverErrorMessage =
      'Erro no servidor. Tente novamente mais tarde';
  static const String notFoundErrorMessage = 'Conteúdo não encontrado';
  static const String unexpectedErrorMessage =
      'Algo deu errado. Tente novamente';
}
