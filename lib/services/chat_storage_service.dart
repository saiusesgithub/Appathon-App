import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for saving and loading chat messages
class ChatStorageService {
  static const String _hostChatKey = 'host_chat_messages';
  static const String _clientChatKey = 'client_chat_messages';

  /// Save host chat messages
  static Future<void> saveHostChat(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(messages);
      await prefs.setString(_hostChatKey, jsonString);
      print('💾 Saved ${messages.length} host messages');
    } catch (e) {
      print('❌ Error saving host chat: $e');
    }
  }

  /// Save client chat messages
  static Future<void> saveClientChat(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(messages);
      await prefs.setString(_clientChatKey, jsonString);
      print('💾 Saved ${messages.length} client messages');
    } catch (e) {
      print('❌ Error saving client chat: $e');
    }
  }

  /// Load host chat messages
  static Future<List<Map<String, dynamic>>> loadHostChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_hostChatKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('📭 No saved host messages found');
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      final messages = decoded.cast<Map<String, dynamic>>();
      print('📬 Loaded ${messages.length} host messages');
      return messages;
    } catch (e) {
      print('❌ Error loading host chat: $e');
      return [];
    }
  }

  /// Load client chat messages
  static Future<List<Map<String, dynamic>>> loadClientChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_clientChatKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('📭 No saved client messages found');
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      final messages = decoded.cast<Map<String, dynamic>>();
      print('📬 Loaded ${messages.length} client messages');
      return messages;
    } catch (e) {
      print('❌ Error loading client chat: $e');
      return [];
    }
  }

  /// Clear host chat messages
  static Future<void> clearHostChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hostChatKey);
      print('🗑️ Cleared host chat');
    } catch (e) {
      print('❌ Error clearing host chat: $e');
    }
  }

  /// Clear client chat messages
  static Future<void> clearClientChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clientChatKey);
      print('🗑️ Cleared client chat');
    } catch (e) {
      print('❌ Error clearing client chat: $e');
    }
  }

  /// Check if host chat has saved messages
  static Future<bool> hasHostChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_hostChatKey);
    } catch (e) {
      return false;
    }
  }

  /// Check if client chat has saved messages
  static Future<bool> hasClientChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_clientChatKey);
    } catch (e) {
      return false;
    }
  }
}
