import 'package:cure_buddy/screens/patient/pharmacy_screen.dart'; // New screen
import 'package:cure_buddy/screens/patient/schedule_checkup_screen.dart';
import 'package:flutter/material.dart';
import 'package:cure_buddy/screens/patient/patient_dashboard_screen.dart';
import 'package:cure_buddy/screens/patient/upload_report_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  const BottomNavBar({super.key, required this.selectedIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  void _onItemTapped(int index) {
    if (index == widget.selectedIndex) return;

    final List<Widget Function()> screens = [
          () => PatientDashboardScreen(),      // Index 0: Home
          () => UploadReportScreen(),          // Index 1: Health Reports
          () => ScheduleCheckupScreen(),       // Index 2: Checkups
          () => PharmacyScreen(),              // Index 3: Pharmacy
    ];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screens[index]()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), label: 'Checkups'),
        BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy_outlined), label: 'Pharmacy'),
      ],
    );
  }
}