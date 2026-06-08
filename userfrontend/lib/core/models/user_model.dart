class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profilePic;
  final String role;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? referralCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profilePic,
    required this.role,
    this.gender,
    this.dateOfBirth,
    this.referralCode,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      profilePic: map['profilePic'],
      role: map['role'] ?? 'user',
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      referralCode: map['referralCode'],
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
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'referralCode': referralCode,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? mobile,
    String? profilePic,
    String? role,
    String? gender,
    DateTime? dateOfBirth,
    String? referralCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      referralCode: referralCode ?? this.referralCode,
    );
  }
}
