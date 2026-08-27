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
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0288D1),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
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

  // Owner Profile Controllers
  final ownerNameCtrl = TextEditingController();
  final ownerEmailCtrl = TextEditingController();
  final ownerPhoneCtrl = TextEditingController();
  final ownerUpiIdCtrl = TextEditingController();
  final ownerUpiNumCtrl = TextEditingController();
  final defaultUnitRateCtrl = TextEditingController(text: '8');
  final studentWelcomeRulesCtrl = TextEditingController();
  final renterWelcomeRulesCtrl = TextEditingController();
  String? ownerPhotoBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
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
      defaultUnitRateCtrl.text = ownerProfile['unitRate'] ?? '8';
      ownerPhotoBase64 = ownerProfile['photo'];
      studentWelcomeRulesCtrl.text = ownerProfile['studentRules'] ??
          "🎓 *STUDENT RULES*\n1. Monthly fee due every 30 days.\n2. Keep premises clean.";
      renterWelcomeRulesCtrl.text = ownerProfile['renterRules'] ??
          "🏠 *RENTER RULES*\n1. Room rent due monthly.\n2. Electricity bill as per meter.";
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
      'photo': ownerPhotoBase64,
      'studentRules': studentWelcomeRulesCtrl.text,
      'renterRules': renterWelcomeRulesCtrl.text,
    };
    await prefs.setString('owner_profile', json.encode(ownerProfile));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Owner Profile & Settings Saved!")));
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (type == 'student') {
          studentImgBase64 = base64Encode(bytes);
        } else if (type == 'idCard') {
          idCardImgBase64 = base64Encode(bytes);
        } else if (type == 'owner') {
          ownerPhotoBase64 = base64Encode(bytes);
        }
      });
    }
  }

  void _sendWhatsApp(String phone, String text) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse("https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  double _calculateBackDue(Map<String, dynamic> item) {
    double totalDue = 0.0;
    if (item['history'] != null) {
      for (var h in item['history']) {
        if (h['status'] == 'Pending') {
          totalDue += (h['totalPayable'] as num).toDouble();
        }
      }
    }
    return totalDue;
  }

  void _saveNewRegistration() async {
    if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Name aur Mobile number dalein!")));
      return;
    }

    DateTime dueDate = selectedDate.add(const Duration(days: 30));
    String entryDateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String nextDueDateStr = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> newEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'pType': personType,
      'name': nameCtrl.text.trim(),
      'mobile': mobileCtrl.text.trim(),
      'parentMobile': parentMobileCtrl.text.trim(),
      'father': fatherCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'idNum': idNumCtrl.text.trim(),
      'idCardImg': idCardImgBase64 ?? '',
      'studentImg': studentImgBase64 ?? '',
      'entryDate': entryDateStr,
      'nextDueDate': nextDueDateStr,
      'rent': double.tryParse(rentCtrl.text) ?? 0.0,
      'advance': double.tryParse(advanceCtrl.text) ?? 0.0,
      'prevReading': double.tryParse(initialReadingCtrl.text) ?? 0.0,
      'lastStatus': 'Pending',
      'history': []
    };

    setState(() {
      renters.add(newEntry);
    });
    await _saveRentersToStorage();

    String welcomeRules = personType == 'Student'
        ? (studentWelcomeRulesCtrl.text.isNotEmpty ? studentWelcomeRulesCtrl.text : "Welcome Student!")
        : (renterWelcomeRulesCtrl.text.isNotEmpty ? renterWelcomeRulesCtrl.text : "Welcome Renter!");

    String ownerName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Manager";
    String ownerPhone = ownerPhoneCtrl.text.isNotEmpty ? ownerPhoneCtrl.text : "";
    String feeLabel = personType == 'Student' ? "Monthly Fee" : "Monthly Rent";

    String msg = "Namaste ${nameCtrl.text.trim()} ji,\n\n$welcomeRules\n\n📌 Registration Details:\nType: $personType\nJoining Date: $entryDateStr\nNext Due Date: $nextDueDateStr\n$feeLabel: ₹${rentCtrl.text}\nAdvance Paid: ₹${advanceCtrl.text}\n\nOwner: $ownerName\nContact: $ownerPhone";

    String sendPhone = (sendToTarget == 'parents' && parentMobileCtrl.text.trim().isNotEmpty)
        ? parentMobileCtrl.text.trim()
        : mobileCtrl.text.trim();

    _sendWhatsApp(sendPhone, msg);

    nameCtrl.clear();
    mobileCtrl.clear();
    parentMobileCtrl.clear();
    fatherCtrl.clear();
    addressCtrl.clear();
    idNumCtrl.clear();
    rentCtrl.clear();
    advanceCtrl.text = '0';
    initialReadingCtrl.text = '0';
    setState(() {
      studentImgBase64 = null;
      idCardImgBase64 = null;
    });

    _tabController.animateTo(1);
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final eName = TextEditingController(text: item['name']);
    final eMobile = TextEditingController(text: item['mobile']);
    final eParentMobile = TextEditingController(text: item['parentMobile'] ?? '');
    final eFather = TextEditingController(text: item['father'] ?? '');
    final eAddress = TextEditingController(text: item['address'] ?? '');
    final eRent = TextEditingController(text: item['rent'].toString());
    final eIdNum = TextEditingController(text: item['idNum'] ?? '');
    final ePrevReading = TextEditingController(text: item['prevReading']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("✏️ Edit: ${item['name']}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: eName, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: eMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number")),
              if (item['pType'] == 'Student')
                TextField(controller: eParentMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number")),
              TextField(controller: eFather, decoration: const InputDecoration(labelText: "Father / Guardian Name")),
              TextField(controller: eAddress, decoration: const InputDecoration(labelText: "Address")),
              TextField(controller: eRent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Rent / Fee (₹)")),
              if (item['pType'] == 'Renter')
                TextField(controller: ePrevReading, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Meter Reading (Units)")),
              TextField(controller: eIdNum, decoration: const InputDecoration(labelText: "Identity / Document No")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['name'] = eName.text.trim();
                item['mobile'] = eMobile.text.trim();
                item['parentMobile'] = eParentMobile.text.trim();
                item['father'] = eFather.text.trim();
                item['address'] = eAddress.text.trim();
                item['rent'] = double.tryParse(eRent.text) ?? item['rent'];
                if (item['pType'] == 'Renter') {
                  item['prevReading'] = double.tryParse(ePrevReading.text) ?? item['prevReading'];
                }
                item['idNum'] = eIdNum.text.trim();
              });
              _saveRentersToStorage();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Details Updated!")));
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  void _generateStudentMonthlyBill(Map<String, dynamic> item, String target) {
    double rent = (item['rent'] as num).toDouble();
    double backDue = _calculateBackDue(item);
    double totalPayable = rent + backDue;

    String dateStr = DateTime.now().toString().split(' ')[0];
    String phone = (target == 'parents' && item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty)
        ? item['parentMobile']
        : item['mobile'];

    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
    String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
    String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";

    String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
    String msg = "*🎓 MONTHLY STUDENT FEE NOTICE*\n--------------------\nStudent: ${item['name']}\nParent Name: ${item['father'] ?? 'N/A'}\nBill Date: $dateStr\n\nMonthly Fee: ₹$rent$dueText\n--------------------\n*TOTAL PAYABLE: ₹$totalPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

    setState(() {
      item['lastStatus'] = 'Pending';
      item['history'].add({
        'date': dateStr,
        'type': 'Monthly Fee',
        'unitsUsed': 0,
        'elecBill': 0.0,
        'rentAmount': rent,
        'backDue': backDue,
        'totalPayable': totalPayable,
        'status': 'Pending'
      });
    });
    _saveRentersToStorage();
    _sendWhatsApp(phone, msg);
  }

  void _showRenterBillOptionDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("⚡ Bill Options for ${item['name']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: false);
              },
              child: const Text("1. Sirf Electricity Bill Generate Karein", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () {
                Navigator.pop(ctx);
                _openRentOnlyBill(item);
              },
              child: const Text("2. Sirf Room Rent Bill Generate Karein", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: true);
              },
              child: const Text("3. Room Rent + Electricity (Combined Bill)", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openRentOnlyBill(Map<String, dynamic> item) {
    double rent = (item['rent'] as num).toDouble();
    double backDue = _calculateBackDue(item);
    double totalPayable = rent + backDue;

    String dateStr = DateTime.now().toString().split(' ')[0];
    String phone = item['mobile'];
    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
    String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
    String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";

    String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
    String msg = "*🏠 MONTHLY ROOM RENT BILL*\n--------------------\nName: ${item['name']}\nDate: $dateStr\n\nRoom Rent: ₹$rent$dueText\n--------------------\n*TOTAL PAYABLE: ₹$totalPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

    setState(() {
      item['lastStatus'] = 'Pending';
      item['history'].add({
        'date': dateStr,
        'type': 'Room Rent',
        'unitsUsed': 0,
        'elecBill': 0.0,
        'rentAmount': rent,
        'backDue': backDue,
        'totalPayable': totalPayable,
        'status': 'Pending'
      });
    });
    _saveRentersToStorage();
    _sendWhatsApp(phone, msg);
  }

  void _openElectricityCalculationDialog(Map<String, dynamic> item, {required bool isCombined}) {
    final currentReadingCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: defaultUnitRateCtrl.text.isNotEmpty ? defaultUnitRateCtrl.text : '8');
    double startUnits = (item['prevReading'] as num).toDouble();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCombined ? "⚡ Combined Bill (${item['name']})" : "⚡ Electricity Bill (${item['name']})"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Purani Reading: $startUnits Units", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            TextField(
              controller: currentReadingCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Nayi Current Reading Dalein *", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Per Unit Rate (₹)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              double endUnits = double.tryParse(currentReadingCtrl.text) ?? 0.0;
              if (endUnits < startUnits) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nayi reading purani reading se kam nahi ho sakti!")));
                return;
              }
              Navigator.pop(ctx);

              double rate = double.tryParse(rateCtrl.text) ?? 8.0;
              double unitsUsed = endUnits - startUnits;
              double elecBill = unitsUsed * rate;
              double rent = isCombined ? (item['rent'] as num).toDouble() : 0.0;
              double backDue = _calculateBackDue(item);
              double totalPayable = elecBill + rent + backDue;

              String dateStr = DateTime.now().toString().split(' ')[0];
              String phone = item['mobile'];
              String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
              String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
              String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";

              String billTitle = isCombined ? "MONTHLY RENT & ELECTRICITY BILL" : "MONTHLY ELECTRICITY BILL";
              String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
              String rentText = isCombined ? "Room Rent: ₹$rent\n" : "";

              String msg = "*🏠 $billTitle*\n--------------------\nName: ${item['name']}\nDate: $dateStr\nMeter: $startUnits to $endUnits\nUnits Consumed: $unitsUsed Units x ₹$rate = ₹$elecBill\n$rentText$dueText--------------------\n*TOTAL PAYABLE: ₹$totalPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

              setState(() {
                item['prevReading'] = endUnits;
                item['lastStatus'] = 'Pending';
                item['history'].add({
                  'date': dateStr,
                  'type': isCombined ? 'Rent + Electricity' : 'Electricity Only',
                  'startUnits': startUnits.toString(),
                  'endUnits': endUnits.toString(),
                  'unitsUsed': unitsUsed,
                  'elecBill': elecBill,
                  'rentAmount': rent,
                  'backDue': backDue,
                  'totalPayable': totalPayable,
                  'status': 'Pending'
                });
              });
              _saveRentersToStorage();
              _sendWhatsApp(phone, msg);
            },
            child: const Text("Calculate & Send WhatsApp"),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          List history = item['history'] ?? [];
          return AlertDialog(
            title: Text("📜 Bill History: ${item['name']}"),
            content: SizedBox(
              width: double.maxFinite,
              child: history.isEmpty
                  ? const Center(child: Text("Abhi koi bill history nahi hai."))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (c, idx) {
                        var h = history[idx];
                        bool isPaid = h['status'] == 'Paid';
                        return Card(
                          color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            title: Text("${h['type'] ?? 'Bill'} - ₹${h['totalPayable']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Date: ${h['date']}${h['backDue'] != null && h['backDue'] > 0 ? ' (Includes ₹${h['backDue']} Due)' : ''}"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPaid ? Colors.green : Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              onPressed: () {
                                setState(() {
                                  h['status'] = isPaid ? 'Pending' : 'Paid';
                                  item['lastStatus'] = h['status'];
                                });
                                _saveRentersToStorage();
                                setDialogState(() {});
                              },
                              child: Text(isPaid ? "PAID ✅" : "UNPAID ❌", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
            ],
          );
        },
      ),
    );
  }

  void _exportJsonBackup() async {
    Map<String, dynamic> fullData = {
      'renters': renters,
      'profile': ownerProfile,
    };
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/rent_manager_backup.json");
    await file.writeAsString(json.encode(fullData));
    await Share.shareXFiles([XFile(file.path)], text: 'Rent Manager Data Backup (.JSON)');
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
          if (data['profile'] != null) ownerProfile = Map<String, dynamic>.from(data['profile']);
        });
        await _saveRentersToStorage();
        await _saveOwnerProfile();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Restored!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Backup File!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          title: const Text('Tenant & Student Manager Pro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              onPressed: _openOwnerProfileSheet,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(icon: Icon(Icons.person_add), text: "+ New Entry"),
              Tab(icon: const Icon(Icons.groups), text: "List"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNewEntryForm(),
            _buildRegisteredListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewEntryForm() {
    bool isStudent = (personType == 'Student');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: personType,
                decoration: const InputDecoration(labelText: "Category Select Karein *", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Student", child: Text("🎓 Student")),
                  DropdownMenuItem(value: "Renter", child: Text("🏠 Renter / Family")),
                ],
                onChanged: (v) => setState(() => personType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isStudent ? "Student Full Name *" : "Renter Head Full Name *",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isStudent ? "Student WhatsApp No. *" : "Renter WhatsApp No. *",
                  border: const OutlineInputBorder(),
                ),
              ),
              if (isStudent) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: parentMobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Parents WhatsApp Number", border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: fatherCtrl,
                decoration: InputDecoration(
                  labelText: isStudent ? "Father / Parents Name *" : "Father's Name",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isStudent ? "Student Permanent Address *" : "Renter Permanent Address *",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idNumCtrl,
                decoration: const InputDecoration(labelText: "Identity / Document Number", border: OutlineInputBorder()),
              ),
              if (!isStudent) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: initialReadingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Initial Electricity Meter Reading (Units)", border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: rentCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isStudent ? "Monthly Student Fee (₹) *" : "Monthly Room Rent (₹) *",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: advanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Advance Fee/Rent Paid (₹)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage('student'),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(studentImgBase64 == null ? "Photo Upload" : "✅ Photo Added"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage('idCard'),
                      icon: const Icon(Icons.badge),
                      label: Text(idCardImgBase64 == null ? "ID Proof" : "✅ ID Added"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isStudent)
                DropdownButtonFormField<String>(
                  value: sendToTarget,
                  decoration: const InputDecoration(labelText: "Welcome Message Kise Bhejna Hai?", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "student", child: Text("1. Sirf Student WhatsApp Par")),
                    DropdownMenuItem(value: "parents", child: Text("2. Sirf Parents WhatsApp Par")),
                  ],
                  onChanged: (v) => setState(() => sendToTarget = v!),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveNewRegistration,
                child: const Text("💾 Save & Send Welcome Rules", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredListView() {
    List<Map<String, dynamic>> filtered = renters;
    if (listFilter != 'all') {
      filtered = renters.where((r) => r['pType'] == listFilter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              FilterChip(label: Text("All (${renters.length})"), selected: listFilter == 'all', onSelected: (_) => setState(() => listFilter = 'all')),
              const SizedBox(width: 6),
              FilterChip(label: const Text("🎓 Students"), selected: listFilter == 'Student', onSelected: (_) => setState(() => listFilter = 'Student')),
              const SizedBox(width: 6),
              FilterChip(label: const Text("🏠 Renters"), selected: listFilter == 'Renter', onSelected: (_) => setState(() => listFilter = 'Renter')),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("Koi record nahi mila.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered[i];
                    bool isStudent = (r['pType'] == 'Student');
                    double backDue = _calculateBackDue(r);
                    bool isFullyPaid = (backDue == 0 && r['history'] != null && r['history'].isNotEmpty);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isFullyPaid ? Colors.green : Colors.red.shade400, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(isStudent ? "🎓" : "🏠", style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isFullyPaid ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isFullyPaid ? "PAID" : "UNPAID (Due: ₹$backDue)",
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditDialog(r),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() => renters.removeWhere((item) => item['id'] == r['id']));
                                        _saveRentersToStorage();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text("📱 Phone: ${r['mobile']} ${r['parentMobile'] != '' && r['parentMobile'] != null ? '\n👨‍👩‍👦 Parents: ' + r['parentMobile'] : ''}", style: const TextStyle(fontSize: 13)),
                            if (r['address'] != null && r['address'].toString().isNotEmpty)
                              Text("📍 Addr: ${r['address']}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            Text("🗓 Entry: ${r['entryDate']} | Due Date: ${r['nextDueDate']}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            Text("💰 Fixed Rent/Fee: ₹${r['rent']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (!isStudent)
                              Text("⚡ Last Saved Reading: ${r['prevReading']} Units", style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (isStudent) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _generateStudentMonthlyBill(r, 'student'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                                    icon: const Icon(Icons.send, color: Colors.white, size: 14),
                                    label: const Text("⚡ Student Bill", style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                  if (r['parentMobile'] != null && r['parentMobile'].toString().isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () => _generateStudentMonthlyBill(r, 'parents'),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                                      icon: const Icon(Icons.send, color: Colors.white, size: 14),
                                      label: const Text("📱 Parents Bill", style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _showRenterBillOptionDialog(r),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                                    icon: const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                                    label: const Text("⚡ Generate Monthly Bill", style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => _showHistoryDialog(r),
                                  icon: const Icon(Icons.history, size: 14),
                                  label: Text("History (${r['history']?.length ?? 0})", style: const TextStyle(fontSize: 11)),
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

  void _openOwnerProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("⚙️ Owner Profile & Rules Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: ownerPhotoBase64 != null ? MemoryImage(base64Decode(ownerPhotoBase64!)) : null,
                        child: ownerPhotoBase64 == null ? const Icon(Icons.person, size: 45, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            onPressed: () async {
                              await _pickImage('owner');
                              setModalState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: "Owner Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: ownerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Owner WhatsApp Number", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: ownerUpiIdCtrl, decoration: const InputDecoration(labelText: "UPI ID (for payments)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: ownerUpiNumCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "UPI Mobile Number", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: defaultUnitRateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Default Electricity Unit Rate (₹)", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: studentWelcomeRulesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "🎓 Student Welcome Rules & Notice", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: renterWelcomeRulesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "🏠 Renter Welcome Rules & Notice", border: OutlineInputBorder())),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), minimumSize: const Size(double.infinity, 45)),
                  onPressed: () {
                    _saveOwnerProfile();
                    Navigator.pop(ctx);
                  },
                  child: const Text("💾 Save Profile & Rules", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportJsonBackup,
                        icon: const Icon(Icons.download),
                        label: const Text("Backup Data"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importJsonBackup,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Restore Data"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
