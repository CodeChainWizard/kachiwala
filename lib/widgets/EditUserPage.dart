import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditUserPage extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String password;

  EditUserPage({required this.userId, required this.name, required this.email, required this.password});

  @override
  _EditUserPageState createState() => _EditUserPageState();
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
    bool success = await ApiService.updateUser(
      widget.userId,
      nameController.text,
      emailController.text,
        passwordController.text
    );

    if (success) {
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update user.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
