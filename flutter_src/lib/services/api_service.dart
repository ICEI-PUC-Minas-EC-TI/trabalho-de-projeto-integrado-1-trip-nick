import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/exceptions.dart';

/// Base service for all HTTP API calls
/// Handles authentication, error processing, and common request logic
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;

  /// Initialize the service (call this in main.dart)
  void initialize() {
    _client = http.Client();
  }

  /// Dispose resources (call when app closes)
  void dispose() {
    _client.close();
  }

  /// GET request with error handling
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    return _makeRequest('GET', endpoint, queryParameters: queryParameters);
  }

  /// POST request with error handling
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      body: body,
      queryParameters: queryParameters,
    );
  }

  /// DELETE request with error handling
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    return _makeRequest('DELETE', endpoint, queryParameters: queryParameters);
  }

  /// Core request method that handles all the common logic
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      // Build the complete URL
      final uri = _buildUri(endpoint, queryParameters);

      // Create the request
      final request = http.Request(method, uri);

      // Add headers
      request.headers.addAll(_getHeaders());

      // Add body for POST requests
      if (body != null) {
        request.body = json.encode(body);
      }

      // Send request with timeout
      final streamedResponse = await _client
          .send(request)
          .timeout(ApiConstants.requestTimeout);

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      // Process response
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sem conexão com a internet');
    } on http.ClientException {
      throw const NetworkException('Erro de conexão');
    } on FormatException {
      throw const DataException('Resposta inválida do servidor');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const NetworkException('Erro de rede desconhecido');
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final baseUri = Uri.parse(ApiConstants.baseUrl + endpoint);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return baseUri.replace(queryParameters: queryParameters);
    }

    return baseUri;
  }

  /// Get standard headers for all requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // TODO: Add authentication headers when needed
      // 'Authorization': 'Bearer $token',
    };
  }

  /// Process HTTP response and handle errors
  Map<String, dynamic> _processResponse(http.Response response) {
    // Success responses (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return responseData;
      } catch (e) {
        throw const DataException('Falha ao processar resposta do servidor');
      }
    }

    // Error responses
    String errorMessage = 'Erro desconhecido';

    try {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
    } catch (e) {
      // If we can't parse error response, use default message
      errorMessage = _getDefaultErrorMessage(response.statusCode);
    }

    throw ExceptionHelper.fromStatusCode(response.statusCode, errorMessage);
  }

  /// Get user-friendly error messages for common status codes
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requisição inválida';
      case 401:
        return 'Não autorizado';
      case 403:
        return 'Acesso negado';
      case 404:
        return 'Não encontrado';
      case 500:
        return 'Erro interno do servidor';
      case 502:
        return 'Servidor indisponível';
      case 503:
        return 'Serviço temporariamente indisponível';
      default:
        return 'Erro de servidor (${statusCode})';
    }
  }
}
