/// Represents a booking made by a renter.
class BookingModel {
  final String id;
  final String renterId;
  final String vehicleId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final DateTime bookingDate;
  final String? pickupLocation;
  
  // Vehicle details from join
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;

  BookingModel({
    required this.id,
    required this.renterId,
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.bookingDate,
    this.pickupLocation,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;
  
  String get vehicleDisplayName {
    if (vehicleBrand != null && vehicleModel != null) {
      return '$vehicleYear $vehicleBrand $vehicleModel';
    }
    return 'Vehicle #${vehicleId.substring(0, 8)}...';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'],
      renterId: json['renter_id'],
      vehicleId: json['vehicle_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      bookingDate: DateTime.parse(json['created_at']),
      pickupLocation: json['pickup_location'],
      vehicleBrand: vehicleData?['brand'],
      vehicleModel: vehicleData?['model'],
      vehicleYear: vehicleData?['year'],
    );
  }
}

