import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'session_service.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  static WebSocketService get instance => _instance;

  WebSocketChannel? _channel;
  String? _currentUsername;
  List<ChatMessage> _messages = [];
  List<String> _onlineUsers = [];
  bool _isConnected = false;
  
  // Message deduplication
  final Set<String> _processedMessages = <String>{};
  static const int _maxProcessedMessages = 1000; // Limit memory usage

  // Getters
  List<ChatMessage> get messages => _messages;
  List<String> get onlineUsers => _onlineUsers;
  
  bool isUserOnline(String username) {
    return _onlineUsers.contains(username);
  }
  bool get isConnected => _isConnected;
  String? get currentUsername => _currentUsername;

  // WebSocket server URL - using cloud deployment
  static const String _serverUrl = 'wss://first-app-production-0c2f.up.railway.app';

  Future<bool> connect(String username) async {
    try {
      // Ensure we're disconnected first
      if (_channel != null) {
        await disconnect();
      }
      
      _currentUsername = username;
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      
      // Send join message
      _sendMessage({
        'type': 'join',
        'username': username,
      });

      // Listen to messages
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          notifyListeners();
        },
      );

      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to connect: $e');
      return false;
    }
  }

  String _generateMessageHash(Map<String, dynamic> message) {
    // Create a unique hash for the message to detect duplicates
    final type = message['type'] ?? '';
    final username = message['username'] ?? '';
    final users = message['users']?.toString() ?? '';
    final from = message['from'] ?? '';
    final to = message['to'] ?? '';
    final messageText = message['message'] ?? '';
    
    return '$type:$username:$users:$from:$to:$messageText'.hashCode.toString();
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      
      // Generate hash for deduplication
      final messageHash = _generateMessageHash(message);
      
      // Check if we've already processed this exact message
      if (_processedMessages.contains(messageHash)) {
        // Silently ignore duplicate - no logging to reduce spam
        return;
      }
      
      // Add to processed messages set
      _processedMessages.add(messageHash);
      
      // Clean up old messages if set gets too large
      if (_processedMessages.length > _maxProcessedMessages) {
        final messagesToRemove = _processedMessages.take(_processedMessages.length - _maxProcessedMessages ~/ 2);
        _processedMessages.removeAll(messagesToRemove);
      }
      
      debugPrint('📥 Processing message: $message');
      
      switch (message['type']) {
        case 'joined':
        case 'join_success':
          debugPrint('✅ Successfully joined as ${message['username']}');
          break;
          
        case 'user_joined':
          final joinedUsername = message['username'];
          if (!_onlineUsers.contains(joinedUsername)) {
            _onlineUsers.add(joinedUsername);
            debugPrint('👤 User joined: $joinedUsername');
          }
          break;
          
        case 'user_left':
          final leftUsername = message['username'];
          _onlineUsers.remove(leftUsername);
          debugPrint('👋 User left: $leftUsername');
          
          // Add disconnect notification to chat history
          final disconnectMessage = ChatMessage(
            from: 'System',
            to: _currentUsername!,
            message: '$leftUsername has disconnected',
            timestamp: DateTime.now(),
            isFromMe: false,
            isSystemMessage: true,
          );
          _messages.add(disconnectMessage);
          debugPrint('📝 Added disconnect notification for $leftUsername');
          break;
          
        case 'users_list':
          final rawUsersList = List<String>.from(message['users']);
          // Remove duplicates by converting to Set and back to List
          final newUsersList = rawUsersList.toSet().toList();
          
          // Only update if the list actually changed
          if (!_listsEqual(_onlineUsers, newUsersList)) {
            final previousCount = _onlineUsers.length;
            _onlineUsers = newUsersList;
            debugPrint('👥 Updated users list: $_onlineUsers (${_onlineUsers.length} users, was $previousCount)');
            
            // Remove offline contacts from session
            SessionService.instance.removeOfflineContacts(_onlineUsers);
          }
          break;
          
        case 'chat_message':
        case 'message':
          debugPrint('💬 Received chat message from ${message['from']} to ${message['to']}: ${message['message']}');
          final chatMessage = ChatMessage(
            from: message['from'],
            to: message['to'],
            message: message['message'],
            timestamp: DateTime.now(),
            isFromMe: message['from'] == _currentUsername,
            isSystemMessage: false,
          );
          _messages.add(chatMessage);
          debugPrint('📝 Added received message to local storage');
          break;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  void sendChatMessage(String to, String message) {
    if (_channel != null && _isConnected) {
      debugPrint('📤 Sending message from $_currentUsername to $to: $message');
      _sendMessage({
        'type': 'chat_message',
        'from': _currentUsername,
        'to': to,
        'message': message,
      });
      
      // Add to local messages immediately
      final chatMessage = ChatMessage(
        from: _currentUsername!,
        to: to,
        message: message,
        timestamp: DateTime.now(),
        isFromMe: true,
        isSystemMessage: false,
      );
      _messages.add(chatMessage);
      debugPrint('📝 Added local message: ${chatMessage.message}');
      notifyListeners();
    } else {
      debugPrint('❌ Cannot send message - not connected');
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
      debugPrint('📤 Sent message: ${jsonEncode(message)}');
    }
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    final set1 = list1.toSet();
    final set2 = list2.toSet();
    
    return set1.length == set2.length && set1.containsAll(set2);
  }

  List<ChatMessage> getMessagesWithUser(String username) {
    return _messages.where((msg) => 
      (msg.from == username && msg.to == _currentUsername) ||
      (msg.from == _currentUsername && msg.to == username)
    ).toList();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      try {
        _sendMessage({
          'type': 'leave',
          'username': _currentUsername,
        });
        await _channel!.sink.close(status.normalClosure);
      } catch (e) {
        debugPrint('Error during disconnect: $e');
      }
      _channel = null;
    }
    
    _isConnected = false;
    _currentUsername = null;
    _messages.clear();
    _onlineUsers.clear();
    _processedMessages.clear(); // Clear processed messages on disconnect
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class ChatMessage {
  final String from;
  final String to;
  final String message;
  final DateTime timestamp;
  final bool isFromMe;
  final bool isSystemMessage;

  ChatMessage({
    required this.from,
    required this.to,
    required this.message,
    required this.timestamp,
    required this.isFromMe,
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isFromMe': isFromMe,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    from: json['from'],
    to: json['to'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
    isFromMe: json['isFromMe'],
  );
}
