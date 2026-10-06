import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/models/listing.dart';

void main() {
  group('Listing Model - JSON Deserialization & Null Safety', () {
    test('parses full valid JSON payload with provider_locations', () {
      final json = {
        'id': 'listing-123',
        'owner_id': 'owner-456',
        'price_per_day': 2500.0,
        'is_listed': true,
        'created_at': '2026-03-15T10:30:00.000Z',
        'brand': 'Mahindra',
        'model': 'Thar 4x4',
        'year': 2023,
        'fuel_type': 'Diesel',
        'transmission': 'Automatic',
        'category': 'SUV',
        'color': 'Rocky Beige',
        'plate_number': 'GA-01-A-1234',
        'image_url': 'https://example.com/thar.jpg',
        'provider_locations': {
          'name': 'Panaji Hub',
          'lat': 15.4989,
          'lng': 73.8278,
        },
      };

      final listing = Listing.fromJson(json);

      expect(listing.id, equals('listing-123'));
      expect(listing.ownerId, equals('owner-456'));
      expect(listing.pricePerDay, equals(2500.0));
      expect(listing.isListed, isTrue);
      expect(listing.createdAt, equals(DateTime.parse('2026-03-15T10:30:00.000Z')));
      expect(listing.brand, equals('Mahindra'));
      expect(listing.model, equals('Thar 4x4'));
      expect(listing.year, equals(2023));
      expect(listing.fuelType, equals('Diesel'));
      expect(listing.transmission, equals('Automatic'));
      expect(listing.category, equals('SUV'));
      expect(listing.color, equals('Rocky Beige'));
      expect(listing.plateNumber, equals('GA-01-A-1234'));
      expect(listing.imageUrl, equals('https://example.com/thar.jpg'));
      expect(listing.vehicleLat, equals(15.4989));
      expect(listing.vehicleLng, equals(73.8278));
      expect(listing.vehicleLocationName, equals('Panaji Hub'));
    });

    test('handles numeric types gracefully (int for price_per_day and lat/lng)', () {
      final json = {
        'id': 'listing-num-cast',
        'price_per_day': 1800, // int instead of double
        'is_listed': false,
        'provider_locations': {
          'name': 'Margao Railway Station',
          'lat': 15, // int instead of double
          'lng': 74, // int instead of double
        },
      };

      final listing = Listing.fromJson(json);

      expect(listing.pricePerDay, equals(1800.0));
      expect(listing.vehicleLat, equals(15.0));
      expect(listing.vehicleLng, equals(74.0));
      expect(listing.vehicleLocationName, equals('Margao Railway Station'));
    });

    test('handles missing or null optional fields without runtime exceptions', () {
      final minimalJson = {
        'id': 'minimal-listing',
      };

      final listing = Listing.fromJson(minimalJson);

      expect(listing.id, equals('minimal-listing'));
      expect(listing.ownerId, isNull);
      expect(listing.pricePerDay, equals(0.0));
      expect(listing.isListed, isFalse);
      expect(listing.createdAt, isNull);
      expect(listing.brand, isNull);
      expect(listing.model, isNull);
      expect(listing.year, isNull);
      expect(listing.fuelType, isNull);
      expect(listing.transmission, isNull);
      expect(listing.category, isNull);
      expect(listing.color, isNull);
      expect(listing.plateNumber, isNull);
      expect(listing.imageUrl, isNull);
      expect(listing.vehicleLat, isNull);
      expect(listing.vehicleLng, isNull);
      expect(listing.vehicleLocationName, isNull);
    });

    test('handles null provider_locations object safely', () {
      final json = {
        'id': 'null-location-listing',
        'price_per_day': 900.0,
        'is_listed': true,
        'provider_locations': null,
      };

      final listing = Listing.fromJson(json);

      expect(listing.vehicleLat, isNull);
      expect(listing.vehicleLng, isNull);
      expect(listing.vehicleLocationName, isNull);
    });

    test('handles malformed date string gracefully', () {
      final json = {
        'id': 'invalid-date-listing',
        'created_at': 'not-a-valid-date',
      };

      final listing = Listing.fromJson(json);
      expect(listing.createdAt, isNull);
    });
  });
}
