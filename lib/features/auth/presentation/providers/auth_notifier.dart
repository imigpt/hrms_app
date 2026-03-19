import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/auth/data/models/auth_login_model.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Status Enum
// ═══════════════════════════════════════════════════════════════════════════

enum AuthStatus {
  unauthenticated,
  checking,
  authenticated,
  loading,
  error,
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication State Class
// ═══════════════════════════════════════════════════════════════════════════

class AuthState extends Equatable {
  final bool isAuthenticated;
  final AuthUser? currentUser;
  final String? token;
  final bool isLoading;
  final bool isCheckingAuth;
  final String? errorMessage;
  final AuthStatus status;

  const AuthState({
    this.isAuthenticated = false,
    this.currentUser,
    this.token,
    this.isLoading = false,
    this.isCheckingAuth = false,
    this.errorMessage,
    this.status = AuthStatus.unauthenticated,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AuthUser? currentUser,
    String? token,
    bool? isLoading,
    bool? isCheckingAuth,
    String? errorMessage,
    AuthStatus? status,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    isAuthenticated,
    currentUser,
    token,
    isLoading,
    isCheckingAuth,
    errorMessage,
    status,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Notifier (Change Notifier Pattern)
// ═══════════════════════════════════════════════════════════════════════════

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorageService _tokenStorage;

  AuthState _state = const AuthState();

  AuthNotifier(
    this._authService,
    this._tokenStorage,
  );

  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Check authentication status on app startup
  /// Fast check using only cached data - profile refresh happens in background
  Future<void> checkAuthStatus() async {
    if (_state.isCheckingAuth) return;

    _setState(_state.copyWith(
      isCheckingAuth: true,
      status: AuthStatus.checking,
    ));

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        _setState(_state.copyWith(
          isCheckingAuth: false,
          isAuthenticated: false,
          status: AuthStatus.unauthenticated,
        ));
        return;
      }

      // For fast startup: use cached data without network call
      // Profile refresh will happen in background after navigation
      final userId = await _tokenStorage.getUserId();
      final userName = await _tokenStorage.getUserName();
      final userEmail = await _tokenStorage.getUserEmail();
      final userRole = await _tokenStorage.getUserRole();

      if (userId != null && userName != null) {
        final cachedUser = AuthUser(
          id: userId,
          employeeId: userId,
          name: userName,
          email: userEmail ?? '',
          role: userRole ?? 'employee',
        );

        _setState(_state.copyWith(
          isCheckingAuth: false,
          isAuthenticated: true,
          token: token,
          currentUser: cachedUser,
          status: AuthStatus.authenticated,
        ));

        // Fetch fresh profile in background (non-blocking)
        _authService.getMe(token).then((profile) {
          try {
            final user = AuthUser.fromJson(profile);
            _setState(_state.copyWith(currentUser: user));
          } catch (e) {
            print('⚠️  Background profile update failed: $e');
          }
        }).catchError((e) {
          print('⚠️  Background profile fetch error: $e');
        });
      } else {
        // No cached data, clear auth
        await _tokenStorage.clearLoginData();
        _setState(_state.copyWith(
          isCheckingAuth: false,
          isAuthenticated: false,
          status: AuthStatus.unauthenticated,
        ));
      }
    } catch (e) {
      print('❌ Auth check failed: $e');
      _setState(_state.copyWith(
        isCheckingAuth: false,
        isAuthenticated: false,
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to restore authentication',
      ));
    }
  }

  /// Attempt to restore auth from persistent storage without network call
  Future<void> restoreAuthFromStorage() async {
    try {
      final token = await _tokenStorage.getToken();
      final userId = await _tokenStorage.getUserId();
      final userName = await _tokenStorage.getUserName();
      final userEmail = await _tokenStorage.getUserEmail();
      final userRole = await _tokenStorage.getUserRole();

      if (token != null && userId != null && userName != null) {
        final user = AuthUser(
          id: userId,
          employeeId: userId,
          name: userName,
          email: userEmail ?? '',
          role: userRole ?? 'employee',
        );

        _setState(_state.copyWith(
          isAuthenticated: true,
          token: token,
          currentUser: user,
          status: AuthStatus.authenticated,
        ));
      }
    } catch (e) {
      print('⚠️  Failed to restore auth from storage: $e');
    }
  }

  /// Login with email/employeeId and password
  Future<void> login(
    String email,
    String password, {
    double? latitude,
    double? longitude,
  }) async {
    _setState(_state.copyWith(
      isLoading: true,
      status: AuthStatus.loading,
      errorMessage: null,
    ));

    try {
      // Call auth service
      final response = await _authService.login(
        email,
        password,
        latitude: latitude,
        longitude: longitude,
      );

      // Save token and user data
      await _tokenStorage.saveLoginData(
        token: response.token,
        userId: response.user.id,
        email: response.user.email,
        name: response.user.name,
        role: response.user.role,
      );

      // Update state
      _setState(_state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: response.token,
        currentUser: response.user,
        status: AuthStatus.authenticated,
      ));
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      print('❌ Login failed: $errorMsg');

      _setState(_state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: errorMsg,
      ));

      // Auto-clear error after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (_state.errorMessage == errorMsg) {
        _setState(_state.copyWith(errorMessage: null));
      }
    }
  }

  /// Logout and clear authentication
  Future<void> logout() async {
    _setState(_state.copyWith(
      isLoading: true,
      status: AuthStatus.loading,
    ));

    try {
      if (_state.token != null) {
        await _authService.logout(_state.token!);
      }

      // Clear stored data
      await _tokenStorage.clearLoginData();

      // Update state
      _setState(_state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        currentUser: null,
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    } catch (e) {
      print('⚠️  Logout error: $e');
      // Still clear local state even if server call fails
      await _tokenStorage.clearLoginData();

      _setState(_state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        currentUser: null,
        status: AuthStatus.unauthenticated,
      ));
    }
  }

  /// Request password reset code via email
  Future<void> forgotPassword(String email) async {
    _setState(_state.copyWith(
      isLoading: true,
      status: AuthStatus.loading,
      errorMessage: null,
    ));

    try {
      await _authService.forgotPassword(email);

      _setState(_state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
      ));
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      print('❌ Forgot password failed: $errorMsg');

      _setState(_state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: errorMsg,
      ));

      // Auto-clear error
      await Future.delayed(const Duration(seconds: 5));
      if (_state.errorMessage == errorMsg) {
        _setState(_state.copyWith(errorMessage: null));
      }
    }
  }

  /// Reset password using code from email
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    _setState(_state.copyWith(
      isLoading: true,
      status: AuthStatus.loading,
      errorMessage: null,
    ));

    try {
      await _authService.resetPassword(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
      );

      _setState(_state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
      ));
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      print('❌ Reset password failed: $errorMsg');

      _setState(_state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: errorMsg,
      ));

      // Auto-clear error
      await Future.delayed(const Duration(seconds: 5));
      if (_state.errorMessage == errorMsg) {
        _setState(_state.copyWith(errorMessage: null));
      }
    }
  }

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
  }

  /// Refresh token when expired
  Future<void> refreshToken() async {
    // TODO: Implement when backend provides refresh token endpoint
    print('🔄 Token refresh not yet implemented');
  }
}
