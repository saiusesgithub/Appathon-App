package com.example.shadowmesh

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app_control"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"uninstallSelf" -> {
					try {
						val pkg = applicationContext.packageName
						val intent = Intent(Intent.ACTION_UNINSTALL_PACKAGE)
						intent.data = Uri.parse("package:$pkg")
						intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
						startActivity(intent)
						result.success(true)
					} catch (e: Exception) {
						result.error("UNINSTALL_ERROR", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
