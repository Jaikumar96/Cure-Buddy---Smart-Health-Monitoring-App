import 'package:cure_buddy/screens/admin/admin_main_screen.dart';

import 'package:cure_buddy/screens/doctor/doctor_main_screen.dart';
import 'package:cure_buddy/screens/patient/lab_booking_screen.dart';
import 'package:cure_buddy/screens/patient/my_reports_screen.dart'; // Assuming this exists
import 'package:cure_buddy/screens/patient/patient_profile_screen.dart';
import 'package:cure_buddy/screens/patient/pharmacy_screen.dart';
import 'package:cure_buddy/screens/patient/schedule_checkup_screen.dart';
import 'package:cure_buddy/screens/patient/upload_report_screen.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginScreen(),
  '/patient-dashboard': (context) => PatientDashboardScreen(), // Tab 0 (Home)


  // Tab specific routes (though BottomNav handles main navigation)
  '/home': (context) => PatientDashboardScreen(),
  '/health-reports': (context) => UploadReportScreen(),      // Tab 1
  '/checkups': (context) => ScheduleCheckupScreen(),         // Tab 2
  '/pharmacy': (context) => PharmacyScreen(),
  // Tab 3
  '/patient-profile': (context) => const PatientProfileScreen(),

  // Specific feature routes (can be pushed from anywhere)
  '/schedule-checkup-form': (ctx) => ScheduleCheckupScreen(), // If needed for deep linking to form
  '/lab-booking': (ctx) => LabBookingScreen(),
  '/my-reports': (context) => MyReportsScreen(), // Make sure this screen exists and is defined
  // '/analytics': (context) => AnalyticsScreen(), // Define if exists
  // '/generate-report': (context) => GenerateReportScreenPage(), // Define if exists

  // In your appRoutes
  '/doctor-dashboard': (context) => DoctorMainScreen(), // Changed to DoctorMainScreen
  // In your appRoutes
  '/admin-dashboard': (context) => AdminMainScreen(),
};