// lib/screens/doctor/filtered_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'doctor_reports_tab.dart'; // For PatientReport model
import 'report_detail_screen.dart';

class FilteredReportsScreen extends StatelessWidget {
  final List<PatientReport> reports;
  final String title;
  final Future<void> Function(String)? onReportUpdated; // Callback to refresh original list

  const FilteredReportsScreen({
    super.key,
    required this.reports,
    required this.title,
    this.onReportUpdated,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? Center(
        child: Text(
          'No reports found for "$title".',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportListItem(context, theme, report);
        },
      ),
    );
  }

  Widget _buildReportListItem(BuildContext context, ThemeData theme, PatientReport report) {
    final riskColor = _getRiskColor(report.healthRiskPrediction);
    final riskIcon = _getRiskIcon(report.healthRiskPrediction);
    final bool actualIsPending = report.doctorRemarks == null || report.doctorRemarks!.isEmpty;
    final statusText = actualIsPending ? 'Needs Review' : 'Reviewed';
    final statusColor = actualIsPending ? Colors.orange.shade700 : Colors.green.shade700;

    String formattedDate = report.uploadedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(report.uploadedAt!.toLocal())
        : 'Date N/A';

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
            ),
          ).then((value) {
            if (value == true && onReportUpdated != null && report.id != null) {
              onReportUpdated!(report.id!); // Notify parent to refresh
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Icon(riskIcon, color: riskColor, size: 26),
                  ),
                  if(actualIsPending) ...[
                    const SizedBox(height: 6),
                    Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.shade600),
                        child: Tooltip(message: "Pending Review")
                    )
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      report.fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (report.uploadedAt != null) ... [
                      const SizedBox(height: 4),
                      Text('Uploaded: $formattedDate', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (report.healthRiskPrediction != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                            child: Text(report.healthRiskPrediction!, style: theme.textTheme.labelSmall?.copyWith(color: riskColor, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 8),
                        if (!actualIsPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                            child: Text(statusText, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 26, color: Colors.deepPurple.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}