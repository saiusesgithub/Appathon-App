import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
// Note: On Android we use the device_apps plugin; other platforms no-op here.

class SystemUtils {
  static const MethodChannel _channel = MethodChannel('app_control');

  /// Attempts to open the system uninstall UI for this app (Android only).
  /// On other platforms, opens the app settings screen as a fallback.
  static Future<void> requestUninstallOrOpenSettings() async {
    if (Platform.isAndroid) {
      try {
        await DeviceApps.uninstallApp('com.example.shadowmesh');
        return;
      } catch (_) {
        // Try native app settings via channel
        try {
          await _channel.invokeMethod('openAppSettingsNative');
          return;
        } catch (_) {}
        // Fall through to package-based plugin method
      }
    }
    // Non-Android: nothing to do
    return;
  }
}
