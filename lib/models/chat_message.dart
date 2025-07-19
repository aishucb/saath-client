class ChatMessage {
  final String id;
  final String sender;
  final String recipient;
  final String content;
  final DateTime timestamp;
  final String? replyTo;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.timestamp,
    this.replyTo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      sender: json['sender'] ?? '',
      recipient: json['recipient'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      replyTo: json['replyTo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'recipient': recipient,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'replyTo': replyTo,
    };
  }

  // Create a message from WebSocket data
  factory ChatMessage.fromWebSocket(Map<String, dynamic> data) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      sender: data['from'] ?? '',
      recipient: '', // Will be set by the chat service
      content: data['content'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      replyTo: data['replyTo'],
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $sender, content: $content, timestamp: $timestamp)';
  }
} 