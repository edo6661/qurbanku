import 'package:equatable/equatable.dart';

enum UserRole { admin, peserta }

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'name': name, 'email': email, 'role': role.name};
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.peserta; // Default fallback
  }

  @override
  List<Object?> get props => [uid, name, email, role];
}
