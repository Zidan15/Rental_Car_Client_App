import 'package:flutter/material.dart';
import 'package:client_app/screens/recommended_cars_screen.dart';
import 'package:client_app/screens/my_bookings_screen.dart';
import 'package:client_app/screens/profile_screen.dart';
import 'package:client_app/screens/license_verification_screen.dart';
import 'package:client_app/screens/initial_screen.dart';
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
      backgroundColor: Colors.white,
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select Pickup Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _goaLocations.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_goaLocations[index]),
                onTap: () {
                  setState(() => _locationController.text = _goaLocations[index]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RENT.GOA'),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('RENT.GOA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text('Profile / Account Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.black),
              title: const Text('License Verification'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseVerificationScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.black),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.black),
              title: const Text('Help / Support'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.black),
              title: const Text('Terms & Conditions'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.black),
              title: const Text('Privacy Policy'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SafeArea(
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
      ),
    );
  }
}
