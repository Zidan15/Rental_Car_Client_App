import 'package:client_app/models/car_model.dart';
import 'package:client_app/models/service_provider_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final CarModel car;
  final ServiceProviderModel provider;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final double totalPrice;
  final String status;
  final DateTime bookingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.car,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.totalPrice,
    required this.status,
    required this.bookingDate,
    required this.createdAt,
    required this.updatedAt,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;
  
  double get pricePerDay => totalPrice / numberOfDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'car': car.toJson(),
    'provider': provider.toJson(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'pickupLocation': pickupLocation,
    'totalPrice': totalPrice,
    'status': status,
    'bookingDate': bookingDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'],
    userId: json['userId'],
    car: CarModel.fromJson(json['car']),
    provider: ServiceProviderModel.fromJson(json['provider']),
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    pickupLocation: json['pickupLocation'],
    totalPrice: json['totalPrice'],
    status: json['status'],
    bookingDate: DateTime.parse(json['bookingDate']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  BookingModel copyWith({
    String? id,
    String? userId,
    CarModel? car,
    ServiceProviderModel? provider,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupLocation,
    double? totalPrice,
    String? status,
    DateTime? bookingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BookingModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    car: car ?? this.car,
    provider: provider ?? this.provider,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    pickupLocation: pickupLocation ?? this.pickupLocation,
    totalPrice: totalPrice ?? this.totalPrice,
    status: status ?? this.status,
    bookingDate: bookingDate ?? this.bookingDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
