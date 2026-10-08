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
  List<Map<String, dynamic>> recycleBin = []; // New: Recycle Bin
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> complaints = [];
  Map<String, dynamic> ownerProfile = {};
  
  String searchQuery = ''; // New: Search Query

  // Form Controllers
  bool isEditing = false; // New: Flag for Edit Mode
  String? editingId; // New: Keep track of which renter is being edited

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
    final recycleData = prefs.getString('recycle_bin_db');
    final expensesData = prefs.getString('expenses_db');
    final complaintsData = prefs.getString('complaints_db');
    final profileData = prefs.getString('owner_profile');

    if (rentersData != null) {
      List<dynamic> loaded = json.decode(rentersData);
      setState(() {
        renters = loaded.map((e) {
          var item = Map<String, dynamic>.from(e);
          // Purane data mein ID nahi hogi, toh auto generate karenge
          if (item['id'] == null) item['id'] = DateTime.now().microsecondsSinceEpoch.toString() + item['name'];
          return item;
        }).toList();
      });
    }

    // Load and Clean Recycle Bin (30 days logic)
    if (recycleData != null) {
      List<dynamic> rb = json.decode(recycleData);
      DateTime now = DateTime.now();
      setState(() {
        recycleBin = rb.where((item) {
          DateTime deletedAt = DateTime.parse(item['deletedAt']);
          return now.difference(deletedAt).inDays <= 30; // 30 din se purana hamesha ke liye delete
        }).map((e) => Map<String, dynamic>.from(e)).toList();
      });
      _saveRecycleBinToStorage();
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

  Future<void> _saveRecycleBinToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recycle_bin_db', json.encode(recycleBin));
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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp not installed!")));
    }
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

  void _exportJsonBackup() async {
    Map<String, dynamic> fullData = {
      'renters': renters,
      'recycleBin': recycleBin,
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
          if (data['recycleBin'] != null) recycleBin = List<Map<String, dynamic>>.from(data['recycleBin']);
          if (data['expenses'] != null) expenses = List<Map<String, dynamic>>.from(data['expenses']);
          if (data['complaints'] != null) complaints = List<Map<String, dynamic>>.from(data['complaints']);
          if (data['profile'] != null) ownerProfile = Map<String, dynamic>.from(data['profile']);
        });
        await _saveRentersToStorage();
        await _saveRecycleBinToStorage();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Restored Successfully!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Backup File!")));
      }
    }
  }

  void _resetForm() {
    nameCtrl.clear();
    mobileCtrl.clear();
    rentCtrl.clear();
    isEditing = false;
    editingId = null;
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
    List<Map<String, dynamic>> filtered = renters.where((r) {
      return r['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             r['mobile'].toString().contains(searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (val) => setState(() => searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search by Name or Mobile...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final r = filtered[i];
              bool isClosed = r['isClosed'] == true;
              double due = _getAccurateUnpaidDue(r);

              return Card(
                color: isClosed ? Colors.grey.shade200 : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    r['name'] ?? 'No Name', 
                    style: TextStyle(fontWeight: FontWeight.bold, decoration: isClosed ? TextDecoration.lineThrough : null)
                  ),
                  subtitle: Text("Mobile: ${r['mobile']} | Rent: ₹${r['rent']}\nStatus: ${isClosed ? 'Closed/Left' : 'Active'}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'whatsapp') {
                        _sendWhatsApp(r['mobile'], "Hello ${r['name']}, aapka rent due ₹$due hai. Kripya samay par jama karein. - ${propertyNameCtrl.text}");
                      } else if (value == 'edit') {
                        setState(() {
                          isEditing = true;
                          editingId = r['id'];
                          nameCtrl.text = r['name'];
                          mobileCtrl.text = r['mobile'];
                          rentCtrl.text = r['rent'].toString();
                        });
                        _tabController.animateTo(1); // Go to Add Tab
                      } else if (value == 'toggleStatus') {
                        setState(() => r['isClosed'] = !(r['isClosed'] == true));
                        _saveRentersToStorage();
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(r);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (!isClosed) const PopupMenuItem(value: 'whatsapp', child: Row(children: [Icon(Icons.chat, color: Colors.green), SizedBox(width: 8), Text("WhatsApp Reminder")])),
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Edit Details")])),
                      PopupMenuItem(value: 'toggleStatus', child: Row(children: [Icon(isClosed ? Icons.check_circle : Icons.door_back_door, color: Colors.orange), SizedBox(width: 8), Text(isClosed ? "Mark as Active" : "Mark as Closed")])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Move to Trash")])),
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

  void _showDeleteConfirmDialog(Map<String, dynamic> renter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Renter?"),
        content: Text("Are you sure you want to delete ${renter['name']}? They will be kept in the Recycle Bin for 30 days."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              renter['deletedAt'] = DateTime.now().toIso8601String();
              setState(() {
                recycleBin.add(renter);
                renters.removeWhere((r) => r['id'] == renter['id']);
              });
              _saveRentersToStorage();
              _saveRecycleBinToStorage();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Moved to Recycle Bin!")));
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  void _showRecycleBin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("🗑️ Recycle Bin (Auto delete in 30 days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: recycleBin.isEmpty 
                    ? const Center(child: Text("Recycle Bin is empty."))
                    : ListView.builder(
                      itemCount: recycleBin.length,
                      itemBuilder: (ctx, i) {
                        final r = recycleBin[i];
                        DateTime deletedTime = DateTime.parse(r['deletedAt']);
                        int daysLeft = 30 - DateTime.now().difference(deletedTime).inDays;
                        
                        return Card(
                          child: ListTile(
                            title: Text(r['name'], style: const TextStyle(decoration: TextDecoration.lineThrough)),
                            subtitle: Text("Deleted on: ${deletedTime.day}/${deletedTime.month}/${deletedTime.year}\n$daysLeft days left"),
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              label: const Text("Restore"),
                              onPressed: () {
                                r.remove('deletedAt');
                                setState(() {
                                  renters.add(r);
                                  recycleBin.removeWhere((item) => item['id'] == r['id']);
                                });
                                setModalState(() {}); // update bottom sheet UI
                                _saveRentersToStorage();
                                _saveRecycleBinToStorage();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${r['name']} Restored!")));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEditing ? "✏️ Edit Member" : "➕ Add New Member", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isEditing) TextButton(onPressed: () => setState(() => _resetForm()), child: const Text("Cancel Edit", style: TextStyle(color: Colors.red)))
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Rent/Fee (₹) *", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isEditing ? Colors.orange : const Color(0xFF01579B)),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              
              setState(() {
                if (isEditing && editingId != null) {
                  // Update existing
                  int index = renters.indexWhere((r) => r['id'] == editingId);
                  if (index != -1) {
                    renters[index]['name'] = nameCtrl.text.trim();
                    renters[index]['mobile'] = mobileCtrl.text.trim();
                    renters[index]['rent'] = double.tryParse(rentCtrl.text) ?? 0.0;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member Updated!")));
                } else {
                  // Add new
                  renters.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString() + nameCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'mobile': mobileCtrl.text.trim(),
                    'rent': double.tryParse(rentCtrl.text) ?? 0.0,
                    'isClosed': false,
                    'history': []
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Member Added!")));
                }
              });
              
              _saveRentersToStorage();
              _resetForm();
              _tabController.animateTo(2); // Go to Records tab
            },
            child: Text(isEditing ? "Update Details" : "Save Member", style: const TextStyle(color: Colors.white)),
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
          // --- NEW RECYCLE BIN BUTTON ---
          OutlinedButton.icon(
            onPressed: _showRecycleBin,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text("View Recycle Bin (Trash)", style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
          const SizedBox(height: 20),
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
            Tab(icon: Icon(Icons.person_add), text: "Add/Edit"),
            Tab(icon: Icon(Icons.people), text: "Records"),
            Tab(icon: Icon(Icons.settings), text: "Settings"),
          ],
        ),
      ),
    );
  }
}
