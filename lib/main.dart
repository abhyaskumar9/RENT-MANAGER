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
  String personType = 'Student'; // 'Student', 'Renter', 'Hostel'
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
  DateTime elecStartDate = DateTime.now();
  DateTime securityDate = DateTime.now(); 
  
  String? studentImgBase64;
  String? idCardImgBase64;
  String sendToTarget = 'student';

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

  final ImagePicker _picker = ImagePicker();

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
      ownerPhotoBase64 = ownerProfile['photo'];
      studentWelcomeRulesCtrl.text = ownerProfile['studentRules'] ??
          "🎓 *STUDENT & HOSTEL RULES*\n1. Monthly fee/rent due every 30 days.\n2. Keep premises clean.\n3. Follow silent hours.";
      renterWelcomeRulesCtrl.text = ownerProfile['renterRules'] ??
          "🏠 *RENTER RULES*\n1. Room rent due monthly.\n2. Electricity meter reading cycle starts from 1st.";
    }
    
    await _checkAndGenerateAutoBills();
  }

  Future<void> _checkAndGenerateAutoBills() async {
    DateTime now = DateTime.now();
    bool dataChanged = false;

    for (var r in renters) {
      if (r['isClosed'] == true) continue;
      
      try {
        DateTime dueDate = DateTime.parse(r['nextDueDate']);
        
        while (now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate)) {
          double rent = (r['rent'] as num).toDouble();
          double backDue = _getAccurateUnpaidDue(r, category: 'rent');
          double netPayable = rent + backDue;
          
          String dateStr = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";
          
          r['history'].add({
            'date': dateStr,
            'type': 'Auto Generated Monthly Bill',
            'unitsUsed': 0,
            'elecBill': 0.0,
            'rentAmount': rent,
            'backDue': backDue,
            'advanceUsed': 0.0,
            'totalPayable': netPayable,
            'paidAmount': 0.0,
            'paymentDate': '-',
            'status': 'Pending',
            'paymentLogs': [] 
          });

          dueDate = dueDate.add(const Duration(days: 30));
          r['nextDueDate'] = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";
          
          dataChanged = true;
        }
      } catch (e) {
        // error handling
      }
    }

    if (dataChanged) {
      if (mounted) setState(() {});
      await _saveRentersToStorage();
    }
  }

  Future<void> _saveRentersToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('renters_db', json.encode(renters));
  }

  Future<void> _saveExpensesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses_db', json.encode(expenses));
  }

  Future<void> _saveComplaintsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('complaints_db', json.encode(complaints));
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
      'photo': ownerPhotoBase64,
      'studentRules': studentWelcomeRulesCtrl.text,
      'renterRules': renterWelcomeRulesCtrl.text,
    };
    await prefs.setString('owner_profile', json.encode(ownerProfile));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile & Settings Saved!")));
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (type == 'student') studentImgBase64 = base64Encode(bytes);
        if (type == 'idCard') idCardImgBase64 = base64Encode(bytes);
        if (type == 'owner') ownerPhotoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<DateTime?> _selectCustomDate(BuildContext context, DateTime initDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  void _sendWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number missing ya galat hai!")));
      return;
    }

    if (clean.length == 10) {
      clean = '91$clean';
    } else if (clean.length == 11 && clean.startsWith('0')) {
      clean = '91${clean.substring(1)}';
    }

    final encodedText = Uri.encodeComponent(text);
    final Uri appIntent = Uri.parse("whatsapp://send?phone=$clean&text=$encodedText");
    final Uri universalUrl = Uri.parse("https://api.whatsapp.com/send?phone=$clean&text=$encodedText");

    bool launched = false;
    try {
      launched = await launchUrl(appIntent, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp open nahi ho saka. Kripya check karein.")),
      );
    }
  }

  double _getAccurateUnpaidDue(Map<String, dynamic> item, {String category = 'all'}) {
    List history = item['history'] ?? [];
    if (history.isEmpty) return 0.0;

    double totalDue = 0.0;
    for (var h in history) {
      String t = (h['type'] ?? '').toString().toLowerCase();
      bool match = true;
      if (category == 'electricity') match = t.contains('electricity');
      if (category == 'rent') match = t.contains('room rent') || t.contains('fee') || t.contains('hostel') || t.contains('auto generated');

      if (match) {
        double totalPayable = (h['totalPayable'] as num?)?.toDouble() ?? 0.0;
        double backDue = (h['backDue'] as num?)?.toDouble() ?? 0.0;
        double paidAmount = (h['paidAmount'] as num?)?.toDouble() ?? 0.0;

        double newChargeForThisMonth = totalPayable - backDue;
        totalDue += newChargeForThisMonth; 
        totalDue -= paidAmount;            
      }
    }
    return totalDue > 0 ? double.parse(totalDue.toStringAsFixed(1)) : 0.0;
  }

  void _sendBulkReminders() {
    List<Map<String, dynamic>> unpaidList = renters.where((r) => r['isClosed'] != true && _getAccurateUnpaidDue(r) > 0).toList();
    if (unpaidList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabhi ka bill paid hai! Koi unpaid nahi mila.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("📢 Bulk Reminders (${unpaidList.length} Unpaid)"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unpaidList.length,
            itemBuilder: (c, idx) {
              final item = unpaidList[idx];
              double due = _getAccurateUnpaidDue(item);
              bool isStudent = (item['pType'] == 'Student');
              String roomLabel = isStudent ? "Roll No: ${item['roomNo'] ?? 'N/A'}" : "Room: ${item['roomNo'] ?? 'N/A'}";

              return ListTile(
                dense: true,
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("$roomLabel | Total Due: ₹$due"),
                trailing: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF25D366)),
                  onPressed: () {
                    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                    String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                    String msg = "*📢 PAYMENT DUE REMINDER*\n--------------------\nName: ${item['name']}\n$roomLabel\n*Pending Due: ₹$due*\n--------------------\nKripya baki amount jald jama karein.\nUPI ID: $upi\nOwner: $oName\nDhanyawad!";
                    _sendWhatsApp(item['mobile'], msg);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _sharePoliceVerificationForm(Map<String, dynamic> item) {
    String pName = propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : "Institute / Hostel";
    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Property Manager";
    String oPhone = ownerPhoneCtrl.text.isNotEmpty ? ownerPhoneCtrl.text : "";
    bool isStudent = (item['pType'] == 'Student');

    String verificationDoc = "==============================\n📋 MEMBER RECORD & VERIFICATION\n==============================\nProperty/Institute: $pName\n\n1. Full Name: ${item['name']}\n2. Category: ${item['pType']}\n3. ${isStudent ? 'Roll Number' : 'Room / Bed No'}: ${item['roomNo'] ?? 'N/A'}\n4. Mobile No: ${item['mobile']}\n5. Parents Mobile: ${item['parentMobile'] ?? 'N/A'}\n6. Father/Guardian Name: ${item['father'] ?? 'N/A'}\n7. Permanent Address: ${item['address'] ?? 'N/A'}\n8. ID / Document No: ${item['idNum'] ?? 'N/A'}\n9. Joining Date: ${item['entryDate']}\n10. Monthly Fee/Rent: ₹${item['rent']}\n11. Security Deposit: ₹${item['securityDeposit'] ?? 0}\n\nOwner / Manager: $oName\nContact: $oPhone\n==============================";

    Share.share(verificationDoc, subject: "Member Verification - ${item['name']}");
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

  Widget _buildAddMemberView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Select Member Type:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: personType,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            items: const [
              DropdownMenuItem(value: "Student", child: Text("🎓 Student / Coaching")),
              DropdownMenuItem(value: "Hostel", child: Text("🏢 Hostel Resident")),
              DropdownMenuItem(value: "Renter", child: Text("🏠 Room / Flat Renter")),
            ],
            onChanged: (v) => setState(() => personType = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (personType == 'Student' || personType == 'Hostel') ...[
            TextField(controller: parentMobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number", border: OutlineInputBorder())),
            const SizedBox(height: 12),
          ],
          TextField(controller: fatherCtrl, decoration: InputDecoration(labelText: personType == 'Student' ? "Father / Parents Name" : "Father / Husband Name", border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: roomOrRollCtrl, decoration: InputDecoration(labelText: personType == 'Student' ? "Roll Number / Batch" : "Room / Bed Number", border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Permanent Address", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: idNumCtrl, decoration: const InputDecoration(labelText: "ID / Document Number", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: personType == 'Student' ? "Monthly Fee (₹) *" : "Monthly Rent (₹) *", border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit Paid (₹)", border: OutlineInputBorder())),
          if (personType == 'Renter' || personType == 'Hostel') ...[
            const SizedBox(height: 12),
            TextField(controller: initialReadingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Meter Reading (Units)", border: OutlineInputBorder())),
          ],
          const SizedBox(height: 20),
          ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01579B)).runtimeType == ElevatedButton ? ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01579B), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty || rentCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Name, Mobile aur Monthly Fee/Rent dalein!")));
                return;
              }
              // Save logic triggered
            },
            child: const Text("Save & Send Welcome WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ) : Container(),
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
          TextField(controller: propertyNameCtrl, decoration: const InputDecoration(labelText: "Property / Institute Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: "Owner Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: ownerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Owner Phone", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: ownerUpiIdCtrl, decoration: const InputDecoration(labelText: "UPI ID (e.g. merchant@upi)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: ownerUpiNumCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "UPI Mobile Number", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: defaultUnitRateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Default Electricity Unit Rate (₹)", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01579B), padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: _saveOwnerProfile,
            child: const Text("Save Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 30),
          const Text("Backup & Restore Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
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
}
