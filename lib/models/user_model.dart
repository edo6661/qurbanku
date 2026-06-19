import 'package:equatable/equatable.dart';

enum UserRole { admin, peserta }

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role'] as String?),
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      if (phone != null) 'phone': phone,
    };
  }

  UserModel copyWith({String? name, String? phone}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.peserta; // Default fallback
  }

  @override
  List<Object?> get props => [uid, name, email, role, phone];
}
