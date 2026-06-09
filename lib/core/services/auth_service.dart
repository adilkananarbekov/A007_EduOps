import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/auth_response.dart';
import '../models/user_role.dart';
import '../storage/secure_storage_service.dart';
import '../utils/remote_id_registry.dart';

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

    var authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    _apiClient.setAuthToken(authResponse.token);
    authResponse = await _hydrateAuthResponse(authResponse, emailHint: email);

    // Save authentication data
    await _storageService.saveAuthResponse(authResponse);
    await _storageService.saveSavedEmail(email);
    await _storageService.deleteSavedPassword();

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
    await _apiClient.post(
      ApiConstants.register,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': _normalizeRole(role),
      },
      includeAuth: false,
    );

    return login(email, password);
  }

  /// Register initial admin (public, first setup)
  Future<AuthResponse> registerInitial({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: 'ROLE_ADMIN',
    );
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

  Future<String?> getSavedEmail() async {
    return await _storageService.getSavedEmail();
  }

  Future<String?> getSavedPassword() async {
    return await _storageService.getSavedPassword();
  }

  Future<AuthResponse?> refreshSession() async {
    final currentAuth = await _storageService.getAuthResponse();
    final refreshToken = currentAuth?.refreshToken;
    if (currentAuth == null ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      return null;
    }

    final response = await _apiClient.post(
      ApiConstants.refresh,
      body: {'refreshToken': refreshToken},
      includeAuth: false,
    );

    final refreshed = AuthResponse.fromJson(response as Map<String, dynamic>);
    if (refreshed.token.isEmpty) {
      return null;
    }

    final merged = currentAuth.copyWith(
      token: refreshed.token,
      type: refreshed.type,
      refreshToken: refreshed.refreshToken ?? currentAuth.refreshToken,
    );

    _apiClient.setAuthToken(merged.token);
    await _storageService.saveAuthResponse(merged);
    return merged;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  /// Initialize auth state on app start
  Future<void> initialize() async {
    var authResponse = await _storageService.getAuthResponse();
    if (authResponse == null) {
      return;
    }

    _apiClient.setAuthToken(authResponse.token);
    authResponse = await _hydrateAuthResponse(authResponse);
    await _storageService.saveAuthResponse(authResponse);
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toUpperCase().replaceFirst('ROLE_', '');
    switch (normalized) {
      case 'ADMIN':
      case 'ADMINISTRATOR':
      case 'SUPER_ADMIN':
      case 'MANAGER':
      case 'MANAGEMENT':
      case 'ACCOUNTANT':
      case 'FINANCE':
        return 'manager';
      case 'TEACHER':
        return 'teacher';
      default:
        return 'student';
    }
  }

  Future<AuthResponse> _hydrateAuthResponse(
    AuthResponse authResponse, {
    String? emailHint,
  }) async {
    final email = (emailHint ?? authResponse.email).trim().toLowerCase();
    final nameFallback = _nameFromEmail(email);

    try {
      final response = await _apiClient.get('/auth/me');
      if (response is Map<String, dynamic>) {
        return _mergeUserProfile(authResponse, response, emailFallback: email);
      }
    } catch (_) {
      // Keep the stored token usable even if profile hydration is temporarily
      // unavailable; protected endpoints will still enforce the session.
    }

    return authResponse.copyWith(
      email: email.isNotEmpty ? email : authResponse.email,
      firstName: authResponse.firstName.isNotEmpty
          ? authResponse.firstName
          : nameFallback.$1,
      lastName: authResponse.lastName.isNotEmpty
          ? authResponse.lastName
          : nameFallback.$2,
    );
  }

  AuthResponse _mergeUserProfile(
    AuthResponse authResponse,
    Map<String, dynamic> json, {
    required String emailFallback,
  }) {
    final className = (json['className'] as String?)?.trim();
    final classGroupId = className == null || className.isEmpty
        ? authResponse.classGroupId
        : RemoteIdRegistry.localId(className, namespace: 'group_name');
    if (className != null && className.isNotEmpty && classGroupId != null) {
      RemoteIdRegistry.registerGroupName(classGroupId, className);
    }

    return authResponse.copyWith(
      userId: RemoteIdRegistry.localId(json['id'], namespace: 'user'),
      email: (json['email'] as String?)?.trim().toLowerCase() ?? emailFallback,
      firstName:
          (json['firstName'] as String?)?.trim() ??
          (json['first_name'] as String?)?.trim() ??
          authResponse.firstName,
      lastName:
          (json['lastName'] as String?)?.trim() ??
          (json['last_name'] as String?)?.trim() ??
          authResponse.lastName,
      role: UserRole.fromString(
        (json['role'] ?? authResponse.role.name).toString(),
      ),
      classGroupId: classGroupId,
    );
  }

  (String, String) _nameFromEmail(String email) {
    if (email.isEmpty) {
      return ('Student', '');
    }

    final localPart = email.split('@').first;
    final words = localPart
        .split(RegExp(r'[._\-]+'))
        .where((word) => word.trim().isNotEmpty)
        .map(_capitalize)
        .toList();

    if (words.isEmpty) {
      return ('Student', '');
    }

    if (words.length == 1) {
      return (words.first, '');
    }

    return (words.first, words.skip(1).join(' '));
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
  }
}
