/// Base exception class for all API-related errors
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Network connectivity issues
class NetworkException extends ApiException {
  const NetworkException(String message) : super(message);
}

/// Server returned an error (4xx, 5xx status codes)
class ServerException extends ApiException {
  const ServerException(String message, {int? statusCode})
    : super(message, statusCode: statusCode);
}

/// Data parsing/validation errors
class DataException extends ApiException {
  const DataException(String message) : super(message);
}

/// Resource not found (404)
class NotFoundException extends ApiException {
  const NotFoundException(String message) : super(message, statusCode: 404);
}

/// Request timeout
class TimeoutException extends ApiException {
  const TimeoutException(String message) : super(message);
}

/// Helper to convert HTTP status codes to appropriate exceptions
class ExceptionHelper {
  static ApiException fromStatusCode(int statusCode, String message) {
    switch (statusCode) {
      case 404:
        return NotFoundException(message);
      case 400:
      case 401:
      case 403:
      case 422:
        return ServerException(message, statusCode: statusCode);
      case 500:
      case 502:
      case 503:
        return ServerException(
          'Erro interno do servidor',
          statusCode: statusCode,
        );
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }
}
