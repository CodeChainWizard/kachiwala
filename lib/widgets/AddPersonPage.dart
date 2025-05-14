import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:newprg/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

import 'getUserDetails.dart';

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({super.key});

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isImageLoading = true;
  File? compressedImage;

  String selectedRole = 'user';
  final List<String> roles = ['user', 'admin'];

  @override
  void initState() {
    super.initState();
    loadAndCompressImage();
  }

  Future<void> loadAndCompressImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/placeholder.png";

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
          _isImageLoading = false;
        });
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      print("Error loading or compressing image: $e");
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  Future<File?> compressImage(String path) async {
    try {
      final newPath = "${path}_compressed.png";
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        newPath,
        quality: 10,
        format: CompressFormat.png,
      );

      if (result == null) {
        return null;
      }

      return File(result.path);
    } catch (e) {
      return null;
    }
  }

  void onAddPerson() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = selectedRole;

    if (name.isEmpty || email.isEmpty || password.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    try {
      final response = await ApiService.addUser(name, email, password, role);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person added successfully')),
        );

        // Clear fields after successful submission
        nameController.clear();
        emailController.clear();
        passwordController.clear();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GetUserDetails()),
        );

        setState(() {
          selectedRole = "user";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add person: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  bool _isPasswordVisiable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: Color(0xFF6F4E37),
        title: const Text('Add Person', style: TextStyle(color: Color(0xFFF5DEB3))),
        iconTheme: IconThemeData(color: Color(0xFFF5DEB3)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    // child: _isImageLoading
                    //     ? const CircularProgressIndicator()
                    //     : compressedImage != null
                    //     ? Image.file(
                    //   compressedImage!,
                    //   fit: BoxFit.cover,
                    // )
                    //     : const Icon(Icons.image_not_supported),
                  ),
                ),

                const SizedBox(height: 24),
                // Name Input Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Input Field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Phone Input Field
                TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisiable,
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisiable
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisiable = !_isPasswordVisiable;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole.isNotEmpty ? selectedRole : null,
                  items:
                      ["user", "admin"].map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Add Person Button
                ElevatedButton(
                  onPressed: onAddPerson,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    backgroundColor: Color(0xFF432B1A),
                  ),
                  child: const Text(
                    'Add Person',
                    style: TextStyle(color: Color(0xFFF3EBCB)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
