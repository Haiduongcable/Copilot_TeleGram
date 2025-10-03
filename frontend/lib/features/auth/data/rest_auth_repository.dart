import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';
import '../../../flavors/flavor_config.dart';
import '../../profiles/domain/user.dart';
import '../domain/auth_state.dart';
import 'auth_repository.dart';

class RestAuthRepository implements AuthRepository {
  RestAuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage,
        _config = FlavorConfig.instance;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final FlavorConfig _config;

  String get _authPath => _config.apiEndpoints.auth;

  @override
  Future<AuthState> bootstrap() async {
    debugPrint('RestAuthRepository.bootstrap: START');
    try {
      final token = await _tokenStorage.readAccessToken();
      debugPrint('RestAuthRepository.bootstrap: Token = ${token != null ? "EXISTS" : "NULL"}');
      if (token == null) {
        debugPrint('RestAuthRepository.bootstrap: No token, returning unauthenticated');
        return AuthState.unauthenticated();
      }
      try {
        debugPrint('RestAuthRepository.bootstrap: Fetching current user...');
        final me = await _fetchCurrentUser();
        debugPrint('RestAuthRepository.bootstrap: Got user: ${me.email}');
        return AuthState.authenticated(me);
      } on DioException catch (error) {
        debugPrint('RestAuthRepository.bootstrap: DioException: ${error.message}');
        if (error.response?.statusCode == 401) {
          await _tokenStorage.clear();
        }
        return AuthState.unauthenticated();
      }
    } catch (e, stackTrace) {
      debugPrint('RestAuthRepository.bootstrap: ERROR: $e');
      debugPrint('RestAuthRepository.bootstrap: STACK: $stackTrace');
      return AuthState.unauthenticated();
    }
  }

  @override
  Future<AuthState> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/login',
      data: {'email': email, 'password': password},
    );
    final body = response.data ?? <String, dynamic>{};
    final tokensJson = body['tokens'] as Map<String, dynamic>?;
    if (tokensJson != null) {
      final access = tokensJson['access_token'] as String?;
      final refresh = tokensJson['refresh_token'] as String?;
      if (access != null && refresh != null) {
        await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      }
    }
    final userJson = body['user'] as Map<String, dynamic>?;
    final user = userJson != null ? User.fromJson(userJson) : await _fetchCurrentUser();
    return AuthState.authenticated(user);
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken != null) {
        await _dio.post('$_authPath/logout', data: {'refresh_token': refreshToken});
      }
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    // Generate username from email
    final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/register',
      data: {
        'full_name': name,
        'username': username,
        'email': email,
        'password': password,
        'department': department,
      },
    );
    final user = User.fromJson(response.data ?? <String, dynamic>{});
    
    // After registration, login to get tokens
    final loginState = await login(email: email, password: password);
    return loginState.user!;
  }

  @override
  Future<AuthState> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return AuthState.unauthenticated();
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/refresh',
      data: {'refresh_token': refreshToken},
    );
    final body = response.data ?? <String, dynamic>{};
    final access = body['access_token'] as String?;
    final refresh = body['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
    }
    final user = await _fetchCurrentUser();
    return AuthState.authenticated(user);
  }

  Future<User> _fetchCurrentUser() async {
    final usersPath = _config.apiEndpoints.directory;
    final response = await _dio.get<Map<String, dynamic>>('$usersPath/me');
    final data = response.data ?? <String, dynamic>{};
    return User.fromJson(data);
  }

  Future<void> _persistTokens(Map<String, dynamic> payload) async {
    final tokens = payload['tokens'] as Map<String, dynamic>? ?? payload;
    final access = tokens['accessToken'] as String? ?? tokens['access_token'] as String?;
    final refresh = tokens['refreshToken'] as String? ?? tokens['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
    }
  }
}
