import 'package:flutter/material.dart';
import '../services/chat_storage_service.dart';
import '../services/wipe_service.dart';
import '../utils/system_utils.dart';

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

            const SizedBox(height: 30),
            _buildDangerZone(context),
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

  // --- Kill Switch UI Block ---
  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger Zone',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFF1F1F1F),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kill Switch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Wipes all saved chats, files, and local data. Then opens the system uninstall screen to remove the app.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text(
                      'Activate Kill Switch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmKillSwitch(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmKillSwitch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F1F1F),
            title: const Text('Activate Kill Switch?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'This will permanently delete all chats, received files, and local data. Next, you\'ll be taken to the uninstall screen. This cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, Wipe & Uninstall'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // Progress dialog while wiping
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    // 1) Clear local app data
    await WipeService.clearAllData();
    await ChatStorageService.clearHostChat();
    await ChatStorageService.clearClientChat();

    // Close progress
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // 2) Notify and open uninstall/settings
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Local data wiped. Opening uninstall/settings...'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 2),
    ));

    await SystemUtils.requestUninstallOrOpenSettings();
  }
}
