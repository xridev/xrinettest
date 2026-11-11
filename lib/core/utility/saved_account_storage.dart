import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedAccountStorage {
  static const String _accountsKey = 'savedAccounts';
  static const String _activeAccountKey = 'myPersonalId';

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_accountsKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(savedData);

      return decoded
          .whereType<Map>()
          .map((account) => Map<String, dynamic>.from(account))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAccount({
    required String userId,
    required String email,
    required String name,
    required String userName,
    required String profileImageUrl,
  }) async {
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();

    accounts.removeWhere((account) => account['userId'] == userId);

    accounts.insert(0, {
      'userId': userId,
      'email': email,
      'name': name,
      'userName': userName,
      'profileImageUrl': profileImageUrl,
    });

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static Future<void> removeAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();

    accounts.removeWhere((account) => account['userId'] == userId);

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static Future<void> clearActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeAccountKey);
  }
}
