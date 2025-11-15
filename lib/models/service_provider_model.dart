class ServiceProviderModel {
  final String id;
  final String name;
  final String phoneNumber;
  final double distanceKm;
  final double pricePerDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.distanceKm,
    required this.pricePerDay,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'distanceKm': distanceKm,
    'pricePerDay': pricePerDay,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) => ServiceProviderModel(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    distanceKm: json['distanceKm'],
    pricePerDay: json['pricePerDay'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  ServiceProviderModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    double? distanceKm,
    double? pricePerDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ServiceProviderModel(
    id: id ?? this.id,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    distanceKm: distanceKm ?? this.distanceKm,
    pricePerDay: pricePerDay ?? this.pricePerDay,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
