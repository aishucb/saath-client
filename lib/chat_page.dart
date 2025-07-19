/// Chat page for the Saath app
///
/// This file contains the chat interface using mutual connections API.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_footer.dart';
import 'config/api_config.dart';
import 'pages/chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> mutualConnections = [];
  bool isLoading = true;
  String? error;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchConnections();
  }

  Future<void> _loadUserAndFetchConnections() async {
    await _loadUserId();
    if (currentUserId != null) {
      fetchMutualConnections();
    } else {
      setState(() {
        error = 'User not logged in. Please login first.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try different possible keys for user ID
      currentUserId = prefs.getString('current_user_id') ?? 
                     prefs.getString('userId') ?? 
                     prefs.getString('user_id') ?? 
                     prefs.getString('customerId') ?? 
                     prefs.getString('customer_id');
      
      print('Loaded user ID: $currentUserId');
    } catch (e) {
      print('Error loading user ID: $e');
      currentUserId = null;
    }
  }

  Future<void> fetchMutualConnections() async {
    if (currentUserId == null) {
      setState(() {
        error = 'User ID not found. Please login again.';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('Fetching mutual connections for user: $currentUserId');
      print('API URL: ${ApiConfig.baseUrl}/api/chat/mutual-connections/$currentUserId');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/mutual-connections/$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['mutualConnections'] != null) {
          setState(() {
            mutualConnections = List<Map<String, dynamic>>.from(data['data']['mutualConnections']);
            isLoading = false;
          });
          print('Found ${mutualConnections.length} mutual connections');
        } else {
          setState(() {
            mutualConnections = []; // Empty array instead of error
            isLoading = false;
          });
          print('No mutual connections found');
        }
      } else {
        setState(() {
          error = 'Failed to load connections: ${response.statusCode}';
          isLoading = false;
        });
        print('Error response: ${response.body}');
      }
    } catch (e) {
      print('Exception in fetchMutualConnections: $e');
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToChat(Map<String, dynamic> connection) {
    final otherUserId = connection['_id'] ?? connection['id'];
    final otherUserName = connection['name'] ?? 'Unknown User';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom navigation bar footer
      bottomNavigationBar: AppFooter(
        currentIndex: 4, // Chat tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/welcome');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/forum');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            // Already on chat
          }
        },
      ),
      // Top app bar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(58),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chats',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, size: 26, color: Colors.grey[700]),
                      onPressed: () {
                        // TODO: Implement search functionality
                      },
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 26, color: Colors.grey[700]),
                      onPressed: fetchMutualConnections,
                      tooltip: 'Refresh connections',
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.more_vert, size: 26, color: Colors.grey[700]),
                      onPressed: () {
                        // TODO: Implement more options
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // Main body with chat list
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey[500], size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Chat list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              error!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchMutualConnections,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : mutualConnections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No connections yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Connect with people to start chatting!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: mutualConnections.length,
                            itemBuilder: (context, index) {
                              final connection = mutualConnections[index];
                              final name = connection['name'] ?? 'Unknown User';
                              final picture = connection['picture'];
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: picture != null 
                                      ? NetworkImage(picture) 
                                      : null,
                                  child: picture == null
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Tap to start chatting',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onTap: () => _navigateToChat(connection),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 