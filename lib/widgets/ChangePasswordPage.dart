import 'dart:convert';

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
        // ✅ Store the new password in SharedPreferences
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
      appBar: AppBar(title: Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: "Current Password",
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
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: "New Password",
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
            SizedBox(height: 20),
            isUpdating
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _changePassword,
                  child: Text("Update Password"),
                ),
          ],
        ),
      ),
    );
  }
}
