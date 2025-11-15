import 'package:flutter/material.dart';
import 'package:client_app/models/car_model.dart';
import 'package:client_app/models/service_provider_model.dart';
import 'package:client_app/services/service_provider_service.dart';
import 'package:client_app/screens/booking_summary_screen.dart';

class ServiceProviderListScreen extends StatefulWidget {
  final CarModel car;
  final DateTime startDate;
  final DateTime endDate;
  final String location;

  const ServiceProviderListScreen({
    super.key,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.location,
  });

  @override
  State<ServiceProviderListScreen> createState() => _ServiceProviderListScreenState();
}

class _ServiceProviderListScreenState extends State<ServiceProviderListScreen> {
  final _providerService = ServiceProviderService();
  List<ServiceProviderModel> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final providers = await _providerService.getProvidersForCar(widget.car.id, widget.location);
    setState(() {
      _providers = providers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Providers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _providers.isEmpty
              ? const Center(child: Text('No providers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return ProviderCard(
                      provider: provider,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingSummaryScreen(
                            car: widget.car,
                            provider: provider,
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

class ProviderCard extends StatelessWidget {
  final ServiceProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('₹${provider.pricePerDay.toStringAsFixed(0)}/day', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${provider.distanceKm.toStringAsFixed(1)} km away', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
