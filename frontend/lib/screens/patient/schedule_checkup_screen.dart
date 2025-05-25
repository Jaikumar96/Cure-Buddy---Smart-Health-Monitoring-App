import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:logger/logger.dart'; // Not used, can be removed or properly configured
// Correct:
import 'package:permission_handler/permission_handler.dart'; // For location permissions

import '../../services/api_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class ScheduleCheckupScreen extends StatefulWidget {
  const ScheduleCheckupScreen({super.key});
  @override
  _ScheduleCheckupScreenState createState() => _ScheduleCheckupScreenState();
}

class _ScheduleCheckupScreenState extends State<ScheduleCheckupScreen>
    with SingleTickerProviderStateMixin {
  // === State for "My Checkups" Tab ===
  String? _editingScheduleId;
  final _vitalController = TextEditingController();
  DateTime? _selectedDateTime;
  String _checkupFrequency = 'DAILY';
  List<Map<String, dynamic>> _schedules = [];
  bool _loadingSchedules = true;
  bool _isSubmittingSchedule = false;

  // === State for "Lab Locator" Tab & "Lab Test Services" Tab ===
  List<Map<String, dynamic>> _labs = []; // Will store LabResult data from backend
  String? _selectedLabForBooking;
  String _selectedStateForLabSearch = "Tamil Nadu";
  String? _selectedDistrictForLabSearch = "Chennai";
  final _testNameController = TextEditingController();
  List<Map<String, dynamic>> _labBookings = [];
  bool _loadingLabs = false;
  bool _loadingLabBookings = false;
  bool _isBookingLabTest = false;

  final Map<String, List<String>> _statesAndDistricts = {
    "Andaman and Nicobar Islands": ["Nicobars", "North and Middle Andaman", "South Andaman"],
    "Andhra Pradesh": ["Anantapur", "Chittoor", "East Godavari", "Guntur", "Krishna", "Kurnool", "Nellore", "Prakasam", "Srikakulam", "Visakhapatnam", "Vizianagaram", "West Godavari", "Y.S.R. Kadapa"],
    "Arunachal Pradesh": ["Tawang", "West Kameng", "East Kameng", "Papum Pare", "Kurung Kumey", "Kra Daadi", "Lower Subansiri", "Upper Subansiri", "West Siang", "East Siang", "Siang", "Upper Siang", "Lower Siang", "Lower Dibang Valley", "Dibang Valley", "Anjaw", "Lohit", "Namsai", "Changlang", "Tirap", "Longding"],
    "Assam": ["Baksa", "Barpeta", "Biswanath", "Bongaigaon", "Cachar", "Charaideo", "Chirang", "Darrang", "Dhemaji", "Dhubri", "Dibrugarh", "Dima Hasao", "Goalpara", "Golaghat", "Hailakandi", "Hojai", "Jorhat", "Kamrup Metropolitan", "Kamrup", "Karbi Anglong", "Karimganj", "Kokrajhar", "Lakhimpur", "Majuli", "Morigaon", "Nagaon", "Nalbari", "Sivasagar", "Sonitpur", "South Salmara-Mankachar", "Tinsukia", "Udalguri", "West Karbi Anglong"],
    "Bihar": ["Araria", "Arwal", "Aurangabad", "Banka", "Begusarai", "Bhagalpur", "Bhojpur", "Buxar", "Darbhanga", "East Champaran", "Gaya", "Gopalganj", "Jamui", "Jehanabad", "Kaimur", "Katihar", "Khagaria", "Kishanganj", "Lakhisarai", "Madhepura", "Madhubani", "Munger", "Muzaffarpur", "Nalanda", "Nawada", "Patna", "Purnia", "Rohtas", "Saharsa", "Samastipur", "Saran", "Sheikhpura", "Sheohar", "Sitamarhi", "Siwan", "Supaul", "Vaishali", "West Champaran"],
    "Chandigarh": ["Chandigarh"],
    "Chhattisgarh": ["Balod", "Baloda Bazar", "Balrampur", "Bastar", "Bemetara", "Bijapur", "Bilaspur", "Dantewada", "Dhamtari", "Durg", "Gariaband", "Janjgir-Champa", "Jashpur", "Kabirdham", "Kanker", "Kondagaon", "Korba", "Koriya", "Mahasamund", "Mungeli", "Narayanpur", "Raigarh", "Raipur", "Rajnandgaon", "Sukma", "Surajpur", "Surguja"],
    "Dadra and Nagar Haveli and Daman and Diu": ["Daman", "Diu", "Dadra and Nagar Haveli"],
    "Delhi": ["Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North East Delhi", "North West Delhi", "Shahdara", "South Delhi", "South East Delhi", "South West Delhi", "West Delhi"],
    "Goa": ["North Goa", "South Goa"],
    "Gujarat": ["Ahmedabad", "Amreli", "Anand", "Aravalli", "Banaskantha", "Bharuch", "Bhavnagar", "Botad", "Chhota Udaipur", "Dahod", "Dang", "Devbhoomi Dwarka", "Gandhinagar", "Gir Somnath", "Jamnagar", "Junagadh", "Kheda", "Kutch", "Mahisagar", "Mehsana", "Morbi", "Narmada", "Navsari", "Panchmahal", "Patan", "Porbandar", "Rajkot", "Sabarkantha", "Surat", "Surendranagar", "Tapi", "Vadodara", "Valsad"],
    "Haryana": ["Ambala", "Bhiwani", "Charkhi Dadri", "Faridabad", "Fatehabad", "Gurugram", "Hisar", "Jhajjar", "Jind", "Kaithal", "Karnal", "Kurukshetra", "Mahendragarh", "Nuh", "Palwal", "Panchkula", "Panipat", "Rewari", "Rohtak", "Sirsa", "Sonipat", "Yamunanagar"],
    "Himachal Pradesh": ["Bilaspur", "Chamba", "Hamirpur", "Kangra", "Kinnaur", "Kullu", "Lahaul Spiti", "Mandi", "Shimla", "Sirmaur", "Solan", "Una"],
    "Jammu and Kashmir": ["Anantnag", "Bandipora", "Baramulla", "Budgam", "Doda", "Ganderbal", "Jammu", "Kathua", "Kishtwar", "Kulgam", "Kupwara", "Poonch", "Pulwama", "Rajouri", "Ramban", "Reasi", "Samba", "Shopian", "Srinagar", "Udhampur"],
    "Jharkhand": ["Bokaro", "Chatra", "Deoghar", "Dhanbad", "Dumka", "East Singhbhum", "Garhwa", "Giridih", "Godda", "Gumla", "Hazaribagh", "Jamtara", "Khunti", "Koderma", "Latehar", "Lohardaga", "Pakur", "Palamu", "Ramgarh", "Ranchi", "Sahebganj", "Seraikela Kharsawan", "Simdega", "West Singhbhum"],
    "Karnataka": ["Bagalkot", "Bangalore Rural", "Bangalore Urban", "Belgaum", "Bellary", "Bidar", "Chamarajanagar", "Chikkaballapur", "Chikkamagaluru", "Chitradurga", "Dakshina Kannada", "Davanagere", "Dharwad", "Gadag", "Gulbarga", "Hassan", "Haveri", "Kodagu", "Kolar", "Koppal", "Mandya", "Mysore", "Raichur", "Ramanagara", "Shimoga", "Tumkur", "Udupi", "Uttara Kannada", "Vijayanapura", "Yadgir"],
    "Kerala": ["Alappuzha", "Ernakulam", "Idukki", "Kannur", "Kasaragod", "Kollam", "Kottayam", "Kozhikode", "Malappuram", "Palakkad", "Pathanamthitta", "Thiruvananthapuram", "Thrissur", "Wayanad"],
    "Ladakh": ["Kargil", "Leh"],
    "Lakshadweep": ["Lakshadweep"],
    "Madhya Pradesh": ["Agar Malwa", "Alirajpur", "Anuppur", "Ashoknagar", "Balaghat", "Barwani", "Betul", "Bhind", "Bhopal", "Burhanpur", "Chhatarpur", "Chhindwara", "Damoh", "Datia", "Dewas", "Dhar", "Dindori", "Guna", "Gwalior", "Harda", "Hoshangabad", "Indore", "Jabalpur", "Jhabua", "Katni", "Khandwa", "Khargone", "Mandla", "Mandsaur", "Morena", "Narsinghpur", "Neemuch", "Panna", "Raisen", "Rajgarh", "Ratlam", "Rewa", "Sagar", "Satna", "Sehore", "Seoni", "Shahdol", "Shajapur", "Sheopur", "Shivpuri", "Sidhi", "Singrauli", "Tikamgarh", "Ujjain", "Umaria", "Vidisha"],
    "Maharashtra": ["Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondia", "Hingoli", "Jalgaon", "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded", "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani", "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara", "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"],
    "Manipur": ["Bishnupur", "Chandel", "Churachandpur", "Imphal East", "Imphal West", "Jiribam", "Kakching", "Kamjong", "Kangpokpi", "Noney", "Pherzawl", "Senapati", "Tamenglong", "Tengnoupal", "Thoubal", "Ukhrul"],
    "Meghalaya": ["East Garo Hills", "East Jaintia Hills", "East Khasi Hills", "North Garo Hills", "Ri Bhoi", "South Garo Hills", "South West Garo Hills", "South West Khasi Hills", "West Garo Hills", "West Jaintia Hills", "West Khasi Hills"],
    "Mizoram": ["Aizawl", "Champhai", "Kolasib", "Lawngtlai", "Lunglei", "Mamit", "Saiha", "Serchhip"],
    "Nagaland": ["Dimapur", "Kiphire", "Kohima", "Longleng", "Mokokchung", "Mon", "Peren", "Phek", "Tuensang", "Wokha", "Zunheboto"],
    "Odisha": ["Angul", "Balangir", "Balasore", "Bargarh", "Bhadrak", "Boudh", "Cuttack", "Deogarh", "Dhenkanal", "Gajapati", "Ganjam", "Jagatsinghpur", "Jajpur", "Jharsuguda", "Kalahandi", "Kandhamal", "Kendrapara", "Kendujhar", "Khordha", "Koraput", "Malkangiri", "Mayurbhanj", "Nabarangpur", "Nayagarh", "Nuapada", "Puri", "Rayagada", "Sambalpur", "Subarnapur", "Sundargarh"],
    "Puducherry": ["Karaikal", "Mahe", "Puducherry", "Yanam"],
    "Punjab": ["Amritsar", "Barnala", "Bathinda", "Faridkot", "Fatehgarh Sahib", "Fazilka", "Firozpur", "Gurdaspur", "Hoshiarpur", "Jalandhar", "Kapurthala", "Ludhiana", "Mansa", "Moga", "Mohali", "Muktsar", "Pathankot", "Patiala", "Rupnagar", "Sangrur", "Shaheed Bhagat Singh Nagar", "Tarn Taran"],
    "Rajasthan": ["Ajmer", "Alwar", "Banswara", "Baran", "Barmer", "Bharatpur", "Bhilwara", "Bikaner", "Bundi", "Chittorgarh", "Churu", "Dausa", "Dholpur", "Dungarpur", "Hanumangarh", "Jaipur", "Jaisalmer", "Jalore", "Jhalawar", "Jhunjhunu", "Jodhpur", "Karauli", "Kota", "Nagaur", "Pali", "Pratapgarh", "Rajsamand", "Sawai Madhopur", "Sikar", "Sirohi", "Sri Ganganagar", "Tonk", "Udaipur"],
    "Sikkim": ["East Sikkim", "North Sikkim", "South Sikkim", "West Sikkim"],
    "Tamil Nadu": ["Ariyalur", "Chengalpattu", "Chennai", "Coimbatore", "Cuddalore", "Dharmapuri", "Dindigul", "Erode", "Kallakurichi", "Kanchipuram", "Kanyakumari", "Karur", "Krishnagiri", "Madurai", "Mayiladuthurai", "Nagapattinam", "Namakkal", "Nilgiris", "Perambalur", "Pudukkottai", "Ramanathapuram", "Ranipet", "Salem", "Sivaganga", "Tenkasi", "Thanjavur", "Theni", "Thoothukudi", "Tiruchirappalli", "Tirunelveli", "Tirupathur", "Tiruppur", "Tiruvallur", "Tiruvannamalai", "Tiruvarur", "Vellore", "Viluppuram", "Virudhunagar"],
    "Telangana": ["Adilabad", "Bhadradri Kothagudem", "Hyderabad", "Jagtial", "Jangaon", "Jayashankar Bhupalpally", "Jogulamba Gadwal", "Kamareddy", "Karimnagar", "Khammam", "Komaram Bheem", "Mahabubabad", "Mahbubnagar", "Mancherial", "Medak", "Medchal-Malkajgiri", "Mulugu", "Nagarkurnool", "Nalgonda", "Narayanpet", "Nirmal", "Nizamabad", "Peddapalli", "Rajanna Sircilla", "Ranga Reddy", "Sangareddy", "Siddipet", "Suryapet", "Vikarabad", "Wanaparthy", "Warangal Rural", "Warangal Urban", "Yadadri Bhuvanagiri"],
    "Tripura": ["Dhalai", "Gomati", "Khowai", "North Tripura", "Sepahijala", "South Tripura", "Unakoti", "West Tripura"],
    "Uttar Pradesh": ["Agra", "Aligarh", "Ambedkar Nagar", "Amethi", "Amroha", "Auraiya", "Ayodhya", "Azamgarh", "Baghpat", "Bahraich", "Ballia", "Balrampur", "Banda", "Barabanki", "Bareilly", "Basti", "Bhadohi", "Bijnor", "Budaun", "Bulandshahr", "Chandauli", "Chitrakoot", "Deoria", "Etah", "Etawah", "Farrukhabad", "Fatehpur", "Firozabad", "Gautam Buddh Nagar", "Ghaziabad", "Ghazipur", "Gonda", "Gorakhpur", "Hamirpur", "Hapur", "Hardoi", "Hathras", "Jalaun", "Jaunpur", "Jhansi", "Kannauj", "Kanpur Dehat", "Kanpur Nagar", "Kasganj", "Kaushambi", "Kheri", "Kushinagar", "Lalitpur", "Lucknow", "Maharajganj", "Mahoba", "Mainpuri", "Mathura", "Mau", "Meerut", "Mirzapur", "Moradabad", "Muzaffarnagar", "Pilibhit", "Pratapgarh", "Prayagraj", "Raebareli", "Rampur", "Saharanpur", "Sambhal", "Sant Kabir Nagar", "Shahjahanpur", "Shamli", "Shravasti", "Siddharthnagar", "Sitapur", "Sonbhadra", "Sultanpur", "Unnao", "Varanasi"],
    "Uttarakhand": ["Almora", "Bageshwar", "Chamoli", "Champawat", "Dehradun", "Haridwar", "Nainital", "Pauri Garhwal", "Pithoragarh", "Rudraprayag", "Tehri Garhwal", "Udham Singh Nagar", "Uttarkashi"],
    "West Bengal": ["Alipurduar", "Bankura", "Birbhum", "Cooch Behar", "Dakshin Dinajpur", "Darjeeling", "Hooghly", "Howrah", "Jalpaiguri", "Jhargram", "Kalimpong", "Kolkata", "Malda", "Murshidabad", "Nadia", "North 24 Parganas", "Paschim Bardhaman", "Paschim Medinipur", "Purba Bardhaman", "Purba Medinipur", "Purulia", "South 24 Parganas", "Uttar Dinajpur"],
  };
  late List<String> _districtsForSelectedState;

  GoogleMapController? _labMapController;
  final Set<Marker> _labMarkers = {};
  static const LatLng _initialMapCenterIndia = LatLng(20.5937, 78.9629);
  LatLng _currentLabMapCenter = _initialMapCenterIndia;
  bool _locationPermissionGranted = false;

  bool _isMounted = true;
  late TabController _tabController;
  String? _token;

  // Removed: get logger => null; (as it's not a functional logger)

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _tabController = TabController(length: 3, vsync: this);
    _updateDistrictsForSelectedState();
    _initializeScreen();
    _tabController.addListener(_handleTabSelection);
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.location.request();
    }
    if (mounted) {
      setState(() {
        _locationPermissionGranted = status.isGranted;
      });
      if (!_locationPermissionGranted) {
        _showSnackBar("Location permission is required to show your current location on the map.", isError: true);
      }
    }
  }


  void _updateDistrictsForSelectedState() {
    _districtsForSelectedState = _statesAndDistricts[_selectedStateForLabSearch] ?? [];
    if (_districtsForSelectedState.isNotEmpty) {
      if (_selectedDistrictForLabSearch == null || !_districtsForSelectedState.contains(_selectedDistrictForLabSearch)) {
        _selectedDistrictForLabSearch = _districtsForSelectedState.first;
      }
    } else {
      _selectedDistrictForLabSearch = null;
    }
  }

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isMounted) return;
    _token = prefs.getString('token');

    if (_token == null || _token!.isEmpty) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    await _loadSchedules();

    // Initial load for lab tabs based on current tab index
    // This ensures data is fetched if starting on Lab Map or Lab Services tab
    if (_tabController.index == 1) {
      if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) {
        await _fetchLabs();
      }
    } else if (_tabController.index == 2) {
      if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) {
        await _fetchLabs(); // Labs are needed for booking
      }
      if (_labBookings.isEmpty && !_loadingLabBookings) {
        await _fetchLabBookings();
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _vitalController.dispose();
    _testNameController.dispose();
    _labMapController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && _isMounted) {
      int currentIndex = _tabController.index;
      if (currentIndex == 0) {
        if (_schedules.isEmpty && !_loadingSchedules) _loadSchedules();
      } else if (currentIndex == 1) { // Lab Locator Tab
        if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) {
          _fetchLabs();
        }
      } else if (currentIndex == 2) { // Lab Test Services Tab
        // Ensure labs are fetched if not already, as they are needed for selection
        if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) {
          _fetchLabs();
        }
        if (_labBookings.isEmpty && !_loadingLabBookings) {
          _fetchLabBookings();
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!_isMounted || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<void> _loadSchedules() async {
    if (!_isMounted || _token == null) return;
    if (mounted) setState(() => _loadingSchedules = true);
    try {
      final data = await ApiService.getPatientSchedules(_token!);
      if (!_isMounted) return;
      setState(() {
        _schedules = List<Map<String, dynamic>>.from(
            data.map((s) => Map<String, dynamic>.from(s as Map)));
      });
    } catch (e) {
      if (_isMounted) _showSnackBar('Error loading schedules: ${e.toString().split(':').last.trim()}', isError: true);
    } finally {
      if (_isMounted && mounted) setState(() => _loadingSchedules = false);
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime initialDatePickerDate = _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1));
    final DateTime now = DateTime.now();
    final DateTime firstPickableDate = initialDatePickerDate.isBefore(now) ? now : initialDatePickerDate;

    final date = await showDatePicker(
      context: context,
      initialDate: firstPickableDate,
      firstDate: now,
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).primaryColor)
      ), child: child!),
    );
    if (date == null || !_isMounted) return;

    final TimeOfDay initialTimePickerTime = TimeOfDay.fromDateTime(
        _selectedDateTime ?? DateTime.now().add(const Duration(hours:1))
    );
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(DateTime.now());
    TimeOfDay firstPickableTime = initialTimePickerTime;

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      if(initialTimePickerTime.hour < currentTime.hour || (initialTimePickerTime.hour == currentTime.hour && initialTimePickerTime.minute < currentTime.minute)){
        firstPickableTime = currentTime;
      }
    }

    final time = await showTimePicker(
      context: context,
      initialTime: firstPickableTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).primaryColor)
      ), child: child!),
    );
    if (time == null || !_isMounted) return;

    final newSelectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (newSelectedDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      if(mounted) _showSnackBar('Scheduled time cannot be in the past.', isError: true);
      return;
    }

    if(mounted) {
      setState(() => _selectedDateTime = newSelectedDateTime);
    }
  }

  Future<void> _submitSchedule() async {
    if (_vitalController.text.trim().isEmpty) { _showSnackBar('Please enter a vital name or checkup purpose.', isError: true); return; }
    if (_selectedDateTime == null) { _showSnackBar('Please pick a date and time.', isError: true); return; }
    if (_selectedDateTime!.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      _showSnackBar('Scheduled time cannot be in the past. Please pick a new time.', isError: true);
      return;
    }
    if (!_isMounted || _token == null) return;
    if(mounted) setState(() => _isSubmittingSchedule = true);
    try {
      if (_editingScheduleId != null) {
        await ApiService.updateSchedule(_token!, _editingScheduleId!, "", _vitalController.text.trim(), _selectedDateTime!, _checkupFrequency);
        if (_isMounted) _showSnackBar('Schedule updated successfully!');
      } else {
        await ApiService.scheduleCheckup(_token!, _vitalController.text.trim(), _selectedDateTime!, _checkupFrequency);
        if (_isMounted) _showSnackBar('Checkup scheduled successfully!');
      }
      if (!_isMounted) return;
      _resetScheduleForm();
      await _loadSchedules();
    } catch (e) {
      if (_isMounted) _showSnackBar('Error: ${e.toString().split(':').last.trim()}', isError: true);
    } finally {
      if (_isMounted && mounted) setState(() => _isSubmittingSchedule = false);
    }
  }

  void _resetScheduleForm() {
    _vitalController.clear();
    _selectedDateTime = null;
    _editingScheduleId = null;
    _checkupFrequency = 'DAILY';
    if(mounted) setState(() {});
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await _showConfirmationDialog("Confirm Delete", "Are you sure you want to delete this schedule?");
    if (confirm == true && _isMounted && _token != null) {
      try {
        await ApiService.deleteSchedule(_token!, id);
        if (_isMounted) _showSnackBar('Schedule deleted successfully.');
        await _loadSchedules();
      } catch (e) {
        if (_isMounted) _showSnackBar('Error deleting: ${e.toString().split(':').last.trim()}', isError: true);
      }
    }
  }

  void _editSchedule(Map<String, dynamic> schedule) {
    if (!_isMounted) return;
    setState(() {
      _editingScheduleId = schedule['id'] as String?;
      _vitalController.text = schedule['vitalName'] as String? ?? '';
      _checkupFrequency = schedule['frequency'] as String? ?? 'DAILY';
      try {
        final scheduledDateTimeString = schedule['scheduledDateTime'] as String?;
        _selectedDateTime = scheduledDateTimeString != null ? DateTime.parse(scheduledDateTimeString).toLocal() : null;
      } catch (e) {
        _selectedDateTime = null;
        if (_isMounted) _showSnackBar('Error parsing schedule date.', isError: true);
      }
    });
  }

  void _onLabMapCreated(GoogleMapController controller) {
    if (!_isMounted) return;
    _labMapController = controller;
    // Fetch labs if map is created, state is set, and labs list is empty.
    if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) {
      _fetchLabs();
    } else if (_labs.isNotEmpty) {
      _updateLabMarkers(); // Ensure markers are updated if labs were already fetched
      _animateMapToFirstLabOrCenter(); // Animate to current selection or default
    } else {
      _animateMapToFirstLabOrCenter(); // Animate to default if no labs
    }
  }

  // This method is now compatible with LabResult structure from OSM/Overpass
  // as long as backend sends `id`, `name`, `address`, `lat`, `lon`.
  void _updateLabMarkers() {
    if (!_isMounted) return;
    final Set<Marker> newMarkers = {};
    for (var lab in _labs) { // _labs is List<Map<String, dynamic>> from JSON
      try {
        final lat = lab['lat']; // Expected to be double or parsable string
        final lon = lab['lon']; // Expected to be double or parsable string
        final name = lab['name'] as String? ?? 'Unknown Lab';
        final address = lab['address'] as String? ?? 'N/A';
        // 'id' from LabResult (OSM element ID)
        final markerIdVal = lab['id']?.toString() ?? '${name}_${DateTime.now().millisecondsSinceEpoch}';

        if (lat != null && lon != null) {
          final parsedLat = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
          final parsedLon = (lon is num) ? lon.toDouble() : double.tryParse(lon.toString());

          if (parsedLat != null && parsedLon != null) {
            newMarkers.add(
              Marker(
                markerId: MarkerId(markerIdVal),
                position: LatLng(parsedLat, parsedLon),
                infoWindow: InfoWindow(title: name, snippet: address),
                onTap: () {
                  if(mounted) {
                    setState(() => _selectedLabForBooking = name);
                    _showSnackBar("Selected: $name. Book in 'Test Services' tab.");
                  }
                },
              ),
            );
          } else {
            print("SCHEDULE_CHECKUP_SCREEN: Could not parse lat/lon for lab (OSM): $name from data: $lab");
          }
        } else {
          print("SCHEDULE_CHECKUP_SCREEN: Lab from OSM missing lat/lon: $name from data: $lab");
        }
      } catch (e) {
        print("Error creating marker for lab $lab: $e");
      }
    }
    if (mounted) {
      setState(() {
        _labMarkers.clear();
        _labMarkers.addAll(newMarkers);
      });
    }
    print("Lab markers updated from OSM/Overpass. Total markers: ${_labMarkers.length}");
  }


  void _animateMapToFirstLabOrCenter() {
    if (!_isMounted || _labMapController == null) return;

    LatLng targetCenter = _initialMapCenterIndia;
    double targetZoom = 5.0; // Default zoom for India

    // --- Smart Centering Logic ---
    // 1. Prioritize selected district if available and specific
    if (_selectedDistrictForLabSearch != null && _selectedDistrictForLabSearch!.isNotEmpty) {
      // Example: Specific coordinates for major districts (expand this map)
      const districtCenters = {
        "Chennai": LatLng(13.0827, 80.2707), "Coimbatore": LatLng(11.0168, 76.9558),
        "Bangalore Urban": LatLng(12.9716, 77.5946), "Hyderabad": LatLng(17.3850, 78.4867),
        "Pune": LatLng(18.5204, 73.8567), "Mumbai City": LatLng(19.0760, 72.8777),
        "Kolkata": LatLng(22.5726, 88.3639), "New Delhi": LatLng(28.6139, 77.2090),
      };
      if (districtCenters.containsKey(_selectedDistrictForLabSearch)) {
        targetCenter = districtCenters[_selectedDistrictForLabSearch!]!;
        targetZoom = 10.0; // Zoom in for district
      }
      // Else, if district is selected but not in map, it will fall through to state or first lab.
    }
    // 2. Fallback to selected state if district is not specific or not found
    else if (_selectedStateForLabSearch.isNotEmpty) {
      // Example: Specific coordinates for states (expand this map)
      const stateCenters = {
        "Tamil Nadu": LatLng(11.1271, 78.6569), "Karnataka": LatLng(15.3173, 75.7139),
        "Telangana": LatLng(17.8749, 78.1099), "Maharashtra": LatLng(19.7515, 75.7139),
        "Delhi": LatLng(28.7041, 77.1025),
      };
      if (stateCenters.containsKey(_selectedStateForLabSearch)) {
        targetCenter = stateCenters[_selectedStateForLabSearch]!;
        targetZoom = 7.0; // Zoom out a bit for state
      }
    }

    // 3. If labs are loaded, prioritize the first lab in the list
    if (_labs.isNotEmpty) {
      final firstLabWithCoords = _labs.firstWhere(
            (lab) => lab['lat'] != null && lab['lon'] != null,
        orElse: () => <String, dynamic>{},
      );
      if (firstLabWithCoords.isNotEmpty) {
        final lat = firstLabWithCoords['lat']; final lon = firstLabWithCoords['lon'];
        final pLat = (lat is String) ? double.tryParse(lat) : (lat as num?)?.toDouble();
        final pLon = (lon is String) ? double.tryParse(lon) : (lon as num?)?.toDouble();
        if (pLat != null && pLon != null) {
          targetCenter = LatLng(pLat, pLon);
          targetZoom = 12.0; // Zoom in to the specific lab
        }
      }
    }
    // --- End Smart Centering Logic ---

    _currentLabMapCenter = targetCenter;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isMounted && _labMapController != null) {
        try {
          _labMapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLabMapCenter, targetZoom));
        } catch (e) {
          print("Error animating map: $e. Map might not be fully initialized.");
        }
      }
    });
  }


  Future<void> _fetchLabs() async {
    if (!_isMounted || _token == null) return;
    if (_selectedStateForLabSearch.isEmpty) {
      if (mounted) {
        setState(() { _labs = []; _loadingLabs = false; _selectedLabForBooking = null; _labMarkers.clear(); });
        _animateMapToFirstLabOrCenter(); // Center map to default if no state selected
      }
      return;
    }
    if (mounted) setState(() => _loadingLabs = true);
    try {
      // ApiService.getLabProviders will call the backend endpoint which uses LabLocatorService (OSM)
      final data = await ApiService.getLabProviders(_token!, _selectedStateForLabSearch, _selectedDistrictForLabSearch);
      if (!_isMounted) return;

      // Ensure data is correctly parsed as List<Map<String, dynamic>>
      List<Map<String,dynamic>> fetchedLabs = [];
      if (data is List) {
        fetchedLabs = List<Map<String,dynamic>>.from(data.map((item) {
          if (item is Map) {
            return Map<String,dynamic>.from(item);
          }
          print("Warning: Item in fetched lab data is not a Map: $item");
          return <String,dynamic>{}; // Return empty map to avoid error, will be filtered by _updateLabMarkers
        })).where((map) => map.isNotEmpty).toList();
      } else {
        print("Warning: Fetched lab data is not a List: $data");
      }

      setState(() {
        _labs = fetchedLabs;
        if (_selectedLabForBooking != null && !_labs.any((lab) => lab['name'] == _selectedLabForBooking)) {
          _selectedLabForBooking = null;
        } else if (_labs.isEmpty) {
          _selectedLabForBooking = null;
        }
        // This will now use the LabResult fields (id, name, address, lat, lon)
        _updateLabMarkers();
      });
      _animateMapToFirstLabOrCenter(); // Animate map after labs are fetched
    } catch (e) {
      if (_isMounted) _showSnackBar('Error fetching labs: ${e.toString().split(':').last.trim()}', isError: true);
      if (mounted) setState(() { _labs = []; _labMarkers.clear(); _selectedLabForBooking = null; });
      _animateMapToFirstLabOrCenter(); // Also animate map on error to reset view
    } finally {
      if (_isMounted && mounted) setState(() => _loadingLabs = false);
    }
  }

  Future<void> _fetchLabBookings() async {
    if (!_isMounted || _token == null) return;
    if (mounted) setState(() => _loadingLabBookings = true);
    try {
      final data = await ApiService.getMyLabBookings(_token!);
      if (!_isMounted) return;
      setState(() => _labBookings = List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map))));
    } catch (e) {
      if (_isMounted) _showSnackBar('Error fetching lab bookings: ${e.toString().split(':').last.trim()}', isError: true);
    } finally {
      if (_isMounted && mounted) setState(() => _loadingLabBookings = false);
    }
  }

  Future<void> _bookLabTest() async {
    if (_selectedLabForBooking == null) { _showSnackBar('Please select a lab.', isError: true); return; }
    if (_testNameController.text.trim().isEmpty) { _showSnackBar('Please enter the test name.', isError: true); return; }
    if (!_isMounted || _token == null) return;

    // Find the selected lab details to potentially pass more info to backend if needed (e.g., lab ID)
    // For now, the backend API `bookLabTest` seems to only take `providerName`.
    // Map<String, dynamic>? selectedLabDetails = _labs.firstWhere(
    //   (lab) => lab['name'] == _selectedLabForBooking,
    //   orElse: () => <String, dynamic>{},
    // );
    // String? labId = selectedLabDetails['id'] as String?;

    if (mounted) setState(() => _isBookingLabTest = true);
    try {
      final String bookingMessage = await ApiService.bookLabTest(
        _token!,
        _selectedLabForBooking!,
        _testNameController.text.trim(),
        0.0, // Price - backend might calculate or it's fixed
        // labId: labId, // Optional: if your ApiService.bookLabTest supports it
      );
      if (!_isMounted) return;
      _showSnackBar(bookingMessage.isNotEmpty ? bookingMessage : 'Lab test booked successfully!');
      _testNameController.clear();
      // _selectedLabForBooking = null; // Optionally clear selection after booking
      await _fetchLabBookings(); // Refresh bookings list
    } catch (e) {
      if (_isMounted) _showSnackBar('Error booking lab test: ${e.toString().split(':').last.trim()}', isError: true);
    } finally {
      if (_isMounted && mounted) setState(() => _isBookingLabTest = false);
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Confirm", style: TextStyle(color: Theme.of(context).primaryColorDark))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.primaryColorDark, size: 22), // Slightly smaller icon
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontSize: 18), // Slightly smaller title
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledTextField(TextEditingController controller, String label, {String? hint, IconData? pIcon, bool readOnly = false, VoidCallback? onTapAction}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTapAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: pIcon != null ? Icon(pIcon, color: Theme.of(context).primaryColor.withOpacity(0.7)) : null,
        suffixIcon: readOnly && onTapAction != null ? Icon(Icons.calendar_today_rounded, color: Theme.of(context).primaryColor) : null,
        filled: true,
        isDense: true, // Makes field a bit smaller
        fillColor: Colors.white,
      ),
    );
  }

  Widget _styledDropdown<T>(String label, T? value, List<T> items, Function(T?) onChanged, {String Function(T)? displayText, String? hintText}) {
    displayText ??= (item) => item.toString();
    T? currentValue = value;
    // Ensure the current value is among the items, or set to null to avoid "value not in items" error.
    if (value != null && !items.contains(value)) {
      // If items are not empty, and value not found, consider setting to first item or null.
      // For now, setting to null if not found.
      bool valueExists = false;
      for (var item in items) {
        if (item == value) {
          valueExists = true;
          break;
        }
      }
      if (!valueExists) currentValue = null;
    }


    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? (items.isEmpty ? "No options available" : "Select $label"),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        isDense: true,
        fillColor: Colors.white,
      ),
      value: currentValue,
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(displayText!(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Theme.of(context).primaryColor),
    );
  }

  Widget _styledButton(String label, VoidCallback? onPressed, {IconData? icon, bool isLoading = false}) {
    return ElevatedButton.icon(
      icon: isLoading
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)) // Smaller indicator
          : Icon(icon ?? Icons.check_circle_outline_rounded, size: 20), // Smaller icon
      onPressed: isLoading ? null : onPressed,
      label: Text(isLoading ? "Processing..." : label, style: const TextStyle(fontSize: 15)), // Slightly smaller text
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46), // Slightly smaller height
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  Widget _emptyStateWidget(String message, {IconData? icon = Icons.info_outline_rounded, BuildContext? specificContext}) {
    final contextForTheme = specificContext ?? context;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingWidget({String message = "Loading..."}) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 15),
              Text(message, style: TextStyle(color: Colors.grey[700], fontSize: 15), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCheckupsTab() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadSchedules,
      color: theme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3, // Consistent elevation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent shape
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingScheduleId == null ? "Schedule New Checkup" : "Edit Checkup",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColorDark),
                  ),
                  const SizedBox(height: 20),
                  _styledTextField(_vitalController, 'Vital Name / Checkup Purpose', hint: 'e.g., Blood Pressure Check', pIcon: Icons.monitor_heart_outlined),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _styledTextField(
                            TextEditingController(text: _selectedDateTime == null ? '' : DateFormat('dd MMM y, hh:mm a').format(_selectedDateTime!)),
                            'Date & Time',
                            readOnly: true,
                            onTapAction: _pickDateTime,
                            pIcon: Icons.calendar_month_outlined,
                          )
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 130,
                          child: _styledDropdown<String>(
                              'Frequency',
                              _checkupFrequency,
                              ['DAILY', 'WEEKLY', 'MONTHLY', 'ONCE'],
                                  (v) { if (_isMounted && v != null) setState(() => _checkupFrequency = v); }
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _styledButton(
                    _editingScheduleId == null ? 'Schedule Checkup' : 'Update Schedule',
                    _submitSchedule,
                    icon: _editingScheduleId == null ? Icons.add_task_rounded : Icons.edit_calendar_rounded,
                    isLoading: _isSubmittingSchedule,
                  ),
                  if (_editingScheduleId != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                          onPressed: _isSubmittingSchedule ? null : _resetScheduleForm,
                          child: Text("Cancel Edit", style: TextStyle(color: Colors.grey[700]))
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
          _buildSectionHeader("Upcoming Schedules", theme, icon: Icons.list_alt_rounded),
          _loadingSchedules
              ? _loadingWidget(message: "Fetching schedules...")
              : _schedules.isEmpty
              ? _emptyStateWidget("No checkups scheduled yet. Add one above!", icon: Icons.event_busy_outlined)
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _schedules.length,
            itemBuilder: (ctx, i) {
              final s = _schedules[i];
              DateTime? scheduleDate;
              String scheduleDateTimeString = s['scheduledDateTime'] as String? ?? '';
              try { scheduleDate = DateTime.parse(scheduleDateTimeString).toLocal(); } catch(e) { /* Parsing error */ }
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.medical_services_outlined, color: theme.primaryColor, size: 24)
                  ),
                  title: Text(s['vitalName'] as String? ?? 'Unknown Vital', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(
                      (scheduleDate != null ? DateFormat('E, dd MMM yyyy \'at\' hh:mm a').format(scheduleDate) : scheduleDateTimeString) +
                          '\nFrequency: ${s['frequency'] as String? ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 13)
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit_outlined, color: Colors.orange.shade700, size: 22),tooltip: "Edit", onPressed: () => _editSchedule(s)),
                      IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade500, size: 22), tooltip: "Delete", onPressed: () => _deleteSchedule(s['id'] as String)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLabLocatorTab() {
    // Explicitly prepare the list of items for the district dropdown
    List<String?> districtDropdownItems;
    if (_districtsForSelectedState.isEmpty) {
      districtDropdownItems = <String?>[]; // An empty list of String?
    } else {
      // Create a new list that can hold String? (null for "All Districts" and actual district names)
      districtDropdownItems = [null, ..._districtsForSelectedState];
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _styledDropdown<String>(
                      'Select State',
                      _selectedStateForLabSearch,
                      _statesAndDistricts.keys.toList(),
                          (String? newValue) {
                        if (newValue != null && _isMounted) {
                          setState(() {
                            _selectedStateForLabSearch = newValue;
                            _updateDistrictsForSelectedState();
                            _labs.clear();
                            _labMarkers.clear();
                            _selectedLabForBooking = null;
                          });
                          _fetchLabs();
                        }
                      }
                  ),
                  const SizedBox(height: 10),
                  _styledDropdown<String?>( // Generic type is String?
                    'Select District',
                    _selectedDistrictForLabSearch, // value is String?
                    districtDropdownItems,         // items is now explicitly List<String?>
                        (String? newValue) {       // newValue is String?
                      if (_isMounted) {
                        setState(() {
                          _selectedDistrictForLabSearch = newValue;
                          _labs.clear();
                          _labMarkers.clear();
                          _selectedLabForBooking = null;
                        });
                        _fetchLabs();
                      }
                    },
                    hintText: "All Districts / Select District",
                    displayText: (item) => item ?? "All Districts", // item is String?
                  ),
                ],
              ),
            ),
          ),
        ),
        // ... rest of the _buildLabLocatorTab method remains the same
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              GoogleMap(
                onMapCreated: _onLabMapCreated,
                initialCameraPosition: CameraPosition(target: _currentLabMapCenter, zoom: 5.0),
                markers: _labMarkers,
                myLocationButtonEnabled: _locationPermissionGranted,
                myLocationEnabled: _locationPermissionGranted,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                padding: EdgeInsets.only(bottom: _labs.isNotEmpty && !_loadingLabs ? 100 : 0),
              ),
              if (_loadingLabs && _labs.isEmpty)
                Container(color: Colors.black.withOpacity(0.05), child: _loadingWidget(message: "Finding labs...")),
              if (!_loadingLabs && _labs.isEmpty && _selectedStateForLabSearch.isNotEmpty)
                Positioned(
                  top: 20,
                  left: 20, right: 20,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal:16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _emptyStateWidget(
                        _selectedStateForLabSearch.isEmpty
                            ? "Please select a state to find labs."
                            : "No labs found for the current selection.\nTry a different district or state.",
                        icon: Icons.location_searching_rounded,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_labs.isNotEmpty && !_loadingLabs)
          Container(
            height: 110,
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _labs.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final lab = _labs[index];
                final labName = lab['name'] as String? ?? 'Unknown Lab';
                final isSelected = _selectedLabForBooking == labName;
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Card(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5) : BorderSide.none,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: InkWell(
                      onTap: (){
                        if(mounted) {
                          setState(() => _selectedLabForBooking = labName);
                          _showSnackBar("Selected: $labName. Book in 'Test Services' tab.");
                        }
                        final lat = lab['lat']; final lon = lab['lon'];
                        if (lat != null && lon != null && _labMapController != null) {
                          final pLat = (lat is String) ? double.tryParse(lat) : (lat as num?)?.toDouble();
                          final pLon = (lon is String) ? double.tryParse(lon) : (lon as num?)?.toDouble();
                          if(pLat != null && pLon != null) {
                            _labMapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pLat, pLon), 14.0));
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(labName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            const SizedBox(height: 4),
                            Text(lab['address'] as String? ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis,),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLabTestServicesTab() {
    final theme = Theme.of(context);
    // Create a unique list of lab names for the dropdown
    final uniqueLabNames = _labs
        .map<String?>((lab) => lab['name'] as String?)
        .where((name) => name != null && name != 'Unknown Lab')
        .toSet()
        .toList();
    if (_labs.any((lab) => lab['name'] == 'Unknown Lab') && uniqueLabNames.isEmpty && _labs.length == 1) {
      uniqueLabNames.add('Unknown Lab'); // Add if it's the only one
    }


    return RefreshIndicator(
      onRefresh: () async {
        if (_labs.isEmpty && !_loadingLabs && _selectedStateForLabSearch.isNotEmpty) await _fetchLabs();
        await _fetchLabBookings();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Book a Lab Test", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColorDark, fontSize: 20)),
                  const SizedBox(height: 20),
                  _styledDropdown<String?>(
                    'Select Lab/Provider',
                    _selectedLabForBooking, // This should be a String?
                    uniqueLabNames, // This is List<String?>
                        (String? value) {
                      if (_isMounted) setState(() => _selectedLabForBooking = value);
                    },
                    hintText: uniqueLabNames.isEmpty ? "Find labs in 'Lab Map' tab first" : "Select a lab",
                    displayText: (item) => item ?? "N/A", // Handle null for display
                  ),
                  const SizedBox(height: 16),
                  _styledTextField(_testNameController, 'Test Name', hint: 'e.g., Complete Blood Count', pIcon: Icons.colorize_outlined),
                  const SizedBox(height: 24),
                  _styledButton("Book Test", _bookLabTest, icon: Icons.add_task_rounded, isLoading: _isBookingLabTest),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16), // Reduced space
          _buildSectionHeader("My Recent Lab Bookings", theme, icon: Icons.history_edu_outlined),
          _loadingLabBookings
              ? _loadingWidget(message: "Loading bookings...")
              : _labBookings.isEmpty
              ? _emptyStateWidget("You haven't booked any lab tests yet.", icon: Icons.bookmark_border_rounded)
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _labBookings.length,
            itemBuilder: (context, index) {
              final booking = _labBookings[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.biotech_rounded, color: Colors.green.shade700, size: 26),
                  title: Text(booking['selectedTest'] as String? ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: Text("Lab: ${booking['providerName'] as String? ?? 'N/A'} \nPrice: ₹${(booking['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  isThreeLine: true,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double tabIconSize = 18.0;
    // Dynamic text sizing for TabBar labels can be tricky.
    // Using a fixed smaller font size is often more reliable.
    // Let's try a fixed size that generally looks good.
    final double screenWidth = MediaQuery.of(context).size.width;
    double tabLabelFontSize = 11.5; // Default
    if (screenWidth > 400) tabLabelFontSize = 12.5; // Slightly larger for wider screens
    if (screenWidth < 350) tabLabelFontSize = 10.5; // Slightly smaller for narrower screens


    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Appointments & Labs'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.75),
          labelStyle: TextStyle(fontSize: tabLabelFontSize, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: tabLabelFontSize - 0.5), // Slightly smaller for unselected
          labelPadding: const EdgeInsets.symmetric(horizontal: 2.0), // Minimal padding
          isScrollable: false, // Keep false if 3 tabs fit
          tabs: [
            _buildTab('Checkups', Icons.event_available_outlined, tabIconSize, screenWidth),
            _buildTab('Lab Map', Icons.map_outlined, tabIconSize, screenWidth),
            _buildTab('Test Services', Icons.science_rounded, tabIconSize, screenWidth),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swipe gestures if causing issues
        children: [
          _buildMyCheckupsTab(),
          _buildLabLocatorTab(),
          _buildLabTestServicesTab(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2),
    );
  }

  // Helper to build Tab to ensure consistent styling and allow for more complex layouts if needed
  Widget _buildTab(String text, IconData icon, double iconSize, double screenWidth) {
    // Determine if text should be shown based on screen width, or always show.
    // For 3 tabs, text can usually always be shown.
    bool showText = true; // screenWidth > 360; // Example condition

    double labelFontSize = 11.5;
    if (screenWidth > 400) labelFontSize = 12.5;
    if (screenWidth < 350) labelFontSize = 10.5;


    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          Icon(icon, size: iconSize),
          if (showText) const SizedBox(width: 4), // Space between icon and text
          if (showText)
            Flexible( // Use Flexible to allow text to shrink or wrap if necessary
              child: Text(
                text,
                overflow: TextOverflow.ellipsis, // Use ellipsis if text is too long
                softWrap: false, // Try to keep on one line
                style: TextStyle(fontSize: labelFontSize), // Use the dynamically calculated font size
              ),
            ),
        ],
      ),
    );
  }
}