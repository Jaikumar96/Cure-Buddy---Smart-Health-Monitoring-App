// lib/screens/doctor/doctor_dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; // Your ApiService

class DoctorDashboardTab extends StatefulWidget {
  const DoctorDashboardTab({super.key});

  @override
  State<DoctorDashboardTab> createState() => _DoctorDashboardTabState();
}

class _DoctorDashboardTabState extends State<DoctorDashboardTab> {
  String _doctorName = "Doctor";
  bool _isLoading = true;

  // Example data
  int _urgentReportsCount = 3;
  int _reviewedTodayCount = 5;
  int _upcomingAppointmentsCount = 2;
  int _pendingVerificationCount = 1;

  @override
  void initState() {
    super.initState();
    _loadDoctorDetailsAndStats();
  }

  Future<void> _loadDoctorDetailsAndStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final userDetails = await ApiService.getUserDetails(token);
      // --- ACTUAL STATS FETCHING (Example) ---
      // try {
      //   final stats = await ApiService.getDoctorDashboardStats(token);
      //   if (mounted) {
      //     setState(() {
      //       _urgentReportsCount = stats['urgentReportsCount'] ?? _urgentReportsCount;
      //       // ... and so on for other stats
      //     });
      //   }
      // } catch (e) { /* ... */ }

      if (mounted) {
        setState(() {
          _doctorName = userDetails['name'] ?? 'Doctor';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDoctorInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 5.0,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox(
          height: 190, // Increased height for better image display
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
                        "Hello, Dr. $_doctorName",
                        style: theme.textTheme.headlineMedium?.copyWith( // Slightly larger
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2, // Allow for longer names
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Here's your daily brief. Ready to make an impact?",
                        style: theme.textTheme.titleSmall?.copyWith( // Adjusted size
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
                    'assets/doctor_card_image.png', // Ensure this image is suitable
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter, // Try to show lower part if cropped
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(Icons.person_outline, size: 70, color: Colors.white60),
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100], // Cleaner background
      appBar: AppBar(
        title: Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 3, // Subtle shadow for AppBar
        centerTitle: false, // Align title to the left for a common modern look
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
        onRefresh: _loadDoctorDetailsAndStats,
        color: theme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDoctorInfoCard(context, theme),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildSectionTitle("Overview", theme),
                    const SizedBox(height: 14), // Increased spacing
                    _buildDashboardCard(
                      context,
                      icon: Icons.error_outline_rounded,
                      title: 'Urgent Reports',
                      value: _urgentReportsCount.toString(),
                      subtitle: 'Need immediate attention',
                      cardColor: Colors.red.shade50,
                      accentColor: Colors.red.shade700,
                      onTap: () => DefaultTabController.of(context)?.animateTo(1),
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.playlist_add_check_circle_outlined,
                      title: 'Reviewed Today',
                      value: _reviewedTodayCount.toString(),
                      subtitle: 'Productive day!',
                      cardColor: Colors.green.shade50,
                      accentColor: Colors.green.shade700,
                      onTap: () => DefaultTabController.of(context)?.animateTo(1),
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.pending_actions_outlined,
                      title: 'Pending Verification',
                      value: _pendingVerificationCount.toString(),
                      subtitle: 'Doctor registrations',
                      cardColor: Colors.orange.shade50,
                      accentColor: Colors.orange.shade700,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to Pending Verifications (Not Implemented)')),
                        );
                      },
                    ),
                    const SizedBox(height: 30), // Increased spacing
                    _buildSectionTitle("Quick Actions", theme),
                    const SizedBox(height: 14), // Increased spacing
                    _buildDashboardCard(
                      context,
                      icon: Icons.calendar_month_outlined,
                      title: 'My Schedule',
                      value: _upcomingAppointmentsCount.toString(),
                      subtitle: 'Upcoming appointments',
                      cardColor: Colors.blue.shade50,
                      accentColor: Colors.blue.shade700,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to My Schedule (Not Implemented)')),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.folder_shared_outlined,
                      title: 'View All Reports',
                      subtitle: 'Access patient report archive',
                      cardColor: Colors.purple.shade50,
                      accentColor: Colors.purple.shade700,
                      onTap: () => DefaultTabController.of(context)?.animateTo(1),
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.manage_search_outlined,
                      title: 'Patient Lookup',
                      subtitle: 'Search patient records',
                      cardColor: Colors.teal.shade50,
                      accentColor: Colors.teal.shade700,
                      onTap: () => DefaultTabController.of(context)?.animateTo(2),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), // More top padding
      child: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith( // Larger section title
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withOpacity(0.95), // More opaque
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? value,
        required String subtitle,
        required Color cardColor,
        required Color accentColor,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1.5, // Softer elevation for content cards
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Slightly less margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0), // Consistent rounding
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        splashColor: accentColor.withOpacity(0.1),
        highlightColor: accentColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Increased vertical padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0), // Larger icon background
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(icon, size: 30, color: accentColor), // Larger icon
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    value,
                    style: theme.textTheme.headlineLarge?.copyWith( // Larger value text
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              if (onTap != null && value == null)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 20, color: accentColor.withOpacity(0.7)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}