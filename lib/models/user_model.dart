class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'address': address,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    fullName: json['fullName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    address: json['address'],
    dateOfBirth: DateTime.parse(json['dateOfBirth']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    address: address ?? this.address,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
