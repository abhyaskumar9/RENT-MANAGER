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
      title: 'RentManager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F766E),
          surface: Colors.white,
        ),
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

    double due = 0.0;
    for (var h in history) {
      String t = (h['type'] ?? '').toString().toLowerCase();
      bool match = true;
      if (category == 'electricity') match = t.contains('electricity');
      if (category == 'rent') match = t.contains('room rent') || t.contains('fee') || t.contains('hostel');

      if (match) {
        double total = (h['totalPayable'] as num?)?.toDouble() ?? 0.0;
        double paid = (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
        double remaining = total - paid;
        if (remaining > 0) due += remaining;
      }
    }
    return due;
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
        title: Text("📢 Bulk Reminders (${unpaidList.length} Unpaid)", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
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

    String verificationDoc = "==============================\n📋 MEMBER RECORD & VERIFICATION\n==============================\nProperty/Institute: $pName\n\n1. Full Name: ${item['name']}\n2. Category: ${item['pType']}\n3. ${isStudent ? 'Roll Number' : 'Room / Bed No'}: ${item['roomNo'] ?? 'N/A'}\n4. Mobile No: ${item['mobile']}\n5. Parents Mobile: ${item['parentMobile'] ?? 'N/A'}\n6. Father/Guardian Name: ${item['father'] ?? 'N/A'}\n7. Permanent Address: ${item['address'] ?? 'N/A'}\n8. ID / Aadhaar / Doc No: ${item['idNum'] ?? 'N/A'}\n9. Joining Date: ${item['entryDate']}\n10. Monthly Fee/Rent: ₹${item['rent']}\n11. Security Deposit: ₹${item['securityDeposit'] ?? 0}\n\nOwner / Manager: $oName\nContact: $oPhone\n==============================";

    Share.share(verificationDoc, subject: "Member Verification - ${item['name']}");
  }

  void _saveNewRegistration() async {
    if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Name aur Mobile number dalein!")));
      return;
    }

    bool isRenterOrHostel = (personType == 'Renter' || personType == 'Hostel');
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
      'roomNo': roomOrRollCtrl.text.trim(),
      'idNum': idNumCtrl.text.trim(),
      'idCardImg': idCardImgBase64 ?? '',
      'studentImg': studentImgBase64 ?? '',
      'entryDate': rentDateStr,
      'elecDate': isRenterOrHostel ? elecDateStr : null,
      'nextDueDate': nextDueDateStr,
      'rent': double.tryParse(rentCtrl.text) ?? 0.0,
      'securityDeposit': double.tryParse(advanceCtrl.text) ?? 0.0,
      'extraWalletAdvance': 0.0,
      'prevReading': isRenterOrHostel ? (double.tryParse(initialReadingCtrl.text) ?? 0.0) : 0.0,
      'isClosed': false,
      'closedDate': null,
      'closureDetails': null,
      'history': []
    };

    setState(() => renters.add(newEntry));
    await _saveRentersToStorage();

    String welcomeRules = (personType == 'Student' || personType == 'Hostel')
        ? (studentWelcomeRulesCtrl.text.isNotEmpty ? studentWelcomeRulesCtrl.text : "Welcome to our Institution / Hostel!")
        : (renterWelcomeRulesCtrl.text.isNotEmpty ? renterWelcomeRulesCtrl.text : "Welcome to Residency!");

    String ownerName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Manager";
    String ownerPhone = ownerPhoneCtrl.text.isNotEmpty ? ownerPhoneCtrl.text : "";
    String feeLabel = (personType == 'Student') ? "Monthly Fee" : "Monthly Rent";
    String roomLabel = (personType == 'Student') ? "Roll No" : "Room / Bed";

    String msg = "Namaste ${nameCtrl.text.trim()} ji,\n\n$welcomeRules\n\n📌 Registration Details:\nCategory: $personType\n$roomLabel: ${roomOrRollCtrl.text.trim()}\nJoining Date: $rentDateStr\n${isRenterOrHostel ? 'Initial Meter Reading: ${initialReadingCtrl.text} Units\n' : ''}Next Due Date: $nextDueDateStr\n$feeLabel: ₹${rentCtrl.text}\nSecurity Deposit Paid: ₹${advanceCtrl.text}\n\nOwner: $ownerName\nContact: $ownerPhone";

    String sendPhone = (sendToTarget == 'parents' && parentMobileCtrl.text.trim().isNotEmpty)
        ? parentMobileCtrl.text.trim()
        : mobileCtrl.text.trim();

    _sendWhatsApp(sendPhone, msg);

    nameCtrl.clear();
    mobileCtrl.clear();
    parentMobileCtrl.clear();
    fatherCtrl.clear();
    addressCtrl.clear();
    roomOrRollCtrl.clear();
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

    _tabController.animateTo(2);
  }

  void _showEditDialog(Map<String, dynamic> item) {
    bool isStudent = (item['pType'] == 'Student');
    bool isRenterOrHostel = (item['pType'] == 'Renter' || item['pType'] == 'Hostel');

    final eName = TextEditingController(text: item['name']);
    final eMobile = TextEditingController(text: item['mobile']);
    final eParentMobile = TextEditingController(text: item['parentMobile'] ?? '');
    final eFather = TextEditingController(text: item['father'] ?? '');
    final eAddress = TextEditingController(text: item['address'] ?? '');
    final eRoomNo = TextEditingController(text: item['roomNo'] ?? '');
    final eRent = TextEditingController(text: item['rent'].toString());
    final eSecurity = TextEditingController(text: (item['securityDeposit'] ?? item['advance'] ?? 0.0).toString());
    final eIdNum = TextEditingController(text: item['idNum'] ?? '');
    final ePrevReading = TextEditingController(text: item['prevReading']?.toString() ?? '0');
    final eEntryDate = TextEditingController(text: item['entryDate'] ?? '');
    final eElecDate = TextEditingController(text: item['elecDate'] ?? item['entryDate'] ?? '');
    final eDueDate = TextEditingController(text: item['nextDueDate'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("✏️ Edit: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: eName, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: eMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number")),
              if (isStudent || item['pType'] == 'Hostel')
                TextField(controller: eParentMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number")),
              TextField(controller: eFather, decoration: const InputDecoration(labelText: "Father / Guardian Name")),
              TextField(controller: eRoomNo, decoration: InputDecoration(labelText: isStudent ? "Student Roll Number" : "Room / Bed / Flat No.")),
              TextField(controller: eAddress, decoration: const InputDecoration(labelText: "Address")),
              TextField(controller: eEntryDate, decoration: InputDecoration(labelText: isStudent ? "Joining Date (YYYY-MM-DD)" : "Rent Entry Date (YYYY-MM-DD)")),
              if (isRenterOrHostel)
                TextField(controller: eElecDate, decoration: const InputDecoration(labelText: "Electricity Cycle Date (YYYY-MM-DD)")),
              TextField(controller: eDueDate, decoration: const InputDecoration(labelText: "Next Due Date (YYYY-MM-DD)")),
              TextField(controller: eRent, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isStudent ? "Monthly Student Fee (₹)" : "Monthly Rent (₹)")),
              TextField(controller: eSecurity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit Paid (₹)")),
              if (isRenterOrHostel)
                TextField(controller: ePrevReading, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Meter Reading (Units)")),
              TextField(controller: eIdNum, decoration: const InputDecoration(labelText: "Identity / Document No")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                item['name'] = eName.text.trim();
                item['mobile'] = eMobile.text.trim();
                item['parentMobile'] = eParentMobile.text.trim();
                item['father'] = eFather.text.trim();
                item['address'] = eAddress.text.trim();
                item['roomNo'] = eRoomNo.text.trim();
                item['entryDate'] = eEntryDate.text.trim();
                if (isRenterOrHostel) {
                  item['elecDate'] = eElecDate.text.trim();
                  item['prevReading'] = double.tryParse(ePrevReading.text) ?? item['prevReading'];
                }
                item['nextDueDate'] = eDueDate.text.trim();
                item['rent'] = double.tryParse(eRent.text) ?? item['rent'];
                item['securityDeposit'] = double.tryParse(eSecurity.text) ?? 0.0;
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

  void _openCloseAccountDialog(Map<String, dynamic> item) {
    bool isStudent = (item['pType'] == 'Student');
    DateTime leaveDate = DateTime.now();
    double security = (item['securityDeposit'] ?? item['advance'] ?? 0.0) as double;
    double unpaidDue = _getAccurateUnpaidDue(item, category: 'all');
    double startUnits = (item['prevReading'] as num?)?.toDouble() ?? 0.0;

    final finalReadingCtrl = TextEditingController(text: startUnits.toString());
    final rateCtrl = TextEditingController(text: defaultUnitRateCtrl.text.isNotEmpty ? defaultUnitRateCtrl.text : '8');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String leaveDateFormatted = "${leaveDate.year}-${leaveDate.month.toString().padLeft(2, '0')}-${leaveDate.day.toString().padLeft(2, '0')}";
          double currentReading = double.tryParse(finalReadingCtrl.text) ?? startUnits;
          double finalUnitsUsed = isStudent ? 0.0 : (currentReading > startUnits ? currentReading - startUnits : 0.0);
          double finalRate = double.tryParse(rateCtrl.text) ?? 8.0;
          double finalElecBill = isStudent ? 0.0 : (finalUnitsUsed * finalRate);

          double totalDueToPay = unpaidDue + finalElecBill;
          double netBalance = security - totalDueToPay;
          bool isRefund = netBalance >= 0;

          return AlertDialog(
            title: Text("🚪 Final Settlement: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🗓 Joining Date: ${item['entryDate']}", style: const TextStyle(fontSize: 12)),
                        Text("${isStudent ? 'Roll No' : 'Room/Bed'}: ${item['roomNo'] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                        const Divider(height: 12),
                        Text("🔒 Security Deposit: ₹$security", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                        Text("⚠️ Pichhla Baki (Unpaid Due): ₹$unpaidDue", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, leaveDate);
                      if (p != null) setDialogState(() => leaveDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Leaving Date: $leaveDateFormatted", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_month, color: Color(0xFFE11D48), size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (!isStudent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: finalReadingCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: "Final Meter Reading (Purani: $startUnits)",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (finalUnitsUsed > 0) ...[
                      const SizedBox(height: 4),
                      Text("Final Electricity Bill: $finalUnitsUsed x ₹$finalRate = ₹$finalElecBill", style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold)),
                    ],
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRefund ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isRefund ? const Color(0xFF10B981) : const Color(0xFFF43F5E), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRefund ? "💰 TENANT/STUDENT KO WAPAS (REFUND) KARNA HAI:" : "⚠️ TENANT/STUDENT SE LENA (COLLECT) KARNA HAI:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isRefund ? const Color(0xFF047857) : const Color(0xFFBE123C)),
                        ),
                        const SizedBox(height: 4),
                        Text("₹${netBalance.abs().toStringAsFixed(1)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isRefund ? const Color(0xFF047857) : const Color(0xFFBE123C))),
                        Text("Hisaab: Security (₹$security) - Total Due (₹$totalDueToPay)", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String oPhone = ownerPhoneCtrl.text.isNotEmpty ? ownerPhoneCtrl.text : "";
                  String settlementText = isRefund
                      ? "*₹${netBalance.abs().toStringAsFixed(1)} Refund/Wapas kiya gaya.*"
                      : "*₹${netBalance.abs().toStringAsFixed(1)} Collect/Liya gaya.*";

                  String roomTag = isStudent ? "Roll No" : "Room/Bed";
                  String nocMsg = "*📜 FINAL ACCOUNT SETTLEMENT / NOC NOTICE*\n--------------------\nName: ${item['name']}\nCategory: ${item['pType']}\n$roomTag: ${item['roomNo'] ?? 'N/A'}\nLeaving Date: $leaveDateFormatted\n--------------------\n• Security Deposit: ₹$security\n• Previous Due: ₹$unpaidDue\n${!isStudent ? '• Final Electricity Bill: ₹$finalElecBill\n' : ''}• Total Dues: ₹$totalDueToPay\n--------------------\n*RESULT:* $settlementText\n--------------------\n*Status: CLEARED & CLOSED ✅*\nVerified By: $oName ($oPhone)\nDhanyawad!";

                  setState(() {
                    item['isClosed'] = true;
                    item['closedDate'] = leaveDateFormatted;
                    item['closureDetails'] = {
                      'leaveDate': leaveDateFormatted,
                      'security': security,
                      'totalDue': totalDueToPay,
                      'netBalance': netBalance,
                      'isRefund': isRefund,
                    };
                  });
                  _saveRentersToStorage();
                  _sendWhatsApp(item['mobile'], nocMsg);
                  if (item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty) {
                    _sendWhatsApp(item['parentMobile'], nocMsg);
                  }
                },
                child: const Text("Confirm & Close Account", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openStudentGenerateBillDialog(Map<String, dynamic> item) {
    DateTime selectedBillDate = DateTime.now();
    double rent = (item['rent'] as num).toDouble();
    double backDue = _getAccurateUnpaidDue(item, category: 'rent');
    double extraWallet = (item['extraWalletAdvance'] as num?)?.toDouble() ?? 0.0;
    double grossTotal = rent + backDue;
    double advanceUsed = (extraWallet > 0) ? (extraWallet >= grossTotal ? grossTotal : extraWallet) : 0.0;
    double netPayable = grossTotal - advanceUsed;
    String target = 'both';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String dateFormatted = "${selectedBillDate.year}-${selectedBillDate.month.toString().padLeft(2, '0')}-${selectedBillDate.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: Text("⚡ Fee Notice: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly Fee: ₹$rent", style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (backDue > 0)
                          Text("+ Pichhla Baki (Due): ₹$backDue", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                        if (advanceUsed > 0)
                          Text("- Advance Adjusted: ₹$advanceUsed", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                        const Divider(height: 12),
                        Text("NET TOTAL PAYABLE: ₹$netPayable", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, selectedBillDate);
                      if (p != null) setDialogState(() => selectedBillDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Bill Date: $dateFormatted", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_month, color: Color(0xFF0284C7), size: 20),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  String dateStr = dateFormatted;
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";
                  String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Used: ₹$advanceUsed" : "";

                  String msg = "*🎓 MONTHLY STUDENT FEE NOTICE*\n--------------------\nStudent: ${item['name']}\nRoll No: ${item['roomNo'] ?? 'N/A'}\nBill Date: $dateStr\n\nMonthly Fee: ₹$rent$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['extraWalletAdvance'] = extraWallet - advanceUsed;
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

                  if (target == 'student' || target == 'both') _sendWhatsApp(item['mobile'], msg);
                  if ((target == 'parents' || target == 'both') && item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty) {
                    _sendWhatsApp(item['parentMobile'], msg);
                  }
                },
                child: const Text("Generate & Send Bill", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenterOrHostelBillOptionDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("⚡ Bill Options for ${item['name']}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.electric_bolt),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: false);
              },
              label: const Text("1. Sirf Electricity Bill (Alag)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.house_rounded),
              onPressed: () {
                Navigator.pop(ctx);
                _openRentOnlyBill(item);
              },
              label: Text(item['pType'] == 'Hostel' ? "2. Sirf Hostel Rent Bill (Alag)" : "2. Sirf Room Rent Bill (Alag)", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.receipt_long_rounded),
              onPressed: () {
                Navigator.pop(ctx);
                _openElectricityCalculationDialog(item, isCombined: true);
              },
              label: Text(item['pType'] == 'Hostel' ? "3. Hostel Rent + Electricity (Combined)" : "3. Room Rent + Electricity (Combined)", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openRentOnlyBill(Map<String, dynamic> item) {
    DateTime billDate = DateTime.now();
    double rent = (item['rent'] as num).toDouble();
    double backDue = _getAccurateUnpaidDue(item, category: 'rent');
    double extraWallet = (item['extraWalletAdvance'] as num?)?.toDouble() ?? 0.0;
    double grossTotal = rent + backDue;
    double advanceUsed = (extraWallet > 0) ? (extraWallet >= grossTotal ? grossTotal : extraWallet) : 0.0;
    double netPayable = grossTotal - advanceUsed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String dateFormatted = "${billDate.year}-${billDate.month.toString().padLeft(2, '0')}-${billDate.day.toString().padLeft(2, '0')}";
          String billTitle = item['pType'] == 'Hostel' ? "Hostel Rent" : "Room Rent";

          return AlertDialog(
            title: Text("🏠 $billTitle Bill (${item['name']})", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly $billTitle: ₹$rent", style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (backDue > 0)
                          Text("+ Pichhla Rent Due: ₹$backDue", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                        if (advanceUsed > 0)
                          Text("- Advance Adjusted: ₹$advanceUsed", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                        const Divider(height: 12),
                        Text("NET TOTAL PAYABLE: ₹$netPayable", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, billDate);
                      if (p != null) setDialogState(() => billDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Rent Bill Date: $dateFormatted", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 20),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  String dateStr = dateFormatted;
                  String phone = item['mobile'];
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";
                  String dueText = backDue > 0 ? "\n+ Pichhla Rent Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Adjusted: ₹$advanceUsed" : "";

                  String msg = "*🏠 MONTHLY $billTitle BILL*\n--------------------\nName: ${item['name']}\nRoom/Bed: ${item['roomNo'] ?? 'N/A'}\nBill Date: $dateStr\n$billTitle: ₹$rent$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['extraWalletAdvance'] = extraWallet - advanceUsed;
                    item['history'].add({
                      'date': dateStr,
                      'type': '$billTitle Bill',
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
                child: const Text("Generate & Send Rent Bill", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openElectricityCalculationDialog(Map<String, dynamic> item, {required bool isCombined}) {
    final currentReadingCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: defaultUnitRateCtrl.text.isNotEmpty ? defaultUnitRateCtrl.text : '8');
    DateTime customElecDate = DateTime.now();
    double startUnits = (item['prevReading'] as num).toDouble();
    double backDue = isCombined 
        ? _getAccurateUnpaidDue(item, category: 'all')
        : _getAccurateUnpaidDue(item, category: 'electricity');
    double extraWallet = (item['extraWalletAdvance'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String elecDateFormatted = "${customElecDate.year}-${customElecDate.month.toString().padLeft(2, '0')}-${customElecDate.day.toString().padLeft(2, '0')}";
          String categoryLabel = item['pType'] == 'Hostel' ? 'Hostel Rent' : 'Room Rent';

          return AlertDialog(
            title: Text(isCombined ? "📋 Combined Bill (${item['name']})" : "⚡ Electricity Bill (${item['name']})", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📌 Purani Reading: $startUnits Units", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        if (isCombined)
                          Text("🏠 $categoryLabel: ₹${item['rent']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                        if (backDue > 0)
                          Text("+ Pichhla Baki (Due): ₹$backDue", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, customElecDate);
                      if (p != null) setDialogState(() => customElecDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Bill Date: $elecDateFormatted", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_month, color: Color(0xFF0284C7), size: 20),
                        ],
                      ),
                    ),
                  ),
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
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
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

                  double advanceUsed = (extraWallet > 0) ? (extraWallet >= grossTotal ? grossTotal : extraWallet) : 0.0;
                  double netPayable = grossTotal - advanceUsed;

                  String dateStr = elecDateFormatted;
                  String phone = item['mobile'];
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String upiNum = ownerUpiNumCtrl.text.isNotEmpty ? ownerUpiNumCtrl.text : "";

                  String billTitle = isCombined ? "MONTHLY ${item['pType'].toUpperCase()} & ELECTRICITY BILL" : "MONTHLY ELECTRICITY BILL";
                  String dueText = backDue > 0 ? "\n+ Back Due: ₹$backDue" : "";
                  String advText = advanceUsed > 0 ? "\n- Advance Adjusted: ₹$advanceUsed" : "";
                  String rentText = isCombined ? "$categoryLabel: ₹$rent\n" : "";

                  String msg = "*🏠 $billTitle*\n--------------------\nName: ${item['name']}\nRoom/Bed: ${item['roomNo'] ?? 'N/A'}\nBill Date: $dateStr\nPrevious Reading: $startUnits Units\nCurrent Reading: $endUnits Units\n*Consumed Units: $unitsUsed Units ($endUnits - $startUnits)*\nUnit Rate: ₹$rate / Unit\nElectricity Bill: $unitsUsed x ₹$rate = ₹$elecBill\n$rentText$dueText$advText--------------------\n*TOTAL PAYABLE: ₹$netPayable*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";

                  setState(() {
                    item['prevReading'] = endUnits; 
                    item['elecDate'] = dateStr;
                    item['extraWalletAdvance'] = extraWallet - advanceUsed;
                    item['history'].add({
                      'date': dateStr,
                      'type': isCombined ? '${item['pType']} + Electricity Bill' : 'Electricity Bill',
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
                child: const Text("Calculate & Send WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

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
            title: Text("💳 Payment: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📌 Type: ${billRecord['type']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Date: ${billRecord['date']}"),
                        Text("💰 Amount: ₹$total", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? p = await _selectCustomDate(context, paymentDate);
                      if (p != null) setDialogState(() => paymentDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Paid Date: $pDateFormatted", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 20),
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
                    decoration: const InputDecoration(labelText: "Kitna Paid Kiya (₹) *", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: enteredPaid >= total ? const Color(0xFFECFDF5) : (enteredPaid > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F2)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: enteredPaid >= total ? const Color(0xFF10B981) : (enteredPaid > 0 ? const Color(0xFFF59E0B) : const Color(0xFFF43F5E))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enteredPaid > total
                              ? "🎉 FULL PAID + ADVANCE CREDIT"
                              : (enteredPaid == total && total > 0
                                  ? "✅ Status: ALL PAID (Due: ₹0)"
                                  : (enteredPaid > 0 ? "⚠️ Status: PARTIAL DUE (Balance: ₹${remainingDue.toStringAsFixed(1)})" : "❌ Status: UNPAID (Due: ₹$total)")),
                          style: TextStyle(fontWeight: FontWeight.bold, color: enteredPaid >= total ? const Color(0xFF047857) : (enteredPaid > 0 ? const Color(0xFFB45309) : const Color(0xFFBE123C))),
                        ),
                        if (extraPaid > 0)
                          Text("💎 Extra ₹$extraPaid Advance Wallet me add hoga!", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  double finalPaid = double.tryParse(paidCtrl.text) ?? 0.0;
                  double extra = (finalPaid > total) ? (finalPaid - total) : 0.0;
                  double effectivePaid = (finalPaid > total) ? total : finalPaid;
                  
                  String newStatus = (finalPaid >= total) ? 'Paid' : (finalPaid > 0 ? 'Partial' : 'Pending');

                  setState(() {
                    if (extra > 0) item['extraWalletAdvance'] = ((item['extraWalletAdvance'] as num?)?.toDouble() ?? 0.0) + extra;
                    billRecord['paidAmount'] = effectivePaid;
                    billRecord['paymentDate'] = pDateFormatted;
                    billRecord['status'] = newStatus;
                  });
                  _saveRentersToStorage();

                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String extraNote = extra > 0 ? "\n🎉 Extra ₹$extra Advance Wallet me add ho gaya hai." : "";
                  String receiptMsg = "*🧾 PAYMENT ACKNOWLEDGEMENT / RECEIPT*\n--------------------\nName: ${item['name']}\nPayment Date: $pDateFormatted\nTotal Bill: ₹$total\n*Amount Paid: ₹$finalPaid*\n*Remaining Due: ₹${(total - finalPaid).clamp(0, double.infinity)}*$extraNote\nStatus: $newStatus\n--------------------\nReceived By: $oName\nDhanyawad!";
                  _sendWhatsApp(item['mobile'], receiptMsg);
                },
                child: const Text("Save & Send Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

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
    String roomTag = isStudent ? "Roll No" : "Room/Bed";

    String msg = "";
    if (isStudent) {
      msg = "*🎓 MONTHLY STUDENT FEE NOTICE (REMINDER)*\n--------------------\nStudent: ${item['name']}\n$roomTag: ${item['roomNo'] ?? 'N/A'}\nBill Date: ${billRecord['date']}\n\nMonthly Fee: ₹${billRecord['rentAmount']}$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
    } else {
      String type = billRecord['type'] ?? 'Room Rent Bill';
      if (type.contains('Electricity')) {
        String unitsDetails = (billRecord['unitsUsed'] != null && billRecord['unitsUsed'] > 0)
            ? "Meter Reading: ${billRecord['startUnits']} to ${billRecord['endUnits']}\nConsumed Units: ${billRecord['unitsUsed']} Units\nElectricity Amount: ₹${billRecord['elecBill']}\n"
            : "";
        String rentDetails = (billRecord['rentAmount'] != null && billRecord['rentAmount'] > 0) ? "Rent: ₹${billRecord['rentAmount']}\n" : "";
        msg = "*🏠 $type (REMINDER)*\n--------------------\nName: ${item['name']}\n$roomTag: ${item['roomNo'] ?? 'N/A'}\nBill Date: ${billRecord['date']}\n$unitsDetails$rentDetails$dueText$advText--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
      } else {
        msg = "*🏠 MONTHLY ${item['pType'].toUpperCase()} BILL (REMINDER)*\n--------------------\nName: ${item['name']}\n$roomTag: ${item['roomNo'] ?? 'N/A'}\nBill Date: ${billRecord['date']}\nRent: ₹${billRecord['rentAmount']}$dueText$advText\n--------------------\n*TOTAL PAYABLE: ₹$total*\n--------------------\n*Pay To:*\nName: $oName\nUPI ID: $upi\nUPI Mobile: $upiNum\n\nDhanyawad!";
      }
    }

    if (item['pType'] == 'Renter') {
      _sendWhatsApp(item['mobile'], msg);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill WhatsApp Par Bhej Diya Gaya!")));
      return;
    }

    String resendTarget = 'both';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: const Text("📲 Send Bill on WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Bill Amount: ₹$total (${billRecord['date']})"),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: resendTarget,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: "both", child: Text("1. Dono Ko (Member + Parents)")),
                  const DropdownMenuItem(value: "student", child: Text("2. Sirf Member Ko")),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                if (resendTarget == 'student' || resendTarget == 'both') _sendWhatsApp(item['mobile'], msg);
                if ((resendTarget == 'parents' || resendTarget == 'both') && item['parentMobile'] != null && item['parentMobile'].toString().isNotEmpty) {
                  _sendWhatsApp(item['parentMobile'], msg);
                }
              },
              child: const Text("Send WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text("📜 Bill History: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          cardBgColor = const Color(0xFFECFDF5);
                          statusBadgeColor = const Color(0xFF10B981);
                          statusBadgeText = "PAID ✅";
                        } else if (paid > 0 && paid < total) {
                          cardBgColor = const Color(0xFFFFFBEB);
                          statusBadgeColor = const Color(0xFFF59E0B);
                          statusBadgeText = "PARTIAL: ₹${remaining.toStringAsFixed(0)} ⚠️";
                        } else if (total == 0 && (h['status'] == 'Paid')) {
                          cardBgColor = const Color(0xFFECFDF5);
                          statusBadgeColor = const Color(0xFF10B981);
                          statusBadgeText = "PAID (Advance) ✅";
                        } else {
                          cardBgColor = const Color(0xFFFFF1F2);
                          statusBadgeColor = const Color(0xFFF43F5E);
                          statusBadgeText = "UNPAID ❌";
                        }

                        return Card(
                          color: cardBgColor,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusBadgeColor.withOpacity(0.5), width: 1.5)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openPaymentRecordDialog(item, h),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(h['type'] ?? 'Bill', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: statusBadgeColor, borderRadius: BorderRadius.circular(8)),
                                        child: Text(statusBadgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("📅 ${h['date']}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      Text("Total: ₹$total", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Paid Date: ${h['paymentDate'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      Text("Paid: ₹$paid", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                    ],
                                  ),
                                  if (h['advanceUsed'] != null && (h['advanceUsed'] as num) > 0)
                                    Text("💎 Advance Adjusted: ₹${h['advanceUsed']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                                  if (remaining > 0 && paid > 0)
                                    Text("⚠️ Remaining Due: ₹${remaining.toStringAsFixed(1)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                        onPressed: () => _openResendChoiceDialog(item, h),
                                        icon: const Icon(Icons.send_rounded, size: 12, color: Color(0xFF25D366)),
                                        label: const Text("Send Bill 🔁", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                        onPressed: () => _openPaymentRecordDialog(item, h),
                                        child: const Text("Update Pay 💳", style: TextStyle(fontSize: 11)),
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

  void _openAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Electricity Bill';
    DateTime expenseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: const Text("💸 Add Property Expense", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "Electricity Bill", child: Text("⚡ Main Electricity Bill")),
                    DropdownMenuItem(value: "Plumber/Electrician", child: Text("🔧 Repair & Maintenance")),
                    DropdownMenuItem(value: "Staff Salary", child: Text("🧹 Staff / Cleaning Salary")),
                    DropdownMenuItem(value: "WiFi/Internet", child: Text("📶 WiFi Bill")),
                    DropdownMenuItem(value: "Other", child: Text("📦 Other Expense")),
                  ],
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Expense Description / Notes", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹) *", border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
              onPressed: () {
                double amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) return;
                setState(() {
                  expenses.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'category': category,
                    'title': titleCtrl.text.trim().isEmpty ? category : titleCtrl.text.trim(),
                    'amount': amt,
                    'date': "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}",
                  });
                });
                _saveExpensesToStorage();
                Navigator.pop(ctx);
              },
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddComplaintDialog() {
    final titleCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    String priority = 'Normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: const Text("🛠️ Log Member Issue", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Room / Member Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Issue Details (e.g. Fan problem, Water leak)", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: "Priority", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "Urgent", child: Text("🚨 Urgent")),
                    DropdownMenuItem(value: "Normal", child: Text("⚠️ Normal")),
                  ],
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  complaints.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'room': roomCtrl.text.trim(),
                    'title': titleCtrl.text.trim(),
                    'priority': priority,
                    'status': 'Pending',
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                _saveComplaintsToStorage();
                Navigator.pop(ctx);
              },
              child: const Text("Log Issue"),
            ),
          ],
        ),
      ),
    );
  }

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
          if (data['expenses'] != null) expenses = List<Map<String, dynamic>>.from(data['expenses']);
          if (data['complaints'] != null) complaints = List<Map<String, dynamic>>.from(data['complaints']);
          if (data['profile'] != null) ownerProfile = Map<String, dynamic>.from(data['profile']);
        });
        await _saveRentersToStorage();
        await _saveExpensesToStorage();
        await _saveComplaintsToStorage();
        await _saveOwnerProfile();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Restored Successfully!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Backup File!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.domain_rounded, color: Colors.amberAccent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : 'RentManager Pro',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  onPressed: _openOwnerProfileSheet,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 3,
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: "Dashboard"),
                  Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 18), text: "+ New Entry"),
                  Tab(icon: Icon(Icons.folder_shared_rounded, size: 18), text: "Total Members (Data)"),
                  Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 18), text: "Expenses & Issues"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardView(),
            _buildNewEntryForm(),
            _buildRegisteredListView(),
            _buildExpensesAndComplaintsView(),
          ],
        ),
      ),
    );
  }

  // 1. ULTRA MODERN DASHBOARD VIEW
  Widget _buildDashboardView() {
    double totalCollected = 0.0;
    double totalPendingDue = 0.0;
    double totalSecurity = 0.0;
    int activeResidents = 0;

    for (var r in renters) {
      if (r['isClosed'] != true) {
        activeResidents++;
        totalSecurity += (r['securityDeposit'] ?? r['advance'] ?? 0.0) as double;
        totalPendingDue += _getAccurateUnpaidDue(r);
        if (r['history'] != null) {
          for (var h in r['history']) {
            totalCollected += (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }

    double totalExpenseAmt = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    double netProfit = totalCollected - totalExpenseAmt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Floating Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sendBulkReminders,
                    icon: const Icon(Icons.notifications_active_rounded, size: 18),
                    label: const Text("📢 Bulk Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF14B8A6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text("+ Add Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Modern 4 Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildGlassMetricCard(
                  title: "TOTAL COLLECTED",
                  value: "₹${totalCollected.toStringAsFixed(0)}",
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF059669),
                  gradientColors: [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  borderColor: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGlassMetricCard(
                  title: "MARKET DUE (BAKI)",
                  value: "₹${totalPendingDue.toStringAsFixed(0)}",
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFE11D48),
                  gradientColors: [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
                  borderColor: const Color(0xFFF43F5E).withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGlassMetricCard(
                  title: "TOTAL MEMBERS",
                  value: "$activeResidents Active",
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF0284C7),
                  gradientColors: [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                  borderColor: const Color(0xFF38BDF8).withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGlassMetricCard(
                  title: "NET PROFIT",
                  value: "₹${netProfit.toStringAsFixed(0)}",
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  gradientColors: [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                  borderColor: const Color(0xFFA78BFA).withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security Deposit Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text("Security Deposit Held", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                Text("₹${totalSecurity.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Upcoming Dues
          const Text("🔔 Rent/Fee Due in Next 3 Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          _buildUpcomingDuesList(),
        ],
      ),
    );
  }

  Widget _buildGlassMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: iconColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconColor, letterSpacing: 0.5)),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }

  Widget _buildUpcomingDuesList() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> upcoming = renters.where((r) {
      if (r['isClosed'] == true) return false;
      try {
        DateTime due = DateTime.parse(r['nextDueDate']);
        int diff = due.difference(now).inDays;
        return diff >= -1 && diff <= 4;
      } catch (_) {
        return false;
      }
    }).toList();

    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 10),
            Text("Sabhi payments time par hain! Agle 3 din me koi due nahi.", style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: upcoming.length,
      itemBuilder: (c, idx) {
        final item = upcoming[idx];
        String icon = item['pType'] == 'Student' ? "🎓" : (item['pType'] == 'Hostel' ? "🏢" : "🏠");
        String roomLabel = item['pType'] == 'Student' ? "Roll No" : "Room";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200, width: 1.2)),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(backgroundColor: const Color(0xFFF8FAFC), child: Text(icon, style: const TextStyle(fontSize: 18))),
            title: Text("${item['name']} ($roomLabel: ${item['roomNo'] ?? 'N/A'})", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Due: ${item['nextDueDate']} | ₹${item['rent']}", style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
            trailing: IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
              onPressed: () {
                String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                String msg = "*🔔 RENT/FEE DUE REMINDER*\n--------------------\nName: ${item['name']}\n$roomLabel: ${item['roomNo'] ?? 'N/A'}\nDue Date: ${item['nextDueDate']}\nAmount: ₹${item['rent']}\nOwner: $oName";
                _sendWhatsApp(item['mobile'], msg);
              },
            ),
          ),
        );
      },
    );
  }

  // 2. TOTAL MEMBERS (DATA) VIEW
  Widget _buildRegisteredListView() {
    List<Map<String, dynamic>> filtered = renters;
    if (listFilter == 'Student') {
      filtered = renters.where((r) => r['pType'] == 'Student' && (r['isClosed'] != true)).toList();
    } else if (listFilter == 'Hostel') {
      filtered = renters.where((r) => r['pType'] == 'Hostel' && (r['isClosed'] != true)).toList();
    } else if (listFilter == 'Renter') {
      filtered = renters.where((r) => r['pType'] == 'Renter' && (r['isClosed'] != true)).toList();
    } else if (listFilter == 'Closed') {
      filtered = renters.where((r) => r['isClosed'] == true).toList();
    } else {
      filtered = List.from(renters);
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All (${renters.length})", 'all'),
                const SizedBox(width: 6),
                _buildFilterChip("🎓 Students", 'Student'),
                const SizedBox(width: 6),
                _buildFilterChip("🏢 Hostel", 'Hostel'),
                const SizedBox(width: 6),
                _buildFilterChip("🏠 Renters", 'Renter'),
                const SizedBox(width: 6),
                _buildFilterChip("🚪 Closed (${renters.where((r) => r['isClosed'] == true).length})", 'Closed'),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text("Koi record nahi mila.", style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered[i];
                    bool isStudent = (r['pType'] == 'Student');
                    bool isHostel = (r['pType'] == 'Hostel');
                    bool isClosed = (r['isClosed'] == true);
                    double currentDue = _getAccurateUnpaidDue(r, category: 'all');
                    double securityDeposit = (r['securityDeposit'] ?? r['advance'] ?? 0.0) as double;
                    bool hasHistory = (r['history'] != null && (r['history'] as List).isNotEmpty);
                    bool isFullyPaid = (currentDue == 0 && hasHistory);
                    bool isPartial = (currentDue > 0 && hasHistory);

                    Color statusColor = const Color(0xFFF43F5E);
                    String statusText = "UNPAID (Due: ₹$currentDue)";
                    if (isClosed) {
                      statusColor = const Color(0xFF64748B);
                      statusText = "LEFT / CLOSED 🚫";
                    } else if (isFullyPaid) {
                      statusColor = const Color(0xFF10B981);
                      statusText = "ALL PAID ✅";
                    } else if (isPartial) {
                      statusColor = const Color(0xFFF59E0B);
                      statusText = "DUE: ₹$currentDue";
                    }

                    String categoryIcon = isStudent ? "🎓" : (isHostel ? "🏢" : "🏠");
                    String roomDisplay = isStudent
                        ? (r['roomNo'] != null && r['roomNo'].toString().isNotEmpty ? '(Roll: ' + r['roomNo'] + ')' : '')
                        : (r['roomNo'] != null && r['roomNo'].toString().isNotEmpty ? '(Room: ' + r['roomNo'] + ')' : '');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      elevation: 0,
                      color: isClosed ? const Color(0xFFF8FAFC) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: statusColor.withOpacity(0.5), width: isClosed ? 1 : 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(categoryIcon, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text("${r['name']} $roomDisplay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: isClosed ? TextDecoration.lineThrough : null)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                                      child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    if (!isClosed)
                                      IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F766E), size: 22), onPressed: () => _showEditDialog(r)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        setState(() => renters.removeWhere((item) => item['id'] == r['id']));
                                        _saveRentersToStorage();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text("📱 Phone: ${r['mobile']} ${r['parentMobile'] != '' && r['parentMobile'] != null ? '\n👨‍👩‍👦 Parents: ' + r['parentMobile'] : ''}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (r['address'] != null && r['address'].toString().isNotEmpty)
                              Text("📍 Addr: ${r['address']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            Text("🗓 Joining: ${r['entryDate']} ${!isClosed ? '| Next Due: ' + r['nextDueDate'].toString() : ''}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            if (!isStudent && r['elecDate'] != null)
                              Text("⚡ Elec Date: ${r['elecDate']}", style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Fixed ${isStudent ? 'Fee' : 'Rent'}: ₹${r['rent']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                if (securityDeposit > 0)
                                  Text("🔒 Security: ₹$securityDeposit", style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (!isStudent)
                              Text("⚡ Current Reading: ${r['prevReading']} Units", style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (!isClosed) ...[
                                  if (isStudent) ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _openStudentGenerateBillDialog(r),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                      label: const Text("⚡ Bill", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ] else ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _showRenterOrHostelBillOptionDialog(r),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                      label: const Text("⚡ Bill", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  OutlinedButton.icon(
                                    onPressed: () => _sharePoliceVerificationForm(r),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    icon: const Icon(Icons.description_outlined, size: 14, color: Color(0xFF0F766E)),
                                    label: const Text("Doc / ID", style: TextStyle(fontSize: 11, color: Color(0xFF0F766E))),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _openCloseAccountDialog(r),
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE11D48), side: BorderSide(color: Colors.red.shade300), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    icon: const Icon(Icons.exit_to_app_rounded, size: 14),
                                    label: const Text("Close 🚪", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => _showHistoryDialog(r),
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                  icon: const Icon(Icons.history_rounded, size: 14, color: Color(0xFF10B981)),
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

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = (listFilter == value);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF0F766E),
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) => setState(() => listFilter = value),
    );
  }

  // 3. NEW REGISTRATION FORM VIEW
  Widget _buildNewEntryForm() {
    bool isStudent = (personType == 'Student');
    bool isRenterOrHostel = (personType == 'Renter' || personType == 'Hostel');
    String rentDateStr = "${rentEntryDate.year}-${rentEntryDate.month.toString().padLeft(2, '0')}-${rentEntryDate.day.toString().padLeft(2, '0')}";
    String elecDateStr = "${elecStartDate.year}-${elecStartDate.month.toString().padLeft(2, '0')}-${elecStartDate.day.toString().padLeft(2, '0')}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("📝 New Resident Registration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: personType,
                decoration: const InputDecoration(labelText: "Category Select Karein *", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Student", child: Text("🎓 Student")),
                  DropdownMenuItem(value: "Hostel", child: Text("🏢 Hostel")),
                  DropdownMenuItem(value: "Renter", child: Text("🏠 Renter / Family")),
                ],
                onChanged: (v) => setState(() => personType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isStudent ? "Student Full Name *" : "Member / Head Full Name *", border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: isStudent ? "Student WhatsApp No. *" : "Member WhatsApp No. *", border: const OutlineInputBorder())),
              if (isStudent || personType == 'Hostel') ...[
                const SizedBox(height: 10),
                TextField(controller: parentMobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents WhatsApp Number", border: OutlineInputBorder())),
              ],
              const SizedBox(height: 10),
              TextField(controller: fatherCtrl, decoration: InputDecoration(labelText: isStudent ? "Father / Parents Name *" : "Father's Name", border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: roomOrRollCtrl,
                decoration: InputDecoration(
                  labelText: isStudent ? "Student Roll Number *" : "Room / Bed / Flat No. (e.g. 102-A) *",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, maxLines: 2, decoration: InputDecoration(labelText: isStudent ? "Student Permanent Address *" : "Permanent Address *", border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  DateTime? p = await _selectCustomDate(context, rentEntryDate);
                  if (p != null) setState(() => rentEntryDate = p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isStudent ? "🗓 Joining Date: $rentDateStr" : "🗓 Rent Entry Date: $rentDateStr", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const Icon(Icons.calendar_month, color: Color(0xFF0F766E)),
                    ],
                  ),
                ),
              ),
              if (isRenterOrHostel) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    DateTime? p = await _selectCustomDate(context, elecStartDate);
                    if (p != null) setState(() => elecStartDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
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
              TextField(controller: idNumCtrl, decoration: const InputDecoration(labelText: "Identity / Document Number", border: OutlineInputBorder())),
              if (isRenterOrHostel) ...[
                const SizedBox(height: 10),
                TextField(controller: initialReadingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Meter Reading (e.g. 1200)", border: OutlineInputBorder())),
              ],
              const SizedBox(height: 10),
              TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isStudent ? "Monthly Student Fee (₹) *" : "Monthly Room Rent (₹) *", border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit / Advance Paid (₹)", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage('student'), icon: const Icon(Icons.camera_alt), label: Text(studentImgBase64 == null ? "Photo" : "✅ Photo Added"))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage('idCard'), icon: const Icon(Icons.badge), label: Text(idCardImgBase64 == null ? "ID Proof" : "✅ ID Added"))),
                ],
              ),
              const SizedBox(height: 12),
              if (isStudent || personType == 'Hostel')
                DropdownButtonFormField<String>(
                  value: sendToTarget,
                  decoration: const InputDecoration(labelText: "Welcome Message Kise Bhejna Hai?", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "student", child: Text("1. Sirf Member WhatsApp Par")),
                    DropdownMenuItem(value: "parents", child: Text("2. Sirf Parents WhatsApp Par")),
                  ],
                  onChanged: (v) => setState(() => sendToTarget = v!),
                ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _saveNewRegistration,
                  child: const Text("💾 Save & Send Welcome Rules", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. EXPENSES & COMPLAINTS VIEW
  Widget _buildExpensesAndComplaintsView() {
    double totalExpenseAmt = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("💸 Expenses: ₹${totalExpenseAmt.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE11D48))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                onPressed: _openAddExpenseDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Expense"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          expenses.isEmpty
              ? Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text("Abhi koi property expense add nahi hai.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (c, idx) {
                    final exp = expenses[idx];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt_rounded, color: Color(0xFFE11D48)),
                        title: Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Date: ${exp['date']} | ${exp['category']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("₹${exp['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE11D48))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
                              onPressed: () {
                                setState(() => expenses.removeAt(idx));
                                _saveExpensesToStorage();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🛠️ Issues (${complaints.where((c) => c['status'] == 'Pending').length} Open)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white),
                onPressed: _openAddComplaintDialog,
                icon: const Icon(Icons.report_problem_rounded, size: 16),
                label: const Text("Log Issue"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          complaints.isEmpty
              ? Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text("Koi complaint ya repair issue nahi hai.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  itemBuilder: (c, idx) {
                    final cmp = complaints[idx];
                    bool isPending = cmp['status'] == 'Pending';
                    return Card(
                      elevation: 0,
                      color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isPending ? Colors.amber.shade300 : Colors.green.shade300)),
                      child: ListTile(
                        dense: true,
                        leading: Icon(isPending ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: isPending ? const Color(0xFFD97706) : const Color(0xFF10B981)),
                        title: Text("${cmp['title']} (Room: ${cmp['room'] ?? 'N/A'})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Logged: ${cmp['date']} | Priority: ${cmp['priority']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isPending ? const Color(0xFFD97706) : const Color(0xFF10B981), foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() => cmp['status'] = isPending ? 'Resolved' : 'Pending');
                            _saveComplaintsToStorage();
                          },
                          child: Text(isPending ? "OPEN 🔴" : "RESOLVED 🟢", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _openOwnerProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("⚙️ Owner & Property Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          backgroundColor: const Color(0xFF0F766E),
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
                TextField(controller: propertyNameCtrl, decoration: const InputDecoration(labelText: "Hostel / Residency / Institute Name", border: OutlineInputBorder())),
                const SizedBox(height: 8),
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
                TextField(controller: studentWelcomeRulesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "🎓 Student & Hostel Welcome Rules", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: renterWelcomeRulesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "🏠 Renter Welcome Rules", border: OutlineInputBorder())),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), minimumSize: const Size(double.infinity, 45)),
                  onPressed: () {
                    _saveOwnerProfile();
                    Navigator.pop(ctx);
                  },
                  child: const Text("💾 Save Profile & Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 25),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _exportJsonBackup, icon: const Icon(Icons.download), label: const Text("Backup Data"))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: _importJsonBackup, icon: const Icon(Icons.upload_file), label: const Text("Restore Data"))),
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
