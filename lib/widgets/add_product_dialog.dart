import 'package:flutter/material.dart';
import 'package:newprg/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;

class AddProductDialog extends StatefulWidget {
  final ui.VoidCallback onProductAdded;

  AddProductDialog({required this.onProductAdded});

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final typeController = TextEditingController();
  final codeController = TextEditingController();
  final designController = TextEditingController();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final sizeController = TextEditingController();
  final colorController = TextEditingController();
  final packingController = TextEditingController();
  final rateController = TextEditingController();

  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool isLoading = false;
  bool isImagePicked = false;

  List<Uint8List?> images = [];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        images.add(bytes);
        isImagePicked = false;
      });
    }
  }

  Future<void> _addProduct() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<MultipartFile> multipartImages = [];
      for (int i = 0; i < images.length; i++) {
        if (images[i] != null) {
          multipartImages.add(
            MultipartFile.fromBytes(images[i]!, filename: 'image_$i.jpg'),
          );
        }
      }

      FormData formData = FormData.fromMap({
        "type": typeController.text,
        "code": codeController.text,
        "designNo": designController.text,
        "name": nameController.text,
        "description": descriptionController.text,
        "size": sizeController.text,
        "color": colorController.text,
        "packing": packingController.text,
        "rate": rateController.text,
        "images": multipartImages,
      });

      var response = await ApiService.addProduct(formData);

      if (response.statusCode == 201) {
        widget.onProductAdded();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send data. Status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding product: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.7,
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Column(
                  children: [
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Code'),
                    ),
                    TextField(
                      controller: designController,
                      decoration: const InputDecoration(labelText: 'Design'),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                  ),
                  TextField(
                    controller: packingController,
                    decoration: const InputDecoration(labelText: 'Packing'),
                  ),
                  TextField(
                    controller: rateController,
                    decoration: const InputDecoration(labelText: 'Rate'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: images.isNotEmpty ? null : _pickImage,
                      child: const Text('Select Image'),
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
                            ? Stack(
                              children: [
                                Image.memory(
                                  image,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        images.removeAt(index);
                                        isImagePicked = image.isNotEmpty;
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
                            )
                            : SizedBox();
                      }).toList(),

                      if (images.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 22.0),
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _pickImage,
                          ),
                        ),
                    ],
                  ),
                  // Wrap(
                  //   spacing: 10,
                  //   runSpacing: 10,
                  //   children: [
                  //     ...images.map((image) {
                  //       return image != null
                  //           ? Image.memory(
                  //         image,
                  //         height: 80,
                  //         width: 80,
                  //         fit: BoxFit.cover,
                  //       )
                  //           : SizedBox();
                  //     }).toList(),
                  //     IconButton(
                  //       icon: Icon(Icons.add),
                  //       onPressed: _pickImage,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              isLoading
                  ? null
                  : () {
                    if (_currentPage == 0) {
                      Navigator.pop(context);
                    } else {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
          child: Text(_currentPage == 0 ? 'Cancel' : 'Back'),
        ),
        ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () async {
                    if (_currentPage == 0) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      await _addProduct();
                    }
                  },
          child:
              isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(_currentPage == 0 ? 'Next' : 'Add Product'),
        ),
      ],
    );
  }
}
