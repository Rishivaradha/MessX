import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static SessionService get instance => _instance;

  User? _currentUser;
  List<Contact> _contacts = [];

  User? get currentUser => _currentUser;
  List<Contact> get contacts => _contacts;

  Future<void> initialize() async {
    await _loadSession();
  }

  Future<bool> login(String name) async {
    if (name.trim().isEmpty) return false;

    _currentUser = User(
      name: name.trim(),
      deviceId: const Uuid().v4(),
    );

    // Initialize empty contacts list - users will be added from Internet Chat scanner
    _contacts = [];

    await _saveSession();
    notifyListeners();
    return true;
  }

  void addContact(Contact contact) {
    // Remove any existing contact with the same name to prevent duplicates
    _contacts.removeWhere((c) => c.name == contact.name);
    _contacts.add(contact);
    _saveSession();
    notifyListeners();
    debugPrint('✅ Contact added: ${contact.name}');
  }

  void removeOfflineContacts(List<String> onlineUsers) {
    // Remove contacts that are no longer online
    final initialCount = _contacts.length;
    _contacts.removeWhere((contact) => !onlineUsers.contains(contact.name));
    
    if (_contacts.length != initialCount) {
      _saveSession();
      notifyListeners();
      debugPrint('🧹 Removed offline contacts. Online: $onlineUsers');
    }
  }

  void removeContact(String deviceId) {
    _contacts.removeWhere((c) => c.deviceId == deviceId);
    _saveSession();
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _contacts.clear();
    _clearStoredSession();
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentUser != null) {
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    }

    final contactsJson = _contacts.map((c) => c.toJson()).toList();
    await prefs.setString('contacts', jsonEncode(contactsJson));
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }

    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> contactsList = jsonDecode(contactsJson);
      _contacts = contactsList.map((c) => Contact.fromJson(c)).toList();
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('contacts');
  }
}

class User {
  final String name;
  final String deviceId;

  User({required this.name, required this.deviceId});

  Map<String, dynamic> toJson() => {
    'name': name,
    'deviceId': deviceId,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'],
    deviceId: json['deviceId'],
  );
}

// ✅ Contact class also defined here to avoid import issues
class Contact {
  final String name;
  final String deviceId;
  final bool isActive;

  Contact({
    required this.name,
    required this.deviceId,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'deviceId': deviceId,
    'isActive': isActive,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    name: json['name'],
    deviceId: json['deviceId'],
    isActive: json['isActive'] ?? false,
  );
}
