import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LabBookingScreen extends StatefulWidget {
  const LabBookingScreen({Key? key}) : super(key: key);

  @override
  State<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> with TickerProviderStateMixin {
  late TabController _labTabController;

  List<dynamic> labs = [];
  String? selectedLab;
  String selectedState = "Andaman and Nicobar Islands"; // Default
  String selectedDistrict = "South Andaman"; // Default
  final testController = TextEditingController();
  final priceController = TextEditingController();
  List<dynamic> bookings = [];

  bool isLoadingData = false; // For general data loading
  bool isBookingTest = false; // Specific for booking action
  bool _isMounted = true;

  // Sample states and districts - consider fetching this from an API or a more robust local source
  final Map<String, List<String>> statesAndDistricts = {
    "Andaman and Nicobar Islands": ["Nicobars", "North and Middle Andaman", "South Andaman"],
    "Maharashtra": ["Pune", "Mumbai City", "Mumbai Suburban", "Nagpur", "Thane"],
    "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai"],
    // Add more states and districts as needed
  };
  late List<String> districtsForSelectedState;

  @override
  void initState() {
    super.initState();
    _labTabController = TabController(length: 2, vsync: this);
    districtsForSelectedState = statesAndDistricts[selectedState] ?? [];
    if (districtsForSelectedState.isNotEmpty && !districtsForSelectedState.contains(selectedDistrict)) {
      selectedDistrict = districtsForSelectedState.first;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await fetchLabs();
    await fetchBookings();
  }

  @override
  void dispose() {
    _isMounted = false;
    _labTabController.dispose();
    testController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchLabs() async {
    if (!_isMounted) return;
    setState(() => isLoadingData = true);
    try {
      final url = Uri.parse("http://192.168.252.250:8080/api/labs/providers?state=$selectedState&district=$selectedDistrict");
      String? token = await getToken(); // Add token if endpoint is secured
      final headers = {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
      final response = await http.get(url, headers: headers);

      if (!_isMounted) return;
      if (response.statusCode == 200) {
        setState(() {
          labs = json.decode(response.body);
          if (labs.isNotEmpty && !labs.any((lab) => lab['name'] == selectedLab)) {
            selectedLab = null;
          }
        });
      } else {
        throw Exception('Failed to load labs: ${response.statusCode}');
      }
    } catch (e) {
      if (_isMounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching labs: ${e.toString()}')));
    } finally {
      if (_isMounted) setState(() => isLoadingData = false);
    }
  }

  Future<void> fetchBookings() async {
    final token = await getToken();
    if (token == null) return;
    if (!_isMounted) return;
    setState(() => isLoadingData = true);
    try {
      final response = await http.get(
        Uri.parse("http://192.168.252.250:8080/api/labs/my-bookings"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      if (!_isMounted) return;
      if (response.statusCode == 200) {
        setState(() => bookings = json.decode(response.body));
      } else {
        throw Exception('Failed to load bookings: ${response.body}');
      }
    } catch (e) {
      if (_isMounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching bookings: ${e.toString()}')));
    } finally {
      if (_isMounted) setState(() => isLoadingData = false);
    }
  }

  Future<void> bookTest() async {
    final token = await getToken();
    if (token == null) { /* ... */ return; }
    if (selectedLab == null || testController.text.isEmpty || priceController.text.isEmpty) { /* ... */ return; }
    if (!_isMounted) return;
    setState(() => isBookingTest = true);

    try {
      // ... (API call logic as in HealthServicesScreen)
      final url = Uri.parse("http://192.168.252.250:8080/api/labs/book");
      final body = json.encode({"providerName": selectedLab, "selectedTest": testController.text, "price": double.tryParse(priceController.text)});
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: body);

      if (!_isMounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test booked successfully!")));
        testController.clear();
        priceController.clear();
        selectedLab = null; // Optionally reset selected lab
        await fetchBookings();
      } else {
        throw Exception('Failed to book test: ${response.body}');
      }
    } catch (e) {
      if (_isMounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error booking test: ${e.toString()}')));
    } finally {
      if (_isMounted) setState(() => isBookingTest = false);
    }
  }

  // Copy UI builder methods from HealthServicesScreen:
  // buildLabBookingTab and buildPharmacyLocatorTab (adapted for labs)
  // Ensure they use local state variables and methods.
  Widget buildBookTestTabLayout() {
    // Use: selectedLab, labs, testController, priceController, isBookingTest, bookTest,
    // bookings, isLoadingData, fetchBookings
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView( // Ensure scrollability
        children: [
          // ... (Form from HealthServicesScreen -> buildLabBookingTab)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Book a Lab Test", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLab,
                    hint: Text("Select Lab/Provider"),
                    isExpanded: true,
                    items: labs.map<DropdownMenuItem<String>>((lab) => DropdownMenuItem(value: lab['name'], child: Text(lab['name'] ?? 'Unknown Lab'))).toList(),
                    onChanged: (value) { if(_isMounted) setState(() => selectedLab = value);},
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(controller: testController, decoration: InputDecoration(labelText: "Test Name", border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder())),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isBookingTest ? null : bookTest,
                    child: isBookingTest ? SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text("Book Test"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text("My Recent Bookings", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          // ... (Bookings list from HealthServicesScreen -> buildLabBookingTab)
          isLoadingData && bookings.isEmpty ? Center(child: CircularProgressIndicator()) :
          bookings.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("No bookings yet."))) :
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(child: ListTile(title: Text(booking['selectedTest'] ?? 'N/A'), subtitle: Text("Provider: ${booking['providerName'] ?? 'N/A'} | Price: ₹${booking['price'] ?? 'N/A'}")));
            },
          )
        ],
      ),
    );
  }

  Widget buildFindLabsTabLayout() {
    // Use: selectedState, selectedDistrict, statesAndDistricts, districtsForSelectedState,
    // fetchLabs, isLoadingData, labs
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Find Labs by Location", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          // State Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Select State', border: OutlineInputBorder()),
            value: selectedState,
            isExpanded: true,
            items: statesAndDistricts.keys.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && _isMounted) {
                setState(() {
                  selectedState = newValue;
                  districtsForSelectedState = statesAndDistricts[newValue] ?? [];
                  selectedDistrict = districtsForSelectedState.isNotEmpty ? districtsForSelectedState.first : "";
                  labs.clear(); selectedLab = null; // Reset dependent fields
                });
                fetchLabs();
              }
            },
          ),
          SizedBox(height: 12),
          // District Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Select District', border: OutlineInputBorder()),
            value: selectedDistrict,
            isExpanded: true,
            items: districtsForSelectedState.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && _isMounted) {
                setState(() { selectedDistrict = newValue; labs.clear(); selectedLab = null; });
                fetchLabs();
              }
            },
          ),
          SizedBox(height: 20),
          // Labs list
          Expanded(
            child: isLoadingData && labs.isEmpty ? Center(child: CircularProgressIndicator()) :
            labs.isEmpty ? Center(child: Text("No labs found for the selected location.")) :
            ListView.builder(
              itemCount: labs.length,
              itemBuilder: (context, index) {
                final lab = labs[index];
                return Card(child: ListTile(title: Text(lab['name'] ?? 'N/A'), subtitle: Text(lab['address'] ?? 'N/A')));
              },
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
        title: const Text("Lab Services"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _labTabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: "Book Test"),
            Tab(icon: Icon(Icons.search_outlined), text: "Find Labs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _labTabController,
        children: [
          buildBookTestTabLayout(),
          buildFindLabsTabLayout(),
        ],
      ),
      // No BottomNavBar here, this screen is typically pushed onto the stack
    );
  }
}