import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A screen that allows users to pick a location on a map.
/// The map is centered on Goa, India.
class LocationPickerScreen extends StatefulWidget {
  final String? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Goa, India coordinates
  static const _goaCenter = LatLng(15.2993, 74.1240);
  
  GoogleMapController? _mapController;
  LatLng _selectedLocation = _goaCenter;
  String _locationName = 'Goa, India';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pickup Location'),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text('CONFIRM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _goaCenter,
              zoom: 10, // Zoom level to show all of Goa
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (newPosition) {
                  setState(() {
                    _selectedLocation = newPosition;
                    _locationName = 'Lat: ${newPosition.latitude.toStringAsFixed(4)}, Lng: ${newPosition.longitude.toStringAsFixed(4)}';
                  });
                },
              ),
            },
            // Restrict to Goa region (approximate bounds)
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: const LatLng(14.8, 73.6), // Southwest corner of Goa
                northeast: const LatLng(15.8, 74.5), // Northeast corner of Goa
              ),
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(8, 18),
          ),
          
          // Location info card at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap on the map or drag the marker to select location',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _locationName = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    });
  }

  void _confirmLocation() {
    // Return the selected location to the previous screen
    Navigator.pop(context, {
      'name': _locationName,
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
    });
  }
}
