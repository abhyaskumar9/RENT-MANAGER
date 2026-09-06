import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RentManagerApp());
}

class RentManagerApp extends StatelessWidget {
  const RentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentManager Pro Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF01579B),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: 'Roboto',
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> renters = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> complaints = [];
  Map<String, dynamic> ownerProfile = {};
  String listFilter = 'all';

  // Form Controllers
  String personType = 'Student'; 
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final parentMobileCtrl = TextEditingController();
  final fatherCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final roomOrRollCtrl = TextEditingController(); 
  final idNumCtrl = TextEditingController();
  final rentCtrl = TextEditingController();
  final advanceCtrl = TextEditingController(text: '0'); 
  final initialReadingCtrl = TextEditingController(text: '0');
  
  DateTime rentEntryDate = DateTime.now();
  
  // Owner Profile Controllers
  final ownerNameCtrl = TextEditingController();
  final ownerEmailCtrl = TextEditingController();
  final ownerPhoneCtrl = TextEditingController();
  final ownerUpiIdCtrl = TextEditingController();
  final ownerUpiNumCtrl = TextEditingController();
  final defaultUnitRateCtrl = TextEditingController(text: '8');
  final propertyNameCtrl = TextEditingController(text: 'My Hostel / Institute');
  final studentWelcomeRulesCtrl = TextEditingController();
  final renterWelcomeRulesCtrl = TextEditingController();
  String? ownerPhotoBase64;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final rentersData = prefs.getString('renters_db');
    final expensesData = prefs.getString('expenses_db');
    final complaintsData = prefs.getString('complaints_db');
    final profileData = prefs.getString('owner_profile');

    if (rentersData != null) {
      setState(() => renters = List<Map<String, dynamic>>.from(json.decode(rentersData)));
    }
    if (expensesData != null) {
      setState(() => expenses = List<Map<String, dynamic>>.from(json.decode(expensesData)));
    }
    if (complaintsData != null) {
      setState(() => complaints = List<Map<String, dynamic>>.from(json.decode(complaintsData)));
    }

    if (profileData != null) {
      ownerProfile = json.decode(profileData);
      ownerNameCtrl.text = ownerProfile['name'] ?? '';
      ownerEmailCtrl.text = ownerProfile['email'] ?? '';
      ownerPhoneCtrl.text = ownerProfile['phone'] ?? '';
      ownerUpiIdCtrl.text = ownerProfile['upiId'] ?? '';
      ownerUpiNumCtrl.text = ownerProfile['upiNum'] ?? '';
      defaultUnitRateCtrl.text = ownerProfile['unitRate'] ?? '8';
      propertyNameCtrl.text = ownerProfile['propertyName'] ?? 'My Hostel / Institute';
    }
  }

  Future<void> _saveRentersToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('renters_db', json.encode(renters));
  }

  Future<void> _saveOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    ownerProfile = {
      'name': ownerNameCtrl.text,
      'email': ownerEmailCtrl.text,
      'phone': ownerPhoneCtrl.text,
      'upiId': ownerUpiIdCtrl.text,
      'upiNum': ownerUpiNumCtrl.text,
      'unitRate': defaultUnitRateCtrl.text,
      'propertyName': propertyNameCtrl.text,
    };
    await prefs.setString('owner_profile', json.encode(ownerProfile));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved!")));
    }
  }

  void _sendWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    if (clean.length == 10) clean = '91$clean';
    final Uri appIntent = Uri.parse("whatsapp://send?phone=$clean&text=${Uri.encodeComponent(text)}");
    try {
      await launchUrl(appIntent, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  double _getAccurateUnpaidDue(Map<String, dynamic> item) {
    List history = item['history'] ?? [];
    if (history.isEmpty) return 0.0;
    double totalDue = 0.0;
    for (var h in history) {
      double totalPayable = (h['totalPayable'] as num?)?.toDouble() ?? 0.0;
      double backDue = (h['backDue'] as num?)?.toDouble() ?? 0.0;
      double paidAmount = (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
      totalDue += (totalPayable - backDue);
      totalDue -= paidAmount;
    }
    return totalDue > 0 ? double.parse(totalDue.toStringAsFixed(1)) : 0.0;
  }

  // --- RESTORED MISSING METHODS ---

  void _exportJsonBackup() async {
    Map<String, dynamic> fullData = {
      'renters': renters,
      'expenses': expenses,
      'complaints': complaints,
      'profile': ownerProfile,
    };
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/rent_manager_backup.json");
    await file.writeAsString(json.encode(fullData));
    await Share.shareXFiles([XFile(file.path)], text: 'Rent Manager Complete Data Backup (.JSON)');
  }

  void _importJsonBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      try {
        Map<String, dynamic> data = json.decode(content);
        setState(() {
          if (data['renters'] != null) renters = List<Map<String, dynamic>>.from(data['renters']);
          if (data['expenses'] != null) expenses = List<Map<String, dynamic>>.from(data['expenses']);
          if (data['complaints'] != null) complaints = List<Map<String, dynamic>>.from(data['complaints']);
          if (data['profile'] != null) ownerProfile = Map<String, dynamic>.from(data['profile']);
        });
        await _saveRentersToStorage();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Restored Successfully!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Backup File!")));
      }
    }
  }

  Widget _buildDashboardView() {
    double totalCollected = 0.0;
    double totalPendingDue = 0.0;
    int activeResidents = 0;

    for (var r in renters) {
      if (r['isClosed'] != true) {
        activeResidents++;
        totalPendingDue += _getAccurateUnpaidDue(r);
        if (r['history'] != null) {
          for (var h in r['history']) {
            totalCollected += (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard("💰 Total Collected", "₹${totalCollected.toStringAsFixed(0)}", Colors.green.shade800, Colors.green.shade50)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard("⚠️ Market Due", "₹${totalPendingDue.toStringAsFixed(0)}", Colors.red.shade800, Colors.red.shade50)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard("👥 Total Members", "$activeResidents Active", Colors.blue.shade900, Colors.blue.shade50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredListView() {
    return ListView.builder(
      itemCount: renters.length,
      itemBuilder: (ctx, i) {
        final r = renters[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(r['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Mobile: ${r['mobile']} | Rent: ₹${r['rent']}"),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(10), border: Border.all(color: textCol.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildAddMemberView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Add New Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Rent/Fee (₹) *", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01579B)),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              setState(() {
                renters.add({
                  'name': nameCtrl.text.trim(),
                  'mobile': mobileCtrl.text.trim(),
                  'rent': double.tryParse(rentCtrl.text) ?? 0.0,
                  'history': []
                });
              });
              _saveRentersToStorage();
              nameCtrl.clear();
              mobileCtrl.clear();
              rentCtrl.clear();
              _tabController.animateTo(2);
            },
            child: const Text("Save Member", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("⚙️ Owner & Property Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: propertyNameCtrl, decoration: const InputDecoration(labelText: "Property Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: "Owner Name", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01579B)),
            onPressed: _saveOwnerProfile,
            child: const Text("Save Settings", style: TextStyle(color: Colors.white)),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportJsonBackup,
                  icon: const Icon(Icons.download),
                  label: const Text("Export Backup"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importJsonBackup,
                  icon: const Icon(Icons.upload),
                  label: const Text("Restore Backup"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : "RentManager Pro"),
        backgroundColor: const Color(0xFF01579B),
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardView(),
          _buildAddMemberView(),
          _buildRegisteredListView(),
          _buildSettingsView(),
        ],
      ),
      bottomNavigationBar: Material(
        color: const Color(0xFF01579B),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
            Tab(icon: Icon(Icons.person_add), text: "Add New"),
            Tab(icon: Icon(Icons.people), text: "Records"),
            Tab(icon: Icon(Icons.settings), text: "Settings"),
          ],
        ),
      ),
    );
  }
}
