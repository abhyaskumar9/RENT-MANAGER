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
      title: 'Tenant & Student Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0288D1),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0288D1),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> renters = [];
  Map<String, dynamic> ownerProfile = {};
  String listFilter = 'all';

  // Form Controllers
  String personType = 'Student';
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final parentMobileCtrl = TextEditingController();
  final fatherCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final idNumCtrl = TextEditingController();
  final rentCtrl = TextEditingController();
  final advanceCtrl = TextEditingController(text: '0');
  final initialReadingCtrl = TextEditingController(text: '0');
  DateTime selectedDate = DateTime.now();
  String? studentImgBase64;
  String? idCardImgBase64;
  String sendToTarget = 'student';

  // Profile Controllers
  final ownerNameCtrl = TextEditingController();
  final ownerEmailCtrl = TextEditingController();
  final ownerPhoneCtrl = TextEditingController();
  final ownerUpiIdCtrl = TextEditingController();
  final ownerUpiNumCtrl = TextEditingController();
  final studentRulesCtrl = TextEditingController();
  final renterRulesCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rentersData = prefs.getString('renters_db');
    final profileData = prefs.getString('owner_profile');

    if (rentersData != null) {
      setState(() {
        renters = List<Map<String, dynamic>>.from(json.decode(rentersData));
      });
    }
    if (profileData != null) {
      ownerProfile = json.decode(profileData);
      ownerNameCtrl.text = ownerProfile['name'] ?? '';
      ownerEmailCtrl.text = ownerProfile['email'] ?? '';
      ownerPhoneCtrl.text = ownerProfile['phone'] ?? '';
      ownerUpiIdCtrl.text = ownerProfile['upiId'] ?? '';
      ownerUpiNumCtrl.text = ownerProfile['upiNum'] ?? '';
      studentRulesCtrl.text = ownerProfile['studentRules'] ?? "Student Rules:\n1. Monthly Fee due every 30 days.\n2. Keep premises clean.";
      renterRulesCtrl.text = ownerProfile['renterRules'] ?? "Renter Rules:\n1. Rent due every month.\n2. Electricity reading taken on 1st.";
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('renters_db', json.encode(renters));
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    ownerProfile = {
      'name': ownerNameCtrl.text,
      'email': ownerEmailCtrl.text,
      'phone': ownerPhoneCtrl.text,
      'upiId': ownerUpiIdCtrl.text,
      'upiNum': ownerUpiNumCtrl.text,
      'studentRules': studentRulesCtrl.text,
      'renterRules': renterRulesCtrl.text,
    };
    await prefs.setString('owner_profile', json.encode(ownerProfile));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Settings Saved!")));
    }
  }

  Future<void> _pickImage(bool isStudent) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isStudent) {
          studentImgBase64 = base64Encode(bytes);
        } else {
          idCardImgBase64 = base64Encode(bytes);
        }
      });
    }
  }

  void _saveRenter() async {
    if (nameCtrl.text.isEmpty || mobileCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Name aur Mobile number dalein!")));
      return;
    }

    DateTime dueDate = selectedDate.add(const Duration(days: 30));
    String entryDateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String nextDueDateStr = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> newRenter = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'pType': personType,
      'name': nameCtrl.text,
      'mobile': mobileCtrl.text,
      'parentMobile': parentMobileCtrl.text,
      'father': fatherCtrl.text,
      'address': addressCtrl.text,
      'idNum': idNumCtrl.text,
      'idCardImg': idCardImgBase64 ?? '',
      'studentImg': studentImgBase64 ?? '',
      'entryDate': entryDateStr,
      'nextDueDate': nextDueDateStr,
      'rent': double.tryParse(rentCtrl.text) ?? 0.0,
      'advance': double.tryParse(advanceCtrl.text) ?? 0.0,
      'prevReading': double.tryParse(initialReadingCtrl.text) ?? 0.0,
      'history': []
    };

    setState(() {
      renters.add(newRenter);
    });
    await _saveData();

    String customRules = personType == 'Student' ? (ownerProfile['studentRules'] ?? '') : (ownerProfile['renterRules'] ?? '');
    String msg = "Namaste ${nameCtrl.text} ji,\n\n$customRules\n\nJoining Date: $entryDateStr\nNext Due Date: $nextDueDateStr\n\nOwner: ${ownerProfile['name'] ?? ''}\nContact: ${ownerProfile['phone'] ?? ''}";
    
    String sendPhone = (sendToTarget == 'parents' && parentMobileCtrl.text.isNotEmpty) ? parentMobileCtrl.text : mobileCtrl.text;
    _sendWhatsApp(sendPhone, msg);

    nameCtrl.clear();
    mobileCtrl.clear();
    parentMobileCtrl.clear();
    fatherCtrl.clear();
    addressCtrl.clear();
    idNumCtrl.clear();
    rentCtrl.clear();
    setState(() {
      studentImgBase64 = null;
      idCardImgBase64 = null;
    });

    _tabController.animateTo(1);
  }

  void _sendWhatsApp(String phone, String text) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _generateBill(Map<String, dynamic> renter, String target) {
    bool isStudent = renter['pType'] == 'Student';
    double rent = (renter['rent'] as num).toDouble();
    double advance = (renter['advance'] as num).toDouble();
    double totalPayable = rent - advance;

    String dateStr = DateTime.now().toString().split(' ')[0];
    String phone = (target == 'parents' && renter['parentMobile'].toString().isNotEmpty)
        ? renter['parentMobile']
        : renter['mobile'];

    if (isStudent) {
      String msg = "*MONTHLY STUDENT FEE NOTICE*\n--------------------\nStudent: ${renter['name']}\nParent: ${renter['father']}\nDue Date: ${renter['nextDueDate']}\n\nFee: ₹$rent\nAdvance: -₹$advance\n*Total Payable: ₹$totalPayable*\n\nUPI: ${ownerProfile['upiId'] ?? ''} (${ownerProfile['upiNum'] ?? ''})";
      
      setState(() {
        renter['history'].add({
          'date': dateStr,
          'startUnits': '-',
          'endUnits': '-',
          'unitsUsed': 0,
          'elecBill': 0.0,
          'rentAmount': rent,
          'totalPayable': totalPayable,
          'status': 'Pending'
        });
      });
      _saveData();
      _sendWhatsApp(phone, msg);
    } else {
      _showRenterBillDialog(renter, phone);
    }
  }

  void _showRenterBillDialog(Map<String, dynamic> renter, String phone) {
    final readingCtrl = TextEditingController(text: renter['prevReading'].toString());
    final rateCtrl = TextEditingController(text: '8');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Meter Reading for ${renter['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: readingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Current Meter Reading")),
            TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Unit Rate (₹)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              double endUnits = double.tryParse(readingCtrl.text) ?? 0.0;
              double rate = double.tryParse(rateCtrl.text) ?? 8.0;
              double startUnits = (renter['prevReading'] as num).toDouble();
              double unitsUsed = endUnits > startUnits ? (endUnits - startUnits) : 0.0;
              double elecBill = unitsUsed * rate;
              double rent = (renter['rent'] as num).toDouble();
              double advance = (renter['advance'] as num).toDouble();
              double total = elecBill + rent - advance;

              String msg = "*MONTHLY RENT & ELECTRICITY BILL*\n--------------------\nName: ${renter['name']}\nUnits: $startUnits to $endUnits ($unitsUsed units)\nElec Bill: ₹$elecBill\nRoom Rent: ₹$rent\n*Total Payable: ₹$total*\n\nUPI: ${ownerProfile['upiId'] ?? ''}";

              setState(() {
                renter['prevReading'] = endUnits;
                renter['history'].add({
                  'date': DateTime.now().toString().split(' ')[0],
                  'startUnits': startUnits.toString(),
                  'endUnits': endUnits.toString(),
                  'unitsUsed': unitsUsed,
                  'elecBill': elecBill,
                  'rentAmount': rent,
                  'totalPayable': total,
                  'status': 'Pending'
                });
              });
              _saveData();
              _sendWhatsApp(phone, msg);
            },
            child: const Text("Send Bill"),
          ),
        ],
      ),
    );
  }

  void _exportBackup() async {
    Map<String, dynamic> fullData = {
      'renters': renters,
      'profile': ownerProfile,
    };
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/rent_manager_backup.json");
    await file.writeAsString(json.encode(fullData));
    await Share.shareXFiles([XFile(file.path)], text: 'Rent Manager Data Backup');
  }

  void _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      try {
        Map<String, dynamic> data = json.decode(content);
        setState(() {
          if (data['renters'] != null) renters = List<Map<String, dynamic>>.from(data['renters']);
          if (data['profile'] != null) ownerProfile = Map<String, dynamic>.from(data['profile']);
        });
        await _saveData();
        await _saveProfile();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Restored Successfully!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Backup File!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent & Student Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showProfileSettings),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.person_add), text: "New Entry"),
            Tab(icon: const Icon(Icons.list), text: "Registered"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: personType,
                decoration: const InputDecoration(labelText: "Select Category"),
                items: const [
                  DropdownMenuItem(value: "Student", child: Text("🎓 Student")),
                  DropdownMenuItem(value: "Renter", child: Text("🏠 Renter / Family")),
                ],
                onChanged: (v) => setState(() => personType = v!),
              ),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: personType == "Student" ? "Student Full Name *" : "Renter Full Name *")),
              TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "WhatsApp / Mobile Number *")),
              if (personType == "Student") ...[
                TextField(controller: parentMobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents WhatsApp Number")),
                TextField(controller: fatherCtrl, decoration: const InputDecoration(labelText: "Father / Parent Name")),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Permanent Address")),
              ],
              TextField(controller: idNumCtrl, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: "Identity / Document Number")),
              if (personType == "Renter")
                TextField(controller: initialReadingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Meter Reading (Units)")),
              TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: personType == "Student" ? "Monthly Student Fee (₹) *" : "Monthly Room Rent (₹) *")),
              TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Advance Paid (₹)")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text("Photo"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.credit_card),
                      label: const Text("ID Proof"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), padding: const EdgeInsets.all(14)),
                onPressed: _saveRenter,
                child: const Text("💾 Save & Send Welcome Rules", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTab() {
    List<Map<String, dynamic>> filtered = renters;
    if (listFilter != 'all') {
      filtered = renters.where((r) => r['pType'] == listFilter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(label: const Text("All"), selected: listFilter == 'all', onSelected: (_) => setState(() => listFilter = 'all')),
              const SizedBox(width: 8),
              FilterChip(label: const Text("🎓 Students"), selected: listFilter == 'Student', onSelected: (_) => setState(() => listFilter = 'Student')),
              const SizedBox(width: 8),
              FilterChip(label: const Text("🏠 Renters"), selected: listFilter == 'Renter', onSelected: (_) => setState(() => listFilter = 'Renter')),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No records found."))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered[i];
                    bool isStudent = r['pType'] == 'Student';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() => renters.removeWhere((item) => item['id'] == r['id']));
                                    _saveData();
                                  },
                                ),
                              ],
                            ),
                            Text("Phone: ${r['mobile']} ${r['parentMobile'] != '' ? ' | Parent: ' + r['parentMobile'] : ''}"),
                            Text("Fee/Rent: ₹${r['rent']} | Due Date: ${r['nextDueDate']}"),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _generateBill(r, 'student'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: Text("⚡ Bill (${isStudent ? 'Student' : 'Renter'})", style: const TextStyle(color: Colors.white)),
                                ),
                                if (r['parentMobile'] != null && r['parentMobile'].toString().isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () => _generateBill(r, 'parents'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("📱 Bill (Parents)", style: const TextStyle(color: Colors.white)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showProfileSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Owner Settings & Backup Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: "Owner Name")),
              TextField(controller: ownerPhoneCtrl, decoration: const InputDecoration(labelText: "Owner WhatsApp Phone")),
              TextField(controller: ownerUpiIdCtrl, decoration: const InputDecoration(labelText: "UPI ID (for payments)")),
              TextField(controller: studentRulesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Student Rules & Notice")),
              TextField(controller: renterRulesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Renter Rules & Notice")),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _saveProfile, child: const Text("Save Settings")),
              const Divider(),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _exportBackup, icon: const Icon(Icons.download), label: const Text("Export Backup"))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(onPressed: _importBackup, icon: const Icon(Icons.upload), label: const Text("Restore Backup"))),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
