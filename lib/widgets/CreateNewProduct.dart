import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:newprg/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CropScreen.dart';

class AddProductPage extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductPage({Key? key, required this.onProductAdded})
      : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController designNoController = TextEditingController();
  final TextEditingController meterController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController packingController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode designNoFocusNode = FocusNode();
  final FocusNode meterFocusNode = FocusNode();
  final FocusNode sizeFocusNode = FocusNode();
  final FocusNode priceFocusNode = FocusNode();
  final FocusNode typeFocusNode = FocusNode();
  final FocusNode colorFocusNode = FocusNode();
  final FocusNode packingFocusNode = FocusNode();

  bool isLoading = false;
  List<Uint8List?> images = [];

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();

    var status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 100,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          final imageBytes = await pickedFile.readAsBytes();
          setState(() {
            images.add(imageBytes);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting images: $e")),
      );
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || images.isEmpty) {
      _showValidationDialog(
        'Please fill in all fields and select at least one image.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final personName = pref.getString("name");
      final token = pref.getString("token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Credentials')),
        );
        setState(() => isLoading = false);
        return;
      }

      List<MultipartFile> multipartImages = images.map((image) {
        return MultipartFile.fromBytes(image!, filename: 'image.jpg');
      }).toList();

      FormData formData = FormData.fromMap({
        "name": nameController.text,
        "designNo": designNoController.text,
        "meter": meterController.text,
        "size": sizeController.text,
        "rate": priceController.text,
        "type": typeController.text,
        "color": colorController.text,
        "packing": packingController.text,
        "images": multipartImages,
        "person": personName
      });

      var response = await ApiService.addProduct(formData, token);

      if (response.statusCode == 201) {
        widget.onProductAdded();
        Navigator.pop(context, true);
      } else {
        _showValidationDialog(
          'Unable to add product. Please check your information or try again later.',
        );
      }
    } catch (e) {
      _showValidationDialog(
        'Something went wrong. Please check your input or try again later.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Oops! Something Went Wrong',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.redAccent,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: ui.Color(0xFF6F4F37),
        title: const Text("Create New Product", style: TextStyle(color: ui.Color(0xFFF5DEB3))),
        iconTheme: const IconThemeData(color: ui.Color(0xFFF5DEB3)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, "Name *", focusNode: nameFocusNode),
                _buildTextField(designNoController, "Design No *", focusNode: designNoFocusNode),
                _buildTextField(meterController, "Meter *", focusNode: meterFocusNode),
                _buildTextField(sizeController, "Size *", focusNode: sizeFocusNode),
                _buildTextField(priceController, "Price *", isNumeric: true, focusNode: priceFocusNode),
                _buildTextField(typeController, "Type *", focusNode: typeFocusNode),
                _buildTextField(colorController, "Color *", focusNode: colorFocusNode),
                _buildTextField(packingController, "Packing *", focusNode: packingFocusNode),
                const SizedBox(height: 20),
                _buildImageSelectionSection(),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isLoading ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color(0xFFFFFDD0), // Cream text
                    backgroundColor: Color(0xFF6F4E37), // Brown background
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFDD0)),
                  )
                      : const Text(
                    "Add Product",
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
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool isNumeric = false,
        required FocusNode focusNode,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        textCapitalization: TextCapitalization.none,
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumeric
            ? [] // no formatter for numbers
            : [UpperCaseTextFormatter()], // custom formatter
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF432B1A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF3EBCB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF432B1A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF432B1A)
          ),
        ),
        const SizedBox(height: 8),
        Text(
          images.isEmpty
              ? 'At least one image is required'
              : '${images.length} image(s) selected',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        images.isEmpty
            ? SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(
              Icons.add_photo_alternate,
              color: Color(0xFF6F4E37), // Coffee brown icon
            ),
            label: const Text(
              'SELECT IMAGES',
              style: TextStyle(
                color: Color(0xFF6F4E37), // Coffee brown text
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF6F4E37)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Color(0x22FFFDD0),
            ),
          ),

        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => _buildImageThumbnail(index),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return GestureDetector(
      onTap: () => _showImageOptions(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              images[index]!,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showImageOptions(index),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  images.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[600],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.zoom_out_map),
                title: const Text('View Full Image'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Image.memory(
                          images[index]!,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop),
                title: const Text('Crop Image'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropScreen(
                          image: images[index]!,
                          index: index,
                        ),
                      ),
                    );
                    if (result != null) {
                      final croppedImage = result['croppedImage'];
                      if (croppedImage != null) {
                        setState(() {
                          images[index] = croppedImage;
                        });
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to crop image: $e")),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

