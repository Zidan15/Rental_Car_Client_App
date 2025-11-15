class LicenseModel {
  final String id;
  final String userId;
  final String licenseNumber;
  final String? frontPhotoPath;
  final String? backPhotoPath;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  LicenseModel({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    this.frontPhotoPath,
    this.backPhotoPath,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'licenseNumber': licenseNumber,
    'frontPhotoPath': frontPhotoPath,
    'backPhotoPath': backPhotoPath,
    'verificationStatus': verificationStatus,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LicenseModel.fromJson(Map<String, dynamic> json) => LicenseModel(
    id: json['id'],
    userId: json['userId'],
    licenseNumber: json['licenseNumber'],
    frontPhotoPath: json['frontPhotoPath'],
    backPhotoPath: json['backPhotoPath'],
    verificationStatus: json['verificationStatus'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  LicenseModel copyWith({
    String? id,
    String? userId,
    String? licenseNumber,
    String? frontPhotoPath,
    String? backPhotoPath,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LicenseModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    frontPhotoPath: frontPhotoPath ?? this.frontPhotoPath,
    backPhotoPath: backPhotoPath ?? this.backPhotoPath,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
