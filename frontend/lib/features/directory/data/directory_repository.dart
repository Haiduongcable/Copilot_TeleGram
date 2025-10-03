import '../../profiles/domain/user.dart';

abstract class DirectoryRepository {
  Future<List<User>> fetchUsers({String? query});
}
