class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? hostelBlock;
  final String? roomNumber;
  final String? avatar;
  final String? specialization;
  final bool isActive;
  final String language;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.hostelBlock,
    this.roomNumber,
    this.avatar,
    this.specialization,
    this.isActive = true,
    this.language = 'en',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      phone: json['phone'],
      hostelBlock: json['hostelBlock'],
      roomNumber: json['roomNumber'],
      avatar: json['avatar'],
      specialization: json['specialization'],
      isActive: json['isActive'] ?? true,
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'phone': phone, 'hostelBlock': hostelBlock, 'roomNumber': roomNumber,
    'avatar': avatar, 'specialization': specialization,
    'isActive': isActive, 'language': language,
  };
}
