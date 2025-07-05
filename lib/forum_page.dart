/// ForumPage for the Saath app
///
/// This file contains the main forum screen where users can view and interact with forum posts.
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'app_footer.dart';
import 'main.dart';
import 'forum_detail_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  List<dynamic> posts = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchForumPosts();
  }

  Future<void> fetchForumPosts() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/forum'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['forums'] is List) {
          setState(() {
            posts = data['forums'];
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Invalid response format';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Error: \\${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to fetch forum posts';
        isLoading = false;
      });
    }
  }

  String getInitials(String title) {
    final words = title.split(' ');
    if (words.length > 1) {
      return words[0][0].toUpperCase() + words[1][0].toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }

  Color getColor(int index) {
    final colors = [
      Colors.deepPurple,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Main page structure for the forum
    return Scaffold(
      backgroundColor: Colors.white,
      // The bottom navigation bar footer for main pages
      bottomNavigationBar: AppFooter(
        currentIndex: 2, // Forum tab
        onTap: (index) {
          if (index == 0) {
Navigator.pushReplacementNamed(context, '/welcome');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            // Already on forum
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/chat');
          }
        },
      ),
      // The top bar of the page
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(58),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Community Forum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                Row(
                  children: [
                    Icon(Icons.search, size: 26, color: Colors.grey[700]),
                    SizedBox(width: 14),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 26, color: Colors.grey[700]),
                      tooltip: 'Refresh',
                      onPressed: fetchForumPosts,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // The main body showing forum posts
      body: Column(
        children: [
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
                        hintText: 'Search discussions...',
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
          Padding(
            padding: EdgeInsets.only(top: 2, left: 8, right: 8),
            child: Row(
              children: [
                _ForumTab(label: 'Trending', selected: true),
                _ForumTab(label: 'Recent'),
                _ForumTab(label: 'Following'),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (error != null) {
                  return Center(child: Text(error!, style: TextStyle(color: Colors.red)));
                } else if (posts.isEmpty) {
                  return Center(child: Text('No forum posts found.'));
                }
                return ListView.separated(
                  padding: EdgeInsets.only(top: 8),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => Divider(indent: 72, endIndent: 12, height: 1),
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    // Use backend fields
                    final title = post['title'] ?? '';
                    final body = post['body'] ?? '';
                    final tags = post['tags'] is List ? (post['tags'] as List).join(', ') : '';
                    final createdAt = post['createdAt'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getColor(i),
                        child: Text(getInitials(title), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2),
                          Text('Tags: $tags', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          Text('Created: $createdAt', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () {
                        if (post['_id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForumDetailPage(forumId: post['_id']),
                            ),
                          );
                        }
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
}

class _ForumTab extends StatelessWidget {
  final String label;
  final bool selected;
  _ForumTab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.purple : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            if (selected)
              Container(
                height: 3,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
