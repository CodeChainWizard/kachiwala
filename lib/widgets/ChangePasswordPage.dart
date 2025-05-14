import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newprg/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final int userId;

  ChangePasswordPage({required this.userId});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController =
  TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isUpdating = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  Future<void> _changePassword() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final token = pref.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication token is missing.")),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      bool success = await ApiService.changePassword(
        widget.userId,
        currentPasswordController.text.trim(),
        newPasswordController.text.trim(),
        token,
      );

      if (success) {
        await pref.setString("password", newPasswordController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully!")),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update password. Please check credentials.")),
        );
      }
    } catch (error) {
      print("Error updating password: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating password. Please try again.")),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        title: const Text(
          "Change Password",
          style: TextStyle(
            color: Color(0xFFF5DEB3),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF5DEB3)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "Update your password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F4E37),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Ensure your new password is strong and unique.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6F4E37),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isUpdating ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Color(0xFFFFFDD0), // Cream text
                  backgroundColor: Color(0xFF6F4E37), // Brown background
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: isUpdating
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFDD0)), // Cream loader
                )
                    : const Text(
                  "Update Password",
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
  }
}
