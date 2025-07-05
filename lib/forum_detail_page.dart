import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'app_footer.dart';
import 'package:intl/intl.dart';

class ForumDetailPage extends StatefulWidget {
  final String forumId;
  const ForumDetailPage({Key? key, required this.forumId}) : super(key: key);

  @override
  _ForumDetailPageState createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  Map<String, dynamic>? forum;
  bool isLoading = true;
  String? error;

  // Comments state
  List<dynamic> comments = [];
  bool isCommentsLoading = true;
  String? commentsError;

  final TextEditingController _commentController = TextEditingController();
  bool isAddingComment = false;
  
  // Reply state
  String? replyToId;
  String? replyToName;

  @override
  void initState() {
    super.initState();
    fetchForumDetail();
    fetchComments();
  }

  Future<void> fetchForumDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/forum/forum/${widget.forumId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['forumPost'] != null) {
          setState(() {
            forum = data['forumPost'];
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
        error = 'Failed to fetch forum details';
        isLoading = false;
      });
    }
  }

  Future<void> fetchComments() async {
    setState(() {
      isCommentsLoading = true;
      commentsError = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/forumcomment/all-forum-comments/${widget.forumId}')
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['comments'] != null) {
          setState(() {
            comments = data['comments'];
            isCommentsLoading = false;
          });
        } else {
          setState(() {
            commentsError = 'Invalid response format';
            isCommentsLoading = false;
          });
        }
      } else {
        setState(() {
          commentsError = 'Error: \\${response.statusCode}';
          isCommentsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        commentsError = 'Failed to fetch comments';
        isCommentsLoading = false;
      });
    }
  }

  // Helper to build a nested comment tree from flat list
  List<Map<String, dynamic>> buildCommentTree(List<dynamic> flatComments) {
    Map<String, Map<String, dynamic>> idToComment = {};
    List<Map<String, dynamic>> roots = [];

    // Prepare all comments with empty replies
    for (var c in flatComments) {
      idToComment[c['_id']] = {
        'id': c['_id'],
        'avatar': 'U',
        'name': 'User',
        'time': c['addedTime'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(c['addedTime'])) : '',
        'badge': 0,
        'text': c['content'],
        'replies': [],
        'replyTo': c['replyTo'],
      };
    }
    // Build tree
    for (var c in flatComments) {
      if (c['replyTo'] != null) {
        final parent = idToComment[c['replyTo']];
        if (parent != null) {
          parent['replies'].add(idToComment[c['_id']]);
        } else {
          if (idToComment[c['_id']] != null) {
            roots.add(idToComment[c['_id']]!); // Orphaned reply
          }
        }
      } else {
        if (idToComment[c['_id']] != null) {
          roots.add(idToComment[c['_id']]!);
        }
      }
    }
    return roots;
  }

  Widget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Post Detail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.favorite_border, color: Colors.pinkAccent), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
      ],
    );
  }

  Widget _buildPostCard() {
    if (forum == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text('JM', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JM-714', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('1h ago', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('42', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(forum!['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(forum!['body'] ?? '', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildTag('Relationships'),
              _buildTag('Advice'),
              _buildTag('Dating'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Chip(
      label: Text(tag, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildTab('Best', true),
          _buildTab('New', false),
          _buildTab('Top', false),
          const Spacer(),
          const Text('16 comments', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.purple : Colors.grey[600], fontSize: 14)),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 3,
              width: 28,
              decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    if (isCommentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (commentsError != null) {
      return Center(child: Text(commentsError!, style: const TextStyle(color: Colors.red)));
    }
    if (comments.isEmpty) {
      return const Center(child: Text('No comments yet.'));
    }
    final commentTree = buildCommentTree(comments);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commentTree.length,
      itemBuilder: (context, i) {
        return _buildCommentTile(commentTree[i]);
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, {bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(left: isReply ? 36 : 0, top: 10, right: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isReply ? Colors.purple[200] : Colors.blue[200],
                radius: 18,
                child: Text(comment['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(comment['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${comment['badge']}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment['text'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          replyToId = comment['id'];
                          replyToName = comment['name'];
                        });
                      },
                      child: const Text('Reply', style: TextStyle(color: Colors.purple, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment['replies'] != null && comment['replies'].isNotEmpty)
            ...comment['replies'].map<Widget>((reply) => _buildCommentTile(reply, isReply: true)).toList(),
        ],
      ),
    );
  }

  Future<void> addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() { isAddingComment = true; });
    try {
      final requestBody = {
        'forumId': widget.forumId,
        'userId': '685d209fd04f883e85784c72', // TODO: Replace with actual logged-in user id
        'content': content,
      };
      
      // Add replyTo if this is a reply
      if (replyToId != null) {
        requestBody['replyTo'] = replyToId!;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/forumcomment/add'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 201) {
        _commentController.clear();
        // Clear reply state
        setState(() {
          replyToId = null;
          replyToName = null;
        });
        await fetchComments();
      }
    } catch (e) {}
    setState(() { isAddingComment = false; });
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          // Reply indicator
          if (replyToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: Colors.purple[600], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to ${replyToName}',
                    style: TextStyle(color: Colors.purple[600], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        replyToId = null;
                        replyToName = null;
                      });
                    },
                    child: Icon(Icons.close, color: Colors.purple[600], size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: replyToId != null ? 'Write a reply...' : 'Add a comment...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  enabled: !isAddingComment,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: isAddingComment ? null : addComment,
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
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: _buildHeader(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : forum == null
                  ? const Center(child: Text('No details found.'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPostCard(),
                          const SizedBox(height: 8),
                          _buildTabs(),
                          const Divider(height: 18),
                          _buildComments(),
                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCommentInput(),
          AppFooter(
            currentIndex: 2,
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
                Navigator.pushReplacementNamed(context, '/chat');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
} 