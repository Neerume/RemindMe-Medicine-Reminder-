import 'package:flutter/material.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';

class ViewAllMedicinesScreen extends StatefulWidget {
  const ViewAllMedicinesScreen({super.key});

  @override
  State<ViewAllMedicinesScreen> createState() => _ViewAllMedicinesScreenState();
}

class _ViewAllMedicinesScreenState extends State<ViewAllMedicinesScreen> {
  final MedicineController _controller = MedicineController();
  late Future<List<Medicine>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    // Call your controller to get all medicines
    _medicinesFuture = _controller.getAllMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Medicines'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<List<Medicine>>(
        future: _medicinesFuture, // <-- This is calling getAllMedicines() from your controller
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // No medicines: show fallback example
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMedicineListItem(
                  context,
                  'Example: Paracetamol',
                  '1 tablet • Everyday',
                  '08:00 AM',
                  Icons.medical_services_outlined,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'No medicines added yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
              ],
            );
          } else {
            // Medicines exist: show them
            final medicines = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                return _buildMedicineListItem(
                  context,
                  med.name,
                  '${med.dose} • ${med.repeat}',
                  med.time,
                  Icons.medical_services_outlined,
                  Colors.blueAccent,
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildMedicineListItem(
      BuildContext context,
      String name,
      String dosage,
      String status,
      IconData icon,
      Color iconColor,
      ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dosage,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 24,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Details for $name')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
