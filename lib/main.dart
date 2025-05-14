import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newprg/widgets/CreateNewProduct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'widgets/Login.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences pref = await SharedPreferences.getInstance();
  final token = pref.getString("token");

  runApp(ProviderScope(child: MyApp(isLoggedIn: token != null)));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SecureScreen(child: isLoggedIn ? HomePage() : LoginPage()),
      title: "kachiwala",
      debugShowCheckedModeBanner: false,
    );
  }
}


class SecureScreen extends StatefulWidget {
  final Widget child;
  SecureScreen({required this.child});

  @override
  _SecureScreenState createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const platform = MethodChannel('secure_screen');

  @override
  void initState() {
    super.initState();
    _enableSecureMode();
  }

  Future<void> _enableSecureMode() async {
    try {
      await platform.invokeMethod('enableSecureMode');
    } on PlatformException catch (e) {
      print("Failed to enable secure mode: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void showAddProductDialog(BuildContext context, VoidCallback onProductAdded) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AddProductPage(
        onProductAdded: onProductAdded,
        // isLoading: false,
      );
      // return AddProductDialog(
      //   onProductAdded: onProductAdded,
      //   isLoading: false, // Ensure isLoading is explicitly initialized
      // );
    },
  );
}

Future<void> setLoginStatus(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('login', isLoggedIn);
}

Future<bool> getLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('login') ?? false; // Ensures null doesn't cause a crash
}
