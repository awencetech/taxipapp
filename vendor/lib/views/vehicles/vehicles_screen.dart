import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../models/vendor_models.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicleVM = context.watch<VehicleViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddVehicleDialog(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vehicleVM.fetchVehicles(),
        child: _buildVehiclesList(vehicleVM),
      ),
    );
  }

  Widget _buildVehiclesList(VehicleViewModel vehicleVM) {
    if (vehicleVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicleVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                vehicleVM.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => vehicleVM.fetchVehicles(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicleVM.vehicles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No vehicles yet',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Add your first vehicle',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicleVM.vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicleVM.vehicles[index];
        return _buildVehicleCard(context, vehicle, vehicleVM);
      },
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    Vehicle vehicle,
    VehicleViewModel vehicleVM,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.directions_car),
        ),
        title: Text(vehicle.model),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.number),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                vehicle.type,
                style: const TextStyle(fontSize: 12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(context, vehicle, vehicleVM);
            }
          },
        ),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final modelController = TextEditingController();
    final numberController = TextEditingController();
    String selectedType = 'Mini';

    final types = ['Mini', 'Sedan', 'SUV', 'Auto', 'Bike'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Vehicle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: modelController,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Enter model' : null,
                  ),
                  TextFormField(
                    controller: numberController,
                    decoration: const InputDecoration(labelText: 'Number'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Enter number' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Consumer<VehicleViewModel>(
              builder: (context, vehicleVM, child) {
                return ElevatedButton(
                  onPressed: vehicleVM.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final success = await vehicleVM.addVehicle({
                              'model': modelController.text,
                              'number': numberController.text,
                              'type': selectedType,
                            });
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vehicle added')),
                              );
                            }
                          }
                        },
                  child: vehicleVM.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Vehicle vehicle,
    VehicleViewModel vehicleVM,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await vehicleVM.deleteVehicle(vehicle.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
