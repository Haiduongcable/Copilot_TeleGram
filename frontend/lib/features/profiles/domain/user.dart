class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.bio,
    this.department,
    this.role,
    this.avatarUrl,
    this.statusMessage,
    this.isActive = true,
    this.lastSeen,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: (json['name'] ?? json['full_name']) as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      department: json['department'] as String?,
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      statusMessage: json['statusMessage'] as String? ?? json['status_message'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String)
          : json['last_seen_at'] != null
              ? DateTime.tryParse(json['last_seen_at'] as String)
              : null,
      isAdmin: json['isAdmin'] as bool? ?? json['is_admin'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String name;
  final String username;
  final String? bio;
  final String? department;
  final String? role;
  final String? avatarUrl;
  final String? statusMessage;
  final bool isActive;
  final DateTime? lastSeen;
  final bool isAdmin;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'username': username,
      'bio': bio,
      'department': department,
      'role': role,
      'avatarUrl': avatarUrl,
      'statusMessage': statusMessage,
      'isActive': isActive,
      'lastSeen': lastSeen?.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? bio,
    String? department,
    String? role,
    String? avatarUrl,
    String? statusMessage,
    bool? isActive,
    DateTime? lastSeen,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      department: department ?? this.department,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
