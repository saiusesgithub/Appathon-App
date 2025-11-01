import 'package:flutter/material.dart';
import 'home_page.dart';
import 'standalone_file_transfer.dart';
import 'settings_page.dart';

// This is the new main navigation page with bottom nav bar
// It contains 3 tabs: Chat, Files, Settings

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  // Track which tab is currently selected (0 = Chat, 1 = Files, 2 = Settings)
  int _currentIndex = 0;
  
  // List of pages for each tab
  final List<Widget> _pages = [
    const HomePage(),                    // Tab 0: Chat/Messaging
    const StandaloneFileTransferPage(),  // Tab 1: File Transfer
    const SettingsPage(),                // Tab 2: Settings
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the current page based on selected tab
      body: _pages[_currentIndex],
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          // Chat Tab
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          // Files Tab
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          // Settings Tab
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
