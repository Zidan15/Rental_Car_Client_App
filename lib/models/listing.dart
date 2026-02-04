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
  
  // Location (Joined from provider_locations)
  final double? vehicleLat;
  final double? vehicleLng;
  final String? vehicleLocationName;

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
    this.vehicleLat,
    this.vehicleLng,
    this.vehicleLocationName,
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
      vehicleLat: (json['provider_locations'] != null && json['provider_locations']['lat'] != null)
          ? (json['provider_locations']['lat'] as num).toDouble()
          : null,
      vehicleLng: (json['provider_locations'] != null && json['provider_locations']['lng'] != null)
          ? (json['provider_locations']['lng'] as num).toDouble()
          : null,
      vehicleLocationName: json['provider_locations']?['name'],
    );
  }
}
