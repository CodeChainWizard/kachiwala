import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../home_page.dart';
import '../main.dart';

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
  bool _isLoading = true; // To track if the image is still loading

  @override
  void initState() {
    super.initState();
    loadAndCompressImage();
  }

  void onLoginSuccess(BuildContext context) async {
    await setLoginStatus(true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _navigateToHomePage() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Enter Both Username and Password')),
      );
      return;
    }

    if (email == 'narayan' && password == 'kachiwala') {
      onLoginSuccess(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Credentials')),
      );
    }
  }

  Future<void> loadAndCompressImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/kachiwala.png";

      final ByteData data = await rootBundle.load("assets/images/kachiwala.png");
      final buffer = data.buffer;
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(
          buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

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

      return File(result.path); // Return the compressed PNG file
    } catch (e) {
      print("Error during compression: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Center(
                child:SizedBox(
                  height: 100,
                  width: 100,
                  child: compressedImage != null
                      ? Image.file(compressedImage!, fit: BoxFit.cover,)
                      // ? Image.asset("assets/images/kachiwala.png")
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Log in',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Email Input Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              // Password Input Field with Toggle Visibility
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
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
              // Continue Button
              ElevatedButton(
                onPressed: _navigateToHomePage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.black,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}