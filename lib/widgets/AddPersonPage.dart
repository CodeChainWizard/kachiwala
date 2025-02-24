import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({super.key});

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isImageLoading = true;
  File? compressedImage;

  @override
  void initState() {
    super.initState();
    loadAndCompressImage();
  }

  Future<void> loadAndCompressImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/placeholder.png";

      final ByteData data = await rootBundle.load("assets/images/kachiwala.png");
      final buffer = data.buffer;
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

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

  void onAddPerson() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    // Handle adding the person logic here, like saving data to a database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Person added successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Person', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF1D3557),
        iconTheme: IconThemeData(color: Colors.white),
      ),
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
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: 'Enter Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
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
                  backgroundColor: Color(0xFF1D3557),
                ),
                child: const Text(
                  'Add Person',
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
