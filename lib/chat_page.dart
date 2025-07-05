/// Chat page for the Saath app
///
/// This file contains the chat interface using mutual connections API.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_footer.dart';
import 'config/api_config.dart';

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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/mutual-connections/$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['mutualConnections'] != null) {
          setState(() {
            mutualConnections = List<Map<String, dynamic>>.from(data['data']['mutualConnections']);
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'No mutual connections found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load connections: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
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
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading mutual connections...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                } else if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          error!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUserAndFetchConnections,
                          child: Text('Retry'),
                        ),
                        if (currentUserId == null) ...[
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text('Go to Login'),
                          ),
                        ],
                      ],
                    ),
                  );
                } else if (mutualConnections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No mutual connections yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start following people to see them here!',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: EdgeInsets.only(top: 8),
                  itemCount: mutualConnections.length,
                  separatorBuilder: (_, __) => Divider(indent: 72, endIndent: 16, height: 1),
                  itemBuilder: (context, index) {
                    final connection = mutualConnections[index];
                    return _ChatTile(
                      name: connection['name'] ?? 'Unknown User',
                      lastMessage: 'Tap to start chatting!',
                      timestamp: 'Mutual connection',
                      unreadCount: 0,
                      isOnline: true, // Assume online for mutual connections
                      profilePicture: connection['profilePicture'] ?? '',
                      onTap: () {
                        _showChatDetail(context, connection);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChatDetail(BuildContext context, Map<String, dynamic> connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat with ${connection['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mutual Connection'),
            SizedBox(height: 8),
            Text('Name: ${connection['name'] ?? 'Unknown'}'),
            Text('Email: ${connection['email'] ?? 'Not provided'}'),
            Text('Phone: ${connection['phone'] ?? 'Not provided'}'),
            SizedBox(height: 16),
            Text('This would open a detailed chat conversation.\n\nChat feature coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;
  final String profilePicture;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    required this.profilePicture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(profilePicture),
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback to initials if image fails to load
            },
            child: profilePicture.isEmpty
                ? Text(
                    name.split(' ').map((n) => n[0]).join(''),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              style: TextStyle(
                fontSize: 14,
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
    );
  }
} 