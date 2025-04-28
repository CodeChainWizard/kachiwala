import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'AddPersonPage.dart';
import 'EditUserPage.dart';

class GetUserDetails extends StatefulWidget {
  const GetUserDetails({super.key});

  @override
  State<GetUserDetails> createState() => _GetUserDetailsState();
}

class _GetUserDetailsState extends State<GetUserDetails> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      List<Map<String, dynamic>> fetchedUsers = await ApiService.getUsers(
        search: "",
        take: 10,
        skip: 0,
      );

      if (!mounted) return;
      setState(() {
        users = fetchedUsers;
        print("USER DETAILS: $users");
      });
    } catch (error) {
      _showError("Error fetching users: $error");
    }
  }

  // Future<void> _fetchUsers() async {
  //   final Uri url = Uri.parse("http://103.251.16.248:5000/api/users?search=&take=10&skip=0");
  //   // final url = ApiService.getUsers(search: "", take: 10, skip: 0);
  //
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? token = prefs.getString("token");
  //
  //     if (token == null) {
  //       _showError("Access Denied: No Authentication Token Found");
  //       return;
  //     }
  //
  //     final response = await http.get(
  //       url,
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(response.body);
  //
  //       if (responseData.containsKey("users")) {
  //         setState(() {
  //           users = List<Map<String, dynamic>>.from(responseData["users"]);
  //         });
  //       } else {
  //         _showError("Invalid response format: 'users' key missing");
  //       }
  //     } else if (response.statusCode == 401) {
  //       _showError("Unauthorized: Please log in again.");
  //     } else {
  //       _showError("Failed to load users: ${response.statusCode}");
  //     }
  //   } catch (error) {
  //     _showError("Error fetching users: $error");
  //   }
  // }

  void _deleteUser(int userId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final token = pref.getString("token");

    if (token != null) {
      bool success = await ApiService.deleteUser([userId], token);

      if (success) {
        print("USER ID: ${userId}");
        setState(() {
          users.removeWhere((user) => user["id"] == userId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User deleted successfully!")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete user")));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ✅ Navigate to Add User Page
  void _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPersonPage()),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: Color(0xFF6F4E37),
        title: Text("User Details", style: TextStyle(color: Color(0xFFF5DEB3)),),
        iconTheme: IconThemeData(color: Color(0xFFF5DEB3)),
        actions: [
          ElevatedButton.icon(
            onPressed: _navigateToAddUser,
            icon: const Icon(Icons.add, color: Color(0xFF6F4E37)), // Coffee icon color
            label: const Text(
              "Add New User",
              style: TextStyle(
                color: Color(0xFF6F4E37), // Coffee text color
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF5DEB3), // Light cream color
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            users.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFD7CCC8)),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Email",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Actions",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...users.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(user["name"] ?? "Unknown"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(user["email"] ?? "Unknown"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(user["password"] ?? "Unknown"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FittedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => EditUserPage(
                                                userId: user["id"],
                                                name: user["name"],
                                                email: user["email"],
                                                password: user["password"]
                                              ),
                                        ),
                                      );
                              
                                      if (result == true) {
                                        _fetchUsers(); // Refresh user list after edit
                                      }
                                    },
                                  ),
                              
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      int userId = user["id"];
                                      _deleteUser(userId);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
      ),
    );
  }
}
