/// Represents a vehicle listing available for rent.
/// Now reads directly from the vehicles table (merged architecture).
class Listing {
  final String id;
  final String? ownerId;
  final double pricePerDay;
  final bool isListed;
  final DateTime? createdAt;
  
  // Vehicle details
  final String? brand;
  final String? model;
  final int? year;
  final String? fuelType;
  final String? transmission;
  final String? category;
  final String? color;
  final String? plateNumber;
  final String? imageUrl;

  Listing({
    required this.id,
    this.ownerId,
    required this.pricePerDay,
    required this.isListed,
    this.createdAt,
    this.brand,
    this.model,
    this.year,
    this.fuelType,
    this.transmission,
    this.category,
    this.color,
    this.plateNumber,
    this.imageUrl,
  });

  /// Creates a Listing from vehicles table JSON (merged architecture)
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      ownerId: json['owner_id'],
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      isListed: json['is_listed'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      fuelType: json['fuel_type'],
      transmission: json['transmission'],
      category: json['category'],
      color: json['color'],
      plateNumber: json['plate_number'],
      imageUrl: json['image_url'],
    );
  }
}
