// lib/screens/doctor/doctor_reports_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'report_detail_screen.dart';
import 'filtered_reports_screen.dart'; // Import the new screen

// PatientReport model (ensure it has all necessary fields, including patientName if available)
// (PatientReport model definition remains the same as your last version)
class PatientReport {
  final String? id;
  final String fileName;
  final String? healthRiskPrediction;
  final String? doctorRemarks;
  final String? doctorAdvice;
  final String patientEmail;
  final String? patientName; // Added for better display
  final DateTime? uploadedAt;
  final String? reportUrl;

  PatientReport({
    this.id,
    required this.fileName,
    this.healthRiskPrediction,
    this.doctorRemarks,
    this.doctorAdvice,
    required this.patientEmail,
    this.patientName,
    this.uploadedAt,
    this.reportUrl,
  });

  factory PatientReport.fromJson(Map<String, dynamic> json) {
    return PatientReport(
      id: json['id']?.toString() ?? json['reportId']?.toString() ?? json['_id']?.toString() ?? json['fileName'] as String?,
      fileName: json['fileName'] as String? ?? 'Unknown Report',
      healthRiskPrediction: json['healthRiskPrediction'] as String?,
      doctorRemarks: json['doctorRemarks'] as String?,
      doctorAdvice: json['doctorAdvice'] as String?,
      patientEmail: json['patientEmail'] as String? ?? 'Unknown Patient',
      patientName: json['patientName'] as String?,
      uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt'] as String) : null,
      reportUrl: json['reportUrl'] as String? ?? json['downloadLink'] as String?,
    );
  }
}


class DoctorReportsTab extends StatefulWidget {
  const DoctorReportsTab({super.key});

  @override
  State<DoctorReportsTab> createState() => _DoctorReportsTabState();
}

class _DoctorReportsTabState extends State<DoctorReportsTab> {
  List<PatientReport> _allFetchedReports = []; // Store all reports from API
  List<PatientReport> _pendingReportsPreview = [];
  List<PatientReport> _reviewedReportsPreview = [];
  List<PatientReport> _displayInMainList = []; // For the main searchable list

  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const int PREVIEW_COUNT = 3;


  @override
  void initState() {
    super.initState();
    _fetchPatientReports();
    _searchController.addListener(() {
      if (mounted) {
        _applySearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientReports({String? updatedReportId}) async {
    if (!mounted) return;
    // If only one report was updated, try to update it in place to avoid full reload flicker
    // This is an advanced optimization. For now, we'll do a full reload.
    // If you want to implement this, you'd fetch only the single updated report
    // and replace it in _allFetchedReports.

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
      final List<dynamic> responseData = await ApiService.getDoctorPatientReports(token);
      if (mounted) {
        _allFetchedReports = responseData
            .map((data) => PatientReport.fromJson(data as Map<String, dynamic>))
            .toList();

        _allFetchedReports.sort((a, b) { // Sort all reports
          bool aIsPending = a.doctorRemarks == null || a.doctorRemarks!.isEmpty;
          bool bIsPending = b.doctorRemarks == null || b.doctorRemarks!.isEmpty;
          if (aIsPending && !bIsPending) return -1;
          if (!aIsPending && bIsPending) return 1;
          if (a.uploadedAt != null && b.uploadedAt != null) {
            return b.uploadedAt!.compareTo(a.uploadedAt!);
          }
          return (a.fileName).compareTo(b.fileName);
        });

        _applySearch(); // This will also update previews
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load reports: ${e.toString().replaceFirst("Exception: ", "")}';
        });
      }
    }
  }

  void _applySearch() {
    List<PatientReport> filteredFromAll;
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      filteredFromAll = _allFetchedReports.where((report) {
        return report.fileName.toLowerCase().contains(query) ||
            report.patientEmail.toLowerCase().contains(query) ||
            (report.patientName?.toLowerCase().contains(query) ?? false) ||
            (report.healthRiskPrediction?.toLowerCase().contains(query) ?? false);
      }).toList();
    } else {
      filteredFromAll = List.from(_allFetchedReports); // Create a copy
    }

    if(mounted){
      setState(() {
        _pendingReportsPreview = filteredFromAll.where((r) => r.doctorRemarks == null || r.doctorRemarks!.isEmpty).take(PREVIEW_COUNT).toList();
        _reviewedReportsPreview = filteredFromAll.where((r) => r.doctorRemarks != null && r.doctorRemarks!.isNotEmpty).take(PREVIEW_COUNT).toList();
        _displayInMainList = filteredFromAll; // The main list shows all (search filtered) reports
      });
    }
  }


  Color _getRiskColor(String? risk) {
    if (risk == "CRITICAL") return Colors.red.shade600;
    if (risk == "MODERATE") return Colors.orange.shade600;
    if (risk == "LOW" || risk == "NORMAL") return Colors.green.shade600;
    return Colors.grey.shade600;
  }

  IconData _getRiskIcon(String? risk) {
    if (risk == "CRITICAL") return Icons.dangerous_outlined;
    if (risk == "MODERATE") return Icons.warning_amber_rounded;
    if (risk == "LOW" || risk == "NORMAL") return Icons.check_circle_outline_rounded;
    return Icons.help_outline_rounded;
  }

  void _navigateToFilteredScreen(String statusTitle, List<PatientReport> reportsToShow) {
    List<PatientReport> actualList;
    if (statusTitle == "Pending Review") {
      actualList = _allFetchedReports.where((r) => r.doctorRemarks == null || r.doctorRemarks!.isEmpty).toList();
    } else if (statusTitle == "Reviewed Reports") {
      actualList = _allFetchedReports.where((r) => r.doctorRemarks != null && r.doctorRemarks!.isNotEmpty).toList();
    } else { // Should not happen with current setup but good for safety
      actualList = reportsToShow;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredReportsScreen(
          reports: actualList,
          title: statusTitle,
          onReportUpdated: (updatedReportId) => _fetchPatientReports(updatedReportId: updatedReportId),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool hasPending = _pendingReportsPreview.isNotEmpty;
    bool hasReviewed = _reviewedReportsPreview.isNotEmpty;
    bool fullPendingListHasMore = _allFetchedReports.where((r) => r.doctorRemarks == null || r.doctorRemarks!.isEmpty).length > PREVIEW_COUNT;
    bool fullReviewedListHasMore = _allFetchedReports.where((r) => r.doctorRemarks != null && r.doctorRemarks!.isNotEmpty).length > PREVIEW_COUNT;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Reports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Reports",
            onPressed: _isLoading ? null : () => _fetchPatientReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(theme),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : _errorMessage.isNotEmpty
                ? _buildErrorState(theme)
                : RefreshIndicator( // Wrap the main content area with RefreshIndicator
              onRefresh: () => _fetchPatientReports(),
              color: Colors.deepPurple,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: [
                  // Quick Access: Pending Review
                  if (hasPending || _searchQuery.isEmpty) // Show header if there are pending items or no search
                    _buildQuickAccessSection(
                      theme,
                      title: "Pending Review",
                      reportsToShow: _pendingReportsPreview,
                      accentColor: Colors.orange.shade700,
                      showViewAll: fullPendingListHasMore || (_searchQuery.isNotEmpty && _allFetchedReports.where((r) => r.doctorRemarks == null || r.doctorRemarks!.isEmpty).isNotEmpty),
                      onViewAll: () => _navigateToFilteredScreen("Pending Review", _pendingReportsPreview),
                    ),

                  // Quick Access: Reviewed
                  if (hasReviewed || _searchQuery.isEmpty) // Show header if there are reviewed items or no search
                    _buildQuickAccessSection(
                      theme,
                      title: "Recently Reviewed",
                      reportsToShow: _reviewedReportsPreview,
                      accentColor: Colors.green.shade700,
                      showViewAll: fullReviewedListHasMore || (_searchQuery.isNotEmpty && _allFetchedReports.where((r) => r.doctorRemarks != null && r.doctorRemarks!.isNotEmpty).isNotEmpty),
                      onViewAll: () => _navigateToFilteredScreen("Reviewed Reports", _reviewedReportsPreview),
                    ),

                  // Separator or "All Reports" Header if quick access sections are shown
                  if ((hasPending || hasReviewed) && _displayInMainList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        _searchQuery.isEmpty ? "All Reports (${_displayInMainList.length})" : "Search Results (${_displayInMainList.length})",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 4),
                  ],

                  // Main List of Reports (or search results)
                  if (_displayInMainList.isEmpty && !_isLoading)
                    _buildEmptyState(theme, isSearchActive: _searchQuery.isNotEmpty, isAfterQuickAccess: hasPending || hasReviewed)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _displayInMainList.length,
                      itemBuilder: (context, index) {
                        final report = _displayInMainList[index];
                        return _buildReportListItem(context, theme, report);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(ThemeData theme, {
    required String title,
    required List<PatientReport> reportsToShow,
    required Color accentColor,
    required bool showViewAll,
    required VoidCallback onViewAll,
  }) {
    if (reportsToShow.isEmpty && _searchQuery.isNotEmpty) return const SizedBox.shrink(); // Don't show if search yields no results for this section

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$title (${reportsToShow.length})",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: accentColor),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: onViewAll,
                  child: Text("View All", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                )
            ],
          ),
        ),
        if (reportsToShow.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(_searchQuery.isEmpty ? "No reports currently in this category." : "No reports match search in this category.", style: TextStyle(color: Colors.grey[600])),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportsToShow.length, // Max PREVIEW_COUNT items
            itemBuilder: (context, index) => _buildReportListItem(context, theme, reportsToShow[index], isPreview: true),
          ),
        const Divider(height: 20, indent: 16, endIndent: 16, thickness: 0.5),
      ],
    );
  }


  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by patient, filename, risk...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.deepPurple.withOpacity(0.8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
            onPressed: () => _searchController.clear(),
          )
              : null,
          filled: true,
          fillColor: Colors.deepPurple.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    // ... (same as previous version)
    return Center( /* ... */ );
  }

  Widget _buildEmptyState(ThemeData theme, {required bool isSearchActive, bool isAfterQuickAccess = false}) {
    String message;
    if (isSearchActive) {
      message = 'No reports match your search for "$_searchQuery".';
    } else if (isAfterQuickAccess) {
      message = 'No further reports found.'; // If quick access sections were shown but main list is empty
    }
    else {
      message = 'No patient reports available at this time.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isSearchActive ? Icons.search_off_rounded : Icons.folder_copy_outlined,
                size: 70, color: Colors.deepPurple.withOpacity(0.3)
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (isSearchActive)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton(
                  onPressed: () => _searchController.clear(),
                  child: const Text('Clear Search', style: TextStyle(color: Colors.deepPurple)),
                ),
              )
          ],
        ),
      ),
    );
  }


  Widget _buildReportListItem(BuildContext context, ThemeData theme, PatientReport report, {bool isPreview = false}) {
    final riskColor = _getRiskColor(report.healthRiskPrediction);
    final riskIcon = _getRiskIcon(report.healthRiskPrediction);
    final bool actualIsPending = report.doctorRemarks == null || report.doctorRemarks!.isEmpty;

    final statusText = actualIsPending ? 'Needs Review' : 'Reviewed';
    final statusColor = actualIsPending ? Colors.orange.shade700 : Colors.green.shade700;

    String formattedDate = report.uploadedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(report.uploadedAt!.toLocal())
        : 'Date N/A';

    return Card(
      elevation: isPreview ? 1.5 : 2.5, // Less elevation for preview items
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportDetailScreen(report: report)),
          ).then((value) {
            if (value == true) _fetchPatientReports();
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: isPreview ? 10.0 : 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0), // Smaller padding for icon
                    decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8.0)),
                    child: Icon(riskIcon, color: riskColor, size: 24), // Slightly smaller icon
                  ),
                  if(actualIsPending) ...[
                    const SizedBox(height: 5),
                    // Wrapped the Container with a Tooltip widget
                    Tooltip(
                      message: "Pending Review", // Use 'message' for the tooltip text
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.patientName ?? report.patientEmail,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.deepPurple[700]), // Bolder patient name
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (!isPreview) // Show filename only in full list, not preview
                      Text(report.fileName, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),

                    if (report.uploadedAt != null) ... [
                      const SizedBox(height: 2),
                      Text(isPreview ? DateFormat('dd MMM').format(report.uploadedAt!.toLocal()) : 'Uploaded: $formattedDate', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (!isPreview || report.healthRiskPrediction != null || !actualIsPending) const SizedBox(height: 5), // Conditional spacing for preview
                    Row(
                      children: [
                        if (report.healthRiskPrediction != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(report.healthRiskPrediction!, style: theme.textTheme.labelSmall?.copyWith(color: riskColor, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        if (report.healthRiskPrediction != null && !actualIsPending) const SizedBox(width: 6), // Space if both tags are shown
                        if (!actualIsPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusText, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24, color: Colors.deepPurple.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}