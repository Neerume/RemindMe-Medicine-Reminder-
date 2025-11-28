import 'dart:async';
import 'dart:convert'; // Required for JSON encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for saving
import '../routes.dart';
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import '../services/medicine_history_service.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../services/notification_service.dart';

// --- 1. GLOBAL ACTIVITY SERVICE WITH PERSISTENCE ---
class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  final StreamController<NotificationEntry> _controller =
      StreamController<NotificationEntry>.broadcast();
  Stream<NotificationEntry> get stream => _controller.stream;

  // Save Key
  static const String _storageKey = 'activity_logs';

  // Add Log (Saves to Storage + Updates UI)
  static Future<void> addLog(NotificationEntry entry) async {
    // 1. Notify listeners (Real-time UI update)
    _instance._controller.add(entry);

    // 2. Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_storageKey) ?? [];

    // Convert entry to JSON string
    Map<String, dynamic> jsonEntry = {
      'id': entry.id,
      'title': entry.title,
      'message': entry.message,
      'time': entry.time,
      'type': entry.type.index, // Store enum as integer
    };

    logs.insert(0, json.encode(jsonEntry)); // Add to top
    // Limit to last 50 logs to save space
    if (logs.length > 50) logs = logs.sublist(0, 50);

    await prefs.setStringList(_storageKey, logs);
  }

  // Load Logs (Called when app starts)
  static Future<List<NotificationEntry>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_storageKey) ?? [];

    return logs.map((logStr) {
      Map<String, dynamic> jsonEntry = json.decode(logStr);
      return NotificationEntry(
        id: jsonEntry['id'],
        title: jsonEntry['title'],
        message: jsonEntry['message'],
        time: jsonEntry['time'],
        type: NotificationType.values[jsonEntry['type']],
      );
    }).toList();
  }

  // Clear Logs
  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

// --- 2. Notification Model ---
enum NotificationType { taken, skipped, snoozed, alarm }

class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  Key _homeKey = UniqueKey();
  late final List<Widget> _widgetOptions;

  // The Master List of Logs
  List<NotificationEntry> _notifications = [];
  StreamSubscription? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSavedLogs(); // Load logs from storage on startup

    // LISTEN TO REAL-TIME UPDATES
    _activitySubscription = ActivityLogService().stream.listen((newEntry) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, newEntry);
        });
      }
    });

    _widgetOptions = <Widget>[
      _HomeContent(
        key: _homeKey,
        onMedicinesLoaded: _scheduleSystemAlarmsOnly,
        onMedicineTaken: _addTakenNotification,
      ),
      const ViewAllMedicinesScreen(),
      const CaregiverScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.requestPermissions();
  }

  // Load logs from SharedPreferences
  Future<void> _loadSavedLogs() async {
    List<NotificationEntry> savedLogs = await ActivityLogService.loadLogs();
    if (mounted) {
      setState(() {
        _notifications = savedLogs;
      });
    }
  }

  Future<void> _scheduleSystemAlarmsOnly(List<Medicine> medicines) async {
    await NotificationService.cancelAll();
    for (var med in medicines) {
      await NotificationService.scheduleMedicineReminder(med);
    }
  }

  void _addTakenNotification(String medicineName, String time) {
    // This calls the service which handles saving + stream
    ActivityLogService.addLog(NotificationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Medicine Taken",
      message: "You took $medicineName",
      time: time,
      type: NotificationType.taken,
    ));
  }

  void _deleteNotification(int index) async {
    setState(() {
      _notifications.removeAt(index);
    });
    // Optional: Re-save the modified list to SharedPreferences if you want deletions to persist
    // For simplicity, we are just removing from UI here.
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _homeKey = UniqueKey();
        _widgetOptions[0] = _HomeContent(
          key: _homeKey,
          onMedicinesLoaded: _scheduleSystemAlarmsOnly,
          onMedicineTaken: _addTakenNotification,
        );
      }
    });
  }

  Icon _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.taken:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case NotificationType.skipped:
        return const Icon(Icons.cancel, color: Colors.redAccent, size: 28);
      case NotificationType.snoozed:
        return const Icon(Icons.snooze, color: Colors.orange, size: 28);
      default:
        return const Icon(Icons.notifications, color: Colors.blue, size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showDashboardAppBar = _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: false,
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
                  Icon(Icons.history_edu, color: Colors.pinkAccent),
                  SizedBox(width: 10),
                  Text(
                    "Medicine Status",
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
                          Icon(Icons.history_toggle_off,
                              size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text("No actions recorded yet",
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
                            backgroundColor: Colors.white,
                            radius: 22,
                            child: _getNotificationIcon(note.type),
                          ),
                          title: Text(note.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note.message,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(note.time,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () => _deleteNotification(index),
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
  final Function(String name, String time)? onMedicineTaken;

  const _HomeContent({super.key, this.onMedicinesLoaded, this.onMedicineTaken});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final MedicineController _medicineController = MedicineController();
  late Future<List<Medicine>> _medicinesFuture;

  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;

  final List<String> _healthQuotes = [
    "Drink at least 8 glasses of water a day.",
    "A good laugh and a long sleep are the best cures.",
    "Early to bed and early to rise makes you healthy.",
  ];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
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
    _medicinesFuture.then((medicines) {
      if (widget.onMedicinesLoaded != null) {
        widget.onMedicinesLoaded!(medicines);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(seconds: 1),
            tween: Tween<double>(begin: 0.8, end: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Card(
              elevation: 5,
              shadowColor: Colors.blueAccent.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFFCE4EC)],
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
                        color: Colors.white.withValues(alpha: 0.6),
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
                        key: ValueKey<int>(_currentQuoteIndex),
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
                color: Color(0xFF37474F)),
          ),
          const SizedBox(height: 15),
          FutureBuilder<List<Medicine>>(
            future: _medicinesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Colors.pinkAccent)),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  height: 150,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40, color: Colors.green.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      const Text("No medicines scheduled for today.",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              final medicines = snapshot.data!;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 100,
                  maxHeight: screenHeight * 0.45,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 10, right: 5),
                      itemCount: medicines.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildMedicineCard(
                            context, medicines[index], index);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
      BuildContext context, Medicine medicine, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      curve: Curves.easeOutQuart,
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
      child: Card(
        elevation: 3,
        shadowColor: Colors.grey.withValues(alpha: 0.2),
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
            child: Row(
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
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[600])),
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

                    if (widget.onMedicineTaken != null) {
                      String now =
                          "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
                      widget.onMedicineTaken!(medicine.name, now);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${medicine.name} taken!')));
                  },
                  child: const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 30),
                ),
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
                        tag: medicine.id,
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.white.withValues(alpha: 0.7),
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
              color: colors[0].withValues(alpha: 0.3),
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
