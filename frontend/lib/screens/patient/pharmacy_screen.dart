import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Not strictly used in this file after recent changes, but good to keep if other parts might use it.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/bottom_nav_bar.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> with TickerProviderStateMixin {
  late TabController _pharmacyTabController;

  List<dynamic> pharmacies = [];
  List<dynamic> medicines = [];
  List<dynamic> discounts = [];
  List<dynamic> reminders = [];

  final searchController = TextEditingController();
  final medicineNameController = TextEditingController();
  final cityController = TextEditingController();
  final timeController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool isLoadingPharmacies = false;
  bool isLoadingMedicines = false;
  bool isLoadingDiscounts = false;
  bool isLoadingReminders = false;
  bool isSettingReminder = false;

  static final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.252.250:8080/api';

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  static const LatLng _initialPositionChennai = LatLng(13.0827, 80.2707);
  LatLng _currentMapCenter = _initialPositionChennai;

  @override
  void initState() {
    super.initState();
    _pharmacyTabController = TabController(length: 4, vsync: this, initialIndex: 0);
    cityController.text = "Chennai";
    _loadInitialDataForVisibleTab();
    _pharmacyTabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (!_pharmacyTabController.indexIsChanging) {
      int currentIndex = _pharmacyTabController.index;
      if (currentIndex == 1 && pharmacies.isEmpty && !isLoadingPharmacies && cityController.text.isNotEmpty) {
        fetchPharmaciesAndDisplayOnMap();
      } else if (currentIndex == 2 && reminders.isEmpty && !isLoadingReminders) {
        fetchReminders();
      } else if (currentIndex == 3 && discounts.isEmpty && !isLoadingDiscounts) {
        fetchDiscounts();
      }
    }
  }

  Future<void> _loadInitialDataForVisibleTab() async {
    // For "Search Meds" tab (index 0), no initial data load needed.
    // It will show the attractive empty state.
    if (_pharmacyTabController.index == 2 && reminders.isEmpty && !isLoadingReminders) {
      await fetchReminders();
    } else if (_pharmacyTabController.index == 3 && discounts.isEmpty && !isLoadingDiscounts) {
      await fetchDiscounts();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pharmacyTabController.removeListener(_handleTabChange);
    _pharmacyTabController.dispose();
    searchController.dispose();
    medicineNameController.dispose();
    cityController.dispose();
    timeController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    _mapController = controller;
    if (pharmacies.isEmpty && !isLoadingPharmacies && cityController.text.isNotEmpty) {
      fetchPharmaciesAndDisplayOnMap();
    } else if (pharmacies.isNotEmpty) {
      _updateMarkers();
      if (_mapController != null && _markers.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapCenter, 12.0),
        );
      }
    }
  }

  Future<void> fetchPharmaciesAndDisplayOnMap() async {
    if (cityController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a city to search for pharmacies.')));
        setState(() {
          pharmacies = [];
          _markers.clear();
          isLoadingPharmacies = false;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => isLoadingPharmacies = true);
    final city = cityController.text;

    try {
      final uri = Uri.parse("$_apiBaseUrl/pharmacy/locator").replace(queryParameters: {'city': city});
      String? token = await getToken();
      final headers = {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          pharmacies = decodedData is List ? decodedData : [];
          _updateMarkers();
          if (pharmacies.isNotEmpty) {
            try {
              final firstPharmacy = pharmacies.first;
              if (firstPharmacy['lat'] != null && firstPharmacy['lon'] != null) {
                final lat = double.tryParse(firstPharmacy['lat'].toString());
                final lon = double.tryParse(firstPharmacy['lon'].toString());
                if (lat != null && lon != null) {
                  _currentMapCenter = LatLng(lat, lon);
                  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentMapCenter, 12.0));
                }
              } else {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPositionChennai, 10.0));
              }
            } catch (e) {
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPositionChennai, 10.0));
            }
          } else {
            _currentMapCenter = _initialPositionChennai;
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentMapCenter, 10.0));
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to load pharmacies: ${response.reasonPhrase ?? "Unknown error"}'),
              action: SnackBarAction(label: 'RETRY', onPressed: fetchPharmaciesAndDisplayOnMap)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error fetching pharmacies: ${e.toString().split(':').last.trim()}'),
            action: SnackBarAction(label: 'RETRY', onPressed: fetchPharmaciesAndDisplayOnMap)));
      }
    } finally {
      if (mounted) setState(() => isLoadingPharmacies = false);
    }
  }

  void _updateMarkers() {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    for (var pharmacy in pharmacies) {
      try {
        final lat = pharmacy['lat'];
        final lon = pharmacy['lon'];
        final name = pharmacy['name'] as String? ?? 'Unknown Pharmacy';
        final address = pharmacy['address'] as String? ?? 'N/A';
        final String markerIdValue = pharmacy['id']?.toString() ?? '${name}_${DateTime.now().millisecondsSinceEpoch}'; // Ensure unique ID

        if (lat != null && lon != null) {
          final parsedLat = lat is double ? lat : double.tryParse(lat.toString());
          final parsedLon = lon is double ? lon : double.tryParse(lon.toString());
          if (parsedLat != null && parsedLon != null) {
            newMarkers.add(Marker(
                markerId: MarkerId(markerIdValue),
                position: LatLng(parsedLat, parsedLon),
                infoWindow: InfoWindow(title: name, snippet: address)));
          }
        }
      } catch (e) {
        print("PharmacyScreen: Error creating marker for pharmacy $pharmacy: $e");
      }
    }
    if(mounted){
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  Future<void> searchMedicines() async {
    if (searchController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a medicine name')));
      }
      return;
    }
    if (!mounted) return;
    setState(() => isLoadingMedicines = true);
    final medicineName = searchController.text;

    try {
      String? token = await getToken();
      final headers = {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
      final response = await http.get(Uri.parse("$_apiBaseUrl/medicine/search?name=$medicineName"), headers: headers);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() => medicines = decodedData is List ? decodedData : []);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search medicines: ${response.reasonPhrase}')));
        setState(() => medicines = []); // Clear medicines on error
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error searching medicines: ${e.toString().split(':').last.trim()}')));
      }
      setState(() => medicines = []); // Clear medicines on error
    } finally {
      if (mounted) setState(() => isLoadingMedicines = false);
    }
  }

  Future<void> fetchDiscounts() async {
    if (!mounted) return;
    setState(() => isLoadingDiscounts = true);
    try {
      final token = await getToken();
      final headers = {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
      final response = await http.get(Uri.parse("$_apiBaseUrl/medicine/discounts"), headers: headers).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() => discounts = decodedData is List ? decodedData : []);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load discounts: ${response.reasonPhrase}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading discounts: ${e.toString().split(':').last.trim()}'),
                action: SnackBarAction(label: 'RETRY', onPressed: fetchDiscounts)));
      }
    } finally {
      if (mounted) setState(() => isLoadingDiscounts = false);
    }
  }

  Future<void> fetchReminders() async {
    if (!mounted) return;
    setState(() => isLoadingReminders = true);
    final token = await getToken();
    if (token == null) {
      if (mounted) setState(() => isLoadingReminders = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/medicine/my-reminders"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() => reminders = decodedData is List ? decodedData : []);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load reminders: ${response.reasonPhrase}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching reminders: ${e.toString().split(':').last.trim()}')));
      }
    } finally {
      if (mounted) setState(() => isLoadingReminders = false);
    }
  }

  Future<void> setMedicineReminder() async {
    final token = await getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please log in.')));
      }
      return;
    }
    if (medicineNameController.text.isEmpty || timeController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all fields.')));
      }
      return;
    }
    if (!mounted) return;
    setState(() => isSettingReminder = true);

    try {
      final response = await http.post(Uri.parse("$_apiBaseUrl/medicine/reminders"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: json.encode({"medicineName": medicineNameController.text, "reminderTime": timeController.text}));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Reminder set successfully!'), backgroundColor: Colors.green));
        }
        medicineNameController.clear();
        timeController.clear();
        selectedTime = TimeOfDay.now();
        fetchReminders();
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to set reminder: ${response.reasonPhrase}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error setting reminder: ${e.toString().split(':').last.trim()}')));
      }
    } finally {
      if (mounted) setState(() => isSettingReminder = false);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        initialEntryMode: TimePickerEntryMode.dial,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                    onSurface: Colors.deepPurple.shade700),
                textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: Colors.deepPurple.shade700))),
            child: child!,
          );
        });
    if (timeOfDay != null && timeOfDay != selectedTime) {
      if (!mounted) return;
      setState(() {
        selectedTime = timeOfDay;
        timeController.text =
        '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildSearchField(TextEditingController controller, String hint, VoidCallback onSearch, {bool forCity = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(forCity ? Icons.location_city : Icons.search, color: Colors.deepPurple.shade300),
          suffixIcon: IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: onSearch,
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }

  Widget _buildLoadingIndicator() => const Center(child: CircularProgressIndicator());

  Widget _buildEmptyState(String message, {IconData icon = Icons.info_outline}) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ));
  }

  // New attractive empty state for medicine search tab
  // New attractive empty state for medicine search tab
  Widget _buildAttractiveEmptySearchState() {
    return Center(
      child: SingleChildScrollView( // <-- WRAP WITH SingleChildScrollView
        padding: const EdgeInsets.all(25.0), // Move padding here
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Ensure text is centered
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 70,
              color: Colors.deepPurple.shade200,
            ),
            const SizedBox(height: 20),
            Text(
              "Discover Medicine Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Enter a medicine name (e.g., Aspirin, Paracetamol) to find details like generic names, US brands, and active ingredients from public health data sources.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              "Note: Price and local availability are not provided by this information service.",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  Widget buildMedicineSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchField(searchController, "Search medicines (e.g., Paracetamol)", searchMedicines),
          Expanded(
            child: isLoadingMedicines
                ? _buildLoadingIndicator()
                : medicines.isEmpty
                ? (searchController.text.isEmpty
                ? _buildAttractiveEmptySearchState() // Use new attractive empty state
                : _buildEmptyState( // Existing empty state for "no results"
              "No medicines found for \"${searchController.text}\".\nTry checking the spelling or search for a generic name.",
              icon: Icons.search_off_rounded,
            ))
                : ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                final String name = med['name'] as String? ?? 'N/A';
                final String brand = med['brand'] as String? ?? 'N/A';
                final String price = med['price'] as String? ?? 'N/A';
                final String strength = med['strength'] as String? ?? 'N/A';
                final String source = med['source'] as String? ?? '';

                return Card(
                  elevation: 2.5,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.medication_outlined, color: Colors.green.shade700, size: 28),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (brand.isNotEmpty && brand != 'N/A (US API)' && brand.toLowerCase() != 'n/a')
                          Padding(
                            padding: const EdgeInsets.only(top:2.0),
                            child: Text("Brand: $brand", style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        if (strength.isNotEmpty && strength != 'N/A')
                          Padding(
                            padding: const EdgeInsets.only(top:2.0),
                            child: Text("Strength: $strength", style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        if (source.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Text(source, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey.shade500)),
                          ),
                      ],
                    ),
                    trailing: Text(
                      price == "N/A (Info API)" || price.toLowerCase() == "n/a" ? "Info Only" : "₹$price",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: price == "N/A (Info API)" || price.toLowerCase() == "n/a" ? Colors.blueGrey.shade700 : Colors.deepPurple,
                          fontSize: 13),
                    ),
                    isThreeLine: true, // Set to true if you expect 2-3 lines in subtitle
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPharmacyLocatorTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSearchField(cityController, "Enter city (e.g., Chennai)", fetchPharmaciesAndDisplayOnMap, forCity: true),
        ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: _currentMapCenter, zoom: 10.0),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
              ),
              if (isLoadingPharmacies)
                Container(color: Colors.black.withOpacity(0.1), child: _buildLoadingIndicator()),
              if (!isLoadingPharmacies && cityController.text.isEmpty && pharmacies.isEmpty)
                Center(
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(10)),
                        child: _buildEmptyState("Enter a city to find pharmacies.", icon: Icons.search_outlined))),
              if (!isLoadingPharmacies && cityController.text.isNotEmpty && pharmacies.isEmpty)
                Center(
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(10)),
                        child: _buildEmptyState("No pharmacies found in \"${cityController.text}\". Try another city.", icon: Icons.location_off_outlined))),
            ],
          ),
        ),
        if (pharmacies.isNotEmpty && !isLoadingPharmacies)
          Container(
            height: 150,
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, -2))]),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];
                return ListTile(
                  title: Text(pharmacy['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(pharmacy['address'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: const Icon(Icons.local_pharmacy, color: Colors.deepPurple),
                  dense: true,
                  onTap: () {
                    final lat = pharmacy['lat'] is double ? pharmacy['lat'] : double.tryParse(pharmacy['lat'].toString());
                    final lon = pharmacy['lon'] is double ? pharmacy['lon'] : double.tryParse(pharmacy['lon'].toString());
                    if (lat != null && lon != null && _mapController != null) {
                      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), 15.0));
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildMedicationRemindersTab() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: fetchReminders,
      color: theme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Set New Reminder", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: medicineNameController,
                      decoration: InputDecoration(labelText: "Medicine Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: Icon(Icons.medication_rounded, color: Colors.deepPurple.shade300)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      onTap: _selectTime,
                      decoration: InputDecoration(labelText: "Reminder Time", suffixIcon: Icon(Icons.access_time_filled_rounded, color: theme.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: Icon(Icons.alarm_on_rounded, color: Colors.deepPurple.shade300)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: isSettingReminder
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5,))
                          : const Icon(Icons.alarm_add_rounded),
                      label: Text(isSettingReminder ? "Setting..." : "Set Reminder"),
                      onPressed: isSettingReminder ? null : setMedicineReminder,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    )
                  ]),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: Colors.deepPurple.shade800, size: 26),
              const SizedBox(width: 8),
              Text("My Reminders", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          isLoadingReminders && reminders.isEmpty
              ? Padding(padding: const EdgeInsets.all(16.0), child: _buildLoadingIndicator())
              : reminders.isEmpty
              ? _buildEmptyState("You have no reminders set yet. Add one above!", icon: Icons.notifications_off_outlined)
              : ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.medication_liquid_outlined, color: Colors.blue.shade700)),
                  title: Text(reminder['medicineName'] as String? ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: Text("Time: ${reminder['reminderTime'] as String? ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
                  trailing: IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400), onPressed: () {
                    // TODO: Implement delete reminder functionality
                    // Example: _showDeleteReminderConfirmation(reminder['id']);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete functionality to be implemented.")));
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildDiscountsTab() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: fetchDiscounts,
      color: theme.primaryColor,
      child: isLoadingDiscounts && discounts.isEmpty
          ? _buildLoadingIndicator()
          : discounts.isEmpty
          ? _buildEmptyState("No discounts or special offers available at the moment. Check back later!", icon: Icons.sentiment_dissatisfied_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(12.0), // Slightly less padding
        itemCount: discounts.length,
        itemBuilder: (context, index) {
          final discount = discounts[index];
          return Card(
            elevation: 3.5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2), width: 0.5)
            ),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  gradient: LinearGradient(
                    colors: [theme.primaryColor.withOpacity(0.03), Colors.white, Colors.purple.shade50.withOpacity(0.3)],
                    stops: const [0.0, 0.7, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.local_offer_rounded, color: theme.primaryColor, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            discount['offer'] as String? ?? 'Special Offer',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColorDark, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      discount['description'] as String? ?? 'Save on your next purchase!',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    if (discount['code'] != null && (discount['code'] as String).isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(Icons.vpn_key_outlined, color: Colors.white, size: 16),
                          label: Text("CODE: ${discount['code']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.event_available_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Valid until: ${discount['validity'] as String? ?? 'N/A'}",
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy & Wellness"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _pharmacyTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), // Adjusted for consistency
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12.5), // Adjusted for consistency
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.search_rounded, size: 20), text: "Search Meds"),
            Tab(icon: Icon(Icons.storefront_outlined, size: 20), text: "Pharmacies"),
            Tab(icon: Icon(Icons.notifications_active_outlined, size: 20), text: "Reminders"),
            Tab(icon: Icon(Icons.local_offer_outlined, size: 20), text: "Offers"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _pharmacyTabController,
        children: [
          buildMedicineSearchTab(),
          buildPharmacyLocatorTab(),
          buildMedicationRemindersTab(),
          buildDiscountsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3),
    );
  }
}