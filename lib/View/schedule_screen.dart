import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart'; // Uncomment this line and add dependency

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Uncomment and use if you add table_calendar dependency
  // CalendarFormat _calendarFormat = CalendarFormat.month;
  // DateTime _focusedDay = DateTime.now();
  // DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // // Example TableCalendar - Uncomment if dependency is added
                    // TableCalendar(
                    //   firstDay: DateTime.utc(2020, 1, 1),
                    //   lastDay: DateTime.utc(2030, 12, 31),
                    //   focusedDay: _focusedDay,
                    //   calendarFormat: _calendarFormat,
                    //   selectedDayPredicate: (day) {
                    //     return isSameDay(_selectedDay, day);
                    //   },
                    //   onDaySelected: (selectedDay, focusedDay) {
                    //     setState(() {
                    //       _selectedDay = selectedDay;
                    //       _focusedDay = focusedDay; // update `_focusedDay` here as well
                    //     });
                    //   },
                    //   onFormatChanged: (format) {
                    //     if (_calendarFormat != format) {
                    //       setState(() {
                    //         _calendarFormat = format;
                    //       });
                    //     }
                    //   },
                    //   onPageChanged: (focusedDay) {
                    //     _focusedDay = focusedDay;
                    //   },
                    //   headerStyle: HeaderStyle(
                    //     formatButtonVisible: false, // Hide format change button
                    //     titleCentered: true,
                    //     titleTextStyle: const TextStyle(
                    //       fontSize: 18.0,
                    //       color: Colors.black87,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //     leftWithChevronIcon: Icon(Icons.chevron_left, color: Colors.red),
                    //     rightWithChevronIcon: Icon(Icons.chevron_right, color: Colors.red),
                    //   ),
                    //   calendarStyle: CalendarStyle(
                    //     selectedDecoration: BoxDecoration(
                    //       color: Theme.of(context).primaryColor,
                    //       shape: BoxShape.circle,
                    //     ),
                    //     todayDecoration: BoxDecoration(
                    //       color: Theme.of(context).primaryColor.withOpacity(0.5),
                    //       shape: BoxShape.circle,
                    //     ),
                    //     weekendTextStyle: const TextStyle(color: Colors.red),
                    //   ),
                    // ),
                    // Placeholder for when table_calendar is not added
                    Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: Text(
                        'Calendar widget goes here.\n(Add table_calendar dependency)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Upcoming Doses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildScheduleItem(
              'Paracetamol',
              'Today, 8:00 AM',
              '1 tablet',
              Colors.blueAccent,
            ),
            _buildScheduleItem(
              'Multivitamin',
              'Today, 1:00 PM',
              '1 capsule',
              Colors.orangeAccent,
            ),
            _buildScheduleItem(
              'Amoxicillin',
              'Today, 7:00 PM',
              '1 tablet',
              Colors.purpleAccent,
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No more doses scheduled for today.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    String medicineName,
    String time,
    String dosage,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$time - $dosage',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 28,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Marked $medicineName as taken')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
