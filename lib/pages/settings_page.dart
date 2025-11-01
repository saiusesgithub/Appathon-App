import 'package:flutter/material.dart';

// Settings page placeholder
// Can add app settings, preferences, about info, etc. later

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0B0B0D),
            fontFamily: "Orbitron",
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF0B0B0D),
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            // App Info Card
            Card(
              color: const Color(0xFF1F1F1F),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset('assets/logo/logo.jpg', width: 80),
                    const SizedBox(height: 15),
                    const Text(
                      'ShadowMesh',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Orbitron",
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Secure. Offline. Untraceable.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Settings sections
            const Text(
              'General',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            _buildSettingItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Configure app notifications',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.storage,
              title: 'Storage',
              subtitle: 'Manage received files',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Privacy',
              subtitle: 'Privacy settings',
              onTap: () {},
            ),
            
            const SizedBox(height: 20),
            const Text(
              'About',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            _buildSettingItem(
              icon: Icons.info,
              title: 'About ShadowMesh',
              subtitle: 'Learn more about the app',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.code,
              title: 'Open Source',
              subtitle: 'View source code',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1F1F1F),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
