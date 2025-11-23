import 'package:flutter/material.dart';

class ViewAllMedicinesScreen extends StatelessWidget {
  const ViewAllMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Medicines'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ), // Ensure back button is visible
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMedicineListItem(
            context,
            'Paracetamol',
            'Take 1 tablet every 8 hours',
            'Last taken: 8:00 AM Today',
            Icons.access_time,
            Colors.blueAccent,
          ),
          _buildMedicineListItem(
            context,
            'Multivitamin',
            'Take 1 capsule every day',
            'Last taken: 1:00 PM Today',
            Icons.local_pharmacy_outlined,
            Colors.orangeAccent,
          ),
          _buildMedicineListItem(
            context,
            'Amoxicillin',
            'Take 1 tablet twice a day for 7 days',
            'Next dose: 7:00 PM Today',
            Icons.medical_services_outlined,
            Colors.purpleAccent,
          ),
          _buildMedicineListItem(
            context,
            'Lisinopril',
            'Take 1 tablet once daily (morning)',
            'Next dose: Tomorrow 9:00 AM',
            Icons.favorite_border,
            Colors.redAccent,
          ),
          _buildMedicineListItem(
            context,
            'Ibuprofen',
            'Take 1-2 tablets as needed for pain',
            'Last taken: Yesterday',
            Icons.medication_liquid_sharp,
            Colors.greenAccent,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'End of your medicine list.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Details for $name')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
