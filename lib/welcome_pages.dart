/// WelcomePages for the Saath app
///
/// This file contains the welcome and onboarding screens shown to users after login or registration.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'forum_page.dart';
import 'config/api_config.dart';
import 'app_footer.dart';
import 'login_signup_page.dart'; // Added import for LoginSignupPage

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

    String normalizePhone(String phone) {
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) {
        return '91$digits';
      }
      return digits;
    }

    final url = Uri.parse('http://192.168.1.7:5000/api/customer'); // Use your computer's WiFi IP address from .env
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'phone': normalizePhone(phone),
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
      bottomNavigationBar: AppFooter(
        currentIndex: 0, // Home tab
        onTap: (index) {
          if (index == 0) {
            // Already on home
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/forum');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/chat');
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

class WelcomeBackPage extends StatefulWidget {
  final String? userName;
  final int? userAge;
  final String? profilePicture;
  final int matchesCount;
  final int sparksLeft;
  final bool isBoosted;
  final String? currentUserId; // Add current user ID parameter

  const WelcomeBackPage({
    super.key,
    this.userName,
    this.userAge,
    this.profilePicture,
    this.matchesCount = 0,
    this.sparksLeft = 5,
    this.isBoosted = false,
    this.currentUserId, // Add to constructor
  });

  @override
  State<WelcomeBackPage> createState() => _WelcomeBackPageState();
}

class _WelcomeBackPageState extends State<WelcomeBackPage> {
  int currentUserIndex = 0;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? error;
  String? currentUserId;
  
  @override
  void initState() {
    super.initState();
    print('WelcomeBackPage - initState called');
    print('WelcomeBackPage - widget.currentUserId:  [33m${widget.currentUserId} [0m');

    if (widget.currentUserId != null) {
      print('WelcomeBackPage - Saving user session: ${widget.currentUserId}');
      saveUserSession(widget.currentUserId!);
      setState(() {
        currentUserId = widget.currentUserId;
      });
      _initializeData();
    } else {
      print('WelcomeBackPage - No currentUserId provided via widget, loading from SharedPreferences');
      loadUserSessionAndInit();
    }
  }

  Future<void> loadUserSessionAndInit() async {
    try {
      print('WelcomeBackPage - Loading user session...');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      setState(() {
        currentUserId = userId;
      });
      print('WelcomeBackPage - Loaded user session: $currentUserId');
      await _initializeData();
    } catch (e) {
      print('WelcomeBackPage - Error loading user session: $e');
      setState(() {
        error = 'Error loading session: $e';
      });
    }
  }

  Future<void> _initializeData() async {
    // Only update session if widget.currentUserId is provided and different from current
    if (widget.currentUserId != null && widget.currentUserId != currentUserId) {
      print('WelcomeBackPage - Updating session with new user ID: ${widget.currentUserId}');
      await saveUserSession(widget.currentUserId!);
    }
    await fetchUsers();
  }

  Future<void> loadUserSession() async {
    try {
      print('WelcomeBackPage - Loading user session...');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      setState(() {
        currentUserId = userId;
      });
      print('WelcomeBackPage - Loaded user session: $currentUserId');
    } catch (e) {
      print('WelcomeBackPage - Error loading user session: $e');
    }
  }

  Future<void> clearUserSession() async {
    try {
      print('WelcomeBackPage - Clearing user session');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('userToken'); // Also clear the JWT token
      setState(() {
        currentUserId = null;
      });
      print('WelcomeBackPage - Cleared user session and token');
    } catch (e) {
      print('WelcomeBackPage - Error clearing user session: $e');
    }
  }

  Future<void> saveUserSession(String userId) async {
    try {
      print('WelcomeBackPage - Saving user session: $userId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      setState(() {
        currentUserId = userId;
      });
      print('WelcomeBackPage - Saved user session: $userId');
    } catch (e) {
      print('WelcomeBackPage - Error saving user session: $e');
    }
  }

  Future<void> saveUserSessionPreserveToken(String userId) async {
    try {
      print('WelcomeBackPage - Saving user session (preserving token): $userId');
      final prefs = await SharedPreferences.getInstance();
      final existingToken = prefs.getString('userToken'); // Preserve existing token
      await prefs.setString('current_user_id', userId);
      if (existingToken != null) {
        await prefs.setString('userToken', existingToken); // Restore token
        print('WelcomeBackPage - Preserved existing token');
      }
      setState(() {
        currentUserId = userId;
      });
      print('WelcomeBackPage - Saved user session: $userId');
    } catch (e) {
      print('WelcomeBackPage - Error saving user session: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Check if we have current user ID
      if (currentUserId == null) {
        setState(() {
          error = 'User session not found. Please log in again.';
          isLoading = false;
        });
        return;
      }

      print('Fetching potential matches for user: $currentUserId');
      print('Widget currentUserId: ${widget.currentUserId}');
      print('State currentUserId: $currentUserId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/followers/potential-matches/$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userList = data['users'] as List<dynamic>;
        final stats = data['stats'];
        
        print('Fetched ${userList.length} users');
        print('Stats: $stats');
        
        setState(() {
          users = userList.map((user) => {
            'name': user['name'] ?? 'User',
            'age': user['age'] ?? 25,
            'picture': user['picture'],
            'isBoosted': user['isBoosted'] ?? false,
            'id': user['_id'],
            'isPotentialMatch': user['isPotentialMatch'] ?? false,
            'showedInterest': user['showedInterest'] ?? false,
          }).toList();
          
          // Reset currentUserIndex if it's out of bounds
          if (currentUserIndex >= users.length) {
            currentUserIndex = 0;
          }
          
          isLoading = false;
        });
      } else {
        print('Error response: ${response.body}');
        setState(() {
          error = 'Failed to fetch users: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void showNextUser() {
    if (users.isNotEmpty) {
      setState(() {
        // Ensure currentUserIndex is within bounds
        if (currentUserIndex >= users.length) {
          currentUserIndex = 0;
        } else {
          currentUserIndex = (currentUserIndex + 1) % users.length;
        }
      });
    }
  }

  Future<void> likeAndShowNext() async {
    if (users.isEmpty) return;
    
    // Ensure currentUserIndex is within bounds
    if (currentUserIndex >= users.length) {
      currentUserIndex = 0;
    }
    
    final currentUser = users[currentUserIndex];
    final currentUserId = currentUser['id'];
    // Check if we have the current logged-in user's ID
    if (this.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User session not found. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      print('Following user: $currentUserId');
      print('Current logged-in user: ${this.currentUserId}');
      // Call the follow API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/followers/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id1': this.currentUserId, // Current user (follower)
          'id2': currentUserId, // User being followed
        }),
      ).timeout(Duration(seconds: 10));
      print('Follow response status: ${response.statusCode}');
      print('Follow response body: ${response.body}');
      if (response.statusCode == 200) {
        print('Successfully followed user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liked ${currentUser['name']}!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        await fetchUsers(); // Refresh the list after liking
        return;
      } else {
        print('Failed to follow user: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like user'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error following user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    // Only show next user if fetchUsers is not called (i.e., on error)
    showNextUser();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user data
    final displayMatches = widget.matchesCount;
    final displaySparks = widget.sparksLeft;
    
    if (isLoading) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.pinkAccent),
              SizedBox(height: 16),
              Text('Loading users...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (error != null) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchUsers,
                child: Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await clearUserSession();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session cleared. Please restart the app.')),
                  );
                },
                child: Text('Clear Session (Debug)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }

    if (users.isEmpty) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No users found', style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchUsers,
                child: Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              ),
            ],
          ),
        ),
      );
    }

    // Ensure currentUserIndex is within bounds
    if (currentUserIndex >= users.length) {
      currentUserIndex = 0;
    }
    
    final currentUser = users[currentUserIndex];
    final displayName = currentUser['name'];
    final displayAge = currentUser['age'];
    final displayPicture = currentUser['picture'];
    final displayIsBoosted = currentUser['isBoosted'];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Singe - Single & Looking Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.pinkAccent),
            tooltip: 'Logout',
            onPressed: () async {
              await clearUserSession();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginSignupPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 32),
          Center(
            child: _buildProfileCard(
              context, 
              displayName, 
              displayAge, 
              displayPicture, 
              displayIsBoosted,
              isTopCard: true
            ),
          ),
          SizedBox(height: 32),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              actionButton(Icons.close, Colors.pink[100]!, Colors.pink, () {
                showNextUser();
              }),
              SizedBox(width: 32),
              actionButton(Icons.star, Colors.yellow[100]!, Colors.amber, () {
                // TODO: Implement super like functionality
              }),
              SizedBox(width: 32),
              actionButton(Icons.favorite, Colors.pink[50]!, Colors.pinkAccent, () {
                likeAndShowNext();
              }),
            ],
          ),
          SizedBox(height: 32),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$displayMatches matches', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              SizedBox(width: 32),
              Text('$displaySparks sparks left', style: TextStyle(color: Colors.pinkAccent, fontSize: 14)),
            ],
          ),
          Expanded(child: Container()),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: 0, // Home tab
        onTap: (index) {
          if (index == 0) {
            // Already on home
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/forum');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/chat');
          }
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String name, int age, String? picture, bool isBoosted, {bool isTopCard = false}) {
    // Ensure currentUserIndex is within bounds
    if (currentUserIndex >= users.length) {
      currentUserIndex = 0;
    }
    
    // Get current user data for this card
    final currentUser = users[currentUserIndex];
    final isPotentialMatch = currentUser['isPotentialMatch'] ?? false;
    final showedInterest = currentUser['showedInterest'] ?? false;
    
    return Container(
      width: 320,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPotentialMatch ? Color(0xFFFFF8E1) : Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPotentialMatch ? Color(0xFFFFB74D) : Color(0xFFFF64D6), 
          width: 2
        ),
        boxShadow: isTopCard ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Showed Interest badge centered
          if (showedInterest)
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Showed Interest',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: Colors.pink[200],
                backgroundImage: picture != null && picture.isNotEmpty && !picture.contains('placeholder.com') 
                  ? NetworkImage(picture) 
                  : null,
                child: picture == null || picture.isEmpty || picture.contains('placeholder.com')
                  ? Icon(Icons.person, size: 44, color: Colors.white)
                  : null,
              ),
              if (picture == null || picture.isEmpty || picture.contains('placeholder.com'))
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(54),
                      onTap: () {
                        // TODO: Implement photo upload functionality
                      },
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
          Center(
            child: Text('$name, $age', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          if (showedInterest) ...[
            SizedBox(height: 10),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This person liked your profile!',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          SizedBox(height: 18),
        ],
      ),
    );
  }
}

