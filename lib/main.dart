import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newprg/widgets/Login.page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await getLoginStatus();
  runApp(ProviderScope(child: MyApp(isLoggedIn)));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp(this.isLoggedIn);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn ? HomePage() : LoginPage(),
      title: "kachiwala",
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> setLoginStatus(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('login', isLoggedIn);
}

Future<bool> getLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('login') ?? false;
}
