import 'dart:io';
import 'package:flutter/material.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
// Import the new screen
import 'edit_medicine_screen.dart';

class ViewAllMedicinesScreen extends StatefulWidget {
  const ViewAllMedicinesScreen({super.key});

  @override
  State<ViewAllMedicinesScreen> createState() => _ViewAllMedicinesScreenState();
}

class _ViewAllMedicinesScreenState extends State<ViewAllMedicinesScreen> {
  final MedicineController _medicineController = MedicineController();
  late Future<List<Medicine>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMedicines();
  }

  void _refreshMedicines() {
    setState(() {
      _medicinesFuture = _medicineController.getAllMedicines();
    });
  }

  Future<void> _deleteMedicine(String id, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete $name?",
            style: const TextStyle(color: Color(0xFFC2185B))),
        content: const Text("This cannot be undone. Are you sure?"),
        backgroundColor: const Color(0xFFFFF8FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48FB1)),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _medicineController.deleteMedicine(id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted successfully")));
                _refreshMedicines();
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- NEW: Navigation to Edit Screen ---
  void _navigateToEdit(Medicine med) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicineScreen(medicine: med),
      ),
    );

    // If result is true, it means we updated something, so refresh the list
    if (result == true) {
      _refreshMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text("My Medicine Box",
            style: TextStyle(
                color: Color(0xFF37474F), fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFFFFF0F5),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFE1F5FE)],
          ),
        ),
        child: FutureBuilder<List<Medicine>>(
          future: _medicinesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: Text("Box is empty",
                      style: TextStyle(color: Colors.grey[500], fontSize: 18)));
            }

            final medicines = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];

                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                          offset: Offset(0, 30 * (1 - val)), child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      // Fixed deprecated withOpacity
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    // Wrap the card content in Material & InkWell for tap effect
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () => _navigateToEdit(med), // Tap to Edit
                        borderRadius: BorderRadius.circular(15),
                        child: Row(
                          children: [
                            // Left Image Section
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15)),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[100],
                                child:
                                    (med.photo != null && med.photo!.isNotEmpty)
                                        ? Image.file(File(med.photo!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.medication,
                                                    color: Colors.pinkAccent))
                                        : const Icon(Icons.medication,
                                            color: Colors.blueAccent, size: 40),
                              ),
                            ),
                            // Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Text(med.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16))),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 22),
                                          onPressed: () =>
                                              _deleteMedicine(med.id, med.name),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text("${med.time} • ${med.repeat}",
                                        style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Text(
                                        "Tap to view details & edit", // Hint text
                                        style: TextStyle(
                                            color: Colors.pink[300],
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
