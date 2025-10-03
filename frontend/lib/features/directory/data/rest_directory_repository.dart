import 'package:dio/dio.dart';

import '../../../flavors/flavor_config.dart';
import '../../profiles/domain/user.dart';
import 'directory_repository.dart';

class RestDirectoryRepository implements DirectoryRepository {
  RestDirectoryRepository(this._dio) : _config = FlavorConfig.instance;

  final Dio _dio;
  final FlavorConfig _config;

  String get _directoryPath => _config.apiEndpoints.directory;

  @override
  Future<List<User>> fetchUsers({String? query}) async {
    final response = await _dio.get<dynamic>(
      _directoryPath,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    final payload = response.data;
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic>
            ? payload['results'] as List<dynamic>? ?? payload['items'] as List<dynamic>? ?? []
            : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList(growable: false);
  }
}
