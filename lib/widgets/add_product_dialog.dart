// // import 'package:flutter/material.dart';
// // import 'package:newprg/services/api_service.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'dart:typed_data';
// // import 'dart:convert';
// // import 'package:dio/dio.dart';
// // import 'dart:ui' as ui;
// //
// // class AddProductDialog extends StatefulWidget {
// //   final ui.VoidCallback onProductAdded;
// //
// //   AddProductDialog({required this.onProductAdded});
// //
// //   @override
// //   _AddProductDialogState createState() => _AddProductDialogState();
// // }
// //
// // class _AddProductDialogState extends State<AddProductDialog> {
// //   final typeController = TextEditingController();
// //   final codeController = TextEditingController();
// //   final designController = TextEditingController();
// //   final nameController = TextEditingController();
// //   final descriptionController = TextEditingController();
// //   final sizeController = TextEditingController();
// //   final colorController = TextEditingController();
// //   final packingController = TextEditingController();
// //   final rateController = TextEditingController();
// //
// //   final PageController _pageController = PageController();
// //
// //   int _currentPage = 0;
// //   bool isLoading = false;
// //   bool isImagePicked = false;
// //
// //   List<Uint8List?> images = [];
// //
// //   Future<void> _pickImage() async {
// //     final pickedFile = await ImagePicker().pickImage(
// //       source: ImageSource.gallery,
// //     );
// //     if (pickedFile != null) {
// //       final bytes = await pickedFile.readAsBytes();
// //       setState(() {
// //         images.add(bytes);
// //         isImagePicked = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _addProduct() async {
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     try {
// //       List<MultipartFile> multipartImages = [];
// //       for (int i = 0; i < images.length; i++) {
// //         if (images[i] != null) {
// //           multipartImages.add(
// //             MultipartFile.fromBytes(images[i]!, filename: 'image_$i.jpg'),
// //           );
// //         }
// //       }
// //
// //       FormData formData = FormData.fromMap({
// //         "type": typeController.text,
// //         "code": codeController.text,
// //         "designNo": designController.text,
// //         "name": nameController.text,
// //         "description": descriptionController.text,
// //         "size": sizeController.text,
// //         "color": colorController.text,
// //         "packing": packingController.text,
// //         "rate": rateController.text,
// //         "images": multipartImages,
// //       });
// //
// //       var response = await ApiService.addProduct(formData);
// //
// //       if (response.statusCode == 201) {
// //         widget.onProductAdded();
// //         Navigator.pop(context);
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               'Failed to send data. Status: ${response.statusCode}',
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       print('Error adding product: $e');
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return AlertDialog(
// //       title: const Text('Add New Product'),
// //       content: SizedBox(
// //         width: MediaQuery.of(context).size.width * 0.8,
// //         height: MediaQuery.of(context).size.width * 0.7,
// //         child: PageView(
// //           controller: _pageController,
// //           onPageChanged: (page) {
// //             setState(() {
// //               _currentPage = page;
// //             });
// //           },
// //           physics: const NeverScrollableScrollPhysics(),
// //           children: [
// //             SingleChildScrollView(
// //               child: Padding(
// //                 padding: const EdgeInsets.only(bottom: 15.0),
// //                 child: Column(
// //                   children: [
// //                     TextField(
// //                       controller: typeController,
// //                       decoration: const InputDecoration(labelText: 'Type'),
// //                     ),
// //                     TextField(
// //                       controller: codeController,
// //                       decoration: const InputDecoration(labelText: 'Code'),
// //                     ),
// //                     TextField(
// //                       controller: designController,
// //                       decoration: const InputDecoration(labelText: 'Design'),
// //                     ),
// //                     TextField(
// //                       controller: nameController,
// //                       decoration: const InputDecoration(labelText: 'Name'),
// //                     ),
// //                     TextField(
// //                       controller: descriptionController,
// //                       decoration: const InputDecoration(
// //                         labelText: 'Description',
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             SingleChildScrollView(
// //               child: Column(
// //                 children: [
// //                   TextField(
// //                     controller: sizeController,
// //                     decoration: const InputDecoration(labelText: 'Size'),
// //                   ),
// //                   TextField(
// //                     controller: colorController,
// //                     decoration: const InputDecoration(labelText: 'Color'),
// //                   ),
// //                   TextField(
// //                     controller: packingController,
// //                     decoration: const InputDecoration(labelText: 'Packing'),
// //                   ),
// //                   TextField(
// //                     controller: rateController,
// //                     decoration: const InputDecoration(labelText: 'Rate'),
// //                   ),
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 12.0, bottom: 10.0),
// //                     child: ElevatedButton(
// //                       onPressed: images.isNotEmpty ? null : _pickImage,
// //                       child: const Text('Select Image'),
// //                     ),
// //                   ),
// //
// //                   Wrap(
// //                     spacing: 10,
// //                     runSpacing: 10,
// //                     children: [
// //                       ...images.asMap().entries.map((entry) {
// //                         final index = entry.key;
// //                         final image = entry.value;
// //                         return image != null
// //                             ? Stack(
// //                               children: [
// //                                 Image.memory(
// //                                   image,
// //                                   height: 80,
// //                                   width: 80,
// //                                   fit: BoxFit.cover,
// //                                 ),
// //                                 Positioned(
// //                                   top: 0,
// //                                   right: 0,
// //                                   child: GestureDetector(
// //                                     onTap: () {
// //                                       setState(() {
// //                                         images.removeAt(index);
// //                                         isImagePicked = image.isNotEmpty;
// //                                       });
// //                                     },
// //                                     child: Container(
// //                                       decoration: BoxDecoration(
// //                                         shape: BoxShape.circle,
// //                                         color: Colors.red,
// //                                       ),
// //                                       padding: const EdgeInsets.all(4),
// //                                       child: const Icon(
// //                                         Icons.remove,
// //                                         color: Colors.white,
// //                                         size: 16,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             )
// //                             : SizedBox();
// //                       }).toList(),
// //
// //                       if (images.isNotEmpty)
// //                         Padding(
// //                           padding: const EdgeInsets.only(top: 22.0),
// //                           child: IconButton(
// //                             icon: const Icon(Icons.add),
// //                             onPressed: _pickImage,
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                   // Wrap(
// //                   //   spacing: 10,
// //                   //   runSpacing: 10,
// //                   //   children: [
// //                   //     ...images.map((image) {
// //                   //       return image != null
// //                   //           ? Image.memory(
// //                   //         image,
// //                   //         height: 80,
// //                   //         width: 80,
// //                   //         fit: BoxFit.cover,
// //                   //       )
// //                   //           : SizedBox();
// //                   //     }).toList(),
// //                   //     IconButton(
// //                   //       icon: Icon(Icons.add),
// //                   //       onPressed: _pickImage,
// //                   //     ),
// //                   //   ],
// //                   // ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       actions: [
// //         TextButton(
// //           onPressed:
// //               isLoading
// //                   ? null
// //                   : () {
// //                     if (_currentPage == 0) {
// //                       Navigator.pop(context);
// //                     } else {
// //                       _pageController.previousPage(
// //                         duration: const Duration(milliseconds: 300),
// //                         curve: Curves.easeInOut,
// //                       );
// //                     }
// //                   },
// //           child: Text(_currentPage == 0 ? 'Cancel' : 'Back'),
// //         ),
// //         ElevatedButton(
// //           onPressed:
// //               isLoading
// //                   ? null
// //                   : () async {
// //                     if (_currentPage == 0) {
// //                       _pageController.nextPage(
// //                         duration: const Duration(milliseconds: 300),
// //                         curve: Curves.easeInOut,
// //                       );
// //                     } else {
// //                       await _addProduct();
// //                     }
// //                   },
// //           child:
// //               isLoading
// //                   ? CircularProgressIndicator(color: Colors.white)
// //                   : Text(_currentPage == 0 ? 'Next' : 'Add Product'),
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:newprg/services/api_service.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'dart:ui' as ui;
//
// class AddProductDialog extends StatefulWidget {
//   final ui.VoidCallback onProductAdded;
//   late final bool isLoading;
//
//   AddProductDialog({required this.onProductAdded, required this.isLoading});
//
//   @override
//   _AddProductDialogState createState() => _AddProductDialogState();
// }
//
// class _AddProductDialogState extends State<AddProductDialog> {
//   final typeController = TextEditingController();
//   final codeController = TextEditingController();
//   final designController = TextEditingController();
//   final nameController = TextEditingController();
//   final descriptionController = TextEditingController();
//   final sizeController = TextEditingController();
//   final colorController = TextEditingController();
//   final packingController = TextEditingController();
//   final rateController = TextEditingController();
//   final meterController = TextEditingController();
//
//   final PageController _pageController = PageController();
//
//   int _currentPage = 0;
//   bool isImagePicked = false;
//
//   List<Uint8List?> images = [];
//   Uint8List? compressedImage;
//
//   Future<void> _pickImage() async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         final imageBytes = await pickedFile.readAsBytes();
//
//         // Compress the selected image
//         final compressed = await _compressImage(imageBytes);
//         if (compressed != null) {
//           setState(() {
//             compressedImage = compressed;
//             images.add(compressed); // Add to the list of selected images
//           });
//         }
//       }
//     } catch (e) {
//       print("Error selecting image: $e");
//     }
//   }
//
//   Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
//     if (imageBytes.isEmpty) {
//       print("Error: Empty image data received for compression.");
//       return null;
//     }
//
//     try {
//       final compressedImage = await FlutterImageCompress.compressWithList(
//         imageBytes,
//         minWidth: 300,
//         minHeight: 300,
//         quality: 20,
//       );
//
//       if (compressedImage == null || compressedImage.isEmpty) {
//         print("Error: Image compression failed.");
//         return null;
//       }
//
//       return compressedImage;
//     } catch (e) {
//       print("Error during image compression: $e");
//       return null;
//     }
//   }
//
//
//   // Helper method to focus on the first field that is not filled
//   void _focusOnField(TextEditingController controller) {
//     FocusScope.of(context).requestFocus(FocusNode());
//     FocusScope.of(context).requestFocus(controller as FocusNode?);
//   }
//
//   // Show validation error dialog
//   void _showValidationDialog(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Validation Error'),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _addProduct() async {
//     if (typeController.text.isEmpty) {
//       _showValidationDialog('Please fill Type field.');
//       _focusOnField(typeController);
//       return;
//     }
//
//     if (codeController.text.isEmpty) {
//       _showValidationDialog('Please fill Code field.');
//       _focusOnField(codeController);
//       return;
//     }
//
//     if (designController.text.isEmpty) {
//       _showValidationDialog('Please fill Design field.');
//       _focusOnField(designController);
//       return;
//     }
//
//     if (nameController.text.isEmpty) {
//       _showValidationDialog('Please fill Name field.');
//       _focusOnField(nameController);
//       return;
//     }
//
//     if (descriptionController.text.isEmpty) {
//       _showValidationDialog('Please fill Description field.');
//       _focusOnField(descriptionController);
//       return;
//     }
//
//     if (sizeController.text.isEmpty) {
//       _showValidationDialog('Please fill Size field.');
//       _focusOnField(sizeController);
//       return;
//     }
//
//     if (colorController.text.isEmpty) {
//       _showValidationDialog('Please fill Color field.');
//       _focusOnField(colorController);
//       return;
//     }
//
//     if (packingController.text.isEmpty) {
//       _showValidationDialog('Please fill Packing field.');
//       _focusOnField(packingController);
//       return;
//     }
//
//     if (rateController.text.isEmpty) {
//       _showValidationDialog('Please fill Rate field.');
//       _focusOnField(rateController);
//       return;
//     }
//
//     if (meterController.text.isEmpty) {
//       _showValidationDialog('Please fill Meter field.');
//       _focusOnField(rateController);
//       return;
//     }
//
//     if (images.isEmpty) {
//       _showValidationDialog('Please select at least one image.');
//       return;
//     }
//
//     if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(rateController.text)) {
//       _showValidationDialog('Rate must be a valid number.');
//       return;
//     }
//
//     // Close the popup and hide the keyboard before making the API request
//     if (widget.isLoading) {
//       Navigator.pop(context);
//       FocusScope.of(context).unfocus();
//     }
//
//     try {
//       List<MultipartFile> multipartImages = [];
//       for (int i = 0; i < images.length; i++) {
//         if (images[i] != null) {
//           multipartImages.add(
//             MultipartFile.fromBytes(images[i]!, filename: 'image_$i.jpg'),
//           );
//         }
//       }
//
//       FormData formData = FormData.fromMap({
//         "type": typeController.text,
//         "code": codeController.text,
//         "designNo": designController.text,
//         "name": nameController.text,
//         "description": descriptionController.text,
//         "size": sizeController.text,
//         "color": colorController.text,
//         "packing": packingController.text,
//         "rate": rateController.text,
//         "meter": meterController.text,
//         "images": multipartImages,
//       });
//
//       var response = await ApiService.addProduct(formData);
//
//       print("RES Add Product: $formData");
//
//       if (response.statusCode == 201) {
//         widget.onProductAdded();
//         Navigator.pop(context);
//       } else {
//         _showValidationDialog(
//           'Failed to send data. Status: ${response.statusCode}',
//         );
//       }
//     } catch (e) {
//       print('Error adding product: $e');
//       _showValidationDialog('An error occurred: $e');
//     } finally {
//       setState(() {
//         widget.isLoading = false;
//       });
//       Navigator.pop(context);
//       FocusScope.of(context).unfocus();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add New Product'),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.8,
//         height: MediaQuery.of(context).size.width * 0.7,
//         child: PageView(
//           controller: _pageController,
//           onPageChanged: (page) {
//             setState(() {
//               _currentPage = page;
//             });
//           },
//           physics: const NeverScrollableScrollPhysics(),
//           children: [
//             SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 15.0),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: typeController,
//                       decoration: InputDecoration(
//                         labelText: 'Type *',
//                         labelStyle: TextStyle(color: Colors.black),
//                         suffixText: "*",
//                         suffixStyle: TextStyle(color: Colors.red),
//                       ),
//                     ),
//                     TextField(
//                       controller: codeController,
//                       decoration: const InputDecoration(labelText: 'Code *'),
//                     ),
//                     TextField(
//                       controller: designController,
//                       decoration: const InputDecoration(labelText: 'Design *'),
//                     ),
//                     TextField(
//                       controller: nameController,
//                       decoration: const InputDecoration(labelText: 'Name *'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: const InputDecoration(
//                         labelText: 'Description *',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SingleChildScrollView(
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: sizeController,
//                     decoration: const InputDecoration(labelText: 'Size *'),
//                   ),
//                   TextField(
//                     controller: colorController,
//                     decoration: const InputDecoration(labelText: 'Color *'),
//                   ),
//                   TextField(
//                     controller: packingController,
//                     decoration: const InputDecoration(labelText: 'Packing *'),
//                   ),
//                   TextField(
//                     controller: rateController,
//                     decoration: const InputDecoration(labelText: 'Rate *'),
//                     keyboardType: TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                   ),
//                   TextField(
//                     controller: meterController,
//                     decoration: const InputDecoration(labelText: 'Meter *'),
//                     keyboardType: TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 12.0, bottom: 10.0),
//                     child: ElevatedButton(
//                       onPressed: images.isNotEmpty ? null : _pickImage,
//                       child: const Text('Select Image'),
//                     ),
//                   ),
//
//                   Wrap(
//                     spacing: 10,
//                     runSpacing: 10,
//                     children: [
//                       ...images.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final image = entry.value;
//                         return image != null
//                             ? Stack(
//                               children: [
//                                 Image.memory(
//                                   image,
//                                   height: 80,
//                                   width: 80,
//                                   fit: BoxFit.cover,
//                                 ),
//                                 Positioned(
//                                   top: 0,
//                                   right: 0,
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         images.removeAt(index);
//                                         isImagePicked = image.isNotEmpty;
//                                       });
//                                     },
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         shape: BoxShape.circle,
//                                         color: Colors.red,
//                                       ),
//                                       padding: const EdgeInsets.all(4),
//                                       child: const Icon(
//                                         Icons.remove,
//                                         color: Colors.white,
//                                         size: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             )
//                             : SizedBox();
//                       }).toList(),
//
//                       if (images.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 22.0),
//                           child: IconButton(
//                             icon: const Icon(Icons.add),
//                             onPressed: _pickImage,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed:
//               widget.isLoading
//                   ? null
//                   : () {
//                     if (_currentPage == 0) {
//                       Navigator.pop(context);
//                     } else {
//                       _pageController.previousPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                   },
//           child: Text(_currentPage == 0 ? 'Cancel' : 'Back'),
//         ),
//         ElevatedButton(
//           onPressed:
//               widget.isLoading
//                   ? null
//                   : () async {
//                     if (_currentPage == 0) {
//                       _pageController.nextPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     } else {
//                       await _addProduct();
//                     }
//                   },
//           child:
//               widget.isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text(_currentPage == 0 ? 'Next' : 'Add Product'),
//         ),
//       ],
//     );
//   }
// }
