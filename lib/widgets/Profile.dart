import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newprg/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChangePasswordPage.dart';

class Profile extends StatefulWidget {
  final int userId;

  Profile({required this.userId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        setState(() {
          errorMessage = "Authentication token is missing.";
          isLoading = false;
        });
        return;
      }

      final response = await ApiService.getUserId(widget.userId, token);

      if (response != null) {
        if (response.containsKey("error")) {
          setState(() {
            errorMessage = response["error"];
            isLoading = false;
          });
        } else {
          setState(() {
            userData = {
              "id": response["id"] ?? widget.userId,
              "name": response["name"] ?? "N/A",
              "email": response["email"] ?? "N/A",
              "role": response["role"] ?? "N/A",
              "password": "******", // Hide password for security
            };
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load user details.");
      }
    } catch (error) {
      print("Error fetching user details: $error");
      setState(() {
        errorMessage = "Error fetching user data. Please try again.";
        isLoading = false;
      });
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordPage(userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile Page")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : userData == null
          ? Center(child: Text("No user data available."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(5),
          },
          children: [
            _buildTableRow("User ID", userData?["id"].toString() ?? "N/A"),
            _buildTableRow("Name", userData?["name"] ?? "N/A"),
            _buildTableRow("Email", userData?["email"] ?? "N/A"),
            _buildTableRow("Role", userData?["role"] ?? "N/A"),
            _buildTableRow("Password", userData?["password"] ?? "N/A"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToChangePassword,
        child: Icon(Icons.lock),
        tooltip: "Change Password",
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }
}
