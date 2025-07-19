import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  String? _currentUserId;
  String? _currentSessionId;
  String? _otherUserId; // Store the other user ID
  List<ChatMessage> _messages = [];
  Map<String, List<ChatMessage>> _chatHistory = {};
  bool allMessagesLoaded = false;
  bool isLoadingMore = false;

  // Callbacks
  Function(List<ChatMessage>)? onMessagesUpdated;
  Function(ChatMessage)? onNewMessage;
  Function(String)? onError;
  Function()? onJoined; // Called when joined event is received

  // Getters
  List<ChatMessage> get messages => _messages;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  bool get isConnected => _webSocketService.isConnected;

  // Public getter for the WebSocketService
  WebSocketService get webSocketService => _webSocketService;

  // Initialize chat service
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    
    // Set up WebSocket callbacks
    _webSocketService.onMessageReceived = _handleWebSocketMessage;
    _webSocketService.onNotificationReceived = _handleNotification;
    _webSocketService.onError = onError;
    _webSocketService.onJoined = () {
      print('[ChatService] onJoined callback triggered');
      onJoined?.call();
    }; // Pass through
    
    // Initialize WebSocket connection
    await _webSocketService.initialize(userId);
  }

  // Wait for WebSocket registration before joining session
  Future<void> waitForRegistration() async {
    await _webSocketService.waitForRegistration();
  }

  // Set the current sessionId and update WebSocketService
  void setCurrentSessionId(String sessionId) {
    _currentSessionId = sessionId;
    _webSocketService.setSessionId(sessionId);
  }

  // Get the current sessionId
  String? getCurrentSessionId() {
    return _currentSessionId;
  }

  // Helper to get session key for user pair
  String _sessionCacheKey(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return 'chat_session_${sorted[0]}_${sorted[1]}';
  }

  // Create or reuse a chat session (with cache, as originally)
  Future<String?> createChatSession(String otherUserId) async {
    _otherUserId = otherUserId; // Store the other user ID
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _sessionCacheKey(_currentUserId!, otherUserId);
    final cached = prefs.getString(cacheKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    int expiryMs = 7 * 24 * 60 * 60 * 1000; // 7 days
    if (cached != null) {
      try {
        final cachedObj = Map<String, dynamic>.from(jsonDecode(cached));
        final sessionId = cachedObj['sessionId'] as String?;
        final timestamp = cachedObj['timestamp'] as int?;
        if (sessionId != null && timestamp != null && now - timestamp < expiryMs) {
          print('[ChatService] Using cached sessionId: $sessionId');
          setCurrentSessionId(sessionId); // Always update sessionId
          return sessionId;
        }
      } catch (e) {
        print('[ChatService] Error parsing cached session: $e');
      }
    }
    // No valid cache, create new session
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId1': _currentUserId,
          'userId2': otherUserId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['sessionId'];
        // Save to cache
        await prefs.setString(cacheKey, jsonEncode({
          'sessionId': sessionId,
          'timestamp': now,
        }));
        print('[ChatService] Created and cached new sessionId: $sessionId');
        setCurrentSessionId(sessionId); // Always update sessionId
        return sessionId;
      } else {
        onError?.call('Failed to create chat session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      onError?.call('Error creating chat session: $e');
      return null;
    }
  }

  // Validate session on backend: returns true if both users are present in session
  Future<bool> _validateSessionOnBackend(String sessionId, String userId1, String userId2) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/chat/session/$sessionId';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = (data['users'] as List<dynamic>).cast<String>();
        final valid = users.contains(userId1) && users.contains(userId2) && users.length == 2;
        print('[ChatService] Session $sessionId validation result: $valid, users: $users');
        return valid;
      }
    } catch (e) {
      print('[ChatService] Error validating session on backend: $e');
    }
    return false;
  }

  // Join a chat session
  Future<void> joinChatSession(String sessionId) async {
    print('[ChatService] joinChatSession called with sessionId: $sessionId');
    _currentSessionId = sessionId;
    _webSocketService.setSessionId(sessionId);
    // Listen for join errors
    void handleError(dynamic error) async {
      if (error is String && error.contains('Invalid session or user')) {
        print('[ChatService] Clearing cached sessionId due to invalid session or user');
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = _sessionCacheKey(_currentUserId!, _otherUserId!);
        await prefs.remove(cacheKey);
        // Optionally, trigger a re-join or notify the UI
      }
    }
    _webSocketService.onJoinError = handleError;
    await _webSocketService.joinSession(sessionId, otherUserId: _otherUserId);
    
    // Load chat history
    print('[ChatService] About to call _loadChatHistory');
    await _loadChatHistory();
  }

  // Load chat history from server
  Future<void> _loadChatHistory() async {
    if (_currentSessionId == null) return;

    try {
      // Use the stored other user ID instead of trying to extract from chat history
      final otherUserId = _otherUserId;
      print('[ChatService] _currentUserId: $_currentUserId, otherUserId: $otherUserId, sessionId: $_currentSessionId');
      if (otherUserId == null) {
        print('[ChatService] otherUserId is null, not loading history');
        return;
      }

      final url = '${ApiConfig.baseUrl}/api/chat/messages?user1=$_currentUserId&user2=$otherUserId';
      print('[ChatService] Fetching chat history from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ChatService] Response status: ${response.statusCode}');
      print('[ChatService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('[ChatService] Decoded messages count: ${data.length}');
        _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        _chatHistory[_currentSessionId!] = List.from(_messages);
        print('[ChatService] Parsed messages count: ${_messages.length}');
        onMessagesUpdated?.call(_messages);
      } else {
        onError?.call('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatService] Error loading chat history: $e');
      onError?.call('Error loading chat history: $e');
    }
  }

  // Get the other user ID from the current session
  Future<String?> _getOtherUserIdFromSession() async {
    print('[ChatService] _getOtherUserIdFromSession called');
    print('[ChatService] _currentSessionId: $_currentSessionId');
    print('[ChatService] _chatHistory keys: ${_chatHistory.keys.toList()}');
    // This is a simplified approach. In a real app, you might want to store
    // session participants in a more structured way
    if (_currentSessionId != null && _chatHistory.containsKey(_currentSessionId)) {
      final messages = _chatHistory[_currentSessionId]!;
      print('[ChatService] Found messages in chat history: ${messages.length}');
      if (messages.isNotEmpty) {
        final firstMessage = messages.first;
        final otherUserId = firstMessage.sender == _currentUserId 
            ? firstMessage.recipient 
            : firstMessage.sender;
        print('[ChatService] Returning otherUserId: $otherUserId');
        return otherUserId;
      }
    }
    print('[ChatService] No chat history found, returning null');
    return null;
  }

  // Send a message
  Future<void> sendMessage(String content, {String? replyTo}) async {
    if (_currentSessionId == null) {
      onError?.call('No active chat session');
      return;
    }
    print('[ChatService] Sending message: "$content"');
    await _webSocketService.sendMessage(content, replyTo: replyTo);
  }

  // Handle incoming WebSocket message
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    print('[ChatService] Received message: ${data['content']} from ${data['from']}');
    final message = ChatMessage.fromWebSocket(data);
    
    // Deduplicate: Only add if not already present (by content, sender, and timestamp)
    final alreadyExists = _messages.any((m) =>
      m.content == message.content &&
      m.sender == message.sender &&
      m.timestamp == message.timestamp
    );
    if (!alreadyExists) {
      _messages.add(message);
      // Add to chat history
      if (_currentSessionId != null) {
        if (!_chatHistory.containsKey(_currentSessionId)) {
          _chatHistory[_currentSessionId!] = [];
        }
        _chatHistory[_currentSessionId!]!.add(message);
      }
      // Notify listeners
      onNewMessage?.call(message);
      onMessagesUpdated?.call(_messages);
    } else {
      print('[ChatService] Duplicate message ignored');
    }
  }

  // Handle notification (user not in chat but online)
  void _handleNotification(Map<String, dynamic> data) {
    // You can implement notification logic here
    // For example, show a snackbar or push notification
    print('Notification received: ${data['content']} from ${data['from']}');
  }

  // Get chat history for a specific session
  List<ChatMessage> getChatHistory(String sessionId) {
    return _chatHistory[sessionId] ?? [];
  }

  // Clear current chat
  void clearCurrentChat() {
    _messages.clear();
    _currentSessionId = null;
    onMessagesUpdated?.call(_messages);
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    await _webSocketService.disconnect();
  }

  // Dispose resources
  void dispose() {
    _webSocketService.dispose();
  }

  // Fetch messages with pagination
  Future<List<ChatMessage>> fetchMessagesPaginated({int limit = 30, DateTime? before}) async {
    print('fetchMessagesPaginated called: allMessagesLoaded=$allMessagesLoaded, isLoadingMore=$isLoadingMore');
    if (_currentUserId == null || _otherUserId == null) return [];
    if (allMessagesLoaded || isLoadingMore) return [];
    isLoadingMore = true;
    try {
      String url = '${ApiConfig.baseUrl}/api/chat/messages?user1=$_currentUserId&user2=$_otherUserId&limit=$limit';
      if (before != null) {
        url += '&before=${before.toIso8601String()}';
      }
      print('Requesting: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<ChatMessage> fetched = data.map((json) => ChatMessage.fromJson(json)).toList();
        print('Fetched ${fetched.length} messages');
        for (var m in fetched) {
          print('Fetched message: id=${m.id}, timestamp=${m.timestamp.toIso8601String()}');
        }
        if (fetched.isEmpty) allMessagesLoaded = true;
        isLoadingMore = false;
        return fetched;
      } else {
        isLoadingMore = false;
        return [];
      }
    } catch (e) {
      isLoadingMore = false;
      return [];
    }
  }

  // Helper to prepend older messages
  void prependMessages(List<ChatMessage> older) {
    _messages = [...older, ..._messages];
    onMessagesUpdated?.call(_messages);
  }
} 