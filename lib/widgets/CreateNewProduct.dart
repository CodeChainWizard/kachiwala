import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:newprg/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'CropScreen.dart';

class AddProductPage extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductPage({Key? key, required this.onProductAdded})
    : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // final typeController = TextEditingController();
  // final codeController = TextEditingController();
  // final designController = TextEditingController();
  // final nameController = TextEditingController();
  // final descriptionController = TextEditingController();
  // final sizeController = TextEditingController();
  // final colorController = TextEditingController();
  // final packingController = TextEditingController();
  // final rateController = TextEditingController();
  // final meterController = TextEditingController();

  // --- Text-Filed ----
  final Name = TextEditingController();
  final DesignNo = TextEditingController();
  final Meter = TextEditingController();
  final Size = TextEditingController();
  final Price = TextEditingController();
  final Type = TextEditingController();
  final Paking = TextEditingController();
  final Color = TextEditingController();

  // --- Focus Node ----
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode designNoFocusNode = FocusNode();
  final FocusNode meterFocusNode = FocusNode();
  final FocusNode sizeFocusNode = FocusNode();
  final FocusNode priceFocusNode = FocusNode();
  final FocusNode typeFocusNode = FocusNode();
  final FocusNode colorFocusNode = FocusNode();
  final FocusNode packingFocusNode = FocusNode();

  bool isLoading = false;
  bool isImagePicked = false;
  List<Uint8List?> images = [];
  Uint8List? compressedImage;

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();

        // final compressed = await _compressImage(imageBytes);
        // if (compressed != null) {
        //   setState(() {
        //     compressedImage = compressed;
        //     images.add(compressed);
        //   });
        // }
        setState(() {
          images.add(imageBytes);
        });

      }
    } catch (e) {
      print("Error selecting image: $e");
    }
  }

  Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      print("Error: Empty image data received for compression.");
      return null;
    }

    try {
      final compressedImage = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 300,
        minHeight: 300,
        quality: 100,
      );

      if (compressedImage == null || compressedImage.isEmpty) {
        print("Error: Image compression failed.");
        return null;
      }

      return compressedImage;
    } catch (e) {
      print("Error during image compression: $e");
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (Name.text.isEmpty ||
        DesignNo.text.isEmpty ||
        Meter.text.isEmpty ||
        Size.text.isEmpty ||
        Price.text.isEmpty ||
        Type.text.isEmpty ||
        Paking.text.isEmpty ||
        Color.text.isEmpty ||
        images.isEmpty) {
      _showValidationDialog(
        'Please fill in all fields and select at least one image.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<MultipartFile> multipartImages =
          images.map((image) {
            return MultipartFile.fromBytes(image!, filename: 'image.jpg');
          }).toList();

      FormData formData = FormData.fromMap({
        "name": Name.text,
        "designNo": DesignNo.text,
        "meter": Meter.text,
        "size": Size.text,
        "rate": Price.text,
        "type": Type.text,
        "color": Color.text,
        "packing": Paking.text,
        "images": multipartImages,
      });

      var response = await ApiService.addProduct(formData);

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

  // Future<void> _addProduct() async {
  //   if (Name.text.isEmpty ||
  //       DesignNo.text.isEmpty ||
  //       Meter.text.isEmpty ||
  //       Size.text.isEmpty ||
  //       Price.text.isEmpty ||
  //       Type.text.isEmpty ||
  //       Paking.text.isEmpty ||
  //       Color.text.isEmpty ||
  //       // packingController.text.isEmpty ||
  //       // rateController.text.isEmpty ||
  //       // meterController.text.isEmpty ||
  //       images.isEmpty) {
  //     _showValidationDialog(
  //       'Please fill all fields and select at least one image.',
  //     );
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     List<MultipartFile> multipartImages =
  //         images.map((image) {
  //           return MultipartFile.fromBytes(image!, filename: 'image.jpg');
  //         }).toList();
  //
  //     FormData formData = FormData.fromMap({
  //       // "type": typeController.text,
  //       // "code": codeController.text,
  //       // "designNo": designController.text,
  //       // "name": nameController.text,
  //       // "description": descriptionController.text,
  //       // "size": sizeController.text,
  //       // "color": colorController.text,
  //       // "packing": packingController.text,
  //       // "rate": rateController.text,
  //       // "meter": meterController.text,
  //       "name": Name.text,
  //       "designNo": DesignNo.text,
  //       "meter": Meter.text,
  //       "size": Size.text,
  //       "rate": Price.text,
  //       "type": Type.text,
  //       "code": Color.text,
  //       "packing": Paking.text,
  //       "images": multipartImages,
  //     });
  //
  //     var response = await ApiService.addProduct(formData);
  //
  //     if (response.statusCode == 201) {
  //       widget.onProductAdded();
  //       Navigator.pop(context, true);
  //     } else {
  //       _showValidationDialog(
  //         'Failed to add product. Status: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     _showValidationDialog('An error occurred: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

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
              color: Colors.redAccent, // Adds a more inviting color
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
            ), // Slightly larger text for better readability
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              15,
            ), // Rounded corners for the dialog
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.blue,
                  // Change button text color to blue for contrast
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
      appBar: AppBar(
        title: Text("Create New Product", style: TextStyle(color: Colors.white),),
        backgroundColor: ui.Color(0xFF1D3557),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(Name, "Name *", focusNode: nameFocusNode),
              _buildTextField(
                DesignNo,
                "DesignNo *",
                focusNode: designNoFocusNode,
              ),
              _buildTextField(
                Meter,
                "Meter *",
                isNumeric: true,
                focusNode: meterFocusNode,
              ),
              _buildTextField(Size, "Size *", focusNode: sizeFocusNode),
              _buildTextField(
                Price,
                "Price *",
                isNumeric: true,
                focusNode: priceFocusNode,
              ),
              _buildTextField(Type, "Type *", focusNode: typeFocusNode),
              _buildTextField(Color, "Color *", focusNode: colorFocusNode),
              _buildTextField(Paking, "Packing *", focusNode: packingFocusNode),
              // _buildTextField(packingController, "Packing *"),
              // _buildTextField(rateController, "Rate *", isNumeric: true),
              // _buildTextField(meterController, "Meter *", isNumeric: true),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 10.0),
                child: ElevatedButton(
                  onPressed: images.isNotEmpty ? null : (){
                    FocusScope.of(context).unfocus();
                    _pickImage();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: ui.Color(0xFF1D3557),
                    // Text color
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    // Padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Rounded corners
                    ),
                    elevation: 5, // Shadow effect
                  ),
                  child: const Text(
                    'Select Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ),
              ),


              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return image != null
                        ? GestureDetector(
                          onTap: () async {

                            FocusScope.of(context).unfocus();

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Image.memory(
                                    image,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              Image.memory(
                                image,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: Icon(
                                                  Icons.zoom_out_map,
                                                ),
                                                title: Text('View Full Image'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  // Show full image dialog
                                                  showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return Dialog(
                                                        child: Image.memory(
                                                          image,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.crop),
                                                title: Text('Crop Image'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  try {
                                                    final result =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => CropScreen(
                                                                  image: image,
                                                                  index: index,
                                                                ),
                                                          ),
                                                        );
                                                    if (result != null) {
                                                      final croppedImage =
                                                          result['croppedImage'];
                                                      final index =
                                                          result['index'];
                                                      if (croppedImage !=
                                                          null) {
                                                        setState(() {
                                                          images[index] =
                                                              croppedImage;
                                                        });
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print(
                                                      "Error cropping image: $e",
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Failed to crop image: $e",
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.zoom_out_map,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    setState(() {
                                      images.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : SizedBox();
                  }).toList(),
                  if (images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 22.0),
                      child: Container(
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.05,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: ui.Color(0xFF1D3557),
                  // Text color
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                  // Padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  elevation: 5, // Shadow effect
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<ui.Color>(
                            Colors.white,
                          ), // Loader color
                        )
                        : const Text(
                          "Add Product",
                          style: TextStyle(
                            fontSize: 16, // Text size
                            fontWeight: FontWeight.bold, // Text weight
                          ),
                        ),
              ),
            ],
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
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType:
            isNumeric
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
