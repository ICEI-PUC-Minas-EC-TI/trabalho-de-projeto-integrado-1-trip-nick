/// API Configuration and App Constants
class ApiConstants {
  static const String baseUrl = 'http://192.168.0.59:7071/api';

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
  // Image placeholders
  static const String defaultSpotImageUrl =
      'https://via.placeholder.com/400x200.png?text=Spot+Image';

  // Error messages
  static const String networkErrorMessage =
      'Verifique sua conexão com a internet';
  static const String serverErrorMessage =
      'Erro no servidor. Tente novamente mais tarde';
  static const String notFoundErrorMessage = 'Conteúdo não encontrado';
  static const String unexpectedErrorMessage =
      'Algo deu errado. Tente novamente';
}
