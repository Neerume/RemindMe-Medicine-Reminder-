import 'package:flutter/material.dart';

// Import your routes.dart file to use named routes
import '../routes.dart'; // Adjust this path if routes.dart is not in lib/

// Screens for the bottom navigation bar - directly import if needed,
// but for bottom nav, it's often better to instantiate them directly if they are stateless
// or manage their own state without needing named route push for their initial display.
// The important part is how you navigate *from* these screens.
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import '../services/medicine_history_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // For bottom navigation bar

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const _HomeContent(), // Your original dashboard's home content
      const ViewAllMedicinesScreen(), // "Medicines" tab content (using corrected name)
      const CaregiverScreen(), // "Caregiver" tab content (replaced Schedule)
      const ProfileScreen(), // "Profile" tab content
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showDashboardAppBar = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: showDashboardAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Image.asset(
                    'assets/1.png',
                    width: 40,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'RemindMe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, size: 28),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications')),
                    );
                  },
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 10),
              ],
            )
          : null,
      body: _widgetOptions.elementAt(
        _selectedIndex,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_liquid_sharp),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Caregiver',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.only(bottom: 25),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF0F5), // Light pink
                    Color(0xFFE0F7FA), // Light cyan
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Health Tip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_right_alt,
                        color: Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drink at least 2L of water everyday',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Text(
            "Today's Medicines",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 15),
          _buildMedicineReminderCard(
            context,
            'Paracetamol',
            '8:00 AM',
            '1 tablet',
          ),
          _buildMedicineReminderCard(
            context,
            'Multivitamin',
            '1:00 PM',
            '1 capsule',
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildAddMedicineButton(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildViewAllMedicinesButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineReminderCard(
    BuildContext context,
    String medicineName,
    String time,
    String dosage,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.blueAccent[700], size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time - $dosage',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 30,
              ),
              onPressed: () async {
                // Save to medicine history
                await MedicineHistoryService.addMedicineRecord(
                  MedicineRecord(
                    medicineName: medicineName,
                    time: time,
                    dosage: dosage,
                    dateTaken: DateTime.now(),
                  ),
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$medicineName taken!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicineButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // *** CHANGE MADE HERE: Use named route for AddMedicineScreen ***
        Navigator.of(context).pushNamed(AppRoutes.addMedicine);
      },
      icon: const Icon(Icons.add_circle_outline, size: 28),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Add\nMedicine',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigoAccent[100],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        elevation: 5,
        shadowColor: Colors.indigoAccent.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildViewAllMedicinesButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // *** CHANGE MADE HERE: Use named route for ViewAllMedicinesScreen ***
        Navigator.of(context).pushNamed(AppRoutes.viewAll);
      },
      icon: const Icon(Icons.list_alt, size: 28),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'View All\nMedicines',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        elevation: 5,
        shadowColor: Colors.teal.withValues(alpha: 0.4),
      ),
    );
  }
}
