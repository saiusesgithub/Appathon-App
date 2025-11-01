import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemUtils {
  static const MethodChannel _channel = MethodChannel('app_control');

  /// Attempts to open the system uninstall UI for this app (Android only).
  /// On other platforms, opens the app settings screen as a fallback.
  static Future<void> requestUninstallOrOpenSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('uninstallSelf');
        return;
      } catch (_) {
        // Fall through to app settings if uninstall intent fails
      }
    }
    // Fallback: open app settings so user can uninstall/manage the app
    await openAppSettings();
  }
}
