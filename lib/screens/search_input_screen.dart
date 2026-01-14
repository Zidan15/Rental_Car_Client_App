import 'package:flutter/material.dart';
import 'package:client_app/screens/recommended_cars_screen.dart';
import 'package:client_app/screens/my_bookings_screen.dart';
import 'package:client_app/screens/profile_screen.dart';
import 'package:client_app/screens/license_verification_screen.dart';
import 'package:client_app/screens/initial_screen.dart';
import 'package:client_app/screens/privacy_policy_screen.dart'; // <--- NEW IMPORT
import 'package:client_app/screens/terms_conditions_screen.dart'; // <--- NEW IMPORT
import 'package:client_app/services/user_service.dart';
import 'package:intl/intl.dart';

class SearchInputScreen extends StatefulWidget {
  const SearchInputScreen({super.key});

  @override
  State<SearchInputScreen> createState() => _SearchInputScreenState();
}

class _SearchInputScreenState extends State<SearchInputScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _userService = UserService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCarType;
  String? _selectedTransmission;

  // --- Bottom Navigation State ---
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  // -------------------------------

  final List<String> _carTypes = [
    'Hatchback',
    'Sedan',
    'Compact SUV',
    'Full-Size SUV',
    'MUV/7-Seater',
    'Luxury/Premium',
    'Convertible/Open-Top',
    'Electric',
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
      builder: (context) {
        return LocationPickerModal(
          locations: _goaLocations,
          onLocationSelected: (location) {
            setState(() => _locationController.text = location);
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
  final Function(String) onLocationSelected;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleMapLocationPicked(String locationName) {
    widget.onLocationSelected(locationName);
    Navigator.pop(context);
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
              // 1. List View Tab
              ListView.builder(
                itemCount: widget.locations.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.black54),
                  title: Text(widget.locations[index]),
                  onTap: () {
                    widget.onLocationSelected(widget.locations[index]);
                    Navigator.pop(context);
                  },
                ),
              ),

              // 2. Map View Tab (Placeholder)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 40, color: Colors.black),
                              SizedBox(height: 8),
                              Text('Map Integration Area', style: TextStyle(color: Colors.black87)),
                              Text('(Requires Google Maps Flutter package)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _handleMapLocationPicked('Custom Location (Map Pin)');
                        },
                        child: const Text('Confirm Map Location'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}