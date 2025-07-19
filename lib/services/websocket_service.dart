import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _userId;
  String? _sessionId;
  bool _isConnected = false;
  bool _isRegistered = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  bool _waitingForRegistered = false;
  Completer<void>? _registeredCompleter;

  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  Function()? onJoined; // Called when joined event is received
  Function(dynamic error)? onJoinError;

  // Getters
  bool get isConnected => _isConnected;
  bool get isRegistered => _isRegistered;
  String? get userId => _userId;
  String? get sessionId => _sessionId;

  // Initialize WebSocket connection
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isRegistered = false;
    _waitingForRegistered = true;
    _registeredCompleter = Completer<void>();
    await _connect();
  }

  // Connect to WebSocket server
  Future<void> _connect() async {
    try {
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      print('[WebSocketService] Connecting to: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl'));
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      print('[WebSocketService] WebSocket connected successfully');
      onConnected?.call();
      
      // Register user immediately after connection
      await _register();
      
      // Start heartbeat
      _startHeartbeat();
      
      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      
    } catch (e) {
      print('[WebSocketService] Connection error: $e');
      _handleError(e);
    }
  }

  // Register user with the server
  Future<void> _register() async {
    if (_channel != null && _userId != null) {
      final registerMessage = {
        'type': 'register',
        'userId': _userId,
      };
      print('[WebSocketService] Registering user: $_userId');
      _channel!.sink.add(jsonEncode(registerMessage));
    } else {
      print('[WebSocketService] Cannot register - channel: ${_channel != null}, userId: $_userId');
    }
  }

  // Join a chat session
  Future<void> joinSession(String sessionId, {String? otherUserId}) async {
    print('[WebSocketService] Joining session: $sessionId');
    if (_channel != null && _channel!.sink != null) {
      final joinPayload = {
        'type': 'join',
        'userId': _userId,
        'sessionId': sessionId,
        if (otherUserId != null) 'otherUserId': otherUserId,
      };
      _channel!.sink.add(jsonEncode(joinPayload));
    }
  }

  // Send a message
  Future<void> sendMessage(String content, {String? replyTo}) async {
    print('[WebSocketService] sendMessage called with content: "$content"');
    print('[WebSocketService] _channel is null: ${_channel == null}');
    print('[WebSocketService] _sessionId is null: ${_sessionId == null}');
    print('[WebSocketService] _sessionId value: $_sessionId');
    
    if (_channel != null && _sessionId != null) {
      final message = {
        'type': 'message',
        'content': content,
        'sessionId': _sessionId, // Always include sessionId
        if (replyTo != null) 'replyTo': replyTo,
      };
      print('[WebSocketService] Sending message: $message');
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('[WebSocketService] Cannot send message - channel or sessionId is null');
      if (_channel == null) {
        print('[WebSocketService] WebSocket channel is null');
      }
      if (_sessionId == null) {
        print('[WebSocketService] Session ID is null');
      }
    }
  }

  // Send heartbeat ping
  Future<void> _sendPing() async {
    if (_channel != null) {
      final pingMessage = {
        'type': 'ping',
      };
      
      _channel!.sink.add(jsonEncode(pingMessage));
    }
  }

  // Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    print('[WebSocketService] Received raw message: $message');
    try {
      final data = jsonDecode(message);
      
      switch (data['type']) {
        case 'registered':
          _isRegistered = true;
          _waitingForRegistered = false;
          if (_registeredCompleter != null && !_registeredCompleter!.isCompleted) {
            _registeredCompleter!.complete();
          }
          break;
          
        case 'joined':
          print('[WebSocketService] Joined session: ${data['sessionId']}');
          // Successfully joined chat session
          onJoined?.call();
          break;
          
        case 'message':
          print('[WebSocketService] Received message: ${data['content']}');
          // Chat message received
          onMessageReceived?.call(data);
          break;
          
        case 'notification':
          // Notification received (user not in chat but online)
          onNotificationReceived?.call(data);
          break;
          
        case 'pong':
          // Heartbeat response
          break;
          
        case 'error':
          print('[WebSocketService] Error received: ${data['error']}');
          if (data['error'] != null && data['error'].contains('Invalid session or user')) {
            onJoinError?.call(data['error']);
          }
          onError?.call(data['error'] ?? 'Unknown error');
          break;
      }
    } catch (e) {
      print('[WebSocketService] Error decoding message: $e');
      onError?.call('Failed to parse message: $e');
    }
  }

  // Handle connection errors
  void _handleError(dynamic error) {
    _isConnected = false;
    _isRegistered = false;
    onError?.call('WebSocket error: $error');
    _scheduleReconnect();
  }

  // Handle disconnection
  void _handleDisconnect() {
    _isConnected = false;
    _isRegistered = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      final delay = Duration(seconds: _reconnectAttempts + 1);
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts++;
        _connect();
      });
    } else {
      onError?.call('Max reconnection attempts reached');
    }
  }

  // Disconnect and cleanup
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    _isRegistered = false;
    _sessionId = null;
  }

  // Dispose resources
  void dispose() {
    disconnect();
  }

  // Wait for registration to complete
  Future<void> waitForRegistration() async {
    if (_isRegistered) return;
    if (_registeredCompleter != null) {
      await _registeredCompleter!.future;
    }
  }

  // Set the current sessionId
  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }
} 