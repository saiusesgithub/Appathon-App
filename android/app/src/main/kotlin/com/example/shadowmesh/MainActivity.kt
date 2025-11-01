package com.example.shadowmesh

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.content.ActivityNotFoundException

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app_control"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"uninstallSelf" -> {
					try {
						val pkg = applicationContext.packageName
						val intent = Intent(Intent.ACTION_DELETE).apply {
							data = Uri.parse("package:$pkg")
							addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						}
						startActivity(intent)
						result.success(true)
					} catch (e: Exception) {
						result.error("UNINSTALL_ERROR", "Failed: ${e.message}", null)
					}
				}
				"openAppSettingsNative" -> {
					runOnUiThread {
						try {
							val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
								data = Uri.parse("package:${applicationContext.packageName}")
								addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							}
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("OPEN_SETTINGS_ERROR", e.message, null)
						}
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
