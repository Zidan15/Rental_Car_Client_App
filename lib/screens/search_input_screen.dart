import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:client_app/screens/recommended_cars_screen.dart';
import 'package:client_app/screens/my_bookings_screen.dart';
import 'package:client_app/screens/profile_screen.dart';
import 'package:client_app/screens/license_verification_screen.dart';
import 'package:client_app/screens/initial_screen.dart';
import 'package:client_app/screens/privacy_policy_screen.dart';
import 'package:client_app/screens/terms_conditions_screen.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/services/license_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchInputScreen extends StatefulWidget {
  final int initialIndex;

  const SearchInputScreen({super.key, this.initialIndex = 0});

  @override
  State<SearchInputScreen> createState() => _SearchInputScreenState();
}

class _SearchInputScreenState extends State<SearchInputScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _userService = UserService();
  final _licenseService = LicenseService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCarType;
  String? _selectedTransmission;
  double? _locationLat;
  double? _locationLng;
  
  // License banner state
  bool _hasLicense = true; // Default to true to avoid flicker
  bool _bannerDismissed = false;

  // --- Bottom Navigation State ---
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkLicenseStatus();
  }

  Future<void> _checkLicenseStatus() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      final hasLicense = await _licenseService.isLicenseVerified(user.id);
      if (mounted) {
        setState(() => _hasLicense = hasLicense);
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  // -------------------------------

  final List<String> _carTypes = [
    'Hatchback',
    'Sedan',
    'SUV',
  ];

  final List<String> _transmissions = ['Automatic', 'Manual'];

  final List<String> _goaLocations = [
    'Panaji',
    'Calangute',
    'Baga',
    'Candolim',
    'Anjuna',
    'Vagator',
    'Palolem',
    'Colva',
    'Mapusa',
    'Margao',
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- Date and Location Handlers ---

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(date);
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start date first')));
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _endDateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      enableDrag: false, // Prevents dragging the modal when panning the map
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        return LocationPickerModal(
          locations: _goaLocations,
          onLocationSelected: (location, {double? lat, double? lng}) {
            setState(() {
              _locationController.text = location;
              _locationLat = lat;
              _locationLng = lng;
            });
          },
        );
      },
    );
  }

  void _searchCars() {
    if (_startDate == null || _endDate == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendedCarsScreen(
          startDate: _startDate!,
          endDate: _endDate!,
          location: _locationController.text,
          locationLat: _locationLat,
          locationLng: _locationLng,
          carType: _selectedCarType,
          transmission: _selectedTransmission,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialScreen()),
      (route) => false,
    );
  }
  // ----------------------------------------------------

  // --- Search Form Widget (Extracted for use in IndexedStack) ---
  Widget _buildSearchForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // License Verification Banner (Dismissable)
            if (!_hasLicense && !_bannerDismissed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete verification to book',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verify your license to start booking vehicles',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LicenseVerificationScreen()),
                        );
                        _checkLicenseStatus(); // Refresh status after returning
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _bannerDismissed = true),
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: const InputDecoration(labelText: 'Start Date', suffixIcon: Icon(Icons.calendar_today, color: Colors.black)),
              readOnly: true,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              decoration: const InputDecoration(labelText: 'End Date', suffixIcon: Icon(Icons.calendar_today, color: Colors.black)),
              readOnly: true,
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCarType,
              decoration: const InputDecoration(labelText: 'Car Type'),
              items: _carTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _selectedCarType = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTransmission,
              decoration: const InputDecoration(labelText: 'Transmission'),
              items: _transmissions.map((trans) => DropdownMenuItem(value: trans, child: Text(trans))).toList(),
              onChanged: (value) => setState(() => _selectedTransmission = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Pickup Location', suffixIcon: Icon(Icons.location_on, color: Colors.black)),
              readOnly: true,
              onTap: _showLocationPicker,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _searchCars,
              child: const Text('Search Cars'),
            ),
          ],
        ),
      ),
    );
  }
  // ---------------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set AppBar title based on the selected tab
        title: Text(_currentIndex == 0 ? 'RENT.GOA' : 'My Bookings'),
        centerTitle: true,
      ),
      // --- MODIFIED DRAWER (Hamburger Menu) ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Dark Header Section (Similar to Service Provider App)
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.black,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16.0),
              child: const Text('RENT.GOA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Profile
                  ListTile(
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  // License Verification
                  ListTile(
                    title: const Text('License Verification'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseVerificationScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  // Terms & Conditions
                  ListTile(
                    title: const Text('Terms & Conditions'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())); // <--- NAVIGATES HERE
                    },
                  ),
                  const Divider(height: 1),
                  // Privacy Policy
                  ListTile(
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())); // <--- NAVIGATES HERE
                    },
                  ),
                  const Divider(height: 1),
                  // Logout
                  ListTile(
                    title: const Text('LOG OUT', style: TextStyle(color: Colors.red)),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ----------------------------------------
      
      // --- BODY: Conditional rendering so MyBookingsScreen rebuilds each time ---
      body: _currentIndex == 0
          ? _buildSearchForm()
          : const MyBookingsScreen(),
      
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Bookings',
          ),
        ],
      ),
      // -----------------------------
    );
  }
}


// =========================================================================
// LOCATION PICKER MODAL (From previous interaction)
// =========================================================================

class LocationPickerModal extends StatefulWidget {
  final List<String> locations;
  final Function(String, {double? lat, double? lng}) onLocationSelected;

  const LocationPickerModal({
    required this.locations,
    required this.onLocationSelected,
    super.key,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mapSearchController = TextEditingController(); // Search controller for MAP tab
  final MapController _mapController = MapController(); // Controller to move the map
  List<String> _filteredLocations = [];
  
  // Goa center coordinates
  static const _goaCenter = LatLng(15.2993, 74.1240);
  LatLng _selectedLocation = _goaCenter;
  String _selectedLocationName = 'Goa, India';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredLocations = widget.locations;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _mapSearchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = widget.locations
          .where((location) => location.toLowerCase().contains(query))
          .toList();
    });
  }

  void _handleMapLocationPicked(String locationName, double lat, double lng) {
    widget.onLocationSelected(locationName, lat: lat, lng: lng);
    Navigator.pop(context);
  }
  
  static const Map<String, LatLng> _locationCoordinates = {
    'Panaji': LatLng(15.4909, 73.8278),
    'Calangute': LatLng(15.5494, 73.7535),
    'Baga': LatLng(15.5553, 73.7517),
    'Candolim': LatLng(15.5181, 73.7626),
    'Anjuna': LatLng(15.5733, 73.7410),
    'Vagator': LatLng(15.6029, 73.7336),
    'Palolem': LatLng(15.0099, 74.0232),
    'Colva': LatLng(15.2754, 73.9136),
    'Mapusa': LatLng(15.5940, 73.8159),
    'Margao': LatLng(15.2832, 73.9862),
  };

  void _handleListLocationPicked(String locationName) {
    final coords = _locationCoordinates[locationName];
    if (coords != null) {
      widget.onLocationSelected(locationName, lat: coords.latitude, lng: coords.longitude);
    } else {
      widget.onLocationSelected(locationName);
    }
    Navigator.pop(context);
  }
  
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _selectedLocation = position;
      _selectedLocationName = 'Fetching address...';
    });
    
    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'RentGoaApp/1.0'}, // Required by Nominatim
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] as String?;
        
        // Shorten address for display (keep first 3 parts)
        String shortAddress = 'Unknown Location';
        if (displayName != null) {
          final parts = displayName.split(', ');
          shortAddress = parts.take(3).join(', ');
        }

        if (mounted) {
          setState(() {
            _selectedLocationName = shortAddress;
            _mapSearchController.text = shortAddress;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
      if (mounted) {
        setState(() {
          _selectedLocationName = 'Selected on Map (Address not found)';
        });
      }
    }
  }

  Future<void> _getLatLngFromAddress() async {
    final query = _mapSearchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _selectedLocationName = 'Searching...';
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'RentGoaApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'];

          if (mounted) {
            setState(() {
              _selectedLocation = LatLng(lat, lon);
              _selectedLocationName = displayName;
              _mapSearchController.text = displayName;
            });
            
            _mapController.move(_selectedLocation, 15.0); 
          }
        } else {
           if (mounted) {
            setState(() {
              _selectedLocationName = 'Location not found';
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found')));
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error searching location')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select Pickup Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Select from List', icon: Icon(Icons.list)),
            Tab(text: 'Select on Map', icon: Icon(Icons.map)),
          ],
        ),
        const Divider(height: 1),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. List View Tab WITH SEARCH
              Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                  ),
                  // Location List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: Colors.black54),
                        title: Text(_filteredLocations[index]),
                        onTap: () {
                          _handleListLocationPicked(_filteredLocations[index]);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Map View Tab - Google Maps (OSM)
              Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _goaCenter,
                        initialZoom: 10,
                        minZoom: 8,
                        maxZoom: 18,
                        onTap: (_, latLng) => _onMapTapped(latLng),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.client_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              alignment: Alignment.topCenter,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _mapSearchController,
                                decoration: InputDecoration(
                                  hintText: 'Search or tap map...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                ),
                                onSubmitted: (_) => _getLatLngFromAddress(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _getLatLngFromAddress,
                              icon: const Icon(Icons.search),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Selected Location Text (Small)
                        Text(
                          _selectedLocationName,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            _handleMapLocationPicked(
                              _selectedLocationName,
                              _selectedLocation.latitude,
                              _selectedLocation.longitude,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Confirm Location'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}