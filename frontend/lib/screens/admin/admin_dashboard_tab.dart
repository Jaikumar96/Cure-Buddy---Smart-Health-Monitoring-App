// lib/screens/admin/admin_dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class AdminDashboardTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminDashboardTab({super.key, this.onNavigateToTab});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  int _totalUsers = 0;
  int _totalReports = 0;
  int _doctorsPendingVerification = 0;
  String _adminName = "Admin";

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllDashboardData();
  }

  Future<void> _fetchAllDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final results = await Future.wait([
        ApiService.getAdminDashboardStats(token),
        ApiService.getUserDetails(token),
        ApiService.getAdminAllUsers(token),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final userDetails = results[1] as Map<String, dynamic>;
      final allUsers = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          _totalUsers = stats['totalUsers'] ?? 0;
          _totalReports = stats['totalReports'] ?? 0;
          _adminName = userDetails['name'] ?? 'Admin';
          _doctorsPendingVerification = allUsers
              .where((user) => user['role'] == 'DOCTOR' && (user['licenseVerified'] == false || user['licenseVerified'] == null) )
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard. Please try again.';
          print("Admin Dashboard Error: $e");
        });
      }
    }
  }

  // NEW: Admin Welcome Card
  Widget _buildAdminWelcomeCard(ThemeData theme) {
    return Card(
      elevation: 6.0,
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
          height: 170, // Adjust height as needed
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 8, // Give more space to text
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome back, $_adminName!",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "\"Empowering health through diligent oversight and innovation.\"", // Admin-focused quote
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3, // Space for an icon
                  child: Column( // To center the icon vertically
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 70,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), // Changed title
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _isLoading ? null : _fetchAllDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _errorMessage.isNotEmpty
          ? _buildErrorState(theme)
          : RefreshIndicator(
        onRefresh: _fetchAllDashboardData,
        color: theme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              // The new Admin Welcome Card is the first item
              child: _buildAdminWelcomeCard(theme),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Adjusted top padding
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('Key Metrics', theme),
                  const SizedBox(height: 14.0),
                  _buildKeyMetricsRow(theme),
                  const SizedBox(height: 30.0),
                  _buildSectionTitle('Quick Actions', theme),
                  const SizedBox(height: 14.0),
                  _buildQuickActionsList(theme),
                  const SizedBox(height: 24.0),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error.withOpacity(0.7), size: 60),
            const SizedBox(height: 16),
            Text(
              'Oops! Something Went Wrong',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: _fetchAllDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  // _buildWelcomeHeader is removed as its content is in _buildAdminWelcomeCard

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildKeyMetricsRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMetricCard(
            theme: theme,
            title: 'Total Users',
            value: _totalUsers.toString(),
            icon: Icons.groups_rounded,
            iconColor: Colors.blue.shade700,
            backgroundColor: Colors.blue.shade50,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildMetricCard(
            theme: theme,
            title: 'Total Reports',
            value: _totalReports.toString(),
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.green.shade700,
            backgroundColor: Colors.green.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Card(
      elevation: 2.0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure card takes minimum necessary height
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28.0, color: iconColor),
            ),
            const SizedBox(height: 16.0),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: iconColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsList(ThemeData theme) {
    return Column(
      children: [
        _buildActionCard(
          theme: theme,
          title: 'Verify Doctors',
          subtitle: '$_doctorsPendingVerification pending verification',
          icon: Icons.medical_information_outlined,
          iconColor: Colors.orange.shade800,
          backgroundColor: Colors.orange.shade50,
          onTap: () {
            widget.onNavigateToTab?.call(2);
          },
          valueForBadge: _doctorsPendingVerification,
        ),
        _buildActionCard(
          theme: theme,
          title: 'Manage All Users',
          subtitle: 'View and manage patient & doctor accounts.',
          icon: Icons.manage_accounts_rounded,
          iconColor: Colors.purple.shade700,
          backgroundColor: Colors.purple.shade50,
          onTap: () {
            widget.onNavigateToTab?.call(1);
          },
        ),
        _buildActionCard(
          theme: theme,
          title: 'System Reports',
          subtitle: 'Access and review all health reports.',
          icon: Icons.assessment_outlined,
          iconColor: Colors.teal.shade700,
          backgroundColor: Colors.teal.shade50,
          onTap: () {
            widget.onNavigateToTab?.call(3);
          },
        ),
        _buildActionCard(
          theme: theme,
          title: 'System Settings',
          subtitle: 'Configure application parameters.',
          icon: Icons.settings_outlined,
          iconColor: Colors.grey.shade700,
          backgroundColor: Colors.grey.shade200,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to System Settings (Not Implemented)'))
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    VoidCallback? onTap,
    int valueForBadge = 0,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 14.0),
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30.0, color: iconColor),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        )
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          height: 1.35
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (valueForBadge > 0) ...[
                const SizedBox(width: 12.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    valueForBadge.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 8.0),
                Icon(Icons.arrow_forward_ios_rounded, color: iconColor.withOpacity(0.7), size: 18),
              ]

            ],
          ),
        ),
      ),
    );
  }
}