import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase local execution initialization active log: $e");
  }
  runApp(const APSRTCSmartApp());
}

class APSRTCSmartApp extends StatelessWidget {
  const APSRTCSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APSRTC Smart App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFF059669),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF059669),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF111827),
        ),
        useMaterial3: true,
      ),
      home: const MainSplashGateScreen(),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: child,
    );
  }
}

class MainSplashGateScreen extends StatefulWidget {
  const MainSplashGateScreen({super.key});

  @override
  State<MainSplashGateScreen> createState() => _MainSplashGateScreenState();
}

class _MainSplashGateScreenState extends State<MainSplashGateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    Timer(const Duration(seconds: 3), () { if (mounted) { _verifyActiveLocalToken(); } });
  }

  void _verifyActiveLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activeUser = prefs.getString('auth_session_email');
    final String? activeRole = prefs.getString('auth_session_role');

    if (activeUser != null && activeRole != null) {
      if (activeRole == 'Admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        return;
      } else if (activeRole == 'Conductor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ConductorPanel(activeConductorId: activeUser)));
        return;
      } else if (activeRole == 'Passenger') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PassengerDashboard(userEmailId: activeUser)));
        return;
      }
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkspaceSelectionScreen()));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 85, color: Colors.white),
              SizedBox(height: 20),
              Text("APSRTC TRANSIT", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              SizedBox(height: 30),
              SizedBox(width: 120, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.white10))
            ],
          ),
        ),
      ),
    );
  }
}

class WorkspaceSelectionScreen extends StatelessWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              const Text("Select your dashboard portal to get started.", style: TextStyle(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginAndRegisterScreen(portalType: 0))),
                child: const Text("PASSENGER HUB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF059669), width: 2), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginAndRegisterScreen(portalType: 1))),
                child: const Text("CONDUCTOR HUB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginAndRegisterScreen(portalType: 2))),
                  child: const Text("Administrator Login Access", style: TextStyle(color: Colors.white38)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LoginAndRegisterScreen extends StatefulWidget {
  final int portalType;
  const LoginAndRegisterScreen({super.key, required this.portalType});

  @override
  State<LoginAndRegisterScreen> createState() => _LoginAndRegisterScreenState();
}

class _LoginAndRegisterScreenState extends State<LoginAndRegisterScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();

  bool isRegisterActive = false;
  String selectedGender = "Male";

  final _usernameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  void _showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF059669)));
  }

  void _registerPassenger() async {
    if (_usernameCtrl.text.isEmpty || _mobileCtrl.text.isEmpty || _aadhaarCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showAlert("All registration fields are required.");
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showAlert("Passwords do not match.");
      return;
    }

    try {
      String userEmail = _emailCtrl.text.trim();
      String inputUsername = _usernameCtrl.text.trim();
      
      var emailCheck = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
      if (emailCheck.exists) {
        _showAlert("Registration Error: This email address is already in use. Try another.");
        return;
      }

      var usernameCheck = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: inputUsername).get();
      if (usernameCheck.docs.isNotEmpty) {
        _showAlert("Registration Error: This username is already taken. Try another.");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'username': inputUsername,
        'phoneNumber': _mobileCtrl.text.trim(),
        'aadhaarNumber': '[Aadhaar Redacted]',
        'email': userEmail,
        'password': _passwordCtrl.text,
        'gender': selectedGender,
        'walletBalance': 2000.0,
        'profileAvatar': '',
        'role': 'Passenger'
      });

      _usernameCtrl.clear();
      _mobileCtrl.clear();
      _aadhaarCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();

      setState(() { isRegisterActive = false; });
      _showAlert("Account registration complete. Please sign in below.");
    } catch (e) {
      _showAlert("Database storage alert: $e");
    }
  }

  void _loginUser() async {
    final inputVal = _idController.text.trim();
    final pass = _passController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (widget.portalType == 0) {
      var docRef = await FirebaseFirestore.instance.collection('users').doc(inputVal).get();
      String resolvedEmail = "";

      if (docRef.exists && docRef.data()!['password'] == pass) {
        resolvedEmail = inputVal;
      } else {
        var query = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: inputVal).get();
        if (query.docs.isNotEmpty && query.docs.first.data()['password'] == pass) {
          resolvedEmail = query.docs.first.id;
        }
      }

      if (resolvedEmail.isNotEmpty) {
        List<String> userList = prefs.getStringList('local_saved_accounts') ?? [];
        if (!userList.contains("$resolvedEmail|Passenger")) {
          userList.add("$resolvedEmail|Passenger");
          await prefs.setStringList('local_saved_accounts', userList);
        }
        await prefs.setString('auth_session_email', resolvedEmail);
        await prefs.setString('auth_session_role', 'Passenger');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PassengerDashboard(userEmailId: resolvedEmail)), (r) => false);
      } else {
        _showAlert("Invalid username/email or password.");
      }
    } else if (widget.portalType == 1) {
      if ((inputVal == "conductor1" || inputVal == "conductor2") && pass == "1234") {
        await prefs.setString('auth_session_email', inputVal);
        await prefs.setString('auth_session_role', 'Conductor');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ConductorPanel(activeConductorId: inputVal)), (r) => false);
      } else {
        _showAlert("Access Denied for Conductor identification numbers.");
      }
    } else if (widget.portalType == 2) {
      if (inputVal == CentralDatabase.defaultAdminId && pass == CentralDatabase.defaultAdminPassword) {
        await prefs.setString('auth_session_email', inputVal);
        await prefs.setString('auth_session_role', 'Admin');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboard()), (r) => false);
      } else {
        _showAlert("Admin login mismatch.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: GlassCard(
            child: isRegisterActive
                ? Column(
                    children: [
                      const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Unique Username')),
                      TextField(controller: _mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number')),
                      TextField(controller: _aadhaarCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Aadhaar Number')),
                      TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address (Unique ID)')),
                      TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                      TextField(controller: _confirmPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: ["Male", "Female", "Other"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() { selectedGender = v!; }),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _registerPassenger, child: const Text("REGISTER"))
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.lock, size: 45, color: Colors.white),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _idController, 
                        decoration: InputDecoration(
                          labelText: widget.portalType == 0 
                              ? 'Username or Email ID' 
                              : (widget.portalType == 1 ? 'Conductor ID' : 'Username')
                        )
                      ),
                      TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Code')),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _loginUser, child: const Text("SIGN IN")),
                      if (widget.portalType == 0)
                        TextButton(
                          onPressed: () => setState(() { isRegisterActive = true; }), 
                          child: const Text("New user? Register", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))
                        )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AccountSwitchManager extends StatelessWidget {
  const AccountSwitchManager({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        List<String> accounts = prefs.getStringList('local_saved_accounts') ?? [];
        
        return PopupMenuButton<String>(
          icon: const Icon(Icons.switch_account, color: Colors.white),
          onSelected: (selectedVal) async {
            List<String> parts = selectedVal.split('|');
            await prefs.setString('auth_session_email', parts[0]);
            await prefs.setString('auth_session_role', parts[1]);
            
            if (parts[1] == 'Passenger') {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PassengerDashboard(userEmailId: parts[0])), (r) => false);
            }
          },
          itemBuilder: (context) {
            return accounts.map((acc) {
              return PopupMenuItem<String>(
                value: acc,
                child: Text("Switch to: ${acc.split('|')[0]}", style: const TextStyle(fontSize: 13)),
              );
            }).toList();
          },
        );
      },
    );
  }
}

class PassengerDashboard extends StatefulWidget {
  final String userEmailId;
  const PassengerDashboard({super.key, required this.userEmailId});

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text("Smart Transit Hub", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: const [AccountSwitchManager(), SizedBox(width: 10)],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          PassengerHomeDesk(userEmail: widget.userEmailId),
          PassengerTicketsDesk(userEmail: widget.userEmailId),
          const PassengerBusesDesk(),
          PassengerTimingsStationDesk(userEmail: widget.userEmailId),
          PassengerAccountDesk(userEmail: widget.userEmailId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.white38,
        backgroundColor: const Color(0xFF111827),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() { _tabIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HomeHub'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'My Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Bus Lines'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timings'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}

class PassengerHomeDesk extends StatefulWidget {
  final String userEmail;
  const PassengerHomeDesk({super.key, required this.userEmail});

  @override
  State<PassengerHomeDesk> createState() => _PassengerHomeDeskState();
}

class _PassengerHomeDeskState extends State<PassengerHomeDesk> {
  bool bookingFormActive = false;
  String? activeSource;
  String? activeDestination;
  bool isRouteAvailable = false;
  double computedCost = 0.0;
  List<Map<String, String>> nextTwoHoursUpcomingBuses = [];
  List<Map<String, String>> sourceIncomingBuses = [];
  List<Map<String, String>> sourceOutgoingBuses = [];

  List<String> getUniqueStops() {
    Set<String> unique = {};
    for (var bus in CentralDatabase.networkFleet) {
      unique.addAll(bus.stops);
    }
    return unique.toList();
  }

  void _evaluateRouteAndPlatformFlow() {
    isRouteAvailable = false;
    computedCost = 0.0;
    nextTwoHoursUpcomingBuses.clear();
    sourceIncomingBuses.clear();
    sourceOutgoingBuses.clear();

    if (activeSource != null && activeDestination != null && activeSource != activeDestination) {
      // 1. Check path validity and compute fare
      for (var bus in CentralDatabase.networkFleet) {
        if (bus.stops.contains(activeSource) && bus.stops.contains(activeDestination)) {
          int srcIdx = bus.stops.indexOf(activeSource!);
          int destIdx = bus.stops.indexOf(activeDestination!);
          if (srcIdx < destIdx) {
            isRouteAvailable = true;
            computedCost = CentralDatabase.calculateFare(bus, activeSource!, activeDestination!);
            
            // Generate next 2 hours upcoming buses for this path
            DateTime now = DateTime.now();
            for (int i = 0; i < 3; i++) {
              DateTime slotTime = now.add(Duration(minutes: (i + 1) * 20 + (srcIdx * 5)));
              String formattedTime = "${slotTime.hour > 12 ? slotTime.hour - 12 : (slotTime.hour == 0 ? 12 : slotTime.hour).toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')} ${slotTime.hour >= 12 ? 'PM' : 'AM'}";
              nextTwoHoursUpcomingBuses.add({
                "time": formattedTime,
                "routeSummary": "${bus.stops.first} ➔ ${bus.stops.last}"
              });
            }
            break;
          }
        }
      }

      // 2. Gather incoming and outgoing platform flows at the source station
      int busCounter = 0;
      for (var bus in CentralDatabase.networkFleet) {
        if (bus.stops.contains(activeSource)) {
          int idx = bus.stops.indexOf(activeSource!);
          String origin = bus.stops.first;
          String terminal = bus.stops.last;

          if (idx > 0) {
            DateTime now = DateTime.now();
            DateTime slotTime = now.add(Duration(minutes: 15 + (busCounter * 10)));
            String tStr = "${slotTime.hour > 12 ? slotTime.hour - 12 : (slotTime.hour == 0 ? 12 : slotTime.hour).toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')} ${slotTime.hour >= 12 ? 'PM' : 'AM'}";
            sourceIncomingBuses.add({
              "desc": "From $origin towards $activeSource",
              "time": tStr
            });
          }
          if (idx < bus.stops.length - 1) {
            DateTime now = DateTime.now();
            DateTime slotTime = now.add(Duration(minutes: 25 + (busCounter * 10)));
            String tStr = "${slotTime.hour > 12 ? slotTime.hour - 12 : (slotTime.hour == 0 ? 12 : slotTime.hour).toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')} ${slotTime.hour >= 12 ? 'PM' : 'AM'}";
            sourceOutgoingBuses.add({
              "desc": "From $activeSource towards $terminal",
              "time": tStr
            });
          }
          busCounter++;
        }
      }
    }
    setState(() {});
  }

  void _commitTicketReservation(double currentWalletBalance, String passengerUsername, String passengerPhone) async {
    if (activeSource == activeDestination || !isRouteAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Invalid or unavailable route.")));
      return;
    }
    if (currentWalletBalance < computedCost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient wallet balance.")));
      return;
    }
    final code = (Random().nextInt(8999) + 1000).toString();

    double remainingBal = currentWalletBalance - computedCost;
    await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).update({'walletBalance': remainingBal});

    // Anonymous bus pass booking (does not lock down to a specific bus number)
    await FirebaseFirestore.instance.collection('tickets').doc(code).set({
      'ticketId': code,
      'userEmail': widget.userEmail,
      'username': passengerUsername,
      'phoneNumber': passengerPhone,
      'busNumber': 'Any Available Corridor Bus',
      'source': activeSource!,
      'destination': activeDestination!,
      'farePaid': computedCost,
      'bookingTime': DateTime.now().toIso8601String(),
      'isScanned': false,
      'isCancelled': false,
      'cancelReason': '',
      'scannedByConductor': '',
      'scannedTime': ''
    });

    setState(() {
      bookingFormActive = false;
      activeSource = null;
      activeDestination = null;
      isRouteAvailable = false;
      computedCost = 0.0;
      nextTwoHoursUpcomingBuses.clear();
      sourceIncomingBuses.clear();
      sourceOutgoingBuses.clear();
    });
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Pass Reserved Successfully"),
        content: Text("Your 4-Digit Conductor Verification Code is: $code"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> allStops = getUniqueStops();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userEmail).snapshots(),
        builder: (context, userSnapshot) {
          double liveWalletBalance = 2000.0;
          String pUsername = "Passenger";
          String pPhone = "";
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            var data = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              liveWalletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 2000.0;
              pUsername = data['username'] ?? "Passenger";
              pPhone = data['phoneNumber'] ?? "";
            }
          }

          bool isSameStop = (activeSource != null && activeDestination != null) && (activeSource == activeDestination);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.userEmail, style: const TextStyle(color: Colors.white60)), const Text("Wallet Balance", style: TextStyle(fontWeight: FontWeight.bold))]),
                      Text("₹${liveWalletBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 26, color: Color(0xFF10B981), fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!bookingFormActive)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(double.infinity, 50)),
                    onPressed: () => setState(() { bookingFormActive = true; }),
                    child: const Text("BOOK TICKET NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                else
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Source & Destination Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: activeSource,
                          dropdownColor: const Color(0xFF1F2937),
                          hint: const Text("Source Station"),
                          items: allStops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (s) {
                            setState(() {
                              activeSource = s;
                              _evaluateRouteAndPlatformFlow();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: activeDestination,
                          dropdownColor: const Color(0xFF1F2937),
                          hint: const Text("Destination Hub"),
                          items: allStops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (d) {
                            setState(() {
                              activeDestination = d;
                              _evaluateRouteAndPlatformFlow();
                            });
                          },
                        ),
                        if (isSameStop) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "⚠️ Invalid Route: Origin and destination cannot be identical.",
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (activeSource != null && activeDestination != null && !isSameStop) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRouteAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRouteAvailable ? "✅ Route Available: Buses operating on this path." : "❌ Route Unavailable: No direct corridor found between these stops.",
                              style: TextStyle(color: isRouteAvailable ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                        if (nextTwoHoursUpcomingBuses.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text("⏱️ Upcoming Buses (Next 2 Hours):", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13)),
                          const SizedBox(height: 6),
                          ...nextTwoHoursUpcomingBuses.map((b) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(b['routeSummary']!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                Text(b['time']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 12)),
                              ],
                            ),
                          )),
                        ],
                        if (sourceIncomingBuses.isNotEmpty || sourceOutgoingBuses.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text("🚉 Source Station Platform Flow (Incoming / Outgoing):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 13)),
                          const SizedBox(height: 6),
                          if (sourceIncomingBuses.isNotEmpty) ...[
                            const Text("📥 Incoming Direction:", style: TextStyle(fontSize: 11, color: Colors.white60)),
                            ...sourceIncomingBuses.take(2).map((inc) => Text(" • ${inc['desc']} at ${inc['time']}", style: const TextStyle(fontSize: 11, color: Colors.white70))),
                          ],
                          if (sourceOutgoingBuses.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            const Text("📤 Outgoing Direction:", style: TextStyle(fontSize: 11, color: Colors.white60)),
                            ...sourceOutgoingBuses.take(2).map((out) => Text(" • ${out['desc']} at ${out['time']}", style: const TextStyle(fontSize: 11, color: Colors.white70))),
                          ],
                        ],
                        if (isRouteAvailable) ...[
                          const SizedBox(height: 20),
                          Text("Ticket Fare: ₹$computedCost", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(double.infinity, 45)),
                            onPressed: () => _commitTicketReservation(liveWalletBalance, pUsername, pPhone), 
                            child: const Text("CONFIRM TICKET BOOKING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        ]
                      ],
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}

class PassengerTimingsStationDesk extends StatefulWidget {
  final String userEmail;
  const PassengerTimingsStationDesk({super.key, required this.userEmail});

  @override
  State<PassengerTimingsStationDesk> createState() => _PassengerTimingsStationDeskState();
}

class _PassengerTimingsStationDeskState extends State<PassengerTimingsStationDesk> {
  String? selectedStation;

  List<String> getUniqueStops() {
    Set<String> unique = {};
    for (var bus in CentralDatabase.networkFleet) {
      unique.addAll(bus.stops);
    }
    return unique.toList();
  }

  List<Map<String, String>> _getDynamicStationTimings(String station, bool isIncoming, int indexOffset) {
    DateTime now = DateTime.now();
    List<Map<String, String>> slots = [];
    
    for (int i = 0; i < 2; i++) {
      int minutesAhead = (isIncoming ? 15 : 30) + (i * 45) + (indexOffset * 10);
      DateTime slotTime = now.add(Duration(minutes: minutesAhead));
      String formattedTime = "${slotTime.hour > 12 ? slotTime.hour - 12 : (slotTime.hour == 0 ? 12 : slotTime.hour).toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')} ${slotTime.hour >= 12 ? 'PM' : 'AM'}";
      slots.add({"time": formattedTime});
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    List<String> allStops = getUniqueStops();

    List<Map<String, String>> incomingBuses = [];
    List<Map<String, String>> outgoingBuses = [];

    if (selectedStation != null) {
      int busCounter = 0;
      for (var bus in CentralDatabase.networkFleet) {
        if (bus.stops.contains(selectedStation)) {
          int idx = bus.stops.indexOf(selectedStation!);
          String origin = bus.stops.first;
          String terminal = bus.stops.last;

          if (idx > 0) {
            var dynamicTimes = _getDynamicStationTimings(selectedStation!, true, busCounter);
            for (var t in dynamicTimes) {
              incomingBuses.add({
                "busNumber": bus.busNumber,
                "routeDesc": "From $origin towards $selectedStation",
                "time": t['time']!
              });
            }
          }
          if (idx < bus.stops.length - 1) {
            var dynamicTimes = _getDynamicStationTimings(selectedStation!, false, busCounter);
            for (var t in dynamicTimes) {
              outgoingBuses.add({
                "busNumber": bus.busNumber,
                "routeDesc": "From $selectedStation towards $terminal",
                "time": t['time']!
              });
            }
          }
          busCounter++;
        }
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Station Timings & Bidirectional Flow", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            const Text("Select your current station stop to inspect live incoming and outgoing buses for the next 2 hours from current system time.", style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 20),
            GlassCard(
              child: DropdownButtonFormField<String>(
                value: selectedStation,
                dropdownColor: const Color(0xFF1F2937),
                hint: const Text("Select Current Station Stop"),
                items: allStops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedStation = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            if (selectedStation != null) ...[
              Text("Platform Status for: $selectedStation", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981))),
              const SizedBox(height: 14),
              const Text("📥 Incoming Side (Arriving towards this stop):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 8),
              if (incomingBuses.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 12), child: Text("No incoming buses right now.", style: TextStyle(color: Colors.white38)))
              else
                ...incomingBuses.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Bus ${b['busNumber']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(b['routeDesc']!, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      ]),
                      Text(b['time']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                )),
              const SizedBox(height: 14),
              const Text("📤 Outgoing Side (Departing from this stop):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              if (outgoingBuses.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 12), child: Text("No outgoing buses right now.", style: TextStyle(color: Colors.white38)))
              else
                ...outgoingBuses.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Bus ${b['busNumber']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(b['routeDesc']!, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      ]),
                      Text(b['time']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                )),
            ]
          ],
        ),
      ),
    );
  }
}

class PassengerTicketsDesk extends StatefulWidget {
  final String userEmail;
  const PassengerTicketsDesk({super.key, required this.userEmail});

  @override
  State<PassengerTicketsDesk> createState() => _PassengerTicketsDeskState();
}

class _PassengerTicketsDeskState extends State<PassengerTicketsDesk> {
  void _showRefundOptionsDialog(BuildContext ctx, String tId, double cost) {
    final List<String> inbuiltReasons = ["Plan changed", "Missed schedule", "Route adjustment", "Other"];
    String temporarySelectedReason = inbuiltReasons.first;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Select Cancel Reason"),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1F2937),
              value: temporarySelectedReason,
              items: inbuiltReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setModalState(() { temporarySelectedReason = val; });
                }
              },
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tickets').doc(tId).update({
                'isCancelled': true,
                'cancelReason': temporarySelectedReason
              });

              var uDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).get();
              if (uDoc.exists) {
                double bal = (uDoc.data()!['walletBalance'] as num).toDouble();
                await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).update({'walletBalance': bal + cost});
              }
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Ticket cancelled successfully. Money returned to wallet.")));
            },
            child: const Text("PROCESS REFUND"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(text: "Active Passes"),
            Tab(text: "Cancelled History"),
            Tab(text: "Invalid / Inactive"),
          ],
          indicatorColor: Color(0xFF10B981),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tickets').where('userEmail', isEqualTo: widget.userEmail).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
            var documents = snapshot.data!.docs;

            List<DocumentSnapshot> activeList = [];
            List<DocumentSnapshot> cancelledList = [];
            List<DocumentSnapshot> invalidList = [];

            for (var doc in documents) {
              var data = doc.data() as Map<String, dynamic>;
              bool scanned = data['isScanned'] ?? false;
              bool cancelled = data['isCancelled'] ?? false;
              String bTimeStr = data['bookingTime'] ?? DateTime.now().toIso8601String();
              DateTime bookedTime = DateTime.parse(bTimeStr);
              bool isExpired = DateTime.now().difference(bookedTime).inHours >= 24;

              if (cancelled) {
                cancelledList.add(doc);
              } else if (scanned || isExpired) {
                invalidList.add(doc);
              } else {
                activeList.add(doc);
              }
            }

            return TabBarView(
              children: [
                _buildDynamicTicketView(context, activeList, canRefund: true),
                _buildDynamicTicketView(context, cancelledList, canRefund: false),
                _buildDynamicTicketView(context, invalidList, canRefund: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDynamicTicketView(BuildContext context, List<DocumentSnapshot> targetList, {required bool canRefund}) {
    if (targetList.isEmpty) return const Center(child: Text("No records available in this tab section."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: targetList.length,
      itemBuilder: (context, idx) {
        var data = targetList[idx].data() as Map<String, dynamic>;
        String codeText = data['ticketId'] ?? '';
        double fairCost = (data['farePaid'] as num).toDouble();
        bool scanned = data['isScanned'] ?? false;
        String source = data['source'] ?? '';
        String destination = data['destination'] ?? '';
        String username = data['username'] ?? 'Passenger';
        String phoneNumber = data['phoneNumber'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("PASS CODE: $codeText", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("₹${fairCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.bold))
                  ],
                ),
                const SizedBox(height: 10),
                Text("Source: $source", style: const TextStyle(color: Colors.white70)),
                Text("Destination: $destination", style: const TextStyle(color: Colors.white70)),
                Text("Username: $username", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                Text("Phone No: $phoneNumber", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                if (canRefund && !scanned) ...[
                  const SizedBox(height: 12),
                  Center(child: QrImageView(data: codeText, size: 100, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white))),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.undo, size: 16, color: Colors.redAccent),
                      label: const Text("Cancel & Refund", style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => _showRefundOptionsDialog(context, codeText, fairCost),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class PassengerBusesDesk extends StatelessWidget {
  const PassengerBusesDesk({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: CentralDatabase.networkFleet.length,
        itemBuilder: (context, index) {
          final bus = CentralDatabase.networkFleet[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: ExpansionTile(
                title: Text("Bus Name: ${bus.busNumber}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("Stops:\n${bus.stops.join(' ➔ ')}", style: const TextStyle(color: Colors.white60, height: 1.5)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PassengerAccountDesk extends StatefulWidget {
  final String userEmail;
  const PassengerAccountDesk({super.key, required this.userEmail});

  @override
  State<PassengerAccountDesk> createState() => _PassengerAccountDeskState();
}

class _PassengerAccountDeskState extends State<PassengerAccountDesk> {
  String profileAvatarUrl = "";

  void _updateProfilePhotoSimulation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Profile Photo Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text("Upload from Device Gallery"),
              onTap: () async {
                setState(() { profileAvatarUrl = "gallery_uploaded_photo"; });
                await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).update({'profileAvatar': 'gallery_uploaded_photo'});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated successfully.")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Delete Profile Photo"),
              onTap: () async {
                setState(() { profileAvatarUrl = ""; });
                await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).update({'profileAvatar': ''});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo removed.")));
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.userEmail).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String avatar = data['profileAvatar'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _updateProfilePhotoSimulation,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    child: avatar.isEmpty
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white38)
                        : const Icon(Icons.face, size: 60, color: Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(title: const Text("Username"), subtitle: Text(data['username'] ?? '')),
                      ListTile(title: const Text("Email ID"), subtitle: Text(data['email'] ?? '')),
                      ListTile(title: const Text("Phone Linked"), subtitle: Text(data['phoneNumber'] ?? '')),
                      ListTile(title: const Text("Aadhaar Registry"), subtitle: Text(data['aadhaarNumber'] ?? '')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).delete();
                        final prefs = await SharedPreferences.getInstance();
                        List<String> userList = prefs.getStringList('local_saved_accounts') ?? [];
                        userList.removeWhere((item) => item.startsWith(widget.userEmail));
                        await prefs.setStringList('local_saved_accounts', userList);
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkspaceSelectionScreen()), (r) => false);
                      },
                      child: const Text("DELETE ACCOUNT", style: TextStyle(color: Colors.white)),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkspaceSelectionScreen()), (r) => false);
                      },
                      child: const Text("LOG OUT", style: TextStyle(color: Colors.white)),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// Payment-style custom scanner overlay with targeting box
class ConductorCameraScannerScreen extends StatelessWidget {
  final Function(String) onScannedCode;
  const ConductorCameraScannerScreen({super.key, required this.onScannedCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  String code = barcode.rawValue!.trim();
                  Navigator.pop(context);
                  onScannedCode(code);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 2,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Text(
              "Align Passenger Pass QR inside box",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL SCANNING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class ConductorPanel extends StatefulWidget {
  final String activeConductorId;
  const ConductorPanel({super.key, required this.activeConductorId});

  @override
  State<ConductorPanel> createState() => _ConductorPanelState();
}

class _ConductorPanelState extends State<ConductorPanel> {
  final _verifyCtrl = TextEditingController();
  List<Map<String, dynamic>> scannedTicketsLedger = [];
  String statusLog = "Ready for scanning or manual entry...";

  void _verifyTicketCode(String code) async {
    if (code.isEmpty) return;
    try {
      var docRef = FirebaseFirestore.instance.collection('tickets').doc(code);
      var snapshot = await docRef.get();

      if (!snapshot.exists) {
        setState(() { statusLog = "❌ ERROR: Pass code '$code' not found in cloud registry."; });
        return;
      }
      var data = snapshot.data()!;
      if (data['isCancelled'] == true) {
        setState(() { statusLog = "❌ REJECTED: Pass '$code' was cancelled and refunded."; });
        return;
      }
      if (data['isScanned'] == true) {
        setState(() { statusLog = "❌ REJECTED: Pass '$code' has already been scanned."; });
        return;
      }

      double fair = (data['farePaid'] as num).toDouble();
      String pUser = data['username'] ?? 'Passenger';
      String pPhone = data['phoneNumber'] ?? 'N/A';
      String sourceStop = data['source'] ?? '';
      String destStop = data['destination'] ?? '';
      String busNum = data['busNumber'] ?? '';
      
      var cSnap = await FirebaseFirestore.instance.collection('conductors').doc(widget.activeConductorId).get();
      double currentConductorWallet = 0.0;
      if (cSnap.exists && cSnap.data()!['walletBalance'] != null) {
        currentConductorWallet = (cSnap.data()!['walletBalance'] as num).toDouble();
      }

      await docRef.update({
        'isScanned': true,
        'scannedByConductor': widget.activeConductorId,
        'scannedTime': DateTime.now().toIso8601String()
      });

      await FirebaseFirestore.instance.collection('conductors').doc(widget.activeConductorId).set({
        'walletBalance': currentConductorWallet + fair
      }, SetOptions(merge: true));

      setState(() { 
        scannedTicketsLedger.insert(0, {
          'ticketId': code,
          'passenger': pUser,
          'phone': pPhone,
          'bus': busNum,
          'route': "$sourceStop ➔ $destStop",
          'fare': fair,
          'time': TimeOfDay.now().format(context)
        });
        statusLog = "✅ Pass $code Verified Successfully! Details captured below.";
      });
      _verifyCtrl.clear();
    } catch (e) {
      setState(() { statusLog = "❌ Error processing request: $e"; });
    }
  }

  void _openRealCameraScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductorCameraScannerScreen(
          onScannedCode: (scannedId) {
            _verifyTicketCode(scannedId.toUpperCase());
          },
        ),
      ),
    );
  }

  void _pushFundsToAdminVault() async {
    try {
      var cSnap = await FirebaseFirestore.instance.collection('conductors').doc(widget.activeConductorId).get();
      double currentBal = 0.0;
      if (cSnap.exists && cSnap.data()!['walletBalance'] != null) {
        currentBal = (cSnap.data()!['walletBalance'] as num).toDouble();
      }

      if (currentBal <= 0) {
        setState(() { statusLog = "⚠️ Wallet balance empty. No funds to push."; });
        return;
      }

      var adminSnap = await FirebaseFirestore.instance.collection('admin').doc('vault').get();
      double centralPool = 0.0;
      if (adminSnap.exists && adminSnap.data()!['totalVaultFunds'] != null) {
        centralPool = (adminSnap.data()!['totalVaultFunds'] as num).toDouble();
      }

      await FirebaseFirestore.instance.collection('admin').doc('vault').set({
        'totalVaultFunds': centralPool + currentBal
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('conductors').doc(widget.activeConductorId).update({
        'walletBalance': 0.0
      });

      setState(() { 
        scannedTicketsLedger.clear();
        statusLog = "🚀 SUCCESS: Handed over shift collections to Central Admin Vault."; 
      });
    } catch (e) {
      setState(() { statusLog = "❌ Transfer Failed: $e"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terminal Conductor: ${widget.activeConductorId}"), backgroundColor: const Color(0xFF111827)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('conductors').doc(widget.activeConductorId).snapshots(),
        builder: (context, conductorWalletSnapshot) {
          double liveConductorWallet = 0.0;
          if (conductorWalletSnapshot.hasData && conductorWalletSnapshot.data!.exists) {
            var data = conductorWalletSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data['walletBalance'] != null) {
              liveConductorWallet = (data['walletBalance'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Shift Session Node", style: TextStyle(color: Colors.white60, fontSize: 13)),
                          Text("Collected Shift Balance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Text("₹${liveConductorWallet.toStringAsFixed(2)}", style: const TextStyle(fontSize: 26, color: Color(0xFF10B981), fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), 
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                  label: const Text("SCAN PASSENGER QR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: _openRealCameraScanner,
                ),
                const SizedBox(height: 16),
                const Center(child: Text("- OR MANUAL ENTRY -", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(height: 16),
                TextField(
                  controller: _verifyCtrl, 
                  decoration: const InputDecoration(labelText: "Enter Passenger 4-Digit Pass Code")
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => _verifyTicketCode(_verifyCtrl.text.trim().toUpperCase()),
                  child: const Text("VERIFY PASS CODE MANUALLY", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, minimumSize: const Size(double.infinity, 50)),
                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  label: const Text("POST COLLECTED CASH TO ADMIN", style: TextStyle(color: Colors.white)),
                  onPressed: _pushFundsToAdminVault,
                ),
                const SizedBox(height: 20),
                Text("📋 Scanned & Verified Tickets Ledger (${scannedTicketsLedger.length}):", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, 
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusLog, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      if (scannedTicketsLedger.isNotEmpty) ...[
                        const Divider(color: Colors.white24),
                        ...scannedTicketsLedger.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Pass: ${t['ticketId']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                  Text("₹${t['fare']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                ],
                              ),
                              Text("Passenger: ${t['passenger']} (${t['phone']})", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              Text("Route: ${t['route']} [Bus: ${t['bus']}]", style: const TextStyle(fontSize: 11, color: Colors.white54)),
                            ],
                          ),
                        )),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkspaceSelectionScreen()), (r) => false);
                    },
                    child: const Text("LOG OUT TERMINAL"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Command Pool Dashboard"), backgroundColor: const Color(0xFF111827)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('admin').doc('vault').snapshots(),
        builder: (context, vaultSnapshot) {
          double centralPoolBalance = 0.0;
          if (vaultSnapshot.hasData && vaultSnapshot.data!.exists) {
            var data = vaultSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data['totalVaultFunds'] != null) {
              centralPoolBalance = (data['totalVaultFunds'] as num).toDouble();
            }
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MAIN REVENUE POOL VAULT:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          "₹${centralPoolBalance.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 22, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkspaceSelectionScreen()), (r) => false);
                  },
                  child: const Text("EXIT GLOBAL ROUTER"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class BusRouteInfo {
  final String busNumber;
  final List<String> stops;
  final Map<String, double> fareMatrix;

  BusRouteInfo({
    required this.busNumber,
    required this.stops,
    required this.fareMatrix,
  });
}

class CentralDatabase {
  static const String defaultAdminId = "admin";
  static const String defaultAdminPassword = "admin123";

  static final List<BusRouteInfo> networkFleet = [
    BusRouteInfo(
      busNumber: "55K",
      stops: ["RTC Complex", "Maddilapalem", "Scindia", "Gajuwaka"],
      fareMatrix: {
        "RTC Complex-Maddilapalem": 10.0, "Maddilapalem-RTC Complex": 10.0,
        "RTC Complex-Scindia": 20.0, "Scindia-RTC Complex": 20.0,
        "RTC Complex-Gajuwaka": 35.0, "Gajuwaka-RTC Complex": 35.0,
        "Maddilapalem-Scindia": 15.0, "Scindia-Maddilapalem": 15.0,
        "Maddilapalem-Gajuwaka": 25.0, "Gajuwaka-Maddilapalem": 25.0,
        "Scindia-Gajuwaka": 10.0, "Gajuwaka-Scindia": 10.0,
      },
    ),
    BusRouteInfo(
      busNumber: "28K",
      stops: ["Jagadamba Junction", "RTC Complex", "Siripuram", "MVP Colony"],
      fareMatrix: {
        "Jagadamba Junction-RTC Complex": 10.0, "RTC Complex-Jagadamba Junction": 10.0,
        "Jagadamba Junction-Siripuram": 15.0, "Siripuram-Jagadamba Junction": 15.0,
        "Jagadamba Junction-MVP Colony": 25.0, "MVP Colony-Jagadamba Junction": 25.0,
        "RTC Complex-Siripuram": 10.0, "Siripuram-RTC Complex": 10.0,
        "RTC Complex-MVP Colony": 15.0, "MVP Colony-RTC Complex": 15.0,
        "Siripuram-MVP Colony": 12.0, "MVP Colony-Siripuram": 12.0,
      },
    ),
    BusRouteInfo(
      busNumber: "211V",
      stops: ["Visakhapatnam Station", "RTC Complex", "Cricket Stadium", "Vizianagaram Complex"],
      fareMatrix: {
        "Visakhapatnam Station-RTC Complex": 10.0, "RTC Complex-Visakhapatnam Station": 10.0,
        "Visakhapatnam Station-Cricket Stadium": 25.0, "Cricket Stadium-Visakhapatnam Station": 25.0,
        "Visakhapatnam Station-Vizianagaram Complex": 85.0, "Vizianagaram Complex-Visakhapatnam Station": 85.0,
        "RTC Complex-Cricket Stadium": 15.0, "Cricket Stadium-RTC Complex": 15.0,
        "RTC Complex-Vizianagaram Complex": 75.0, "Vizianagaram Complex-RTC Complex": 75.0,
        "Cricket Stadium-Vizianagaram Complex": 60.0, "Vizianagaram Complex-Cricket Stadium": 60.0,
      },
    ),
    BusRouteInfo(
      busNumber: "900C",
      stops: ["RTC Complex", "Maddilapalem", "Anandapuram", "Tagarapuvalasa"],
      fareMatrix: {
        "RTC Complex-Maddilapalem": 10.0, "Maddilapalem-RTC Complex": 10.0,
        "RTC Complex-Anandapuram": 35.0, "Anandapuram-RTC Complex": 35.0,
        "RTC Complex-Tagarapuvalasa": 50.0, "Tagarapuvalasa-RTC Complex": 50.0,
        "Maddilapalem-Anandapuram": 25.0, "Anandapuram-Maddilapalem": 25.0,
        "Maddilapalem-Tagarapuvalasa": 40.0, "Tagarapuvalasa-Maddilapalem": 40.0,
        "Anandapuram-Tagarapuvalasa": 15.0, "Tagarapuvalasa-Anandapuram": 15.0,
      },
    ),
    BusRouteInfo(
      busNumber: "999",
      stops: ["Jagadamba Junction", "RTC Complex", "Hanumanthawaka", "Madhurawada"],
      fareMatrix: {
        "Jagadamba Junction-RTC Complex": 10.0, "RTC Complex-Jagadamba Junction": 10.0,
        "Jagadamba Junction-Hanumanthawaka": 20.0, "Hanumanthawaka-Jagadamba Junction": 20.0,
        "Jagadamba Junction-Madhurawada": 35.0, "Madhurawada-Jagadamba Junction": 35.0,
        "RTC Complex-Hanumanthawaka": 10.0, "Hanumanthawaka-RTC Complex": 10.0,
        "RTC Complex-Madhurawada": 25.0, "Madhurawada-RTC Complex": 25.0,
        "Hanumanthawaka-Madhurawada": 15.0, "Madhurawada-Hanumanthawaka": 15.0,
      },
    ),
    BusRouteInfo(
      busNumber: "600",
      stops: ["Anakapalli", "Aganampudi", "Kurmannapalem", "Gajuwaka", "Scindia"],
      fareMatrix: {
        "Anakapalli-Aganampudi": 15.0, "Aganampudi-Anakapalli": 15.0,
        "Anakapalli-Kurmannapalem": 25.0, "Kurmannapalem-Anakapalli": 25.0,
        "Anakapalli-Gajuwaka": 35.0, "Gajuwaka-Anakapalli": 35.0,
        "Anakapalli-Scindia": 50.0, "Scindia-Anakapalli": 50.0,
        "Aganampudi-Kurmannapalem": 10.0, "Kurmannapalem-Aganampudi": 10.0,
        "Aganampudi-Gajuwaka": 20.0, "Gajuwaka-Aganampudi": 20.0,
        "Kurmannapalem-Gajuwaka": 10.0, "Gajuwaka-Kurmannapalem": 10.0,
        "Gajuwaka-Scindia": 15.0, "Scindia-Gajuwaka": 15.0,
      },
    ),
    BusRouteInfo(
      busNumber: "400H",
      stops: ["RTC Complex", "Gurudwara", "NAD Junction", "Vepagunta", "Simhachalam"],
      fareMatrix: {
        "RTC Complex-Gurudwara": 10.0, "Gurudwara-RTC Complex": 10.0,
        "RTC Complex-NAD Junction": 20.0, "NAD Junction-RTC Complex": 20.0,
        "RTC Complex-Vepagunta": 30.0, "Vepagunta-RTC Complex": 30.0,
        "RTC Complex-Simhachalam": 40.0, "Simhachalam-RTC Complex": 40.0,
        "Gurudwara-NAD Junction": 10.0, "NAD Junction-Gurudwara": 10.0,
        "NAD Junction-Vepagunta": 12.0, "Vepagunta-NAD Junction": 12.0,
        "Vepagunta-Simhachalam": 15.0, "Simhachalam-Vepagunta": 15.0,
      },
    ),
    BusRouteInfo(
      busNumber: "10K",
      stops: ["Railway Station", "RTC Complex", "RK Beach", "Kailasagiri"],
      fareMatrix: {
        "Railway Station-RTC Complex": 10.0, "RTC Complex-Railway Station": 10.0,
        "Railway Station-RK Beach": 20.0, "RK Beach-Railway Station": 20.0,
        "Railway Station-Kailasagiri": 40.0, "Kailasagiri-Railway Station": 40.0,
        "RTC Complex-RK Beach": 15.0, "RK Beach-RTC Complex": 15.0,
        "RTC Complex-Kailasagiri": 30.0, "Kailasagiri-RTC Complex": 30.0,
        "RK Beach-Kailasagiri": 20.0, "Kailasagiri-RK Beach": 20.0,
      },
    ),
    BusRouteInfo(
      busNumber: "500A",
      stops: ["RTC Complex", "Maddilapalem", "Yendada", "Madhurawada"],
      fareMatrix: {
        "RTC Complex-Maddilapalem": 10.0, "Maddilapalem-RTC Complex": 10.0,
        "RTC Complex-Yendada": 22.0, "Yendada-RTC Complex": 22.0,
        "RTC Complex-Madhurawada": 35.0, "Madhurawada-RTC Complex": 35.0,
        "Maddilapalem-Yendada": 12.0, "Yendada-Maddilapalem": 12.0,
        "Maddilapalem-Madhurawada": 25.0, "Madhurawada-Maddilapalem": 25.0,
        "Yendada-Madhurawada": 15.0, "Madhurawada-Yendada": 15.0,
      },
    ),
    BusRouteInfo(
      busNumber: "300C",
      stops: ["RTC Complex", "NAD Junction", "Sabbavaram", "Chodavaram"],
      fareMatrix: {
        "RTC Complex-NAD Junction": 20.0, "NAD Junction-RTC Complex": 20.0,
        "RTC Complex-Sabbavaram": 45.0, "Sabbavaram-RTC Complex": 45.0,
        "RTC Complex-Chodavaram": 65.0, "Chodavaram-RTC Complex": 65.0,
        "NAD Junction-Sabbavaram": 25.0, "Sabbavaram-NAD Junction": 25.0,
        "NAD Junction-Chodavaram": 45.0, "Chodavaram-NAD Junction": 45.0,
        "Sabbavaram-Chodavaram": 20.0, "Chodavaram-Sabbavaram": 20.0,
      },
    ),
  ];

  static double calculateFare(BusRouteInfo bus, String from, String to) {
    String key = "$from-$to";
    return bus.fareMatrix[key] ?? 15.0;
  }
}