import 'dart:async'; // Required for Timer
import 'dart:io';
import 'package:flutter/material.dart';
import '../routes.dart';
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import 'invite_Screen.dart';
import '../services/medicine_history_service.dart';
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../Model/invite_info.dart';
import '../services/notification_service.dart';
<<<<<<< Updated upstream
import '../services/activity_log_service.dart';
=======
import '../services/invite_notification_service.dart';
import '../services/refill_alert_service.dart';
import '../services/report_service.dart';

>>>>>>> Stashed changes

// --- 1. Notification Model ---
class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type; // 'medicine', 'invite', or 'refill'
  final InviteInfo? inviteInfo; // For invite notifications

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.type = 'medicine',
    this.inviteInfo,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  Key _homeKey = UniqueKey();
  late final List<Widget> _widgetOptions;

  // List to hold notifications for the UI Drawer
  List<NotificationEntry> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadPendingInvites();

    // Initialize screens
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload invites when screen becomes visible again
    _loadPendingInvites();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.requestPermissions();
  }

  Future<void> _loadPendingInvites() async {
    final pendingInvites = await InviteNotificationService.getPendingInvites();
    if (!mounted) return;
    
    setState(() {
      // Remove old invite notifications
      _notifications.removeWhere((n) => n.type == 'invite');
      
      // Add new invite notifications
      for (var invite in pendingInvites) {
        final inviterName = invite.inviterName ?? 'Someone';
        final roleText = invite.role == 'caregiver' ? 'caregiver' : 'patient';
        _notifications.insert(0, NotificationEntry(
          id: 'invite_${invite.inviterId}_${invite.role}',
          title: 'Connection Invitation',
          message: '$inviterName wants to connect as $roleText',
          time: 'Pending',
          type: 'invite',
          inviteInfo: invite,
        ));
      }
    });
  }

  Future<void> _updateNotificationsFromMedicines(
      List<Medicine> medicines) async {
    await NotificationService.cancelAll();
    for (var med in medicines) {
      await NotificationService.scheduleMedicineReminder(med);
    }

    if (mounted) {
      setState(() {
        // Medicine reminder notifications
        final medicineNotifications = medicines.map((med) {
          return NotificationEntry(
            id: med.id.toString(),
            title: "Alarm Set",
            message: "Pop-up scheduled for ${med.name}",
            time: med.time,
            type: 'medicine',
          );
        }).toList();

        // Refill alert notifications
        final refillNotifications = medicines
            .where((med) => RefillAlertService.needsRefill(med))
            .map((med) {
          final daysRemaining = RefillAlertService.getDaysRemaining(med);
          final urgency = RefillAlertService.getRefillUrgency(med);
          
          String title;
          if (daysRemaining <= 0) {
            title = '⚠️ Refill Needed Now';
          } else if (urgency == 'urgent') {
            title = '🔴 Urgent: Refill Needed';
          } else {
            title = '🟡 Refill Reminder';
          }
          
          return NotificationEntry(
            id: 'refill_${med.id}',
            title: title,
            message: '${med.name} - ${daysRemaining <= 0 ? "Out of stock" : "$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining"}',
            time: 'Refill Alert',
            type: 'refill',
          );
        }).toList();

        // Combine all notifications (refill alerts first, then medicine reminders)
        _notifications = [...refillNotifications, ...medicineNotifications];
      });
    }
  }

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
    // Reload invites when switching tabs
    _loadPendingInvites();
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
                        final isInvite = note.type == 'invite';
                        final isRefill = note.type == 'refill';
                        
                        // Determine icon and color based on notification type
                        IconData icon;
                        Color? backgroundColor;
                        Color? iconColor;
                        
                        if (isInvite) {
                          icon = Icons.person_add_alt_1;
                          backgroundColor = Colors.pink[50];
                          iconColor = Colors.pinkAccent;
                        } else if (isRefill) {
                          icon = Icons.warning_amber_rounded;
                          backgroundColor = Colors.orange[50];
                          iconColor = Colors.orange[700];
                        } else {
                          icon = Icons.alarm_on;
                          backgroundColor = Colors.blue[50];
                          iconColor = Colors.blueAccent;
                        }
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: backgroundColor,
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: 20,
                            ),
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
                          onTap: isInvite ? () {
                            // Open invite screen when invite notification is tapped
                            if (note.inviteInfo != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InviteScreen(
                                    inviterId: note.inviteInfo!.inviterId,
                                    role: note.inviteInfo!.role,
                                    inviterName: note.inviteInfo!.inviterName,
                                  ),
                                ),
                              ).then((_) {
                                // Reload invites after returning from invite screen
                                _loadPendingInvites();
                              });
                            }
                          } : isRefill ? () {
                            // Navigate to medicines tab when refill notification is tapped
                            _onItemTapped(1); // Index 1 is ViewAllMedicinesScreen
                          } : null,
                          trailing: PopupMenuButton<String>(
                            icon:
                                const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'delete') {
                                if (isInvite && note.inviteInfo != null) {
                                  // Remove from pending invites
                                  InviteNotificationService.removePendingInvite(
                                    note.inviteInfo!.inviterId,
                                    note.inviteInfo!.role,
                                  );
                                }
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
    // Get screen height to calculate the "max height" for the list
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // Keeps page stable
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. HEALTH QUOTE (Fixed at Top) ---
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

          // --- 2. MEDICINE LIST (Constrained Height Area) ---
          // This is the fix. It allows the list to grow up to 45% of the screen.
          // If 1 item: it fits naturally.
          // If 10 items: it scrolls INSIDE this box, keeping buttons visible.
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
                // Empty state looks full enough
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

              // ConstrainedBox enforces the "Window" effect
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 100, // Always show at least this much
                  maxHeight: screenHeight * 0.45, // Cap height at 45% of screen
                ),
                child: Container(
                  decoration: BoxDecoration(
                    // A subtle visual cue that this is a contained list
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      shrinkWrap:
                          true, // Only take needed space up to max constraint
                      padding: const EdgeInsets.only(
                          bottom: 10, right: 5), // Space for scrollbar
                      itemCount: medicines.length,
                      physics:
                          const BouncingScrollPhysics(), // Nice scroll feel
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

          // --- 3. ACTION BUTTONS (Always accessible now) ---
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
          // Extra padding at bottom to ensure nothing is cut off
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
