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
        scaffoldBackgroundColor: const Color(0xFF0B132B), // Dark Luxury Background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C2541),
          primary: const Color(0xFFFFB703), // Elegant Gold/Amber Accent
          surface: const Color(0xFF1C2541),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C2541),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFB703), width: 2)),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            backgroundColor: const Color(0xFFFFB703),
            foregroundColor: const Color(0xFF0B132B),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        dialogTheme: DialogTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: const Color(0xFF1C2541)),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1C2541), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
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

    if (rentersData != null) setState(() => renters = List<Map<String, dynamic>>.from(json.decode(rentersData)));
    if (expensesData != null) setState(() => expenses = List<Map<String, dynamic>>.from(json.decode(expensesData)));
    if (complaintsData != null) setState(() => complaints = List<Map<String, dynamic>>.from(json.decode(complaintsData)));

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
      studentWelcomeRulesCtrl.text = ownerProfile['studentRules'] ?? "🎓 *STUDENT & HOSTEL RULES*\n1. Monthly fee/rent due every 30 days.\n2. Keep premises clean.\n3. Follow silent hours.";
      renterWelcomeRulesCtrl.text = ownerProfile['renterRules'] ?? "🏠 *RENTER RULES*\n1. Room rent due monthly.\n2. Electricity meter reading cycle starts from 1st.";
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
      'name': ownerNameCtrl.text, 'email': ownerEmailCtrl.text, 'phone': ownerPhoneCtrl.text,
      'upiId': ownerUpiIdCtrl.text, 'upiNum': ownerUpiNumCtrl.text, 'unitRate': defaultUnitRateCtrl.text,
      'propertyName': propertyNameCtrl.text, 'photo': ownerPhotoBase64,
      'studentRules': studentWelcomeRulesCtrl.text, 'renterRules': renterWelcomeRulesCtrl.text,
    };
    await prefs.setString('owner_profile', json.encode(ownerProfile));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile & Settings Saved!")));
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
    return await showDatePicker(context: context, initialDate: initDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
  }

  void _sendWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number missing ya galat hai!")));
      return;
    }
    if (clean.length == 10) clean = '91$clean';
    else if (clean.length == 11 && clean.startsWith('0')) clean = '91${clean.substring(1)}';

    final encodedText = Uri.encodeComponent(text);
    final Uri appIntent = Uri.parse("whatsapp://send?phone=$clean&text=$encodedText");
    final Uri universalUrl = Uri.parse("https://api.whatsapp.com/send?phone=$clean&text=$encodedText");

    bool launched = false;
    try { launched = await launchUrl(appIntent, mode: LaunchMode.externalApplication); } catch (_) {}
    if (!launched) { try { launched = await launchUrl(universalUrl, mode: LaunchMode.externalApplication); } catch (_) {} }
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
        title: Text("📢 Bulk Reminders (${unpaidList.length} Unpaid)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text("$roomLabel | Total Due: ₹$due", style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
                  onPressed: () {
                    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                    String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                    String msg = "*📢 PAYMENT DUE REMINDER*\n--------------------\nName: ${item['name']}\n$roomLabel\n*Pending Due: ₹$due*\n--------------------\nKripya baki amount jald jama karein.\nUPI ID: $upi\nOwner: $oName";
                    _sendWhatsApp(item['mobile'], msg);
                  },
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFFFFB703))))],
      ),
    );
  }

  void _sharePoliceVerificationForm(Map<String, dynamic> item) {
    String pName = propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : "Institute / Hostel";
    String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Property Manager";
    String oPhone = ownerPhoneCtrl.text.isNotEmpty ? ownerPhoneCtrl.text : "";
    bool isStudent = (item['pType'] == 'Student');

    String verificationDoc = "==============================\n📋 MEMBER RECORD & VERIFICATION\n==============================\nProperty: $pName\n\n1. Full Name: ${item['name']}\n2. Category: ${item['pType']}\n3. ${isStudent ? 'Roll Number' : 'Room No'}: ${item['roomNo'] ?? 'N/A'}\n4. Mobile: ${item['mobile']}\n5. Parents Mobile: ${item['parentMobile'] ?? 'N/A'}\n6. Father Name: ${item['father'] ?? 'N/A'}\n7. Address: ${item['address'] ?? 'N/A'}\n8. ID No: ${item['idNum'] ?? 'N/A'}\n9. Joining Date: ${item['entryDate']}\n10. Monthly Rent/Fee: ₹${item['rent']}\n11. Security Deposit: ₹${item['securityDeposit'] ?? 0}\n\nOwner: $oName\nContact: $oPhone\n==============================";
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

    String msg = "Namaste ${nameCtrl.text.trim()} ji,\n\n$welcomeRules\n\n📌 Registration Details:\nCategory: $personType\n$roomLabel: ${roomOrRollCtrl.text.trim()}\nJoining Date: $rentDateStr\nNext Due Date: $nextDueDateStr\n$feeLabel: ₹${rentCtrl.text}\nSecurity Deposit Paid: ₹${advanceCtrl.text}\n\nOwner: $ownerName\nContact: $ownerPhone";

    String sendPhone = (sendToTarget == 'parents' && parentMobileCtrl.text.trim().isNotEmpty) ? parentMobileCtrl.text.trim() : mobileCtrl.text.trim();
    _sendWhatsApp(sendPhone, msg);

    nameCtrl.clear(); mobileCtrl.clear(); parentMobileCtrl.clear(); fatherCtrl.clear(); addressCtrl.clear(); roomOrRollCtrl.clear(); idNumCtrl.clear(); rentCtrl.clear(); advanceCtrl.text = '0'; initialReadingCtrl.text = '0';
    setState(() { rentEntryDate = DateTime.now(); elecStartDate = DateTime.now(); studentImgBase64 = null; idCardImgBase64 = null; });

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
        title: Text("✏️ Edit: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: eName, decoration: const InputDecoration(labelText: "Full Name")),
              const SizedBox(height: 10),
              TextField(controller: eMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number")),
              if (isStudent || item['pType'] == 'Hostel') ...[
                const SizedBox(height: 10),
                TextField(controller: eParentMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number")),
              ],
              const SizedBox(height: 10),
              TextField(controller: eFather, decoration: const InputDecoration(labelText: "Father / Guardian Name")),
              const SizedBox(height: 10),
              TextField(controller: eRoomNo, decoration: InputDecoration(labelText: isStudent ? "Student Roll Number" : "Room / Bed / Flat No.")),
              const SizedBox(height: 10),
              TextField(controller: eAddress, decoration: const InputDecoration(labelText: "Address")),
              const SizedBox(height: 10),
              TextField(controller: eEntryDate, decoration: InputDecoration(labelText: isStudent ? "Joining Date (YYYY-MM-DD)" : "Rent Entry Date (YYYY-MM-DD)")),
              if (isRenterOrHostel) ...[
                const SizedBox(height: 10),
                TextField(controller: eElecDate, decoration: const InputDecoration(labelText: "Electricity Cycle Date (YYYY-MM-DD)")),
              ],
              const SizedBox(height: 10),
              TextField(controller: eDueDate, decoration: const InputDecoration(labelText: "Next Due Date (YYYY-MM-DD)")),
              const SizedBox(height: 10),
              TextField(controller: eRent, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isStudent ? "Monthly Student Fee (₹)" : "Monthly Rent (₹)")),
              const SizedBox(height: 10),
              TextField(controller: eSecurity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit Paid (₹)")),
              if (isRenterOrHostel) ...[
                const SizedBox(height: 10),
                TextField(controller: ePrevReading, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Meter Reading (Units)")),
              ],
              const SizedBox(height: 10),
              TextField(controller: eIdNum, decoration: const InputDecoration(labelText: "Identity / Document No")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
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
            title: Text("🚪 Final Settlement: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🗓 Joining Date: ${item['entryDate']}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        Text("🔒 Security Deposit: ₹$security", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB703))),
                        Text("⚠️ Unpaid Due: ₹$unpaidDue", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
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
                      decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("📅 Leaving Date: $leaveDateFormatted", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          const Icon(Icons.calendar_month, color: Color(0xFFFFB703), size: 20),
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
                      decoration: InputDecoration(labelText: "Final Meter Reading (Prev: $startUnits)"),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRefund ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFF7F1D1D).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isRefund ? Colors.green : Colors.red, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isRefund ? "💰 REFUND TO MEMBER:" : "⚠️ COLLECT FROM MEMBER:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isRefund ? Colors.greenAccent : Colors.redAccent)),
                        const SizedBox(height: 4),
                        Text("₹${netBalance.abs().toStringAsFixed(1)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isRefund ? Colors.greenAccent : Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  String oName = ownerNameCtrl.text.isNotEmpty ? ownerNameCtrl.text : "Owner";
                  String settlementText = isRefund ? "*₹${netBalance.abs().toStringAsFixed(1)} Refund kiya gaya.*" : "*₹${netBalance.abs().toStringAsFixed(1)} Collect kiya gaya.*";
                  String nocMsg = "*📜 FINAL SETTLEMENT NOTICE*\nName: ${item['name']}\nLeaving Date: $leaveDateFormatted\nSecurity: ₹$security\nTotal Due: ₹$totalDueToPay\n*RESULT:* $settlementText\n*Status: CLEARED & CLOSED ✅*\nOwner: $oName";
                  setState(() {
                    item['isClosed'] = true;
                    item['closedDate'] = leaveDateFormatted;
                  });
                  _saveRentersToStorage();
                  _sendWhatsApp(item['mobile'], nocMsg);
                },
                child: const Text("Confirm & Close Account"),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          String dateFormatted = "${selectedBillDate.year}-${selectedBillDate.month.toString().padLeft(2, '0')}-${selectedBillDate.day.toString().padLeft(2, '0')}";
          return AlertDialog(
            title: Text("⚡ Fee Notice: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monthly Fee: ₹$rent", style: const TextStyle(color: Colors.white)),
                  if (backDue > 0) Text("+ Back Due: ₹$backDue", style: const TextStyle(color: Colors.redAccent)),
                  if (advanceUsed > 0) Text("- Advance Used: ₹$advanceUsed", style: const TextStyle(color: Colors.greenAccent)),
                  const Divider(color: Colors.white24),
                  Text("NET TOTAL: ₹$netPayable", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFB703))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  String upi = ownerUpiIdCtrl.text.isNotEmpty ? ownerUpiIdCtrl.text : "Not Set";
                  String msg = "*🎓 STUDENT FEE NOTICE*\nName: ${item['name']}\nDate: $dateFormatted\n*TOTAL PAYABLE: ₹$netPayable*\nUPI: $upi";
                  setState(() {
                    item['extraWalletAdvance'] = extraWallet - advanceUsed;
                    item['history'].add({
                      'date': dateFormatted, 'type': 'Monthly Fee', 'totalPayable': netPayable, 'paidAmount': 0.0, 'paymentDate': '-', 'status': 'Pending', 'backDue': backDue, 'advanceUsed': advanceUsed, 'rentAmount': rent
                    });
                  });
                  _saveRentersToStorage();
                  _sendWhatsApp(item['mobile'], msg);
                },
                child: const Text("Generate & Send Bill"),
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
            Text("⚡ Bill Options for ${item['name']}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.electric_bolt),
              onPressed: () { Navigator.pop(ctx); _openElectricityCalculationDialog(item, isCombined: false); },
              label: const Text("1. Electricity Bill Only"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.house_rounded),
              onPressed: () { Navigator.pop(ctx); _openRentOnlyBill(item); },
              label: const Text("2. Rent Bill Only"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long_rounded),
              onPressed: () { Navigator.pop(ctx); _openElectricityCalculationDialog(item, isCombined: true); },
              label: const Text("3. Combined Rent + Electricity"),
            ),
          ],
        ),
      ),
    );
  }

  void _openRentOnlyBill(Map<String, dynamic> item) {
    double rent = (item['rent'] as num).toDouble();
    double backDue = _getAccurateUnpaidDue(item, category: 'rent');
    double netPayable = rent + backDue;
    String dateStr = DateTime.now().toString().split(' ')[0];

    setState(() {
      item['history'].add({
        'date': dateStr, 'type': 'Rent Bill', 'totalPayable': netPayable, 'paidAmount': 0.0, 'paymentDate': '-', 'status': 'Pending', 'rentAmount': rent, 'backDue': backDue
      });
    });
    _saveRentersToStorage();
    _sendWhatsApp(item['mobile'], "*🏠 RENT BILL*\nName: ${item['name']}\n*TOTAL PAYABLE: ₹$netPayable*");
  }

  void _openElectricityCalculationDialog(Map<String, dynamic> item, {required bool isCombined}) {
    final currentReadingCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: defaultUnitRateCtrl.text.isNotEmpty ? defaultUnitRateCtrl.text : '8');
    double startUnits = (item['prevReading'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCombined ? "📋 Combined Bill" : "⚡ Electricity Bill", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Previous Reading: $startUnits Units", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(controller: currentReadingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Current Reading *")),
            const SizedBox(height: 10),
            TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Per Unit Rate (₹)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              double endUnits = double.tryParse(currentReadingCtrl.text) ?? 0.0;
              if (endUnits < startUnits) return;
              Navigator.pop(ctx);
              double rate = double.tryParse(rateCtrl.text) ?? 8.0;
              double unitsUsed = endUnits - startUnits;
              double elecBill = unitsUsed * rate;
              double rent = isCombined ? (item['rent'] as num).toDouble() : 0.0;
              double netPayable = elecBill + rent;
              String dateStr = DateTime.now().toString().split(' ')[0];

              setState(() {
                item['prevReading'] = endUnits;
                item['history'].add({
                  'date': dateStr, 'type': isCombined ? 'Rent + Electricity' : 'Electricity Bill', 'unitsUsed': unitsUsed, 'elecBill': elecBill, 'totalPayable': netPayable, 'paidAmount': 0.0, 'status': 'Pending'
                });
              });
              _saveRentersToStorage();
              _sendWhatsApp(item['mobile'], "*⚡ ELECTRICITY BILL*\nConsumed: $unitsUsed Units\n*TOTAL PAYABLE: ₹$netPayable*");
            },
            child: const Text("Calculate & Send"),
          ),
        ],
      ),
    );
  }

  void _openPaymentRecordDialog(Map<String, dynamic> item, Map<String, dynamic> billRecord) {
    double total = (billRecord['totalPayable'] as num).toDouble();
    final paidCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("💳 Record Payment", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total Bill: ₹$total", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(controller: paidCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount Paid (₹) *")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              double paid = double.tryParse(paidCtrl.text) ?? 0.0;
              String dateStr = DateTime.now().toString().split(' ')[0];
              setState(() {
                billRecord['paidAmount'] = paid;
                billRecord['paymentDate'] = dateStr;
                billRecord['status'] = paid >= total ? 'Paid' : 'Partial';
              });
              _saveRentersToStorage();
              _sendWhatsApp(item['mobile'], "*🧾 PAYMENT RECEIVED*\nPaid: ₹$paid\nStatus: ${billRecord['status']}");
            },
            child: const Text("Save Payment"),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("📜 History: ${item['name']}", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (item['history'] ?? []).length,
            itemBuilder: (c, idx) {
              var h = item['history'][idx];
              return ListTile(
                title: Text(h['type'] ?? 'Bill', style: const TextStyle(color: Colors.white)),
                subtitle: Text("Date: ${h['date']} | Total: ₹${h['totalPayable']} | Status: ${h['status']}", style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  onPressed: () => _openPaymentRecordDialog(item, h),
                  child: const Text("Pay"),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFFFFB703))))],
      ),
    );
  }

  void _openAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("💸 Add Expense", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              double amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt <= 0) return;
              setState(() { expenses.add({'title': titleCtrl.text, 'amount': amt, 'date': DateTime.now().toString().split(' ')[0]}); });
              _saveExpensesToStorage();
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openAddComplaintDialog() {
    final titleCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🛠️ Log Issue", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Room / Name")),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Issue Details")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isEmpty) return;
              setState(() { complaints.add({'room': roomCtrl.text, 'title': titleCtrl.text, 'status': 'Pending', 'date': DateTime.now().toString().split(' ')[0]}); });
              _saveComplaintsToStorage();
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0B132B), Color(0xFF1C2541)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 70,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.domain_rounded, color: Color(0xFFFFB703), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : 'RentManager Pro', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.account_circle, color: Colors.white, size: 28), onPressed: _openOwnerProfileSheet),
              ],
              bottom: TabBar(
                controller: _tabController, isScrollable: true, indicatorColor: const Color(0xFFFFB703), indicatorWeight: 3, labelColor: const Color(0xFFFFB703), unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: "Dashboard"),
                  Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 20), text: "+ New Entry"),
                  Tab(icon: Icon(Icons.folder_shared_rounded, size: 20), text: "Members Data"),
                  Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: "Expenses & Issues"),
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

  Widget _buildDashboardView() {
    double totalCollected = 0.0; double totalPendingDue = 0.0; double totalSecurity = 0.0; int activeResidents = 0;
    for (var r in renters) {
      if (r['isClosed'] != true) {
        activeResidents++;
        totalSecurity += (r['securityDeposit'] ?? 0.0) as double;
        totalPendingDue += _getAccurateUnpaidDue(r);
        for (var h in (r['history'] ?? [])) {
          totalCollected += (h['paidAmount'] as num?)?.toDouble() ?? 0.0;
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
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: _sendBulkReminders, icon: const Icon(Icons.notifications_active_rounded), label: const Text("Bulk Reminders"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () => _tabController.animateTo(1), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text("Add Member"))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard("TOTAL COLLECTED", "₹${totalCollected.toStringAsFixed(0)}", Icons.wallet, const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("MARKET DUE", "₹${totalPendingDue.toStringAsFixed(0)}", Icons.error_outline, const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard("ACTIVE MEMBERS", "$activeResidents", Icons.people, const Color(0xFF0EA5E9))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("NET PROFIT", "₹${netProfit.toStringAsFixed(0)}", Icons.trending_up, const Color(0xFFFFB703))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1C2541), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Security Deposit Held", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Text("₹${totalSecurity.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFFB703), fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1C2541), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            Icon(icon, size: 18, color: color),
          ]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildNewEntryForm() {
    bool isStudent = (personType == 'Student');
    bool isRenterOrHostel = (personType == 'Renter' || personType == 'Hostel');
    String rentDateStr = "${rentEntryDate.year}-${rentEntryDate.month.toString().padLeft(2, '0')}-${rentEntryDate.day.toString().padLeft(2, '0')}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1C2541), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: personType, 
                decoration: const InputDecoration(labelText: "Category"), 
                dropdownColor: const Color(0xFF1C2541),
                items: const [
                  DropdownMenuItem(value: "Student", child: Text("🎓 Student", style: TextStyle(color: Colors.white))), 
                  DropdownMenuItem(value: "Hostel", child: Text("🏢 Hostel", style: TextStyle(color: Colors.white))), 
                  DropdownMenuItem(value: "Renter", child: Text("🏠 Renter", style: TextStyle(color: Colors.white)))
                ], 
                onChanged: (v) => setState(() => personType = v!)
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *")),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "WhatsApp No. *")),
              if (isStudent || personType == 'Hostel') ...[
                const SizedBox(height: 12),
                TextField(controller: parentMobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Parents Mobile Number")),
              ],
              const SizedBox(height: 12),
              TextField(controller: roomOrRollCtrl, decoration: InputDecoration(labelText: isStudent ? "Roll No *" : "Room / Bed No *")),
              if (isRenterOrHostel) ...[
                const SizedBox(height: 12),
                TextField(controller: initialReadingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Meter Reading")),
              ],
              const SizedBox(height: 12),
              TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isStudent ? "Monthly Fee (₹) *" : "Monthly Rent (₹) *")),
              const SizedBox(height: 12),
              TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit Paid (₹)")),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveNewRegistration, 
                child: const Text("Save & Send Welcome Rules", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredListView() {
    List<Map<String, dynamic>> filtered = renters;
    if (listFilter == 'Student') filtered = renters.where((r) => r['pType'] == 'Student' && r['isClosed'] != true).toList();
    if (listFilter == 'Renter') filtered = renters.where((r) => r['pType'] == 'Renter' && r['isClosed'] != true).toList();
    if (listFilter == 'Hostel') filtered = renters.where((r) => r['pType'] == 'Hostel' && r['isClosed'] != true).toList();
    if (listFilter == 'Closed') filtered = renters.where((r) => r['isClosed'] == true).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF0B132B), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _buildFilterChip("All", 'all'), const SizedBox(width: 6),
            _buildFilterChip("🎓 Students", 'Student'), const SizedBox(width: 6),
            _buildFilterChip("🏢 Hostel", 'Hostel'), const SizedBox(width: 6),
            _buildFilterChip("🏠 Renters", 'Renter'), const SizedBox(width: 6),
            _buildFilterChip("Closed", 'Closed'),
          ])),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No members found.", style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8), itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered[i];
                    bool isStudent = (r['pType'] == 'Student');
                    double due = _getAccurateUnpaidDue(r);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), elevation: 0, color: const Color(0xFF1C2541),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: due > 0 ? Colors.red.shade400 : Colors.green.shade400, width: 1.5)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                IconButton(icon: const Icon(Icons.edit, size: 18, color: Color(0xFFFFB703)), onPressed: () => _showEditDialog(r)),
                              ],
                            ),
                            Text("📱 ${r['mobile']} | Due: ₹$due", style: const TextStyle(color: Colors.white70)),
                            const Divider(color: Colors.white12, height: 12),
                            Wrap(
                              spacing: 6,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                  icon: const Icon(Icons.receipt, size: 14),
                                  label: const Text("Bill", style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    if (isStudent) {
                                      _openStudentGenerateBillDialog(r);
                                    } else {
                                      _showRenterOrHostelBillOptionDialog(r);
                                    }
                                  },
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent, side: const BorderSide(color: Colors.tealAccent), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                  icon: const Icon(Icons.history, size: 14),
                                  label: Text("History (${(r['history'] ?? []).length})", style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _showHistoryDialog(r),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.lightBlueAccent, side: const BorderSide(color: Colors.lightBlueAccent), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                  icon: const Icon(Icons.description, size: 14),
                                  label: const Text("Doc", style: TextStyle(fontSize: 11)),
                                  onPressed: () => _sharePoliceVerificationForm(r),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                  icon: const Icon(Icons.exit_to_app, size: 14),
                                  label: const Text("Close", style: TextStyle(fontSize: 11)),
                                  onPressed: () => _openCloseAccountDialog(r),
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
              Text("💸 Expenses: ₹${totalExpenseAmt.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF4444))),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white), onPressed: _openAddExpenseDialog, icon: const Icon(Icons.add, size: 16), label: const Text("Add Expense")),
            ],
          ),
          const Divider(color: Colors.white12, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🛠️ Issues (${complaints.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ElevatedButton.icon(onPressed: _openAddComplaintDialog, icon: const Icon(Icons.report_problem, size: 16), label: const Text("Log Issue")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = (listFilter == value);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF0B132B) : Colors.white70)),
      selected: isSelected,
      selectedColor: const Color(0xFFFFB703),
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
      onSelected: (_) => setState(() => listFilter = value),
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
                const Text("⚙️ Owner & Property Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 12),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white12,
                        backgroundImage: ownerPhotoBase64 != null ? MemoryImage(base64Decode(ownerPhotoBase64!)) : null,
                        child: ownerPhotoBase64 == null ? const Icon(Icons.person, size: 45, color: Colors.white70) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: CircleAvatar(
                          radius: 14, backgroundColor: const Color(0xFFFFB703),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF0B132B)),
                            onPressed: () async { await _pickImage('owner'); setModalState(() {}); },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: propertyNameCtrl, decoration: const InputDecoration(labelText: "Hostel / Residency Name")),
                const SizedBox(height: 8),
                TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: "Owner Full Name")),
                const SizedBox(height: 8),
                TextField(controller: ownerPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Owner WhatsApp Number")),
                const SizedBox(height: 8),
                TextField(controller: ownerUpiIdCtrl, decoration: const InputDecoration(labelText: "UPI ID")),
                const SizedBox(height: 8),
                TextField(controller: ownerUpiNumCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "UPI Mobile")),
                const SizedBox(height: 8),
                TextField(controller: defaultUnitRateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Default Unit Rate (₹)")),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                  onPressed: () { _saveOwnerProfile(); Navigator.pop(ctx); },
                  child: const Text("💾 Save Profile & Settings", style: TextStyle(fontWeight: FontWeight.bold)),
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
