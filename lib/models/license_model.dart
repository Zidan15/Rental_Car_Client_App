class LicenseModel {
  final String id;
  final String userId;
  final String licenseNumber;
  final String? frontPhotoUrl;
  final String? backPhotoUrl;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // New fields from OCR
  final String? holderName;
  final String? fatherName;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? address;
  final DateTime? validTill;
  final List<String>? vehicleClasses;
  final DateTime? issueDate;

  LicenseModel({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    this.frontPhotoUrl,
    this.backPhotoUrl,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.holderName,
    this.fatherName,
    this.dateOfBirth,
    this.bloodGroup,
    this.address,
    this.validTill,
    this.vehicleClasses,
    this.issueDate,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) => LicenseModel(
    id: json['id'],
    userId: json['user_id'],
    licenseNumber: json['license_number'],
    frontPhotoUrl: json['front_photo_url'],
    backPhotoUrl: json['back_photo_url'],
    verificationStatus: json['verification_status'] ?? 'pending',
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    holderName: json['holder_name'],
    fatherName: json['father_name'],
    dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
    bloodGroup: json['blood_group'],
    address: json['address'],
    validTill: json['valid_till'] != null ? DateTime.tryParse(json['valid_till']) : null,
    vehicleClasses: json['vehicle_classes'] != null 
        ? List<String>.from(json['vehicle_classes'])
        : null,
    issueDate: json['issue_date'] != null ? DateTime.tryParse(json['issue_date']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'license_number': licenseNumber,
    'front_photo_url': frontPhotoUrl,
    'back_photo_url': backPhotoUrl,
    'verification_status': verificationStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'holder_name': holderName,
    'father_name': fatherName,
    'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
    'blood_group': bloodGroup,
    'address': address,
    'valid_till': validTill?.toIso8601String().split('T').first,
    'vehicle_classes': vehicleClasses,
    'issue_date': issueDate?.toIso8601String().split('T').first,
  };

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}
