import 'package:flutter/material.dart';
import 'package:client_app/models/car_model.dart';
import 'package:client_app/services/car_service.dart';
import 'package:client_app/screens/service_provider_list_screen.dart';

class RecommendedCarsScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? carType;
  final String? transmission;

  const RecommendedCarsScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.carType,
    this.transmission,
  });

  @override
  State<RecommendedCarsScreen> createState() => _RecommendedCarsScreenState();
}

class _RecommendedCarsScreenState extends State<RecommendedCarsScreen> {
  final _carService = CarService();
  List<CarModel> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final cars = await _carService.searchCars(
      category: widget.carType,
      transmission: widget.transmission,
    );
    setState(() {
      _cars = cars;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Cars')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _cars.isEmpty
              ? const Center(child: Text('No cars found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    return CarCard(
                      car: car,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceProviderListScreen(
                            car: car,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                            location: widget.location,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CarCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback onTap;

  const CarCard({super.key, required this.car, required this.onTap});

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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.asset(
                car.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${car.category} • ${car.transmission}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('${car.fuelType} • ${car.seats} Seats', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
