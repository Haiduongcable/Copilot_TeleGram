import '../../profiles/domain/user.dart';
import 'directory_repository.dart';

class MockDirectoryRepository implements DirectoryRepository {
  const MockDirectoryRepository();

  @override
  Future<List<User>> fetchUsers({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final users = List.generate(
      32,
      (index) => User(
        id: 'directory-user-$index',
        email: 'member$index@example.com',
        name: 'Member $index',
        username: 'member$index',
        department: index % 3 == 0
            ? 'Engineering'
            : index % 3 == 1
                ? 'Design'
                : 'Operations',
        role: index % 3 == 0
            ? 'Software Engineer'
            : index % 3 == 1
                ? 'Product Designer'
                : 'Ops Specialist',
        statusMessage: index % 2 == 0 ? 'Available' : 'Away',
        lastSeen: DateTime.now().subtract(Duration(minutes: index * 5)),
        isAdmin: index % 10 == 0,
      ),
    );
    if (query == null || query.isEmpty) {
      return users;
    }
    final lower = query.toLowerCase();
    return users
        .where(
          (user) => user.name.toLowerCase().contains(lower) ||
              user.username.toLowerCase().contains(lower) ||
              user.email.toLowerCase().contains(lower),
        )
        .toList(growable: false);
  }
}
