import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

/// State notifier for managing authentication state
class AuthNotifier extends StateNotifier<AsyncValue<AuthResponse?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  /// Initialize auth state from storage
  Future<void> _initialize() async {
    debugPrint('[AUTH] _initialize started');
    try {
      await _authService.initialize();
      debugPrint('[AUTH] _authService.initialize() done');
      final user = await _authService.getCurrentUser();
      debugPrint('[AUTH] getCurrentUser returned: ${user?.email ?? 'null'}');
      state = AsyncValue.data(user);
      debugPrint('[AUTH] State set to data (isLoading=false)');
    } catch (e, stack) {
      debugPrint('[AUTH] _initialize ERROR: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authResponse = await _authService.login(email, password);
      state = AsyncValue.data(authResponse);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Refresh current user data
  Future<void> refresh() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Handle global unauthorized responses (e.g. expired JWT)
  Future<void> handleUnauthorized() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
