// import 'dart:typed_data';
// import 'dart:ui' as ui;
//
// import 'package:crop_image/crop_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
//
// class CropScreen extends StatefulWidget {
//   final Uint8List image;
//   final int index;
//
//   CropScreen({required this.image, required this.index});
//
//   @override
//   _CropScreenState createState() => _CropScreenState();
// }
//
// class _CropScreenState extends State<CropScreen> {
//   final controller = CropController();
//
//   Future<void> _handleImageCrop(BuildContext context) async {
//     try {
//       // Get the cropped image as a `ui.Image` object (dart:ui image)
//       final ui.Image croppedUiImage = (await controller.croppedImage()) as ui.Image;
//
//       // Convert ui.Image to ByteData
//       final ByteData? byteData = await croppedUiImage.toByteData(
//         format: ui.ImageByteFormat.png,
//       );
//
//       if (byteData == null) {
//         throw Exception('Failed to process cropped image: No byte data received');
//       }
//
//       // Convert ByteData to Uint8List
//       final Uint8List croppedImageBytes = byteData.buffer.asUint8List();
//
//       // Compress the cropped image
//       final Uint8List compressedImage = await FlutterImageCompress.compressWithList(
//         croppedImageBytes,
//         minWidth: 300,
//         minHeight: 300,
//         quality: 20,
//       );
//
//       if (compressedImage == null || compressedImage.isEmpty) {
//         throw Exception('Failed to compress cropped image');
//       }
//
//       // Pass the compressed image and its index back to the parent
//       Navigator.pop(context, {
//         'croppedImage': compressedImage,
//         'index': widget.index,
//       });
//     } catch (e) {
//       print("Error cropping image: $e");
//
//       // Show error in SnackBar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed to crop image: $e"),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Crop Image"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.done),
//             onPressed: () => _handleImageCrop(context),
//           ),
//         ],
//       ),
//       body: CropImage(
//         controller: controller,
//         image: Image.memory(widget.image),  // Displaying image from memory (Uint8List)
//       ),
//     );
//   }
// }
