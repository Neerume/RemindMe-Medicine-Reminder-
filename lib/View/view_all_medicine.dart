import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/medicine_repository.dart';

class ViewAllMedicinesScreen extends StatefulWidget {
  const ViewAllMedicinesScreen({super.key});

  @override
  State<ViewAllMedicinesScreen> createState() => _ViewAllMedicinesScreenState();
}

class _ViewAllMedicinesScreenState extends State<ViewAllMedicinesScreen> {
  final MedicineRepository _repository = MedicineRepository.instance;
  final DateFormat _dateFormatter = DateFormat('EEE, MMM d, yyyy');
  final DateFormat _timeFormatter = DateFormat('h:mm a');

  bool _isLoading = true;
  List<MedicineEntry> _medicines = [];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final entries = await _repository.getAllMedicines();
    if (!mounted) return;
    setState(() {
      _medicines = entries;
      _isLoading = false;
    });
  }

  // ✅ FIXED: Changed parameter type to String
  Future<void> _deleteMedicine(String id) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: const Text(
            'Are you sure you want to remove this medicine schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteMedicine(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine deleted successfully')),
        );
        _loadMedicines(); // Refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Medicines'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMedicines,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _medicines.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medicines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildMedicineCard(_medicines[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.medication_outlined,
          size: 90,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No medicines added yet.\nGo to Home and tap + to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(MedicineEntry entry) {
    final dateLabel = _dateFormatter.format(entry.scheduledDateTime);
    final timeLabel = _timeFormatter.format(entry.scheduledDateTime);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: entry.imagePath.isNotEmpty
                      ? Image.file(
                          File(entry.imagePath),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeLabel • ${entry.dosage}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starts: $dateLabel',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete Button
                IconButton(
                  onPressed: () => _deleteMedicine(entry.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.repeat, 'Frequency', entry.repeat),
            const SizedBox(height: 6),
            _infoRow(Icons.notes, 'Instruction', entry.instruction),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[100],
      child: const Icon(Icons.medication, color: Colors.grey),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
