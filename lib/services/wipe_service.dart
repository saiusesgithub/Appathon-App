import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wipes local app data stored by the app (preferences, received files, caches).
class WipeService {
  /// Clear SharedPreferences and delete app-specific storage directories.
  static Future<void> clearAllData() async {
    // 1) Clear shared preferences (removes saved chats and any other keys)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // ignore: avoid_print
      print('🧹 SharedPreferences cleared');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error clearing SharedPreferences: $e');
    }

    // 2) Delete received files and app document directories we own
    await _deleteDirectorySafely(await getApplicationDocumentsDirectory());

    // 3) Delete temporary cache directory
    try {
      final tmp = await getTemporaryDirectory();
      await _deleteDirectorySafely(tmp);
    } catch (_) {}

    // 4) Application support directory (iOS/macOS)
    try {
      final support = await getApplicationSupportDirectory();
      await _deleteDirectorySafely(support);
    } catch (_) {}
  }

  static Future<void> _deleteDirectorySafely(Directory dir) async {
    try {
      if (await dir.exists()) {
        // Only delete children to avoid permission issues with the root folder itself
        await for (final entity in dir.list(recursive: false)) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
        // ignore: avoid_print
        print('🗑️ Cleared directory: ${dir.path}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error clearing directory ${dir.path}: $e');
    }
  }
}
