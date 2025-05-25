import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'upload_report_screen.dart';
import 'schedule_checkup_screen.dart';
import 'lab_booking_screen.dart';
import 'patient_profile_screen.dart';

// --- Data Model for Health Report Item (remains the same) ---
class HealthReportItem {
  final String id;
  final String fileName;
  final String? healthRiskPrediction;
  final String? doctorRemarks;
  final String? doctorAdvice;
  final DateTime uploadedAt;
  final DateTime? doctorRespondedAt;

  HealthReportItem({
    required this.id,
    required this.fileName,
    this.healthRiskPrediction,
    this.doctorRemarks,
    this.doctorAdvice,
    required this.uploadedAt,
    this.doctorRespondedAt,
  });

  factory HealthReportItem.fromJson(Map<String, dynamic> json) {
    return HealthReportItem(
      id: json['_id'] as String,
      fileName: json['fileName'] as String,
      healthRiskPrediction: json['healthRiskPrediction'] as String?,
      doctorRemarks: json['doctorRemarks'] as String?,
      doctorAdvice: json['doctorAdvice'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      doctorRespondedAt: json['doctorRespondedAt'] != null
          ? DateTime.parse(json['doctorRespondedAt'] as String)
          : null,
    );
  }
}
// --- End of Data Model ---

IconData _getIconData(String? iconName) {
  switch (iconName) {
    case 'water_drop': return Icons.water_drop_outlined;
    case 'fitness_center': return Icons.fitness_center_outlined;
    default: return Icons.lightbulb_outline;
  }
}

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  String userName = 'User';
  List<dynamic> schedules = [];
  List<Map<String, String>> healthTips = [];
  List<HealthReportItem> _healthReports = [];
  bool isLoading = true;
  String? _token;

  bool _showAllReports = false;
  final int _defaultRecentReportsToShow = 1;

  static const String _apiBaseUrl = 'http://192.168.252.250:8080/api'; // Ensure this is correct

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null || _token!.isEmpty) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    _loadData();
  }

  Future<List<HealthReportItem>> _fetchMyHealthReports(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/patient/my-reports'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => HealthReportItem.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load reports. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    if (_token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.getUserDetails(_token!),
        ApiService.getPatientSchedules(_token!),
        ApiService.getFeaturedHealthTips(_token!),
        _fetchMyHealthReports(_token!),
      ]);
      if (!mounted) return;
      setState(() {
        userName = (results[0] as Map<String, dynamic>)['name'] ?? 'User';
        schedules = results[1] as List<dynamic>;
        healthTips = (results[2] as List<dynamic>)
            .map((tip) => Map<String, String>.from(tip as Map))
            .toList();
        _healthReports = results[3] as List<HealthReportItem>;
        _healthReports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      });
    } catch (e) {
      print("Error loading dashboard data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.orangeAccent),
        );
        _healthReports = []; // Ensure it's empty on error
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildPatientInfoCard(ThemeData theme) {
    // This card already has a professional gradient.
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.85),
              theme.primaryColorDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox(
          height: 170,
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.only(left: 22.0, right: 12.0, top: 20.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hello, $userName",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "How are you feeling today? Let's check your health status.",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  height: double.infinity,
                  child: Image.asset(
                    'assets/patient_avatar.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(Icons.person_outline_rounded, size: 60, color: Colors.white60),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(dynamic sched) {
    final theme = Theme.of(context); // Get theme context

    DateTime? dt;
    if (sched['scheduledDateTime'] != null) {
      try {
        dt = DateTime.parse(sched['scheduledDateTime']).toLocal();
      } catch (e) {
        print("Date parse error: $e");
      }
    }
    String formattedDate = dt != null ? DateFormat('dd MMM, yyyy').format(dt) : 'N/A';
    String formattedTime = dt != null ? DateFormat('hh:mm a').format(dt) : 'N/A';

    // --- NEW: Vibrant Purple Color Scheme for Schedule Card ---
    const Color primaryPurple = Color(0xFF7E57C2); // A rich, medium purple (Material Purple 400)
    const Color darkerPurple = Color(0xFF5E35B1); // A slightly darker, deeper purple (Material Purple 600)
    // Alternative Purples you might like:
    // const Color primaryPurple = Color(0xFF673AB7); // Deep Purple 500
    // const Color darkerPurple = Color(0xFF512DA8); // Deep Purple 700
    // const Color primaryPurple = Color(0xFFAB47BC); // Purple 300 (lighter)
    // const Color darkerPurple = Color(0xFF8E24AA); // Purple 500

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, darkerPurple], // Apply new purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryPurple.withOpacity(0.35), // Shadow uses the primary purple color with opacity
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print("Tapped on schedule: ${sched['vitalName']}");
            // Potentially navigate to a schedule detail screen
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.15), // White splash remains good for contrast
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(sched['vitalName'] ?? 'Checkup',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white), // Text color remains white for contrast
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedDate,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9), fontSize: 14)),
                    Text(formattedTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25), // Semi-transparent white tag
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(sched['frequency'] ?? 'One-Time',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHealthTipCard(Map<String, String> tip) {
    final theme = Theme.of(context);
    // --- NEW: Enhanced Background for Health Tip Card ---
    final tipCardBaseColor = theme.cardColor;
    // A subtle blend with primary color for a gentle accent
    final tipCardGradientEndColor = Color.alphaBlend(
        theme.primaryColor.withOpacity(0.05), // Slightly more tint than report card
        tipCardBaseColor
    );

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tipCardBaseColor, tipCardGradientEndColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08), // Consistent soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.3), width: 0.5), // Subtle border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print("Tapped on tip: ${tip['title']}"),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Increased padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.12), // Icon background
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconData(tip['icon']), size: 26, color: theme.primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  tip['title'] ?? 'Health Tip',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface, // Themed text color
                      fontSize: 15.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    tip['description'] ?? 'Stay healthy!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, // Themed text color
                        fontSize: 13,
                        height: 1.35),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecentReportTile(HealthReportItem report, ThemeData theme) {
    bool hasDoctorResponse = report.doctorRemarks != null && report.doctorRemarks!.isNotEmpty;
    String formattedUploadDate = DateFormat('dd MMM yyyy').format(report.uploadedAt.toLocal());

    Color statusColor = hasDoctorResponse ? Colors.green.shade600 : Colors.amber.shade700;
    IconData statusIcon = hasDoctorResponse ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded;
    String statusText = hasDoctorResponse ? "Doctor Responded" : "Awaiting Review";

    Color riskColor = Colors.grey;
    switch (report.healthRiskPrediction?.toUpperCase()) {
      case 'CRITICAL': riskColor = Colors.red.shade700; break;
      case 'MODERATE': riskColor = Colors.orange.shade700; break;
      case 'NORMAL': riskColor = Colors.green.shade700; break;
      default: riskColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.8); // Use themed color
    }

    // --- NEW: Enhanced Background for Report Tile ---
    Color gradientStart;
    Color gradientEnd;

    if (theme.brightness == Brightness.light) {
      // A very light, clean, and cool blue gradient for light mode
      gradientStart = const Color(0xFFEFF7FF); // A very pale, almost icy blue
      gradientEnd = const Color(0xFFE1F0FF);   // A slightly deeper, but still very light, serene blue
    } else {
      // For dark mode, create a subtle gradient based on the theme's card color
      // This adds depth without drastically changing the dark theme's feel.
      final baseDarkCardColor = theme.cardColor;
      gradientStart = Color.lerp(baseDarkCardColor, Colors.white, 0.03)!; // Slightly lighter shade
      gradientEnd = Color.lerp(baseDarkCardColor, Colors.black, 0.03)!;   // Slightly darker shade
      // Or simply baseDarkCardColor if you want less effect
    }

    BoxDecoration cardDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientStart,
            gradientEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4), width: 0.5), // Slightly more visible border
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.07), // Slightly adjusted shadow
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ]
    );
    // --- End of New Background ---

    return Card(
      elevation: 0, // Elevation is handled by the BoxDecoration's shadow
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: Colors.transparent, // Card itself is transparent; decoration provides the background
      child: InkWell(
        onTap: () => _showReportDetailsDialog(report, theme),
        borderRadius: BorderRadius.circular(16.0), // Match shape for ink splash
        splashColor: theme.primaryColor.withOpacity(0.05),
        highlightColor: theme.primaryColor.withOpacity(0.03),
        child: Container(
          decoration: cardDecoration, // Apply the new decoration here
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon remains themed with primaryColor, which should contrast well
              Icon(Icons.description_outlined, size: 36, color: theme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.fileName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface, // Ensure text color is from theme
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded: $formattedUploadDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, // Ensure text color is from theme
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (report.healthRiskPrediction != null && report.healthRiskPrediction!.isNotEmpty)
                      Text(
                        'Risk: ${report.healthRiskPrediction}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: riskColor, // Risk color is dynamic
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetailsDialog(HealthReportItem report, ThemeData theme) {
    String formattedUploadDate = DateFormat('dd MMM yyyy, hh:mm a').format(report.uploadedAt.toLocal());
    String formattedResponseDate = report.doctorRespondedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(report.doctorRespondedAt!.toLocal())
        : 'N/A';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor, // Use theme card color for dialog
          title: Row(
            children: [
              Icon(Icons.summarize_outlined, color: theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: Text(report.fileName, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface))),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow("Uploaded:", formattedUploadDate, theme),
                if (report.healthRiskPrediction != null)
                  _buildDetailRow("Health Risk:", report.healthRiskPrediction!, theme),
                const Divider(height: 20),
                Text("Doctor's Feedback:", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                _buildDetailRow("Remarks:", report.doctorRemarks ?? "No remarks yet.", theme, isValueBold: false),
                _buildDetailRow("Advice:", report.doctorAdvice ?? "No advice yet.", theme, isValueBold: false),
                _buildDetailRow("Responded On:", formattedResponseDate, theme),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme, {bool isValueBold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isValueBold ? FontWeight.w600 : FontWeight.normal, color: theme.colorScheme.onSurface))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewMore, String? viewMoreText}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.3, color: Theme.of(context).colorScheme.onBackground)),
          if (onViewMore != null && viewMoreText != null)
            TextButton(
              onPressed: onViewMore,
              child: Text(viewMoreText, style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    // --- NEW: Enhanced styling for Additional Info Item ---
    final itemCardBaseColor = theme.cardColor;
    // A very subtle gradient for consistency
    final itemCardGradientEndColor = Color.alphaBlend(
        theme.dividerColor.withOpacity(0.02),
        itemCardBaseColor
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0), // Consistent margin
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [itemCardBaseColor, itemCardGradientEndColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05), // Subtle shadow
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.4), width: 0.5), // Subtle border
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Adjusted padding
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? theme.primaryColor, size: 26),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface), // Themed text color
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int reportsToDisplay = _showAllReports ? _healthReports.length : (_healthReports.isNotEmpty ? _defaultRecentReportsToShow : 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Use theme's background color
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 2,
        title: Text(
          'My Dashboard',
          style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.account_circle_rounded,
              color: theme.colorScheme.onPrimary,
              size: 30,
            ),
            tooltip: 'Account Options',
            onSelected: (String result) {
              if (result == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientProfileScreen()),
                ).then((value) {
                  if (value == true) {
                    _initializeDashboard();
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 10),
                    Text('My Profile', style: TextStyle(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: theme.colorScheme.surface, // Use theme surface color for popup
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: theme.primaryColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            _buildPatientInfoCard(theme),

            _buildSectionHeader(
              'Recent Health Reports',
              onViewMore: _healthReports.length > _defaultRecentReportsToShow ? () {
                setState(() {
                  _showAllReports = !_showAllReports;
                });
              } : null,
              viewMoreText: _healthReports.length > _defaultRecentReportsToShow
                  ? (_showAllReports ? 'Show Less' : 'View All')
                  : null,
            ),
            if (_healthReports.isEmpty && !isLoading)
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                  decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.7), // Slightly transparent card
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined,
                          size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('No health reports found yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file_outlined, size: 20),
                        label: const Text("Upload Your First Report"),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadReportScreen())).then((_) => _loadData()),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)
                        ),
                      )
                    ],
                  ))
            else
              ...List.generate(
                reportsToDisplay,
                    (index) => _buildRecentReportTile(_healthReports[index], theme),
              ),

            _buildSectionHeader('My Checkup Schedule'),
            schedules.isEmpty && !isLoading
                ? Container(
              // height: 160, // Height might vary based on content
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5))
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    const SizedBox(height: 10),
                    Text('No upcoming checkups scheduled.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text("Schedule Now"),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ScheduleCheckupScreen())).then((_) => _loadData());
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                      ),
                    )
                  ],
                ))
                : SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: schedules.length,
                itemBuilder: (context, i) =>
                    _buildScheduleCard(schedules[i]),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),


            _buildSectionHeader('Daily Health Tips'),
            healthTips.isEmpty && !isLoading
                ? Container(
              // height: 140, // Height might vary
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  const SizedBox(height: 10),
                  Text('No health tips available right now.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8))),
                ],
              ),
            )
                : SizedBox(
              height: 190, // Adjusted height to better fit enhanced card
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: healthTips.length,
                itemBuilder: (context, i) =>
                    _buildHealthTipCard(healthTips[i]),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),

            _buildSectionHeader('Explore & Manage', viewMoreText: null),
            _buildAdditionalInfoItem(
              icon: Icons.cloud_upload_outlined,
              label: 'Upload New Report',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadReportScreen())).then((_) => _loadData()),
            ),
            // const SizedBox(height: 12), // Margin is handled by _buildAdditionalInfoItem
            _buildAdditionalInfoItem(
              icon: Icons.science_outlined,
              label: 'Book Lab Test',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabBookingScreen())).then((_) => _loadData()),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 0),
    );
  }
}