// lib/screens/doctor/doctor_main_screen.dart
import 'package:flutter/material.dart';
import 'doctor_dashboard_tab.dart';
import 'doctor_reports_tab.dart';
import 'doctor_search_patient_tab.dart';
import 'doctor_profile_tab.dart';
// Potentially: import '../widgets/doctor_bottom_nav_bar.dart'; // Or reuse existing

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    DoctorDashboardTab(),
    DoctorReportsTab(),
    DoctorSearchPatientTab(),
    DoctorProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Using IndexedStack to preserve state of tabs
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true, // Good for discoverability
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        onTap: _onItemTapped,
      ),
    );
  }
}