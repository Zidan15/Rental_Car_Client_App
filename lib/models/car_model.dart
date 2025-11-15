class CarModel {
  final String id;
  final String name;
  final String category;
  final String transmission;
  final String fuelType;
  final int seats;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarModel({
    required this.id,
    required this.name,
    required this.category,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'transmission': transmission,
    'fuelType': fuelType,
    'seats': seats,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    transmission: json['transmission'],
    fuelType: json['fuelType'],
    seats: json['seats'],
    imageUrl: json['imageUrl'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  CarModel copyWith({
    String? id,
    String? name,
    String? category,
    String? transmission,
    String? fuelType,
    int? seats,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CarModel(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    transmission: transmission ?? this.transmission,
    fuelType: fuelType ?? this.fuelType,
    seats: seats ?? this.seats,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
