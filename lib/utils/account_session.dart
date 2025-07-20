import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSession {
  static const String _sessionKey = 'account_session';

  /// Save user details (id, name, email, etc.) as a JSON object
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    print('[AccountSession] Saving user: ' + user.toString());
    await prefs.setString(_sessionKey, jsonEncode(user));
  }

  /// Load user details. Returns null if not found.
  static Future<Map<String, dynamic>?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_sessionKey);
    print('[AccountSession] Loaded raw string: ' + (jsonString ?? 'null'));
    if (jsonString == null) return null;
    try {
      final user = Map<String, dynamic>.from(jsonDecode(jsonString));
      print('[AccountSession] Loaded user: ' + user.toString());
      return user;
    } catch (e) {
      print('[AccountSession] Error decoding user: $e');
      return null;
    }
  }

  /// Clear the account session
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Clear all user-related keys
  static Future<void> clearAllUserKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = [
      'current_user_id',
      'userId',
      'user_id',
      'customerId',
      'customer_id',
      _sessionKey,
    ];
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
} 