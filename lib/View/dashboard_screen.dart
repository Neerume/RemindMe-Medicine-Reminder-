import 'dart:async'; // Required for Timer
import 'dart:io';
import 'package:flutter/material.dart';
import '../routes.dart';
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import '../services/medicine_history_service.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../services/notification_service.dart'; // Import Service

// --- 1. Notification Model ---
class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex; // For bottom navigation bar
  Key _homeKey = UniqueKey();
  late final List<Widget> _widgetOptions;

  // List to hold notifications for the UI Drawer
  List<NotificationEntry> _notifications = [];

  @override
  void initState() {
    super.initState();

    // 1. Request Notification Permissions & Initialize Service
    _initializeNotifications();

    // Initialize screens
    _selectedIndex = widget.initialIndex;
    _widgetOptions = <Widget>[
      _HomeContent(
        key: _homeKey,
        onMedicinesLoaded: _updateNotificationsFromMedicines,
      ),
      const ViewAllMedicinesScreen(),
      const CaregiverScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.init(); // Must come before requesting permissions
    await NotificationService.requestPermissions();
  }

  // Populate notifications based on medicines
  // AND Schedule the actual system alarms
  Future<void> _updateNotificationsFromMedicines(
      List<Medicine> medicines) async {
    // A. System Level: Cancel old and Schedule new High-Priority Alarms
    await NotificationService.cancelAll();
    for (var med in medicines) {
      await NotificationService.scheduleMedicineReminder(med);
    }

    // B. App UI Level: Update the list in the drawer
    if (mounted) {
      setState(() {
        _notifications = medicines.map((med) {
          return NotificationEntry(
            id: med.id.toString(),
            title: "Alarm Set",
            message: "Pop-up scheduled for ${med.name}",
            time: med.time,
          );
        }).toList();
      });
    }
  }

  // Delete a notification (UI only)
  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification removed from list"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _homeKey = UniqueKey();
        _widgetOptions[0] = _HomeContent(
          key: _homeKey,
          onMedicinesLoaded: _updateNotificationsFromMedicines,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showDashboardAppBar = _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey, // Attach the key here
      extendBodyBehindAppBar: false,
      // --- Right Side Drawer for Notifications ---
      endDrawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                  top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF0F5), Color(0xFFE1F5FE)],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.pinkAccent),
                  SizedBox(width: 10),
                  Text(
                    "Scheduled Alerts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off,
                              size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text("No notifications yet",
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final note = _notifications[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Icon(Icons.alarm_on,
                                color: Colors.blueAccent, size: 20),
                          ),
                          title: Text(note.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note.message),
                              Text(note.time,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                          // --- The 3-Dots Menu with Delete ---
                          trailing: PopupMenuButton<String>(
                            icon:
                                const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteNotification(index);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      SizedBox(width: 10),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: showDashboardAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFFFF0F5),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Row(
                children: [
                  SizedBox(width: 10),
                  Text(
                    'RemindMe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF0F5), Color(0xFFE1F5FE)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 28),
                      // Open the drawer using the GlobalKey
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      color: Colors.grey[700],
                    ),
                    if (_notifications.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(width: 10),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.3, 1.0],
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFE1F5FE),
            ],
          ),
        ),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey[500],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Medicines'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Caregiver'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final Function(List<Medicine>)? onMedicinesLoaded;

  const _HomeContent({super.key, this.onMedicinesLoaded});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final MedicineController _medicineController = MedicineController();
  late Future<List<Medicine>> _medicinesFuture;

  // Health Quote Logic
  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;

  final List<String> _healthQuotes = [
    "Drink at least 8 glasses of water a day.",
    "A good laugh and a long sleep are the best cures.",
    "Early to bed and early to rise makes you healthy.",
    "Take your medicines on time for better results.",
    "A 30-minute walk everyday keeps the heart strong.",
    "Eat more fruits and vegetables.",
    "Stay hydrated to maintain energy levels.",
    "Limit sugar intake for a healthier life.",
    "Stretching daily improves flexibility.",
    "Mental health is as important as physical health.",
    "Wash your hands properly before eating.",
    "Get regular check-ups with your doctor.",
    "Limit salt intake to manage blood pressure.",
    "Fiber-rich foods aid in digestion.",
    "Sunshine is a great source of Vitamin D.",
    "Manage stress with deep breathing exercises.",
    "Avoid smoking and alcohol.",
    "Maintain a healthy weight for your age.",
    "Connect with loved ones to stay happy.",
    "Read a book to keep the mind sharp.",
    "Wear comfortable shoes to prevent falls.",
    "Protect your skin from excessive sun.",
    "Practice good posture while sitting.",
    "Eat calcium-rich foods for strong bones.",
    "Listen to your body signals.",
    "A balanced diet is the key to longevity.",
    "Keep your living space clean and airy.",
    "Brush your teeth twice a day.",
    "Positive thoughts create a positive life.",
    "Your health is your greatest wealth."
  ];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();

    // Timer to change quote every 10 SECONDS (as requested)
    _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _healthQuotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _fetchMedicines() {
    _medicinesFuture = _medicineController.getAllMedicines();
    // Notify parent to update notification list
    _medicinesFuture.then((medicines) {
      if (widget.onMedicinesLoaded != null) {
        widget.onMedicinesLoaded!(medicines);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Health Quote Card
          TweenAnimationBuilder(
            duration: const Duration(seconds: 1),
            tween: Tween<double>(begin: 0.8, end: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Card(
              elevation: 5,
              shadowColor: Colors.blueAccent.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE3F2FD),
                      Color(0xFFFCE4EC)
                    ], // Light Blue to Pink
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tips_and_updates,
                              color: Colors.orange[400], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Daily Health Tip',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Animated Text Switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0, 0.5),
                                      end: Offset.zero)
                                  .animate(animation),
                              child: child,
                            ));
                      },
                      child: Text(
                        _healthQuotes[_currentQuoteIndex],
                        key: ValueKey<int>(
                            _currentQuoteIndex), // Key triggers animation
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.3,
                          color: Color(0xFF424242),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            "Today's Medicines",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF37474F) // Dark Blue Grey
                ),
          ),
          const SizedBox(height: 15),

          FutureBuilder<List<Medicine>>(
            future: _medicinesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(15)),
                    child: const Text("No medicines scheduled for today.",
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final medicines = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  return _buildMedicineCard(context, medicines[index], index);
                },
              );
            },
          ),

          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildGradientButton(
                      context,
                      'Add Meds',
                      Icons.add_circle,
                      [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)],
                      AppRoutes.addMedicine)),
              const SizedBox(width: 15),
              Expanded(
                  child: _buildGradientButton(
                      context,
                      'View All',
                      Icons.list_alt,
                      [const Color(0xFFF48FB1), const Color(0xFFF06292)],
                      AppRoutes.viewAll)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
      BuildContext context, Medicine medicine, int index) {
    // Staggered Slide Animation
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      curve: Curves.easeOutQuart,
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
      child: Card(
        elevation: 3,
        shadowColor: Colors.grey.withOpacity(0.2),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () => _showMedicineDetails(context, medicine),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8FDFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.access_alarm,
                          color: Color(0xFF039BE5), size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medicine.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('${medicine.time} • ${medicine.dose}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await MedicineHistoryService.addMedicineRecord(
                            MedicineRecord(
                                medicineName: medicine.name,
                                time: medicine.time,
                                dosage: medicine.dose,
                                dateTaken: DateTime.now()));
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${medicine.name} taken!')));
                      },
                      child: const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "View Details ➔",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[400]),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMedicineDetails(BuildContext context, Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF3E5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 15),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Hero(
                        tag: medicine.id, // Simple hero animation
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10)
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: (medicine.photo != null &&
                                    medicine.photo!.isNotEmpty)
                                ? Image.file(File(medicine.photo!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.medication,
                                        size: 60,
                                        color: Colors.pinkAccent))
                                : const Icon(Icons.medication_liquid,
                                    size: 80, color: Colors.blueAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(medicine.name,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.timer, "Time", medicine.time),
                      _buildInfoRow(Icons.numbers, "Dose", medicine.dose),
                      _buildInfoRow(Icons.refresh, "Repeat", medicine.repeat),
                      _buildInfoRow(
                          Icons.notes, "Instruction", medicine.instruction),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF06292),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: const Text("Close",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context, String label, IconData icon,
      List<Color> colors, String route) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(route);
          setState(() {
            _medicinesFuture = _medicineController.getAllMedicines();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
