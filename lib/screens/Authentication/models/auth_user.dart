class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.avatar,
    this.type = 'human',
  });
  final int id;
  final String type;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatar;
  String get contact => (email?.isNotEmpty ?? false) ? email! : (phone ?? '');
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num).toInt(),
    type: json['type']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    fullName:
        json['full_name']?.toString() ??
        json['name']?.toString() ??
        json['username']?.toString() ??
        '',
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
    avatar: (json['avatar_url'] ?? json['avatar'] ?? json['profile_image'])
        ?.toString(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'username': username,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'avatar': avatar,
  };
}
