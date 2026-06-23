class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profilePic;
  final String role;
  final String? gender;
  final DateTime? dateOfBirth;
  final double ratings;
  final int numReviews;
  final int totalRides;
  final int rewards;
  final String membershipStatus;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profilePic,
    required this.role,
    this.gender,
    this.dateOfBirth,
    this.ratings = 5.0,
    this.numReviews = 0,
    this.totalRides = 0,
    this.rewards = 0,
    this.membershipStatus = 'Bronze',
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
      ratings: (map['ratings'] as num?)?.toDouble() ?? 5.0,
      numReviews: (map['numReviews'] as num?)?.toInt() ?? 0,
      totalRides: (map['totalRides'] as num?)?.toInt() ?? 0,
      rewards: (map['rewards'] as num?)?.toInt() ?? 0,
      membershipStatus: map['membershipStatus'] ?? 'Bronze',
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
      'ratings': ratings,
      'numReviews': numReviews,
      'totalRides': totalRides,
      'rewards': rewards,
      'membershipStatus': membershipStatus,
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
    double? ratings,
    int? numReviews,
    int? totalRides,
    int? rewards,
    String? membershipStatus,
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
      ratings: ratings ?? this.ratings,
      numReviews: numReviews ?? this.numReviews,
      totalRides: totalRides ?? this.totalRides,
      rewards: rewards ?? this.rewards,
      membershipStatus: membershipStatus ?? this.membershipStatus,
    );
  }
}
