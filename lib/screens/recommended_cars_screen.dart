import 'package:flutter/material.dart';
import 'package:client_app/models/listing.dart';
import 'package:client_app/services/listing_service.dart';
import 'package:client_app/screens/booking_summary_screen.dart';
import 'package:latlong2/latlong.dart';

class RecommendedCarsScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final double? locationLat;
  final double? locationLng;
  final String? carType;
  final String? transmission;

  const RecommendedCarsScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.locationLat,
    this.locationLng,
    this.carType,
    this.transmission,
  });

  @override
  State<RecommendedCarsScreen> createState() => _RecommendedCarsScreenState();
}

class _RecommendedCarsScreenState extends State<RecommendedCarsScreen> {
  final _listingService = ListingService();
  List<Listing> _listings = [];
  Map<String, double> _distances = {}; // Stores distance for each listing ID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    // Fetch all active listings from Supabase
    final listings = await _listingService.fetchActiveListings();
    
    // Debug: Log what we received
    debugPrint('Fetched ${listings.length} listings from Supabase');
    for (var l in listings) {
      debugPrint('  - ${l.brand} ${l.model}: category=${l.category}, transmission=${l.transmission}');
    }
    debugPrint('Search filters: carType=${widget.carType}, transmission=${widget.transmission}');
    
    // Filter by category and transmission based on user's search criteria
    final filteredListings = listings.where((listing) {
      // Filter by category (Car Type) - only filter if vehicle has a category set
      if (widget.carType != null && widget.carType!.isNotEmpty) {
        // If vehicle has no category, don't filter it out (be lenient for older data)
        if (listing.category != null && listing.category!.isNotEmpty) {
          if (listing.category != widget.carType) return false;
        }
      }
      // Filter by transmission
      if (widget.transmission != null && widget.transmission!.isNotEmpty) {
        // If vehicle has no transmission set, don't filter it out
        if (listing.transmission != null && listing.transmission!.isNotEmpty) {
          if (listing.transmission != widget.transmission) return false;
        }
      }
      return true;
    }).toList();

    debugPrint('After filtering: ${filteredListings.length} listings');

    // Calculate distances and sort if location is available
    if (widget.locationLat != null && widget.locationLng != null) {
      final Distance distance = const Distance();
      final pickupPoint = LatLng(widget.locationLat!, widget.locationLng!);

      // Calculate distances
      for (var l in filteredListings) {
        if (l.vehicleLat != null && l.vehicleLng != null) {
          final km = distance.as(LengthUnit.Kilometer, pickupPoint, LatLng(l.vehicleLat!, l.vehicleLng!));
          _distances[l.id] = km;
        }
      }

      // Sort by distance (nearest first)
      filteredListings.sort((a, b) {
        final distA = _distances[a.id] ?? 999999;
        final distB = _distances[b.id] ?? 999999;
        return distA.compareTo(distB);
      });
    }

    setState(() {
      _listings = filteredListings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Cars')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _listings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No cars found'),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadListings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadListings,
                  color: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _listings.length,
                    itemBuilder: (context, index) {
                      final listing = _listings[index];
                      return ListingCard(
                        listing: listing,
                        distanceKm: _distances[listing.id],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingSummaryScreen(
                              listing: listing,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              location: widget.location,
                              locationLat: widget.locationLat,
                              locationLng: widget.locationLng,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;
  final double? distanceKm;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, this.distanceKm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (or real image if available)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                  ? Image.network(
                      listing.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${listing.brand} ${listing.model} ${listing.year}', style: Theme.of(context).textTheme.titleLarge),
                      if (distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Location info row
                  if (listing.vehicleLocationName != null || distanceKm != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          listing.vehicleLocationName ?? 'Unknown Location',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        if (distanceKm != null) ...[
                          Text(' • ', style: TextStyle(color: Colors.grey[400])),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km away',
                            style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (listing.category != null) ...[
                        _buildChip(listing.category!),
                        const SizedBox(width: 8),
                      ],
                      _buildChip(listing.transmission ?? 'Manual'),
                      const SizedBox(width: 8),
                      _buildChip(listing.fuelType ?? 'Petrol'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${listing.pricePerDay.toStringAsFixed(0)}/day',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
