import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../widgets/simple_tab_bar.dart';
import 'internet_chat_screen.dart';
import 'chat_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  bool _isLoading = false;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSearchFocused = false;

  final List<String> _categories = ['All', 'Unread', 'Favourites', 'Groups'];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SessionService.instance.currentUser;
    final contacts = SessionService.instance.contacts;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(currentUser),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar with smooth transition
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isSearchVisible ? 60 : 0,
              child: _isSearchVisible ? _buildSearchBar() : const SizedBox.shrink(),
            ),
            
            // Tab bar for All, Unread, Favourites, Groups
            _buildTabBar(),
            
            // Content area with smooth transitions
            Expanded(
              child: _buildContentForCategory(contacts),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? currentUser) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (currentUser != null)
            Text(
              'Welcome, ${currentUser.name}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.wifi, color: Colors.purple),
          onPressed: _navigateToInternetChat,
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToInternetChat,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.25,
                maxHeight: 40,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth * 0.025).clamp(8.0, 12.0),
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    color: Colors.white,
                    size: (screenWidth * 0.04).clamp(16.0, 20.0),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSlider(List<Contact> contacts) {
    return SimpleTabBar(
      categories: _categories,
      selectedIndex: _selectedCategoryIndex,
      categoryCounts: _getCategoryCounts(contacts),
      onChanged: (index) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
    );
  }

  Widget _buildAddContactSection(List<Contact> contacts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Category: ${_categories[_selectedCategoryIndex]}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Active contacts count
          Text(
            '${contacts.where((c) => c.isActive).length} active',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToInternetChat,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.3),
                Colors.purple.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Internet Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _isSearchFocused 
              ? Colors.purple.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isSearchFocused = hasFocus;
          });
        },
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _isSearchFocused ? Colors.purple : Colors.purple[300],
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < _categories.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = i;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: i < _categories.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedCategoryIndex == i 
                        ? Colors.purple 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategoryIndex == i 
                          ? Colors.purple 
                          : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _categories[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedCategoryIndex == i 
                          ? Colors.white 
                          : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: _selectedCategoryIndex == i 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, int> _getCategoryCounts(List<Contact> contacts) {
    return {
      'All': contacts.length,
      'Unread': contacts.where((c) => c.isActive).length,
      'Favourites': 0,
      'Groups': 0,
    };
  }

  Widget _buildContentForCategory(List<Contact> contacts) {
    final selectedCategory = _categories[_selectedCategoryIndex];
    
    // Filter contacts based on search query
    List<Contact> filteredContacts = contacts;
    if (_searchController.text.isNotEmpty) {
      filteredContacts = contacts.where((contact) =>
          contact.name.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    switch (selectedCategory) {
      case 'All':
        return _buildAllChatsContent(filteredContacts);
      case 'Unread':
        return _buildUnreadChatsContent(filteredContacts);
      case 'Favourites':
        return _buildFavouritesContent();
      case 'Groups':
        return _buildGroupsContent();
      default:
        return _buildAllChatsContent(filteredContacts);
    }
  }

  Widget _buildAllChatsContent(List<Contact> contacts) {
    if (contacts.isEmpty) {
      return _buildEmptyState('No contacts yet', 'Scan for nearby ChatApp users to start chatting');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return _buildContactItem(contacts[index]);
      },
    );
  }

  Widget _buildContactItem(Contact contact) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToChat(contact),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildContactAvatar(contact),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getCurrentTime(),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(Contact contact) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple,
                Color(0xFF7B1FA2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Color(0x4D9C27B0),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadChatsContent(List<Contact> contacts) {
    final unreadContacts = contacts.where((c) => c.isActive).toList();

    if (unreadContacts.isEmpty) {
      return _buildEmptyState('No unread chats', 'All caught up! 🎉');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: unreadContacts.length,
      itemBuilder: (context, index) => _buildContactItem(unreadContacts[index]),
    );
  }

  Widget _buildFavouritesContent() {
    return _buildEmptyState('No favourites yet', 'Mark chats as favourite to see them here');
  }

  Widget _buildGroupsContent() {
    return _buildEmptyState('No groups yet', 'Create groups to chat with multiple friends');
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.purple[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildAddContactButton(),
        ],
      ),
    );
  }

  void _navigateToChat(Contact contact) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(contact: contact),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }


  void _navigateToInternetChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const InternetChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showSessionInfo() {
    final currentUser = SessionService.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Session Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', currentUser?.name ?? "Unknown"),
            const SizedBox(height: 8),
            _buildInfoRow('Device ID', '${currentUser?.deviceId.substring(0, 16)}...'),
            const SizedBox(height: 8),
            _buildInfoRow('Contacts', '${SessionService.instance.contacts.length}'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Nearby Connections',
              "Ready",
              color: Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'End session and clear all contacts?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SessionService.instance.clearSession();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
