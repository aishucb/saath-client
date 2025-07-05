/// WelcomePages for the Saath app
///
/// This file contains the welcome and onboarding screens shown to users after login or registration.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'forum_page.dart';
import 'dart:convert';

class WelcomePage extends StatefulWidget {
  final String? email;
  final String? phone;

  const WelcomePage({Key? key, this.email, this.phone}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

// Shared action button widget for both WelcomePage and WelcomeBackPage
Widget actionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(28),
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink[100]!, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 28),
      ),
    ),
  );
}

class _WelcomePageState extends State<WelcomePage> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  bool get isOtpLogin => (widget.phone != null && widget.phone!.isNotEmpty);

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() async {
  final username = _usernameController.text.trim();
  final phone = _phoneController.text.trim();
  final email = _emailController.text.trim();

  final url = Uri.parse('http://192.168.1.5:5000/api/customer'); // Use your computer's WiFi IP address from .env
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'phone': phone,
        'email': email,
      }),
    );
    final respJson = jsonDecode(response.body);
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Success'),
          content: Text(respJson['message'] ?? 'Customer details submitted successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WelcomePage()), // Replace with your homepage widget if different
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(respJson['error'] ?? 'Failed to submit details. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text('An error occurred: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Singe - Single & Looking Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color(0xFFFF64D6), width: 2),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFB6C1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.white70),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to add a photo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Let others see the real you',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF64D6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Boosted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text('Sarah, 28', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          actionButton(Icons.close, Colors.pink[100]!, Colors.pink, () {}),
                          SizedBox(width: 24),
                          actionButton(Icons.star, Colors.yellow[100]!, Colors.amber, () {}),
                          SizedBox(width: 24),
                          actionButton(Icons.favorite, Colors.pink[50]!, Colors.pinkAccent, () {}),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text('15 matches', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text('5 sparks left', style: TextStyle(color: Colors.pinkAccent, fontSize: 14)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Wellness'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: 0,
        onTap: (index) {
  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForumPage()),
    );
  }
},
      ),
    );
  }

  Widget _actionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.pink[100]!, width: 2),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class WelcomeBackPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Singe - Single & Looking Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color(0xFFFF64D6), width: 2),
              ),
              child: Stack(
                children: [
                  // Boosted badge
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Boosted',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.pink[200],
                            child: Icon(Icons.image, size: 44, color: Colors.white),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(54),
                                onTap: () {},
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, color: Colors.white, size: 32),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tap to add a photo',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(blurRadius: 2, color: Colors.black26)]),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        "Let others see the real you",
                                        style: TextStyle(color: Colors.white70, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text('Sarah, 28', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          actionButton(Icons.close, Colors.pink[100]!, Colors.pink, () {}),
                          SizedBox(width: 24),
                          actionButton(Icons.star, Colors.yellow[100]!, Colors.amber, () {}),
                          SizedBox(width: 24),
                          actionButton(Icons.favorite, Colors.pink[50]!, Colors.pinkAccent, () {}),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text('15 matches', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text('5 sparks left', style: TextStyle(color: Colors.pinkAccent, fontSize: 14)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Wellness'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: 0,
        onTap: (index) {
  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForumPage()),
    );
  }
},
      ),
    );
  }
}

