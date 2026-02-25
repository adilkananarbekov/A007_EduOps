import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/auth_response.dart';
import '../storage/secure_storage_service.dart';

/// Service for handling authentication operations
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthService({
    required ApiClient apiClient,
    required SecureStorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      includeAuth: false,
    );

    final authResponse = AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );

    // Save authentication data
    await _storageService.saveAuthResponse(authResponse);

    // Set token in API client for subsequent requests
    _apiClient.setAuthToken(authResponse.token);

    return authResponse;
  }

  /// Register new user (admin only)
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    int? classGroupId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'classGroupId': ?classGroupId,
      },
    );

    final authResponse = AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );
    return authResponse;
  }

  /// Register initial admin (public, first setup)
  Future<AuthResponse> registerInitial({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerInitial,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'ADMIN',
      },
      includeAuth: false,
    );

    final authResponse = AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );

    // Save authentication data
    await _storageService.saveAuthResponse(authResponse);

    // Set token in API client
    _apiClient.setAuthToken(authResponse.token);

    return authResponse;
  }

  /// Logout current user
  Future<void> logout() async {
    // Clear stored authentication data
    await _storageService.clearAll();

    // Clear token from API client
    _apiClient.clearAuthToken();
  }

  /// Get current user from storage
  Future<AuthResponse?> getCurrentUser() async {
    return await _storageService.getAuthResponse();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  /// Initialize auth state on app start
  Future<void> initialize() async {
    final authResponse = await _storageService.getAuthResponse();
    if (authResponse != null) {
      _apiClient.setAuthToken(authResponse.token);
    }
  }
}
