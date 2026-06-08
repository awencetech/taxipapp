class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profilePic;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profilePic,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      profilePic: map['profilePic'],
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'profilePic': profilePic,
      'role': role,
    };
  }
}
