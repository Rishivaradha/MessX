import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/session_service.dart';

class InternetChatScreen extends StatefulWidget {
  const InternetChatScreen({super.key});

  @override
  State<InternetChatScreen> createState() => _InternetChatScreenState();
}

class _InternetChatScreenState extends State<InternetChatScreen> {
  final WebSocketService _wsService = WebSocketService.instance;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    final currentUser = SessionService.instance.currentUser;
    if (currentUser != null) {
      // Disconnect first to prevent duplicate connections
      _wsService.disconnect();
      
      // Small delay to ensure clean disconnect
      await Future.delayed(const Duration(milliseconds: 100));
      
      final success = await _wsService.connect(currentUser.name);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to server. Make sure server is running.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addUserToContacts(String username) {
    final contact = Contact(
      name: username,
      deviceId: 'ws-$username-${DateTime.now().millisecondsSinceEpoch}',
      isActive: true,
    );
    
    SessionService.instance.addContact(contact);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$username added to contacts'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate back to home screen
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Scan for Users',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Refresh button removed to prevent connection issues
      ),
      body: AnimatedBuilder(
        animation: _wsService,
        builder: (context, child) {
          if (!_wsService.isConnected) {
            return _buildConnectionStatus();
          }

          return _buildUsersList();
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'Scanning for users...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Looking for online ChatApp users',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final onlineUsers = _wsService.onlineUsers
        .where((user) => user != _wsService.currentUsername)
        .where((user) => user.trim().isNotEmpty) // Remove empty usernames
        .toSet() // Convert to Set to remove duplicates
        .toList() // Convert back to List
        ..sort(); // Sort alphabetically for consistent display

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _wsService.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _wsService.isConnected ? 'Connected as ${_wsService.currentUsername}' : 'Disconnected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${onlineUsers.length} users online',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: onlineUsers.isEmpty
              ? _buildEmptyUsersList()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: onlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = onlineUsers[index];
                    return _buildUserItem(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyUsersList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              color: Colors.purple[300],
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No users found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning for ChatApp users...\nOther users will appear here when they open the app',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(String username) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'Online • Tap to add contact',
          style: TextStyle(
            color: Colors.green,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.person_add,
          color: Colors.purple,
          size: 20,
        ),
        onTap: () => _addUserToContacts(username),
      ),
    );
  }
}
