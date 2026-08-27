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
  
  DateTime rentEntryDate = DateTime.now();
  DateTime elecStartDate = DateTime.now();
  
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
          "🏠 *RENTER RULES*\n1. Room rent due monthly.\n2. Electricity meter reading cycle starts from 1st.";
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Owner Profile Saved!")));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number missing ya galat hai!")));
      }
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
        const SnackBar(content: Text("WhatsApp open nahi ho saka. Kripya WhatsApp check karein.")),
      );
    }
  }

  // ACCURATE DUE CALCULATION (Only Last Unsettled Balance)
  double _getLatestPendingDue(Map<String, dynamic> item, {String category = 'all'}) {
    List history = item['history'] ?? [];
    if (history.isEmpty) return 0.0;

    List relevant = history.where((h) {
      String t = (h['type'] ?? '').toString().toLowerCase();
      if (category == 'electricity') return t.contains('electricity');
      if (category == 'rent') return t.contains('room rent') || t.contains('student fee');
      return true;
    }).toList();

    if (relevant.isEmpty) return 0.0;

    var latestBill = relevant.last;
    double total = (latestBill['totalPayable'] as num?)?.toDouble() ?? 0.0;
    double paid = (latestBill['paidAmount'] as num?)?.toDouble() ?? 0.0;
    double balance = total - paid;
    return balance > 0 ? balance : 0.0;
  }

  void _saveNewRegistration() async {
    if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Name aur Mobile number dalein!")));
      return;
    }

    DateTime dueDate = rentEntryDate.add(const Duration(days: 30));
    String rentDateStr = "${rentEntryDate.year}-${rentEntryDate.month.toString().padLeft(2, '0')}-${rentEntryDate.day.toString().padLeft(2, '0')}";
    String elecDateStr = "${elecStartDate.year}-${elecStartDate.month.toString().padLeft(2, '0')}-${elecStartDate.day.toString().padLeft(2, '0')}";
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
      'entryDate': rentDateStr,
      'elecDate': personType == 'Renter' ? elecDateStr : null,
      'nextDueDate': nextDueDateStr,
      'rent': double.tryParse(rentCtrl.text) ?? 0.0,
      'advance': double.tryParse(advanceCtrl.text) ?? 0.0,
      'prevReading': personType == 'Renter' ? (double.tryParse(initialReadingCtrl.text) ?? 0.0) : 0.0,
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

    String msg = "Namaste ${nameCtrl.text.trim()} ji,\n\n$welcomeRules\n\n📌 Registration Details:\nType: $personType\nJoining Date: $rentDateStr\n${personType == 'Renter' ? 'Initial Meter Reading: ${initialReadingCtrl.text} Units\n' : ''}Next Due Date: $nextDueDateStr\n$feeLabel: ₹${rentCtrl.text}\nAdvance Paid: ₹${advanceCtrl.text}\n\nOwner: $ownerName\nContact: $ownerPhone";

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
      rentEntryDate = DateTime.now();
      elecStartDate = DateTime.now();
      studentImgBase64 = null;
      idCardImgBase64 = null;
    });

    _tabController.animateTo(1);
  }

  void _showEditDialog(Map<String, dynamic> item) {
    bool isStudent = (item['pType'] == 'Student');
    final eName = TextEditingController(text: item['name']);
    final eMobile = TextEditingController(text: item['mobile']);
    final eParentMobile = TextEditingController(text: item['parentMobile'] ?? '');
    final eFather = TextEditingController(text: item['father'] ?? '');
    final eAddress = TextEditingController(text: item['address'] ?? '');
    final eRent = TextEditingController(text: item['rent'].toString());
    final eAdvance = TextEditingController(text: (item['advance'] ?? 0.0).toString());
    final eIdNum = TextEditingController(text: item['idNum'] ?? '');
    final ePrevReading = TextEditingController(text: item['prevReading']?.toString() ?? '0');
    final eEntryDate = TextEditingController(text: item['entryDate'] ?? '');
    final eElecDate = TextEditingController(text: item['elecDate'] ?? item['entryDate'] ?? '');
    final eDueDate = TextEditingController(text: item['nextDueDate'] ?? '');

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
              if (isStudent)
                TextField(controller: eParentMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number")),
              TextField(controller: eFather, decoration: const InputDecoration(labelText: "Father / Guardian Name")),
              TextField(controller: eAddress, decoration: const InputDecoration(labelText: "Address")),
              TextField(controller: eEntryDate, decoration: InputDecoration(labelText: isStudent ? "Joining Date (YYYY-MM-DD)" : "Rent Entry Date (YYYY-MM-DD)")),
              if (!isStudent)
                TextField(controller: eElecDate, decoration: const InputDecoration(labelText: "Electricity Cycle Date (YYYY-MM-DD)")),
              TextField(controller: eDueDate, decoration: const InputDecoration(labelText: "Next Due Date (YYYY-MM-DD)")),
              TextField(controller: eRent, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isStudent ? "Monthly Student Fee (₹)" : "Monthly Rent (₹)")),
              TextField(controller: eAdvance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Advance Balance / Wallet (₹)")),
              if (!isStudent)
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
                item['entryDate'] = eEntryDate.text.trim();
                if (!isStudent) {
                  item['elecDate'] = eElecDate.text.trim();
                  item['prevReading'] = double.tryParse(ePrevReading.text) ?? item['prevReading'];
                }
                item['nextDueDate'] = eDueDate.text.trim();
                item['rent'] = double.tryParse(eRent.text) ?? item['rent'];
                item['advance'] = double.tryParse(eAdvance.text) ?? 0.0;
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

  // DIALOG: STUDENT MONTHLY BILL WITH AUTO ADVANCE ADJUSTMENT
  void _openStudentGenerateBillDialog(Map<String, dynamic> item) {
    DateTime selectedBillDate = DateTime.now();
    double rent = (item['rent'] as num).toDouble();
    double backDue = _getLatestPendingDue(item, category: 'rent');
    double currentAdvance = (item['advance'] as num?)?.toDouble() ?? 0.0;

    double grossTotal = rent + backDue;
    double advanceUsed = (currentAdvance > 0) ? (currentAdvance >= grossTotal ? grossTotal : currentAdvance) : 0.0;
    double netPayable = grossTotal - advanceUsed;

    String target = 'both';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String dateFormatted = "${selectedBillDate.year}-${selectedBillDate.month.toString().padLeft(2, '0')}-${selectedBillDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: Text("⚡ Fee Notice: ${item['name']}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly Fee: ₹$rent", style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (backDue > 0)
                          Text("+ Pichhla Baki (Due): ₹$backDue", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800)),
                        if (advanceUsed > 0)
                          Text("- Advance Adjusted: ₹$advanceUsed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        const Divider(height: 10),
                        Text("NET PAYABLE: ₹$netPayable", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                        if (currentAdvance > advanceUsed)
                          Text("Remaining Advance: ₹${currentAdvance - advanceUsed}", style: const TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, selectedBillDate);
                      if (p != null) {
                        setDialogState(() => selectedBillDate = p);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Bill Date: $dateFormatted", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Kise Bhejna Hai WhatsApp Par?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: target,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: [
                      const DropdownMenuItem(value: "both", child: Text("1. Dono Ko (Student + Parents)")),
                      const DropdownMenuItem(value: "student", child: Text("2. Sirf Student Ko")),
                      if (item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty)
                        const DropdownMenuItem(value: "parents", child: Text("3. Sirf Parents Ko")),
                    ],
                    onChanged: (v) => setDialogState(() => target = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                onPressed: () {
                  Navigator.pop(ctx);
                  String dateStr = dateFormatted;
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";
                  String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Used: ₹$advanceUsed" : "";

                  String msg = "*🎓 MONTHLY STUDENT FEE NOTICE*\n--------------------\nStudent: ${item['name']}\nParent Name: ${item['father'] ?? 'N/A'}\nBill Date: $dateStr\n\nMonthly Fee: ₹$rent$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['advance'] = currentAdvance - advanceUsed; // Deduct used advance
                    item['history'].add({
                      'date': dateStr,
                      'type': 'Monthly Student Fee',
                      'unitsUsed': 0,
                      'elecBill': 0.0,
                      'rentAmount': rent,
                      'backDue': backDue,
                      'advanceUsed': advanceUsed,
                      'totalPayable': netPayable,
                      'paidAmount': (netPayable == 0) ? 0.0 : 0.0,
                      'paymentDate': (netPayable == 0) ? dateStr : '-',
                      'status': (netPayable == 0) ? 'Paid' : 'Pending'
                    });
                  });
                  _saveRentersToStorage();

                  if (target == 'student' || target == 'both') {
                    _sendWhatsApp(item['mobile'], msg);
                  }
                  if ((target == 'parents' || target == 'both') && item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty) {
                    _sendWhatsApp(item['parentMobile'], msg);
                  }
                },
                child: const Text("Generate & Send Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // RENTER: 3 OPTIONS (ELECTRICITY / ROOM RENT / COMBINED)
  void _showRenterBillOptionDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("⚡ Bill Options for ${item['name']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Kripya chunhein ki kaunsa bill generate karna hai:", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.electric_bolt, color: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: false);
              },
              label: const Text("1. Sirf Electricity Bill (Alag)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.house, color: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _openRentOnlyBill(item);
              },
              label: const Text("2. Sirf Room Rent Bill (Alag)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: true);
              },
              label: const Text("3. Room Rent + Electricity (Combined Bill)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // RENTER: ONLY ROOM RENT BILL WITH ADVANCE ADJUSTMENT
  void _openRentOnlyBill(Map<String, dynamic> item) {
    DateTime billDate = DateTime.now();
    double rent = (item['rent'] as num).toDouble();
    double backDue = _getLatestPendingDue(item, category: 'rent');
    double currentAdvance = (item['advance'] as num?)?.toDouble() ?? 0.0;

    double grossTotal = rent + backDue;
    double advanceUsed = (currentAdvance > 0) ? (currentAdvance >= grossTotal ? grossTotal : currentAdvance) : 0.0;
    double netPayable = grossTotal - advanceUsed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String dateFormatted = "${billDate.year}-${billDate.month.toString().padLeft(2, '0')}-${billDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: Text("🏠 Room Rent Bill (${item['name']})"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly Room Rent: ₹$rent", style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (backDue > 0)
                          Text("+ Pichhla Rent Due: ₹$backDue", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800)),
                        if (advanceUsed > 0)
                          Text("- Advance Adjusted: ₹$advanceUsed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        const Divider(height: 10),
                        Text("NET PAYABLE: ₹$netPayable", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, billDate);
                      if (p != null) {
                        setDialogState(() => billDate = p);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Rent Bill Date: $dateFormatted", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.calendar_month, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                onPressed: () {
                  Navigator.pop(ctx);
                  String dateStr = dateFormatted;
                  String phone = item['mobile'];
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";
                  String dueText = backDue > 0 ? "\n+ Rent Back Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Used: ₹$advanceUsed" : "";

                  String msg = "*🏠 MONTHLY ROOM RENT BILL*\n--------------------\nName: ${item['name']}\nBill Date: $dateStr\nRoom Rent: ₹$rent$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['advance'] = currentAdvance - advanceUsed;
                    item['history'].add({
                      'date': dateStr,
                      'type': 'Room Rent Bill',
                      'unitsUsed': 0,
                      'elecBill': 0.0,
                      'rentAmount': rent,
                      'backDue': backDue,
                      'advanceUsed': advanceUsed,
                      'totalPayable': netPayable,
                      'paidAmount': (netPayable == 0) ? 0.0 : 0.0,
                      'paymentDate': (netPayable == 0) ? dateStr : '-',
                      'status': (netPayable == 0) ? 'Paid' : 'Pending'
                    });
                  });
                  _saveRentersToStorage();
                  _sendWhatsApp(phone, msg);
                },
                child: const Text("Generate & Send Rent Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // RENTER: ELECTRICITY OR COMBINED BILL WITH ADVANCE ADJUSTMENT
  void _openElectricityCalculationDialog(Map<String, dynamic> item, {required bool isCombined}) {
    final currentReadingCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: defaultUnitRateCtrl.text.isNotEmpty ? defaultUnitRateCtrl.text : '8');
    DateTime customElecDate = DateTime.now();
    double startUnits = (item['prevReading'] as num).toDouble();
    double backDue = isCombined 
        ? _getLatestPendingDue(item, category: 'all')
        : _getLatestPendingDue(item, category: 'electricity');
    double currentAdvance = (item['advance'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String elecDateFormatted = "${customElecDate.year}-${customElecDate.month.toString().padLeft(2, '0')}-${customElecDate.day.toString().padLeft(2, '0')}";
          
          return AlertDialog(
            title: Text(isCombined ? "📋 Combined Bill (${item['name']})" : "⚡ Electricity Bill (${item['name']})"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📌 Purani Reading: $startUnits Units", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                        if (backDue > 0)
                          Text("+ Pichhla Baki (Due): ₹$backDue", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800)),
                        if (currentAdvance > 0)
                          Text("💎 Advance Balance Available: ₹$currentAdvance", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, customElecDate);
                      if (p != null) {
                        setDialogState(() => customElecDate = p);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Bill Date: $elecDateFormatted", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: currentReadingCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Nayi Current Reading Dalein (jaise: 1255) *", 
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Per Unit Rate (₹)", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
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
                  double grossTotal = elecBill + rent + backDue;

                  double advanceUsed = (currentAdvance > 0) ? (currentAdvance >= grossTotal ? grossTotal : currentAdvance) : 0.0;
                  double netPayable = grossTotal - advanceUsed;

                  String dateStr = elecDateFormatted;
                  String phone = item['mobile'];
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";

                  String billTitle = isCombined ? "MONTHLY RENT & ELECTRICITY BILL" : "MONTHLY ELECTRICITY BILL";
                  String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Used: ₹$advanceUsed" : "";
                  String rentText = isCombined ? "Room Rent: ₹$rent\n" : "";

                  String msg = "*🏠 $billTitle*\n--------------------\nName: ${item['name']}\nBill Date: $dateStr\nPrevious Reading: $startUnits Units\nCurrent Reading: $endUnits Units\n*Consumed Units: $unitsUsed Units ($endUnits - $startUnits)*\nUnit Rate: ₹$rate / Unit\nElectricity Bill: $unitsUsed x ₹$rate = ₹$elecBill\n$rentText$dueText$advText--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['prevReading'] = endUnits; 
                    item['elecDate'] = dateStr;
                    item['advance'] = currentAdvance - advanceUsed;
                    item['history'].add({
                      'date': dateStr,
                      'type': isCombined ? 'Rent + Electricity Bill' : 'Electricity Bill',
                      'startUnits': startUnits.toString(),
                      'endUnits': endUnits.toString(),
                      'unitsUsed': unitsUsed,
                      'elecBill': elecBill,
                      'rentAmount': rent,
                      'backDue': backDue,
                      'advanceUsed': advanceUsed,
                      'totalPayable': netPayable,
                      'paidAmount': (netPayable == 0) ? 0.0 : 0.0,
                      'paymentDate': (netPayable == 0) ? dateStr : '-',
                      'status': (netPayable == 0) ? 'Paid' : 'Pending'
                    });
                  });
                  _saveRentersToStorage();
                  _sendWhatsApp(phone, msg);
                },
                child: const Text("Calculate & Send WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // PAYMENT ENTRY DIALOG: HANDLES NORMAL & OVERPAYMENTS AUTOMATICALLY INTO ADVANCE
  void _openPaymentRecordDialog(Map<String, dynamic> item, Map<String, dynamic> billRecord) {
    double total = (billRecord['totalPayable'] as num).toDouble();
    double currentPaid = (billRecord['paidAmount'] as num?)?.toDouble() ?? 0.0;
    DateTime paymentDate = DateTime.now();
    final paidCtrl = TextEditingController(text: currentPaid > 0 ? currentPaid.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          double enteredPaid = double.tryParse(paidCtrl.text) ?? 0.0;
          double remainingDue = total - enteredPaid;
          double extraPaid = enteredPaid > total ? (enteredPaid - total) : 0.0;
          String pDateFormatted = "${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: Text("💳 Payment Record: ${item['name']}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📌 Bill Type: ${billRecord['type']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Bill Date: ${billRecord['date']}"),
                        Text("💰 Bill Amount: ₹$total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, paymentDate);
                      if (p != null) {
                        setDialogState(() => paymentDate = p);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Bill Paid Date: $pDateFormatted", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.calendar_month, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (val) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Kitna Paid Kiya (₹) *",
                      hintText: "jaise: 2000",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: enteredPaid >= total
                          ? Colors.green.shade100
                          : (enteredPaid > 0 ? Colors.orange.shade100 : Colors.red.shade100),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: enteredPaid >= total
                            ? Colors.green
                            : (enteredPaid > 0 ? Colors.orange.shade800 : Colors.red),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enteredPaid > total
                              ? "🎉 FULL PAID + ADVANCE CREDIT"
                              : (enteredPaid == total && total > 0
                                  ? "✅ Status: ALL PAID (Due: ₹0)"
                                  : (enteredPaid > 0
                                      ? "⚠️ Status: PARTIAL DUE (Balance: ₹${remainingDue.toStringAsFixed(1)})"
                                      : "❌ Status: UNPAID (Due: ₹$total)")),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: enteredPaid >= total
                                ? Colors.green.shade900
                                : (enteredPaid > 0 ? Colors.orange.shade900 : Colors.red.shade900),
                          ),
                        ),
                        if (extraPaid > 0) ...[
                          const SizedBox(height: 4),
                          Text("💎 Extra ₹$extraPaid unke Advance Wallet me add ho jayega aur agle bill me adjust hoga!", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                        ] else if (enteredPaid > 0 && enteredPaid < total) ...[
                          const SizedBox(height: 4),
                          Text("Calculation: ₹$total (Total) - ₹$enteredPaid (Paid) = ₹${remainingDue.toStringAsFixed(1)}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
                onPressed: () {
                  Navigator.pop(ctx);
                  double finalPaid = double.tryParse(paidCtrl.text) ?? 0.0;
                  double extra = (finalPaid > total) ? (finalPaid - total) : 0.0;
                  double effectivePaid = (finalPaid > total) ? total : finalPaid;
                  
                  String newStatus;
                  if (finalPaid >= total) {
                    newStatus = 'Paid';
                  } else if (finalPaid > 0) {
                    newStatus = 'Partial';
                  } else {
                    newStatus = 'Pending';
                  }

                  setState(() {
                    if (extra > 0) {
                      // Credit extra money to Advance wallet
                      item['advance'] = ((item['advance'] as num?)?.toDouble() ?? 0.0) + extra;
                    }
                    billRecord['paidAmount'] = effectivePaid;
                    billRecord['paymentDate'] = pDateFormatted;
                    billRecord['status'] = newStatus;
                  });
                  _saveRentersToStorage();

                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String extraNote = extra > 0 ? "\n🎉 Extra ₹$extra aapke Advance Account me credit ho gaya hai." : "";
                  String receiptMsg = "*🧾 PAYMENT ACKNOWLEDGEMENT / RECEIPT*\n--------------------\nName: ${item['name']}\nPayment Date: $pDateFormatted\nTotal Bill: ₹$total\n*Amount Paid: ₹$finalPaid*\n*Remaining Due: ₹${(total - finalPaid).clamp(0, double.infinity)}*$extraNote\nStatus: $newStatus\n--------------------\nReceived By: $oName\nDhanyawad!";
                  _sendWhatsApp(item['mobile'], receiptMsg);
                },
                child: const Text("Save & Send Receipt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // SINGLE RESEND DIALOG WITH RECIPIENT SELECTION
  void _openResendChoiceDialog(Map<String, dynamic> item, Map<String, dynamic> billRecord) {
    bool isStudent = (item['pType'] == 'Student');
    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
    String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
    String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";
    double total = (billRecord['totalPayable'] as num).toDouble();
    double backDue = (billRecord['backDue'] as num?)?.toDouble() ?? 0.0;
    double advUsed = (billRecord['advanceUsed'] as num?)?.toDouble() ?? 0.0;
    String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
    String advText = advUsed > 0 ? "\n- Advance Used: ₹$advUsed" : "";

    String msg = "";
    if (isStudent) {
      msg = "*🎓 MONTHLY STUDENT FEE NOTICE (REMINDER)*\n--------------------\nStudent: ${item['name']}\nParent Name: ${item['father'] ?? 'N/A'}\nBill Date: ${billRecord['date']}\n\nMonthly Fee: ₹${billRecord['rentAmount']}$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
    } else {
      String type = billRecord['type'] ?? 'Room Rent Bill';
      if (type.contains('Electricity')) {
        String unitsDetails = (billRecord['unitsUsed'] != null && billRecord['unitsUsed'] > 0)
            ? "Meter Reading: ${billRecord['startUnits']} to ${billRecord['endUnits']}\nConsumed Units: ${billRecord['unitsUsed']} Units\nElectricity Amount: ₹${billRecord['elecBill']}\n"
            : "";
        String rentDetails = (billRecord['rentAmount'] != null && billRecord['rentAmount'] > 0)
            ? "Room Rent: ₹${billRecord['rentAmount']}\n"
            : "";
        msg = "*🏠 $type (REMINDER)*\n--------------------\nName: ${item['name']}\nBill Date: ${billRecord['date']}\n$unitsDetails$rentDetails$dueText$advText--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
      } else {
        msg = "*🏠 MONTHLY ROOM RENT BILL (REMINDER)*\n--------------------\nName: ${item['name']}\nBill Date: ${billRecord['date']}\nRoom Rent: ₹${billRecord['rentAmount']}$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
      }
    }

    if (!isStudent) {
      _sendWhatsApp(item['mobile'], msg);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill WhatsApp Par Bhej Diya Gaya!")));
      return;
    }

    String resendTarget = 'both';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: const Text("📲 Send Bill on WhatsApp"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Student: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Bill Amount: ₹$total (${billRecord['date']})"),
              const SizedBox(height: 12),
              const Text("Kise Bhejna Hai?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: resendTarget,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: [
                  const DropdownMenuItem(value: "both", child: Text("1. Dono Ko (Student + Parents)")),
                  const DropdownMenuItem(value: "student", child: Text("2. Sirf Student Ko")),
                  if (item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty)
                    const DropdownMenuItem(value: "parents", child: Text("3. Sirf Parents Ko")),
                ],
                onChanged: (v) => setDialogState(() => resendTarget = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () {
                Navigator.pop(ctx);
                if (resendTarget == 'student' || resendTarget == 'both') {
                  _sendWhatsApp(item['mobile'], msg);
                }
                if ((resendTarget == 'parents' || resendTarget == 'both') && item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty) {
                  _sendWhatsApp(item['parentMobile'], msg);
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill WhatsApp Par Bhej Diya Gaya!")));
              },
              child: const Text("Send WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
                        double total = (h['totalPayable'] as num).toDouble();
                        double paid = (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
                        double remaining = total - paid;

                        Color cardBgColor;
                        Color statusBadgeColor;
                        String statusBadgeText;

                        if (paid >= total && total > 0) {
                          cardBgColor = Colors.green.shade50;
                          statusBadgeColor = Colors.green;
                          statusBadgeText = "PAID ✅";
                        } else if (paid > 0 && paid < total) {
                          cardBgColor = Colors.orange.shade50;
                          statusBadgeColor = Colors.orange.shade800;
                          statusBadgeText = "PARTIAL: ₹${remaining.toStringAsFixed(0)} ⚠️";
                        } else if (total == 0 && (h['status'] == 'Paid')) {
                          cardBgColor = Colors.green.shade50;
                          statusBadgeColor = Colors.green;
                          statusBadgeText = "PAID (Advance) ✅";
                        } else {
                          cardBgColor = Colors.red.shade50;
                          statusBadgeColor = Colors.red;
                          statusBadgeText = "UNPAID ❌";
                        }

                        return Card(
                          color: cardBgColor,
                          elevation: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: statusBadgeColor, width: 1.5),
                          ),
                          child: InkWell(
                            onTap: () {
                              _openPaymentRecordDialog(item, h);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(h['type'] ?? 'Bill', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: statusBadgeColor, borderRadius: BorderRadius.circular(10)),
                                        child: Text(statusBadgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("📅 Generated: ${h['date']}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      Text("Total Bill: ₹$total", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("📅 Paid Date: ${h['paymentDate'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      Text("Paid Amount: ₹$paid", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                    ],
                                  ),
                                  if (h['advanceUsed'] != null && (h['advanceUsed'] as num) > 0) ...[
                                    const SizedBox(height: 2),
                                    Text("💎 Advance Adjusted: ₹${h['advanceUsed']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                  ],
                                  if (remaining > 0 && paid > 0) ...[
                                    const SizedBox(height: 2),
                                    Text("⚠️ Remaining Due: ₹${remaining.toStringAsFixed(1)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900)),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                        onPressed: () => _openResendChoiceDialog(item, h),
                                        icon: const Icon(Icons.send, size: 12, color: Color(0xFF25D366)),
                                        label: const Text("Send Bill 🔁", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey.shade800,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        ),
                                        onPressed: () {
                                          _openPaymentRecordDialog(item, h);
                                        },
                                        child: const Text("Update Pay 💳", style: TextStyle(fontSize: 10)),
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
    String rentDateStr = "${rentEntryDate.year}-${rentEntryDate.month.toString().padLeft(2, '0')}-${rentEntryDate.day.toString().padLeft(2, '0')}";
    String elecDateStr = "${elecStartDate.year}-${elecStartDate.month.toString().padLeft(2, '0')}-${elecStartDate.day.toString().padLeft(2, '0')}";

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
              InkWell(
                onTap: () async {
                  DateTime? p = await _selectCustomDate(context, rentEntryDate);
                  if (p != null) setState(() => rentEntryDate = p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isStudent ? "🗓 Student Joining Date: $rentDateStr" : "🗓 Rent Entry Date: $rentDateStr", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const Icon(Icons.calendar_month, color: Color(0xFF0288D1)),
                    ],
                  ),
                ),
              ),
              if (!isStudent) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    DateTime? p = await _selectCustomDate(context, elecStartDate);
                    if (p != null) setState(() => elecStartDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("⚡ Electricity Cycle Date: $elecDateStr", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const Icon(Icons.calendar_today, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              ],
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
                  decoration: const InputDecoration(labelText: "Initial Meter Reading (e.g. 1200)", border: OutlineInputBorder()),
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
                    double currentDue = _getLatestPendingDue(r, category: 'all');
                    double currentAdvance = (r['advance'] as num?)?.toDouble() ?? 0.0;
                    bool hasHistory = (r['history'] != null && (r['history'] as List).isNotEmpty);
                    bool isFullyPaid = (currentDue == 0 && hasHistory);
                    bool isPartial = (currentDue > 0 && hasHistory);

                    Color statusColor = Colors.red.shade400;
                    String statusText = "UNPAID (Due: ₹$currentDue)";
                    if (isFullyPaid) {
                      statusColor = Colors.green;
                      statusText = "ALL PAID ✅";
                    } else if (isPartial) {
                      statusColor = Colors.orange.shade800;
                      statusText = "DUE: ₹$currentDue";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: statusColor, width: 2),
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
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
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
                            Text("🗓 ${isStudent ? 'Joining Date' : 'Rent Date'}: ${r['entryDate']} | Due Date: ${r['nextDueDate']}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            if (!isStudent && r['elecDate'] != null)
                              Text("⚡ Elec Date: ${r['elecDate']}", style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
                            Text("💰 Fixed ${isStudent ? 'Fee' : 'Rent'}: ₹${r['rent']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (currentAdvance > 0)
                              Text("💎 Advance Balance: ₹$currentAdvance", style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                            if (!isStudent)
                              Text("⚡ Current Base Reading: ${r['prevReading']} Units", style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (isStudent) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _openStudentGenerateBillDialog(r),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                                    icon: const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                                    label: const Text("⚡ Generate Monthly Bill", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _showRenterBillOptionDialog(r),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                                    icon: const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                                    label: const Text("⚡ Generate Monthly Bill", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => _showHistoryDialog(r),
                                  icon: const Icon(Icons.payments, size: 14, color: Colors.green),
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
