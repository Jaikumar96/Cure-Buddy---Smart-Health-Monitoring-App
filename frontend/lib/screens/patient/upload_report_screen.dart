import 'dart:convert';
import 'dart:io';
import 'dart:math'; // For min/max calculations
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/bottom_nav_bar.dart'; // Assuming this path is correct
import 'package:url_launcher/url_launcher.dart';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen>
    with SingleTickerProviderStateMixin {
  File? selectedFile;
  bool isLoading = false;
  bool isAnalyzing = false;
  bool isFetchingInsights = false;
  bool isGeneratingReport = false;
  bool isSharingReport = false;
  bool isLoadingVitals = false;

  List<Map<String, dynamic>> reports = [];
  Map<String, dynamic>? selectedReport;
  String? selectedReportId;

  String? healthRiskPrediction;
  String? insightTrend;
  String? insightDetails;
  List<String> healthTips = [];
  List<dynamic> vitalsData = [];
  String? reportDownloadLink;
  String? reportId; // For generated summary report ID
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  late TabController _tabController;

  final String apiBaseUrl = 'http://192.168.252.250:8080';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    fetchReports();
    fetchVitals();

    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    startDateController.text =
    "${oneMonthAgo.year}-${oneMonthAgo.month.toString().padLeft(2, '0')}-${oneMonthAgo.day.toString().padLeft(2, '0')}";
    endDateController.text =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _tabController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadReport() async {
    if (selectedFile == null) {
      Fluttertoast.showToast(msg: 'Please select a PDF file first.');
      return;
    }
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Fluttertoast.showToast(msg: 'Please login again.');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      var uri = Uri.parse('$apiBaseUrl/api/patient/upload-report');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files
          .add(await http.MultipartFile.fromPath('file', selectedFile!.path));

      var response = await request.send();
      if (!mounted) return;
      var resp = await http.Response.fromStream(response);
      if (!mounted) return;

      if (resp.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Uploaded Successfully ✅');
        fetchReports();
      } else {
        Fluttertoast.showToast(msg: 'Upload failed: ${resp.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchReports() async {
    print('DEBUG: fetchReports called');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print('DEBUG: fetchReports - No token found, returning.');
        return;
      }

      var response = await http.get(
        Uri.parse('$apiBaseUrl/api/patient/my-reports'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;

      print('DEBUG: fetchReports - Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        print('DEBUG: fetchReports - RAW DECODED DATA from /my-reports: $decodedData');

        // Inside fetchReports, when processing items:
        final List<Map<String, dynamic>> newProcessedReports = decodedData.map((item) {
          final Map<String, dynamic> report = Map<String, dynamic>.from(item as Map);
          report['uniqueId'] = '${report['fileName']}_${report['uploadedAt']}';

          // Adapt to the key the backend uses for the ID
          if (item.containsKey('id')) { // If backend sends "id"
            report['_id'] = item['id'];
          } else if (item.containsKey('reportId')) { // If backend sends "reportId"
            report['_id'] = item['reportId'];
          }
          // If backend sends "_id" directly, no change is needed here for _id.

          print('DEBUG: fetchReports - Processing item: $item, Resulting report map: $report');
          if (!report.containsKey('_id')) {
            print('WARNING: fetchReports - "_id" key (or its mapped equivalent) is MISSING from report map after processing: $report');
          } else {
            print('DEBUG: fetchReports - "_id" key IS PRESENT. Value: ${report['_id']}, Type: ${report['_id'].runtimeType}');
          }
          return report;
        }).toList();

        if (!mounted) return;
        setState(() {
          reports = newProcessedReports;
          print('DEBUG: fetchReports - Reports list updated. Count: ${reports.length}');

          if (reports.isEmpty) {
            selectedReportId = null;
            selectedReport = null;
            print('DEBUG: fetchReports - Reports list is empty. selectedReport set to null.');
          } else {
            final bool currentSelectedIsValid = selectedReportId != null &&
                reports.any((r) => r['uniqueId'] == selectedReportId);

            if (currentSelectedIsValid) {
              selectedReport = reports.firstWhere((r) => r['uniqueId'] == selectedReportId);
              print('DEBUG: fetchReports - Preserved selection. selectedReportId: $selectedReportId');
            } else {
              selectedReport = reports.first;
              selectedReportId = selectedReport!['uniqueId'] as String?;
              print('DEBUG: fetchReports - Selected first report. selectedReportId: $selectedReportId');
            }

            print('DEBUG: fetchReports - Newly selectedReport in fetchReports: $selectedReport');
            if(selectedReport != null && !selectedReport!.containsKey('_id')) {
              print('ERROR: fetchReports - selectedReport is set but MISSING "_id": $selectedReport');
            } else if (selectedReport != null) {
              print('DEBUG: fetchReports - selectedReport has "_id". Value: ${selectedReport!['_id']}, Type: ${selectedReport!['_id']?.runtimeType}');
            }
          }
        });
      } else {
        print('Failed to fetch reports: ${response.body}');
        if (!mounted) return;
        setState(() {
          reports = [];
          selectedReportId = null;
          selectedReport = null;
        });
      }
    } catch (e) {
      print('Error fetching reports: $e');
      if (!mounted) return;
      setState(() {
        reports = [];
        selectedReportId = null;
        selectedReport = null;
      });
    }
  }

  Future<void> analyzeReport() async {
    print('DEBUG: analyzeReport called');
    if (selectedReport == null) {
      Fluttertoast.showToast(msg: 'Please select a report first.');
      print('DEBUG: analyzeReport - selectedReport is null.');
      return;
    }

    print('DEBUG: analyzeReport - selectedReport details: $selectedReport');
    if (selectedReport!.containsKey('_id')) {
      print('DEBUG: analyzeReport - selectedReport[_id] value: ${selectedReport!['_id']}');
      print('DEBUG: analyzeReport - selectedReport[_id] runtimeType: ${selectedReport!['_id'].runtimeType}');
    } else {
      print('DEBUG: analyzeReport - selectedReport does NOT contain key "_id"');
      // This early return might be too aggressive if the _id is just missing
      // The logic below will handle it with a toast.
    }

    if (!mounted) return;
    setState(() => isAnalyzing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Fluttertoast.showToast(msg: 'Please login again.');
        if (mounted) setState(() => isAnalyzing = false);
        return;
      }

      // Check if _id key exists before trying to access it.
      if (!selectedReport!.containsKey('_id') || selectedReport!['_id'] == null) {
        Fluttertoast.showToast(msg: 'Selected report is missing a valid ID.');
        print('ERROR: analyzeReport - Key "_id" is missing or its value is null in selectedReport.');
        if (mounted) setState(() => isAnalyzing = false);
        return;
      }

      dynamic reportIdValue = selectedReport!['_id'];
      String reportIdToAnalyze;

      if (reportIdValue is Map && reportIdValue.containsKey('\$oid')) {
        reportIdToAnalyze = reportIdValue['\$oid'] as String;
        print('DEBUG: analyzeReport - Extracted ID (from \$oid): $reportIdToAnalyze');
      } else if (reportIdValue is String) {
        reportIdToAnalyze = reportIdValue;
        print('DEBUG: analyzeReport - Extracted ID (direct string): $reportIdToAnalyze');
      } else {
        Fluttertoast.showToast(msg: 'Selected report has an invalid ID format.');
        print('ERROR: analyzeReport - Invalid ID format. reportIdValue: $reportIdValue, runtimeType: ${reportIdValue.runtimeType}');
        if (mounted) setState(() => isAnalyzing = false);
        return;
      }

      if (reportIdToAnalyze.isEmpty) {
        Fluttertoast.showToast(msg: 'Selected report ID is empty. Cannot analyze.');
        print('ERROR: analyzeReport - Extracted reportIdToAnalyze is empty.');
        if (mounted) setState(() => isAnalyzing = false);
        return;
      }

      print('DEBUG: analyzeReport - Analyzing report with final ID: $reportIdToAnalyze');

      var response = await http.get(
        Uri.parse('$apiBaseUrl/api/patient/report-analysis/$reportIdToAnalyze'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final msg = response.body;
        if (!mounted) return;
        setState(() {
          if (msg.contains('CRITICAL')) {
            healthRiskPrediction = 'CRITICAL';
          } else if (msg.contains('NORMAL')) {
            healthRiskPrediction = 'NORMAL';
          } else if (msg.contains('MODERATE')) {
            healthRiskPrediction = 'MODERATE';
          } else {
            healthRiskPrediction = 'UNKNOWN';
            print("Analysis response did not match expected risk levels: $msg");
          }
        });
        Fluttertoast.showToast(
          msg: "Report analyzed successfully! Health Risk: $healthRiskPrediction",
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(msg: 'Failed to analyze report: ${response.body}');
        print('Failed to analyze report. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error analyzing report: $e');
      Fluttertoast.showToast(msg: 'Error analyzing report. Please try again.');
    } finally {
      if (mounted) setState(() => isAnalyzing = false);
    }
  }

  Future<void> fetchVitals() async {
    if (!mounted) return;
    setState(() => isLoadingVitals = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        print('Auth token not found for fetching vitals.');
        Fluttertoast.showToast(msg: 'Authentication required to fetch vitals. Please login.');
        if (mounted) {
          _setSampleVitalsData();
          setState(() => isLoadingVitals = false);
        }
        return;
      }

      var response = await http.get(
        Uri.parse('$apiBaseUrl/api/analytics/vitals'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          vitalsData = jsonDecode(response.body);
        });
      } else {
        print('Failed to load vitals: ${response.statusCode} ${response.body}');
        Fluttertoast.showToast(msg: 'Failed to load vitals data. Displaying sample data. Status: ${response.statusCode}');
        if (mounted) {
          _setSampleVitalsData();
        }
      }
    } catch (e) {
      print('Error fetching vitals: $e');
      Fluttertoast.showToast(msg: 'Error fetching vitals. Displaying sample data.');
      if (mounted) {
        _setSampleVitalsData();
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingVitals = false);
      }
    }
  }

  void _setSampleVitalsData() {
    setState(() {
      vitalsData = [
        {"date": "2025-05-10", "bloodPressure": 128, "heartRate": 72},
        {"date": "2025-05-11", "bloodPressure": 124, "heartRate": 74},
        // ... (rest of sample data)
      ];
    });
  }

  Future<void> generateReport() async {
    if (!mounted) return;
    setState(() => isGeneratingReport = true);

    final String apiUrl = '$apiBaseUrl/api/reports/generate';
    final requestPayload = {
      "startDate": startDateController.text,
      "endDate": endDateController.text,
      "format": "PDF"
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Fluttertoast.showToast(msg: 'Authentication token not found. Please login again.');
        if (mounted) setState(() => isGeneratingReport = false);
        return;
      }

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestPayload),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          reportDownloadLink = data['downloadLink'];
          reportId = data['reportId']; // This is for the generated summary
        });
        Fluttertoast.showToast(msg: "Report generated successfully! ID: ${data['reportId']}");
      } else {
        String errorMsg = 'Failed to generate report.';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg += ' Server said: ${errorData['message'] ?? errorData['error'] ?? response.body}';
        } catch (e) {
          errorMsg += ' Status: ${response.statusCode}, Details: ${response.body}';
        }
        Fluttertoast.showToast(msg: errorMsg, toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Error generating report: $e');
    } finally {
      if (mounted) setState(() => isGeneratingReport = false);
    }
  }

  Future<void> shareReport() async {
    if (reportId == null) { // This reportId is for the generated summary
      Fluttertoast.showToast(msg: 'Please generate a health summary report first.');
      return;
    }
    // ... (rest of shareReport)
    if (emailController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter recipient email.');
      return;
    }
    if (!mounted) return;
    setState(() => isSharingReport = true);

    final String apiUrl = '$apiBaseUrl/api/reports/share';
    final requestPayload = {
      "reportId": reportId,
      "recipientEmail": emailController.text
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      Map<String, String> headers = {"Content-Type": "application/json"};
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(requestPayload),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        Fluttertoast.showToast(msg: "Report shared successfully! Status: ${responseData['status']}");
        if (mounted) emailController.clear();
      } else {
        String errorMsg = 'Failed to share report.';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg += ' Server said: ${errorData['message'] ?? errorData['error'] ?? errorData['status'] ?? response.body}';
        } catch (e) {
          errorMsg += ' Status: ${response.statusCode}, Details: ${response.body}';
        }
        Fluttertoast.showToast(msg: errorMsg, toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Error sharing report: $e');
    } finally {
      if (mounted) setState(() => isSharingReport = false);
    }
  }

  Future<void> downloadReport() async {
    if (reportDownloadLink == null) {
      Fluttertoast.showToast(msg: 'No report available to download.');
      return;
    }
    try {
      final Uri url = Uri.parse('$apiBaseUrl$reportDownloadLink');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading report: $e');
    }
  }

  Future<void> fetchInsightsAndTips() async {
    if (healthRiskPrediction == null) {
      Fluttertoast.showToast(msg: 'Please analyze the report first.');
      return;
    }
    // ... (rest of fetchInsightsAndTips)
    if (!mounted) return;
    setState(() => isFetchingInsights = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Fluttertoast.showToast(msg: 'Please login again.');
        if(mounted) setState(() => isFetchingInsights = false);
        return;
      }

      try {
        var insightRes = await http.get(
          Uri.parse('$apiBaseUrl/api/patient/insights'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (!mounted) return;
        if (insightRes.statusCode == 200) {
          final data = jsonDecode(insightRes.body);
          if (!mounted) return;
          setState(() {
            insightTrend = data['trend'];
            insightDetails = data['details'];
          });
        } else {
          _setDefaultInsights();
        }
      } catch (e) {
        print('Error fetching insights: $e');
        if (!mounted) return;
        _setDefaultInsights();
      }

      try {
        var tipRes = await http.get(
          Uri.parse('$apiBaseUrl/api/patient/health-tips/${healthRiskPrediction!}'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (!mounted) return;
        if (tipRes.statusCode == 200) {
          if (!mounted) return;
          setState(() {
            healthTips = List<String>.from(jsonDecode(tipRes.body));
          });
        } else {
          _setDefaultHealthTips();
        }
      } catch (e) {
        print('Error fetching health tips: $e');
        if (!mounted) return;
        _setDefaultHealthTips();
      }
    } catch (e) {
      print('Error in fetchInsightsAndTips: $e');
      Fluttertoast.showToast(msg: 'Error fetching health insights. Using default data.');
      if (!mounted) return;
      _setDefaultInsights();
      _setDefaultHealthTips();
    } finally {
      if (mounted) setState(() => isFetchingInsights = false);
    }
  }

  void _setDefaultInsights() {
    if (!mounted) return;
    setState(() {
      insightTrend = "Trend data unavailable";
      insightDetails = "Could not fetch detailed insights. Please check connection or try again later.";
    });
  }

  void _setDefaultHealthTips() {
    if (!mounted) return;
    setState(() {
      if (healthRiskPrediction == 'CRITICAL') {
        healthTips = [
          "Seek immediate medical attention.",
          // ...
        ];
      } else if (healthRiskPrediction == 'MODERATE') {
        healthTips = [
          "Schedule a doctor appointment soon.",
          // ...
        ];
      } else { // NORMAL or null
        healthTips = [
          "Continue your healthy lifestyle.",
          // ...
        ];
      }
    });
  }

  Widget buildVitalsChart() {
    // ... (buildVitalsChart - no changes needed for this issue)
    if (vitalsData.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No vitals data available to display.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ));
    }

    double minY = double.maxFinite;
    double maxY = double.minPositive;

    for (var data in vitalsData) {
      final bp = (data['bloodPressure'] as num?)?.toDouble() ?? 0.0;
      final hr = (data['heartRate'] as num?)?.toDouble() ?? 0.0;
      if (bp != 0.0) {
        if (bp < minY) minY = bp;
        if (bp > maxY) maxY = bp;
      }
      if (hr != 0.0) {
        if (hr < minY) minY = hr;
        if (hr > maxY) maxY = hr;
      }
    }

    if (minY != double.maxFinite && maxY != double.minPositive) {
      minY = (minY - 15).clamp(0, double.maxFinite);
      maxY = maxY + 15;
    } else {
      minY = 40;
      maxY = 160;
    }


    final bpSpots = vitalsData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(),
          (entry.value['bloodPressure'] as num?)?.toDouble() ?? 0);
    }).toList();

    final hrSpots = vitalsData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(),
          (entry.value['heartRate'] as num?)?.toDouble() ?? 0);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 5 > 0 ? (maxY - minY) / 5 : 20,
            verticalInterval: (vitalsData.length / 7).ceil().toDouble().clamp(1, double.infinity),
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 0.8);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 0.8);
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  final int totalItems = vitalsData.length;
                  final int desiredLabels = min(7, totalItems);
                  int interval = 1;
                  if (totalItems > desiredLabels && desiredLabels > 0) {
                    interval = (totalItems / desiredLabels).ceil();
                  }


                  if (index >= 0 && index < totalItems && (index % interval == 0 || index == totalItems -1)) {
                    final dateStr = vitalsData[index]['date'].toString();
                    try {
                      final dateParts = dateStr.split('-');
                      if (dateParts.length == 3) {
                        final text = '${dateParts[1]}/${dateParts[2]}';
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8.0,
                          child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                        );
                      }
                    } catch (e) {/* Fallback */}
                    return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(dateStr.substring(dateStr.length - 2), style: const TextStyle(fontSize: 10, color: Colors.black87)));
                  }
                  return SideTitleWidget(axisSide: meta.axisSide, child: const SizedBox.shrink());
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY > minY) ? ((maxY - minY) / 5).ceilToDouble().clamp(10, 100) : 20,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          minX: 0,
          maxX: vitalsData.isNotEmpty ? vitalsData.length.toDouble() - 1 : 0,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: bpSpots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: hrSpots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final xIndex = flSpot.x.toInt();

                  if (xIndex < 0 || xIndex >= vitalsData.length) {
                    return LineTooltipItem(
                      '',
                      const TextStyle(color: Colors.transparent),
                    );
                  }

                  final dataPoint = vitalsData[xIndex];
                  final date = dataPoint['date'] as String;
                  String text = '';
                  TextStyle textStyle;

                  if (flSpot.barIndex == 0) {
                    final bp = (dataPoint['bloodPressure'] as num?)?.toStringAsFixed(0) ?? 'N/A';
                    text = 'BP: $bp mmHg\n$date';
                    textStyle = const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    );
                  } else if (flSpot.barIndex == 1) {
                    final hr = (dataPoint['heartRate'] as num?)?.toStringAsFixed(0) ?? 'N/A';
                    text = 'HR: $hr bpm\n$date';
                    textStyle = const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    );
                  } else {
                    text = 'Value: ${flSpot.y.toStringAsFixed(0)}\n$date';
                    textStyle = const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    );
                  }

                  return LineTooltipItem(
                    text,
                    textStyle,
                    textAlign: TextAlign.left,
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    // ... (no changes needed)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.redAccent, 'Blood Pressure'),
        const SizedBox(width: 24),
        _buildLegendItem(Colors.blueAccent, 'Heart Rate'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    // ... (no changes needed)
    return Row(children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _buildVitalsAnalysisSection() {
    // ... (no changes needed)
    if (vitalsData.isEmpty) return const SizedBox.shrink();

    List<double> bps = vitalsData
        .map((d) => (d['bloodPressure'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    List<double> hrs = vitalsData
        .map((d) => (d['heartRate'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

    String startDate = vitalsData.first['date'];
    String endDate = vitalsData.last['date'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vitals Summary (${_formatDisplayDate(startDate)} - ${_formatDisplayDate(endDate)})',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark),
            ),
            const SizedBox(height: 16),
            if (bps.isNotEmpty)
              _buildStatRow('Blood Pressure', bps.reduce(min), bps.reduce(max),
                  bps.reduce((a, b) => a + b) / bps.length, 'mmHg')
            else
              _buildStatRowUnavailable('Blood Pressure'),

            const Divider(height: 24, thickness: 0.5),

            if (hrs.isNotEmpty)
              _buildStatRow('Heart Rate', hrs.reduce(min), hrs.reduce(max),
                  hrs.reduce((a, b) => a + b) / hrs.length, 'bpm')
            else
              _buildStatRowUnavailable('Heart Rate'),

            const SizedBox(height: 20),
            _buildInterpretationNotes(),
          ],
        ),
      ),
    );
  }

  String _formatDisplayDate(String dateStr) {
    // ... (no changes needed)
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        int monthIndex = int.tryParse(parts[1]) ?? 0;
        String month = (monthIndex > 0 && monthIndex <=12) ? months[monthIndex-1] : parts[1];
        return "$month ${parts[2]}, ${parts[0]}";
      }
    } catch(e) {/* ignore */}
    return dateStr;
  }

  Widget _buildStatRow(String label, double minVal, double maxVal, double avgVal, String unit) {
    // ... (no changes needed)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Avg: ${avgVal.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 14)),
              Text('Range: ${minVal.toStringAsFixed(0)} - ${maxVal.toStringAsFixed(0)} $unit',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatRowUnavailable(String label) {
    // ... (no changes needed)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Text('Data unavailable', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInterpretationNotes() {
    // ... (no changes needed)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Reference:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 6),
        Text(' • Normal Blood Pressure: Generally < 120 (Systolic) and < 80 (Diastolic) mmHg.', style: TextStyle(fontSize: 11.5, color: Colors.grey[700])),
        Text(' • Normal Resting Heart Rate: Generally 60-100 bpm.', style: TextStyle(fontSize: 11.5, color: Colors.grey[700])),
        const SizedBox(height: 10),
        const Text(
          'Disclaimer: These are general ranges for adults. Individual targets may vary based on health conditions and other factors. This information is for educational purposes only and not a substitute for professional medical advice. Always consult with a healthcare provider for any health concerns or before making any decisions related to your health or treatment.',
          style: TextStyle(fontSize: 10, color: Colors.redAccent, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  String formatDateTime(String dateTimeStr) {
    // ... (no changes needed)
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    // ... (no changes needed)
    DateTime initial = DateTime.now();
    try {
      if (controller.text.isNotEmpty) initial = DateTime.parse(controller.text);
    } catch (e) { /* Use DateTime.now() */ }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        controller.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget buildQuickActions() {
    // ... (no changes needed)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Upload',
              color: Colors.blueAccent,
              onTap: pickFile,
            ),
            _buildQuickActionButton(
              icon: Icons.analytics_outlined,
              label: 'Analyze',
              color: Colors.green,
              onTap: analyzeReport,
            ),
            _buildQuickActionButton(
              icon: Icons.monitor_heart_outlined,
              label: 'Vitals',
              color: Colors.purpleAccent,
              onTap: () => _tabController.animateTo(1),
            ),
            _buildQuickActionButton(
              icon: Icons.summarize_outlined,
              label: 'Report',
              color: Colors.orangeAccent,
              onTap: () {
                _tabController.animateTo(2);
              },
            ),
            _buildQuickActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              color: Colors.teal,
              onTap: () {
                _tabController.animateTo(2);
                if (reportId == null) { // This is for the generated summary report
                  Fluttertoast.showToast(msg: 'Generate a health summary report first to enable sharing.');
                  return;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // ... (no changes needed)
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportDialog() {
    // ... (no changes needed)
    return AlertDialog(
      title: const Text('Generate Health Summary'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: startDateController,
            decoration: const InputDecoration(
              labelText: 'Start Date (YYYY-MM-DD)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, startDateController),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: endDateController,
            decoration: const InputDecoration(
              labelText: 'End Date (YYYY-MM-DD)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, endDateController),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            generateReport();
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }

  Widget _buildShareDialog() {
    // ... (no changes needed)
    return AlertDialog(
      title: const Text('Share Summary Report'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Recipient Email',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            shareReport();
          },
          child: const Text('Share'),
        ),
      ],
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload New Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Select PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedFile != null ? uploadReport : null,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Selected: ${selectedFile!.path.split('/').last}',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Past Reports & Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (reports.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedReportId,
                      decoration: const InputDecoration(
                        labelText: 'Select Report',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      ),
                      isExpanded: true,
                      items: reports.map((report) {
                        return DropdownMenuItem<String>(
                          value: report['uniqueId'] as String,
                          child: Text(
                            '${report['fileName']} (${formatDateTime(report['uploadedAt'])})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        setState(() {
                          selectedReportId = newId;
                          Map<String, dynamic>? foundReport;
                          if (newId != null) {
                            for (final report in reports) {
                              if (report['uniqueId'] == newId) {
                                foundReport = report;
                                break;
                              }
                            }
                            if (foundReport == null) {
                              print("Error: Inconsistency. Selected ID '$newId' not found in current reports list.");
                            }
                          }
                          selectedReport = foundReport;
                          healthRiskPrediction = null;
                          insightTrend = null;
                          insightDetails = null;
                          healthTips = [];
                        });
                      },
                    )
                  else
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No reports available. Upload your first report!', textAlign: TextAlign.center,),
                    )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedReport != null ? analyzeReport : null,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: healthRiskPrediction != null
                              ? fetchInsightsAndTips
                              : null,
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Get Insights'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isAnalyzing || isFetchingInsights)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (healthRiskPrediction != null)
            Card(
              // ... (rest of healthRiskPrediction card)
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: healthRiskPrediction == 'CRITICAL'
                  ? Colors.red.shade50
                  : healthRiskPrediction == 'MODERATE'
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          healthRiskPrediction == 'CRITICAL'
                              ? Icons.warning_amber_rounded
                              : healthRiskPrediction == 'MODERATE'
                              ? Icons.info_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: healthRiskPrediction == 'CRITICAL'
                              ? Colors.red.shade700
                              : healthRiskPrediction == 'MODERATE'
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Health Risk Prediction: $healthRiskPrediction',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: healthRiskPrediction == 'CRITICAL'
                                  ? Colors.red.shade700
                                  : healthRiskPrediction == 'MODERATE'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    if (insightTrend != null && insightTrend!.isNotEmpty) ...[
                      const Text('Health Trend:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(insightTrend!, style: const TextStyle(fontSize: 14.5)),
                      const SizedBox(height: 12),
                    ],
                    if (insightDetails != null && insightDetails!.isNotEmpty) ...[
                      const Text('Details:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(insightDetails!, style: const TextStyle(fontSize: 14.5)),
                      const SizedBox(height: 12),
                    ],
                    if (healthTips.isNotEmpty) ...[
                      const Text('Personalized Health Tips:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...healthTips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_box_outline_blank_rounded, size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tip, style: const TextStyle(fontSize: 14.5))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab(BuildContext context) {
    // ... (no changes needed)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vitals Trend Monitoring',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  isLoadingVitals
                      ? const Center(heightFactor: 5, child: CircularProgressIndicator())
                      : buildVitalsChart(),
                  const SizedBox(height: 16),
                  _buildChartLegend(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Vitals Data'),
                    onPressed: fetchVitals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLoadingVitals && vitalsData.isNotEmpty)
            _buildVitalsAnalysisSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    // ... (no changes needed)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate & Share Health Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) => _buildReportDialog());
                      },
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Generate New Summary'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 40))),
                  const SizedBox(height: 16),
                  if (reportId != null || reportDownloadLink != null) ...[
                    const Divider(height: 20),
                    const Text(
                      'Generated Report Actions:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: reportDownloadLink != null
                              ? downloadReport
                              : null,
                          icon: const Icon(Icons.download_for_offline_outlined),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: reportId != null // This is for the generated summary report
                              ? () {
                            showDialog(
                                context: context,
                                builder: (context) => _buildShareDialog());
                          }
                              : null,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isGeneratingReport || isSharingReport)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.75),
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 20), SizedBox(width: 8), Text('Reports')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monitor_heart_outlined, size: 20), SizedBox(width: 8), Text('Vitals')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.summarize_sharp, size: 20), SizedBox(width: 8), Text('Summary')])),
          ],
        ),
      ),
      body: Column(
        children: [
          buildQuickActions(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(context),
                _buildVitalsTab(context),
                _buildSummaryTab(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
    );
  }
}