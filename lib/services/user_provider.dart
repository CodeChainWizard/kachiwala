import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userProvider = StateNotifierProvider<UserNotifier, Map<String, dynamic>?>(
      (ref) => UserNotifier(),
);

class UserNotifier extends StateNotifier<Map<String, dynamic>?> {
  UserNotifier() : super(null) {
    _loadUserFromPrefs(); // Load user when app starts
  }

  Future<void> _loadUserFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString("name");
    String? token = prefs.getString("token");

    if (name != null && token != null) {
      state = {"name": name, "token": token};
    }
  }

  Future<void> setUser(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", userData["name"]);
    await prefs.setString("token", userData["token"]);

    state = userData;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = null;
  }
}
