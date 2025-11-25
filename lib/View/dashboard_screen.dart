import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../routes.dart';
import 'view_all_medicine.dart';
import 'caregiver_screen.dart';
import 'profile_screen.dart';
import '../services/medicine_history_service.dart';
import '../services/medicine_repository.dart';
import '../services/notification_center_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);

  // State variable to hold notifications for the drawer
  List<NotificationEntry> _currentNotifications = [];

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  @override
  void dispose() {
    _unreadCountNotifier.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentBody() {
    switch (_selectedIndex) {
      case 0:
        return _HomeContent(
          onNotificationsChanged: _refreshUnreadCount,
        );
      case 1:
        return const ViewAllMedicinesScreen();
      case 2:
        return const CaregiverScreen();
      case 3:
      default:
        return const ProfileScreen();
    }
  }

  Future<void> _refreshUnreadCount() async {
    final count = await NotificationCenterService.getUnreadCount();
    if (!mounted) return;
    _unreadCountNotifier.value = count;
  }

  Future<void> _openNotificationCenter() async {
    // 1. Fetch data
    final notifications = await NotificationCenterService.getNotifications();

    if (!mounted) return;

    // 2. Update state so the drawer rebuilds with data
    setState(() {
      _currentNotifications = notifications;
    });

    // 3. Open the Side Drawer
    _scaffoldKey.currentState?.openEndDrawer();

    // 4. Mark as read
    await NotificationCenterService.markAllRead();
    await _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    bool showDashboardAppBar = _selectedIndex == 0;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey, // Attach the key here
      backgroundColor: Colors.grey[50],
      // Define the Right Side Drawer
      endDrawer: Drawer(
        // INCREASED WIDTH to 85% to prevent overflow and provide better view
        width: screenWidth * 0.85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        ),
        child: _NotificationSidePanel(
          notifications: _currentNotifications,
          onClose: () => Navigator.of(context).pop(), // Close drawer
        ),
      ),
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
                ValueListenableBuilder<int>(
                  valueListenable: _unreadCountNotifier,
                  builder: (context, unreadCount, _) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.notifications_rounded, size: 28),
                          // Trigger the drawer function
                          onPressed: _openNotificationCenter,
                          color: Colors.grey[700],
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 10,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],
            )
          : null,
      body: _buildCurrentBody(),
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

// Renamed and styled for Side Panel with PINK THEME
class _NotificationSidePanel extends StatelessWidget {
  const _NotificationSidePanel({
    required this.notifications,
    required this.onClose,
  });

  final List<NotificationEntry> notifications;
  final VoidCallback onClose;

  IconData _iconForType(String type) {
    switch (type) {
      case 'taken':
        return Icons.check_circle;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.info;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'taken':
        return Colors.green;
      case 'reminder':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d • h:mm a');

    return Container(
      // PINK THEME BACKGROUND
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF0F5), // Light Pink (Lavender Blush)
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Wrapped in Expanded to prevent overflow on right
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  blurRadius: 5)
                            ]),
                        child: const Icon(Icons.close_rounded, size: 20)),
                    onPressed: onClose,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, color: Color(0xFFFFD1DC)), // Pinkish divider

            // Content
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 50,
                                color:
                                    Colors.pinkAccent.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'All caught up!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = notifications[index];
                        final color = _colorForType(entry.type);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD1DC)
                                    .withValues(alpha: 0.3), // Pink shadow
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.pink.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconForType(entry.type),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dateFormatter.format(entry.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    this.onNotificationsChanged,
  });

  final Future<void> Function()? onNotificationsChanged;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final MedicineRepository _repository = MedicineRepository.instance;
  final DateFormat _timeFormatter = DateFormat('h:mm a');
  final DateFormat _dateFormatter = DateFormat('EEE, MMM d');

  // --- UPDATED: 30 Health Tips ---
  final List<String> _healthTips = [
    'Drink at least 8 glasses of water today to stay hydrated.',
    'Take a 5-minute break to stretch and move around.',
    'A healthy outside starts from the inside. Eat your veggies!',
    'Consistency is key. Try to take your meds at the same time.',
    'Sleep is the best meditation. Aim for 7-8 hours.',
    'Wash your hands frequently to keep germs away.',
    'Mental health matters. Take a moment to breathe deeply.',
    'Limit processed sugar for better energy levels.',
    'Walking for 20 minutes a day boosts heart health.',
    'Don\'t skip breakfast! It fuels your day.',
    'Posture check! Sit up straight to avoid back pain.',
    'Laughter boosts your immune system. Smile more!',
    'Limit caffeine intake after 4 PM for better sleep.',
    'Protect your skin. Wear sunscreen when outside.',
    'Keep your emergency contacts updated in your phone.',
    'Organize your pills weekly to avoid missing a dose.',
    'Rest if you feel tired. Listen to your body.',
    'Eat slowly and enjoy your food to aid digestion.',
    'Reduce salt intake to maintain healthy blood pressure.',
    'Connect with a friend today. Socializing is good for the soul.',
    'Eye strain is real. Look away from screens every 20 mins.',
    'Fiber is your friend. Eat whole grains and fruits.',
    'Stay positive. A good attitude heals the body.',
    'Check medication expiry dates regularly.',
    'Herbal tea can be a great way to relax before bed.',
    'Gratitude reduces stress. Name one thing you are thankful for.',
    'Physical activity increases endorphins and happiness.',
    'Keep a water bottle nearby to remind you to drink.',
    'Avoid heavy meals right before bedtime.',
    'You are doing a great job taking care of your health!',
  ];

  bool _isLoading = true;
  List<MedicineEntry> _todayMedicines = [];
  Timer? _healthTipTimer;
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayMedicines();
    _startHealthTipRotation();
  }

  @override
  void dispose() {
    _healthTipTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayMedicines() async {
    final medicines = await _repository.getTodayMedicines(DateTime.now());
    if (!mounted) return;
    setState(() {
      _todayMedicines = medicines;
      _isLoading = false;
    });
    await _checkUpcomingMedicines(medicines);
  }

  void _startHealthTipRotation() {
    _healthTipTimer?.cancel();
    // CHANGED: Rotates every 10 seconds
    _healthTipTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _healthTips.length;
      });
    });
  }

  Future<void> _checkUpcomingMedicines(List<MedicineEntry> medicines) async {
    bool addedNotification = false;
    final now = DateTime.now();
    for (final entry in medicines) {
      final differenceMinutes =
          now.difference(entry.scheduledDateTime).inMinutes;
      if (differenceMinutes < -5 || differenceMinutes > 15) {
        continue;
      }

      await NotificationCenterService.addNotification(
        NotificationEntry(
          id: 'due-${entry.id}-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Time to take ${entry.name}',
          message:
              '${entry.dosage} scheduled at ${_timeFormatter.format(entry.scheduledDateTime)}',
          timestamp: DateTime.now(),
          type: 'reminder',
          metadataTag:
              'due-${entry.id}-${entry.scheduledDateTime.toIso8601String()}',
        ),
      );
      addedNotification = true;
    }

    if (addedNotification && widget.onNotificationsChanged != null) {
      await widget.onNotificationsChanged!();
    }
  }

  Future<void> _openAddMedicine(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.addMedicine);
    if (result == true) {
      await _loadTodayMedicines();
      if (widget.onNotificationsChanged != null) {
        await widget.onNotificationsChanged!();
      }
    }
  }

  Future<void> _openViewAllMedicines(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoutes.viewAll);
    await _loadTodayMedicines();
    if (widget.onNotificationsChanged != null) {
      await widget.onNotificationsChanged!();
    }
  }

  // --- NEW: Method to show details (Restored) ---
  void _showMedicineDetails(BuildContext context, MedicineEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final imagePath = entry.imagePath;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (imagePath != null && imagePath.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(imagePath),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Image not found"),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_outlined,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No photo added',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _detailRow(Icons.schedule, 'Time',
                        _timeFormatter.format(entry.scheduledDateTime)),
                    _detailRow(Icons.calendar_month, 'Date',
                        _dateFormatter.format(entry.scheduledDateTime)),
                    _detailRow(Icons.local_pharmacy, 'Dose', entry.dosage),
                    _detailRow(Icons.not_listed_location, 'Instruction',
                        entry.instruction),
                    _detailRow(Icons.repeat, 'Repeat', entry.repeat),
                    _detailRow(Icons.music_note, 'Ringtone', entry.ringtone),
                    _detailRow(
                      Icons.numbers,
                      'Pills in pack',
                      entry.pillCount.toString(),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTodayMedicines,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD1DC),
                    Color(0xFFE0F2FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Added AnimatedSwitcher for smooth transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _healthTips[_currentTipIndex],
                        key: ValueKey<int>(_currentTipIndex),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
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
            if (_isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (_todayMedicines.isEmpty) ...[
              _buildNoMedicinesCard(context),
            ] else
              ..._todayMedicines
                  .map((entry) => _buildMedicineReminderCard(context, entry)),
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
      ),
    );
  }

  Widget _buildNoMedicinesCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No reminders for today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Add Medicine" to schedule the next pill.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineReminderCard(
    BuildContext context,
    MedicineEntry entry,
  ) {
    final timeLabel = _timeFormatter.format(entry.scheduledDateTime);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.blueAccent[700], size: 32),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeLabel • ${entry.dosage}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
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
                    await MedicineHistoryService.addMedicineRecord(
                      MedicineRecord(
                        medicineName: entry.name,
                        time: timeLabel,
                        dosage: entry.dosage,
                        dateTaken: DateTime.now(),
                      ),
                    );
                    await NotificationCenterService.addNotification(
                      NotificationEntry(
                        id: 'taken-${entry.id}-${DateTime.now().millisecondsSinceEpoch}',
                        title: '${entry.name} taken',
                        message:
                            'Logged ${entry.dosage} at ${_timeFormatter.format(DateTime.now())}',
                        timestamp: DateTime.now(),
                        type: 'taken',
                        metadataTag:
                            'taken-${entry.id}-${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      ),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${entry.name} taken!')),
                      );
                    }
                    if (widget.onNotificationsChanged != null) {
                      await widget.onNotificationsChanged!();
                    }
                  },
                ),
              ],
            ),
            // --- NEW: Added bottom row for Date and View More ---
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormatter.format(entry.scheduledDateTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showMedicineDetails(context, entry),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View details'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicineButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openAddMedicine(context),
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
      ),
    );
  }

  Widget _buildViewAllMedicinesButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openViewAllMedicines(context),
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
        // FIXED THE ERROR HERE: Removed the extra 'a'
        backgroundColor: Colors.teal[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }
}
