import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              child: Icon(
                Icons.person_rounded,
                size: 70,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'John Doe', // Example User Name
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              'johndoe@example.com', // Example Email
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildProfileInfoRow(Icons.phone, 'Phone', '+123 456 7890'),
                    const Divider(height: 20, indent: 10, endIndent: 10),
                    _buildProfileInfoRow(
                      Icons.cake,
                      'Date of Birth',
                      'January 1, 1990',
                    ),
                    const Divider(height: 20, indent: 10, endIndent: 10),
                    _buildProfileInfoRow(
                      Icons.location_on,
                      'Address',
                      '123 Health St, Wellness City',
                    ),
                    const Divider(height: 20, indent: 10, endIndent: 10),
                    _buildProfileInfoRow(Icons.bloodtype, 'Blood Group', 'A+'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile Pressed')),
                );
              },
              icon: const Icon(Icons.edit, size: 24),
              label: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logout Pressed')));
              },
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 26),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
