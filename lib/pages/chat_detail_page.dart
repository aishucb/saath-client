import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? sessionId;

  const ChatDetailPage({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.sessionId,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _canSend = false; // Only allow sending after joined
  bool _isDisposed = false; // Track if disposed
  ChatMessage? _replyToMessage; // Track the message being replied to

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('[ChatDetailPage] _initializeChat called');
    await _loadCurrentUserId();
    print('[ChatDetailPage] _currentUserId after load: $_currentUserId');
    if (_currentUserId != null) {
      await _setupChat();
    } else {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      print('[ChatDetailPage] Error: User not logged in');
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('current_user_id') ?? 
                      prefs.getString('userId') ?? 
                      prefs.getString('user_id') ?? 
                      prefs.getString('customerId') ?? 
                      prefs.getString('customer_id');
      print('[ChatDetailPage] Loaded currentUserId:  [32m$_currentUserId [0m');
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _setupChat() async {
    print('[ChatDetailPage] _setupChat called');
    try {
      // Set up callbacks before initializing
      _chatService.onMessagesUpdated = (messages) {
        if (_isDisposed || !mounted) return;
        print('[ChatDetailPage] Loaded messages:');
        for (var m in messages) {
          print('  sender:  [33m${m.sender} [0m, recipient:  [36m${m.recipient} [0m, content:  [32m${m.content} [0m');
        }
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      };
      _chatService.onError = (error) {
        if (_isDisposed || !mounted) return;
        setState(() {
          _error = error;
          _isLoading = false;
        });
        print('[ChatDetailPage] Error: $error');
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      };
      _chatService.onJoined = () {
        if (_isDisposed || !mounted) return;
        setState(() {
          _canSend = true;
          print('[ChatDetailPage] _canSend set to true (joined event received)');
        });
      };

      // Set up onConnected to join session after WebSocket is ready
      _chatService.webSocketService.onConnected = () async {
        print('[ChatDetailPage] WebSocket connected, now joining session...');
        String? sessionId;
        if (widget.sessionId != null) {
          sessionId = widget.sessionId;
          print('[ChatDetailPage] Using provided sessionId: $sessionId');
          // Always pass otherUserId when joining
          await _chatService.webSocketService.joinSession(sessionId!, otherUserId: widget.otherUserId);
          // Load chat history after joining session
          await _chatService.joinChatSession(sessionId!);
        } else {
          sessionId = await _chatService.createChatSession(widget.otherUserId);
          print('[ChatDetailPage] Created/fetched sessionId: $sessionId for user pair $_currentUserId <-> ${widget.otherUserId}');
          if (sessionId != null) {
            // Always pass otherUserId when joining
            await _chatService.webSocketService.joinSession(sessionId!, otherUserId: widget.otherUserId);
            // Load chat history after joining session
            await _chatService.joinChatSession(sessionId!);
          } else {
            setState(() {
              _error = 'Failed to create chat session';
              _isLoading = false;
            });
            print('[ChatDetailPage] Error: Failed to create chat session');
            return;
          }
        }
        print('[ChatDetailPage] Joined sessionId: $sessionId');
        setState(() {
          _isLoading = false;
        });
        print('[ChatDetailPage] _setupChat complete, loading finished');
      };

      // Initialize chat service (triggers WebSocket connect)
      await _chatService.initialize(_currentUserId!);
      print('[ChatDetailPage] ChatService initialized');
      print('[ChatDetailPage] _currentUserId: $_currentUserId, otherUserId: ${widget.otherUserId}');
    } catch (e) {
      setState(() {
        _error = 'Error setting up chat: $e';
        _isLoading = false;
      });
      print('[ChatDetailPage] Error setting up chat: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_canSend) return;
    print('Sending message from ChatDetailPage: $message'); // Debug print
    _messageController.clear();
    String? replyToId = _replyToMessage?.id;
    await _chatService.sendMessage(message, replyTo: replyToId);
    setState(() {
      _replyToMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.otherUserName.isNotEmpty 
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _chatService.isConnected ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _chatService.isConnected ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeChat,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, 
                                     size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMyMessage = message.sender == _currentUserId;
                              return GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  // Only trigger on a strong enough swipe
                                  if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 200) {
                                    setState(() {
                                      _replyToMessage = message;
                                    });
                                  }
                                },
                                child: _buildMessageBubble(message, isMyMessage),
                              );
                            },
                          ),
          ),
          // Reply preview
          if (_replyToMessage != null)
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        Text(
                          _replyToMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Message input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: _canSend,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _canSend ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _canSend ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMyMessage) {
    final isMine = message.sender.toString() == _currentUserId.toString();
    // Find the replied-to message if this is a reply
    ChatMessage? repliedMessage;
    if (message.replyTo != null) {
      repliedMessage = _messages.where((m) => m.id == message.replyTo).isNotEmpty
          ? _messages.firstWhere((m) => m.id == message.replyTo)
          : null;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.otherUserName.isNotEmpty 
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (repliedMessage != null) ...[
                        Container(
                          margin: EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () {
                              if (repliedMessage != null) {
                                final index = _messages.indexWhere((m) => m.id == repliedMessage!.id);
                                if (index != -1) {
                                  _scrollController.animateTo(
                                    index * 72.0, // Approximate height per message, adjust as needed
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                  // Optionally, you can add a highlight effect here
                                }
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 36,
                                  margin: EdgeInsets.only(right: 8, top: 2),
                                  decoration: BoxDecoration(
                                    color: isMine ? Colors.white70 : Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        repliedMessage.sender == _currentUserId ? 'You' : widget.otherUserName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMine ? Colors.white70 : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        repliedMessage.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          color: isMine ? Colors.white70 : Colors.black87,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMine ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isMine ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMine) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                color: Colors.blue,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chatService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 