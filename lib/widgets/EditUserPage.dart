import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditUserPage extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String password;

  const EditUserPage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    passwordController = TextEditingController(text: widget.password);
  }

  Future<void> _updateUser() async {
    final success = await ApiService.updateUser(
      widget.userId,
      nameController.text,
      emailController.text,
      passwordController.text,
    );

    final snackBar = SnackBar(
      content: Text(success ? "User updated successfully!" : "Failed to update user."),
      backgroundColor: success ? Colors.green : Colors.redAccent,
    );

    if (success) Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.brown),
      filled: true,
      fillColor: const Color(0x22FFFDD0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.brown),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF432B1A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF432B1A),
        elevation: 4,
        iconTheme: const IconThemeData(color: Color(0xFFFFFDD0)),
        title: const Text(
          "Edit User",
          style: TextStyle(
            color: Color(0xFFFFFDD0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // color: const Color(0xFFFFFDD0),
            borderRadius: BorderRadius.circular(16),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.brown.withOpacity(0.2),
            //     blurRadius: 10,
            //     offset: const Offset(0, 6),
            //   ),
            // ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _inputDecoration("Name"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: _inputDecoration("Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration("Password"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF432B1A),
                    foregroundColor: const Color(0xFFFFFDD0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
