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
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0EA5E9),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shadowColor: Colors.black12,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 10,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
    return await showDatePicker(
      context: context, initialDate: initDate, firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0EA5E9)),
          dialogTheme: DialogTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        ), child: child!,
      ),
    );
  }

  void _sendWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    if (clean.length == 10) clean = '91$clean';
    else if (clean.length == 11 && clean.startsWith('0')) clean = '91${clean.substring(1)}';

    final encodedText = Uri.encodeComponent(text);
    final Uri appIntent = Uri.parse("whatsapp://send?phone=$clean&text=$encodedText");
    final Uri universalUrl = Uri.parse("https://api.whatsapp.com/send?phone=$clean&text=$encodedText");

    bool launched = false;
    try { launched = await launchUrl(appIntent, mode: LaunchMode.externalApplication); } catch (_) {}
    if (!launched) { try { launched = await launchUrl(universalUrl, mode: LaunchMode.externalApplication); } catch (_) {} }
    if (!launched && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp open nahi ho saka.")));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabhi ka bill paid hai!")));
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
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  void _saveNewRegistration() async {
    if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
    bool isRenterOrHostel = (personType == 'Renter' || personType == 'Hostel');
    DateTime dueDate = rentEntryDate.add(const Duration(days: 30));
    String rentDateStr = "${rentEntryDate.year}-${rentEntryDate.month.toString().padLeft(2, '0')}-${rentEntryDate.day.toString().padLeft(2, '0')}";
    String elecDateStr = "${elecStartDate.year}-${elecStartDate.month.toString().padLeft(2, '0')}-${elecStartDate.day.toString().padLeft(2, '0')}";
    String nextDueDateStr = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> newEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'pType': personType, 'name': nameCtrl.text.trim(), 'mobile': mobileCtrl.text.trim(),
      'parentMobile': parentMobileCtrl.text.trim(), 'father': fatherCtrl.text.trim(),
      'address': addressCtrl.text.trim(), 'roomNo': roomOrRollCtrl.text.trim(),
      'idNum': idNumCtrl.text.trim(), 'idCardImg': idCardImgBase64 ?? '', 'studentImg': studentImgBase64 ?? '',
      'entryDate': rentDateStr, 'elecDate': isRenterOrHostel ? elecDateStr : null,
      'nextDueDate': nextDueDateStr, 'rent': double.tryParse(rentCtrl.text) ?? 0.0,
      'securityDeposit': double.tryParse(advanceCtrl.text) ?? 0.0, 'extraWalletAdvance': 0.0,
      'prevReading': isRenterOrHostel ? (double.tryParse(initialReadingCtrl.text) ?? 0.0) : 0.0,
      'isClosed': false, 'closedDate': null, 'closureDetails': null, 'history': []
    };

    setState(() => renters.add(newEntry));
    await _saveRentersToStorage();

    nameCtrl.clear(); mobileCtrl.clear(); parentMobileCtrl.clear(); fatherCtrl.clear(); addressCtrl.clear(); roomOrRollCtrl.clear(); idNumCtrl.clear(); rentCtrl.clear(); advanceCtrl.text = '0'; initialReadingCtrl.text = '0';
    setState(() { rentEntryDate = DateTime.now(); elecStartDate = DateTime.now(); studentImgBase64 = null; idCardImgBase64 = null; });
    _tabController.animateTo(2);
  }

  // DIALOG FUNCTIONS
  void _showEditDialog(Map<String, dynamic> item) {
    final eName = TextEditingController(text: item['name']);
    final eMobile = TextEditingController(text: item['mobile']);
    final eRent = TextEditingController(text: item['rent'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("✏️ Edit Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: eName, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: eMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number")),
            const SizedBox(height: 10),
            TextField(controller: eRent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Rent (₹)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() { item['name'] = eName.text.trim(); item['mobile'] = eMobile.text.trim(); item['rent'] = double.tryParse(eRent.text) ?? item['rent']; });
              _saveRentersToStorage(); Navigator.pop(ctx);
            }, child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime expenseDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("💸 Add Property Expense", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              double amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt <= 0) return;
              setState(() { expenses.add({ 'id': DateTime.now().millisecondsSinceEpoch, 'category': 'Other', 'title': titleCtrl.text, 'amount': amt, 'date': "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}" }); });
              _saveExpensesToStorage(); Navigator.pop(ctx);
            }, child: const Text("Save"),
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
        title: const Text("🛠️ Log Member Issue", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Room / Member Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Issue Details", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isEmpty) return;
              setState(() { complaints.add({ 'id': DateTime.now().millisecondsSinceEpoch, 'room': roomCtrl.text, 'title': titleCtrl.text, 'priority': 'Normal', 'status': 'Pending', 'date': DateTime.now().toString().split(' ')[0] }); });
              _saveComplaintsToStorage(); Navigator.pop(ctx);
            }, child: const Text("Log Issue"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = (listFilter == value);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
      onSelected: (_) => setState(() => listFilter = value),
    );
  }

  // APP BUILDER
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 70,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.domain_rounded, color: Color(0xFF0EA5E9), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(propertyNameCtrl.text.isNotEmpty ? propertyNameCtrl.text : 'RentManager Pro', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                ],
              ),
              bottom: TabBar(
                controller: _tabController, isScrollable: true, indicatorColor: const Color(0xFF0EA5E9), indicatorWeight: 4, labelColor: Colors.white, unselectedLabelColor: Colors.white54, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: "Dashboard"),
                  Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 20), text: "+ New Entry"),
                  Tab(icon: Icon(Icons.folder_shared_rounded, size: 20), text: "Members Data"),
                  Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: "Expenses"),
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
        totalSecurity += (r['securityDeposit'] ?? r['advance'] ?? 0.0) as double;
        totalPendingDue += _getAccurateUnpaidDue(r);
      }
    }
    double totalExpenseAmt = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white), onPressed: _sendBulkReminders, icon: const Icon(Icons.notifications_active_rounded), label: const Text("Bulk Reminders"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white), onPressed: () => _tabController.animateTo(1), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text("Add Member"))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildPremiumMetricCard(title: "MARKET DUE", value: "₹${totalPendingDue.toStringAsFixed(0)}", icon: Icons.error_outline_rounded, color: const Color(0xFFF43F5E))),
              const SizedBox(width: 12),
              Expanded(child: _buildPremiumMetricCard(title: "ACTIVE MEMBERS", value: "$activeResidents", icon: Icons.people_alt_rounded, color: const Color(0xFF0EA5E9))),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Security Deposit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
              Text("₹${totalSecurity.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 20)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNewEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(value: personType, decoration: const InputDecoration(labelText: "Category"), items: const [DropdownMenuItem(value: "Student", child: Text("🎓 Student")), DropdownMenuItem(value: "Hostel", child: Text("🏢 Hostel")), DropdownMenuItem(value: "Renter", child: Text("🏠 Renter"))], onChanged: (v) => setState(() => personType = v!)),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *")),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "WhatsApp No. *")),
              const SizedBox(height: 12),
              TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Rent/Fee (₹) *")),
              const SizedBox(height: 12),
              TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Security Deposit Paid (₹)")),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveNewRegistration, child: const Text("Save Member", style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredListView() {
    return Column(
      children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildFilterChip("All", 'all'), const SizedBox(width: 6), _buildFilterChip("🎓 Students", 'Student'), const SizedBox(width: 6), _buildFilterChip("🏠 Renters", 'Renter')])),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8), itemCount: renters.length,
            itemBuilder: (ctx, i) {
              final r = renters[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), elevation: 0, color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                child: ListTile(
                  title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("📱 ${r['mobile']} \nRent: ₹${r['rent']}"),
                  trailing: IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0EA5E9)), onPressed: () => _showEditDialog(r)),
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
              Text("💸 Expenses: ₹${totalExpenseAmt.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF43F5E))),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white), onPressed: _openAddExpenseDialog, icon: const Icon(Icons.add, size: 16), label: const Text("Add Expense")),
            ],
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🛠️ Issues (${complaints.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white), onPressed: _openAddComplaintDialog, icon: const Icon(Icons.report_problem_rounded, size: 16), label: const Text("Log Issue")),
            ],
          ),
        ],
      ),
    );
  }
}
