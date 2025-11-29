import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// --- Imports ---
import '../routes.dart';
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import '../services/medicine_history_service.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../services/notification_service.dart';
// IMPORANT: This imports the shared model we just created
import '../services/activity_log_service.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  Key _homeKey = UniqueKey();
  late final List<Widget> _widgetOptions;

  // This list now uses the Shared Model from the Service
  List<NotificationEntry> _notifications = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializeNotifications();

    _widgetOptions = <Widget>[
      _HomeContent(
        key: _homeKey,
        onMedicineAction: _handleMedicineAction,
        onMedicinesLoaded: _updateData,
      ),
      const ViewAllMedicinesScreen(),
      const CaregiverScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.requestPermissions();
  }

  // --- DATA LOADING LOGIC ---

  Future<void> _updateData(List<Medicine> medicines) async {
    // 1. Re-schedule alarms
    await NotificationService.cancelAll();
    for (var med in medicines) {
      await NotificationService.scheduleMedicineReminder(med);
    }

    List<NotificationEntry> tempList = [];

    // 2. LOAD HISTORY (Taken/Skipped/Snoozed) from the Service
    try {
      final historyLogs = await ActivityLogService.getLogs();
      tempList.addAll(historyLogs);
    } catch (e) {
      debugPrint("Error loading history: $e");
    }

    // 3. ADD SCHEDULED ALARMS
    // Create temporary entries for upcoming scheduled medicines
    for (var med in medicines) {
      tempList.add(NotificationEntry(
        id: "sched_${med.id}",
        title: "Scheduled",
        message: "Reminder for ${med.name}",
        time: med.time,
        type: NotificationType.scheduled,
      ));
    }

    if (mounted) {
      setState(() {
        _notifications = tempList;
      });
    }
  }

  // --- IMMEDIATE UI UPDATE (When clicking buttons on Home) ---
  void _handleMedicineAction(
      String actionType, String medicineName, String time) async {
    NotificationType type = NotificationType.taken;
    String title = "Medicine Taken";
    String message = "You took $medicineName";

    if (actionType.toLowerCase() == "skipped") {
      type = NotificationType.skipped;
      title = "Medicine Skipped";
      message = "You skipped $medicineName";
    } else if (actionType.toLowerCase() == "snoozed") {
      type = NotificationType.snoozed;
      title = "Alarm Snoozed";
      message = "Snoozed $medicineName";
    }

    final newEntry = NotificationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: time,
      type: type,
    );

    // Save to Service so it persists
    await ActivityLogService.addLog(newEntry);

    if (mounted) {
      setState(() {
        _notifications.insert(0, newEntry);
      });
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _homeKey = UniqueKey();
        _widgetOptions[0] = _HomeContent(
          key: _homeKey,
          onMedicineAction: _handleMedicineAction,
          onMedicinesLoaded: _updateData,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showDashboardAppBar = _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      // --- DRAWER UI (Matches Screenshot) ---
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
                  Icon(Icons.medication_liquid, color: Colors.pinkAccent),
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
                          Icon(Icons.notifications_off,
                              size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text("No activity yet",
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final note = _notifications[index];

                        // --- ICON & COLOR LOGIC (Exact match for screenshot) ---
                        IconData icon;
                        Color iconColor;
                        Color circleColor;

                        switch (note.type) {
                          case NotificationType.taken:
                            icon = Icons.check;
                            iconColor = Colors.white;
                            circleColor = Colors.green; // Green Circle
                            break;
                          case NotificationType.skipped:
                            icon = Icons.close;
                            iconColor = Colors.white;
                            circleColor = Colors.redAccent; // Red Circle
                            break;
                          case NotificationType.snoozed:
                            icon = Icons.snooze;
                            iconColor = Colors.orange;
                            circleColor = Colors.white;
                            break;
                          case NotificationType.scheduled:
                          default:
                            icon = Icons.alarm;
                            iconColor = Colors.blue;
                            circleColor = Colors.blue.withOpacity(0.1);
                            break;
                        }

                        // Build the leading widget
                        Widget leadingIcon;
                        if (note.type == NotificationType.snoozed) {
                          // Special style for Snoozed (Orange icon, white bg)
                          leadingIcon = Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 2)),
                            child: Icon(icon, color: iconColor, size: 24),
                          );
                        } else {
                          // Standard style (Filled circle)
                          leadingIcon = CircleAvatar(
                            backgroundColor: circleColor,
                            radius: 22,
                            child: Icon(icon, color: iconColor, size: 24),
                          );
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: leadingIcon,
                          title: Text(note.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(note.message,
                                  style:
                                      const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(note.time,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: Colors.grey),
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
  // Callback to update drawer from Home
  final Function(String action, String medicineName, String time)?
      onMedicineAction;

  const _HomeContent(
      {super.key, this.onMedicinesLoaded, this.onMedicineAction});

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
    "Take your medicines on time for better results.",
    "A 30-minute walk everyday keeps the heart strong.",
    "Eat more fruits and vegetables.",
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
          // --- HEALTH QUOTE ---
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

          // --- MEDICINE LIST ---
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
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.5))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40, color: Colors.green.withOpacity(0.5)),
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

          // --- ACTION BUTTONS ---
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
                    // 1. Add to Database History
                    await MedicineHistoryService.addMedicineRecord(
                        MedicineRecord(
                            medicineName: medicine.name,
                            time: medicine.time,
                            dosage: medicine.dose,
                            dateTaken: DateTime.now()));

                    // 2. Add to Activity Log (Critical for the drawer)
                    final timeStr =
                        "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
                    final entry = NotificationEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: "Medicine Taken",
                        message: "You took ${medicine.name}",
                        time: timeStr,
                        type: NotificationType.taken);

                    await ActivityLogService.addLog(entry);

                    // 3. Update Drawer Immediately
                    if (widget.onMedicineAction != null) {
                      widget.onMedicineAction!("Taken", medicine.name, timeStr);
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
