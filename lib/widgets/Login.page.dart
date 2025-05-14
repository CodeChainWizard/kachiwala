import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newprg/services/api_service.dart';
import 'package:newprg/services/user_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_page.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  File? compressedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAndCompressImage();
  }

  void onLoginSuccess(
    BuildContext context,
    String email,
    String password,
    String token,
  ) async {
    await setLoginStatus(true);

    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("email", email);
    await sp.setString("password", password);
    await sp.setString("token", token); // Save token

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _navigateToHomePage(BuildContext context, WidgetRef ref) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Enter Both Username and Password'),
        ),
      );
      return;
    }

    final response = await ApiService.login(email, password);

    if (response != null && response is Map<String, dynamic>) {
      print("✅ Response received: $response");

      String tokenStr =
          response.containsKey('token') ? response['token'].toString() : "";
      int userId =
          response.containsKey('userId')
              ? int.tryParse(response['userId'].toString()) ?? 0
              : 0;
      String role =
          response.containsKey("role") ? response['role'].toString() : "user";

      final userDetails = {
        "name": email,
        "password": password,
        "token": tokenStr,
      };

      ref.read(userProvider.notifier).setUser(userDetails);

      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.setString("email", email);
      await pref.setString("token", tokenStr);
      await pref.setString("userId", userId.toString());
      await pref.setString("role", role);

      print("✅ Stored userId: $userId");

      // Debug before calling onLoginSuccess
      print("🚀 Calling onLoginSuccess...");
      onLoginSuccess(context, email, password, tokenStr);
      print("✅ onLoginSuccess executed.");

      // Debug before navigation
      print("🚀 Navigating to HomePage...");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      print("✅ Navigation triggered.");
    } else {
      print("❌ Login failed, response: $response");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
    }
  }

  Future<void> loadAndCompressImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/kachiwala.png";

      final ByteData data = await rootBundle.load(
        "assets/images/kachiwala.png",
      );
      final buffer = data.buffer;
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      final File? compressed = await compressImage(tempPath);

      if (compressed != null) {
        setState(() {
          compressedImage = compressed;
          _isLoading = false;
        });
      } else {
        print("Compression returned null");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading or compressing image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File?> compressImage(String path) async {
    try {
      final newPath = "${path}_compressed.png";
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        newPath,
        quality: 20,
        format: CompressFormat.png,
      );

      if (result == null) {
        print("Compression failed");
        return null;
      }

      return File(result.path);
    } catch (e) {
      print("Error during compression: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF5F2E4),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: Image.asset("assets/images/kachiwala.png"),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Name',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Color(0xFF6F4E37)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Color(0xFF6F4E37),
                          width: 2.0,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Color(0xFF6F4E37)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Color(0xFF6F4E37),
                          width: 2.0,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToHomePage(context, ref),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: const Color(0xFFFFFDD0),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFDD0), // Cream text
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
