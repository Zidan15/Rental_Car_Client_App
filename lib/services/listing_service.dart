import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/models/listing.dart';

class ListingService {
  final _supabase = Supabase.instance.client;

  /// Fetches all listed vehicles from the database.
  /// Queries vehicles table directly (merged architecture - no more listings table).
  Future<List<Listing>> fetchActiveListings() async {
    try {
      debugPrint('Fetching listed vehicles from Supabase...');
      
      // Query vehicles table directly where is_listed = true, with location join
      final data = await _supabase
          .from('vehicles')
          .select('*, provider_locations(lat, lng, name)')
          .eq('is_listed', true);

      debugPrint('Raw data received: ${data.length} vehicles');

      // Convert to Listing objects
      final listings = (data as List<dynamic>)
          .map((json) => Listing.fromJson(json))
          .toList();
      
      debugPrint('Parsed ${listings.length} listings successfully');
      return listings;
    } catch (e, stackTrace) {
      debugPrint('Error fetching listings: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}
