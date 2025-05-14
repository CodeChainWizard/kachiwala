import 'dart:async';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CropScreen extends StatefulWidget {
  final Uint8List image;
  final int index;

  CropScreen({required this.image, required this.index});

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final controller = CropController();
  bool isDragging = false;
  int? activeHandleIndex;

  Rect get currentCrop => controller.crop;

  // Get handle positions (4 corners + midpoints)
  List<Offset> _getHandlePositions() {
    final currentCrop = controller.crop;
    return [
      Offset(currentCrop.left, currentCrop.top), // Top-left (0)
      Offset(currentCrop.right, currentCrop.top), // Top-right (1)
      Offset(currentCrop.left, currentCrop.bottom), // Bottom-left (2)
      Offset(currentCrop.right, currentCrop.bottom), // Bottom-right (3)
      // Midpoints (4 edges)
      Offset(currentCrop.left + currentCrop.width / 2, currentCrop.top), // Top edge midpoint (4)
      Offset(currentCrop.right, currentCrop.top + currentCrop.height / 2), // Right edge midpoint (5)
      Offset(currentCrop.left + currentCrop.width / 2, currentCrop.bottom), // Bottom edge midpoint (6)
      Offset(currentCrop.left, currentCrop.top + currentCrop.height / 2), // Left edge midpoint (7)
    ];
  }

  // Start drag on one of the control points
  void _handleDragStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final handles = _getHandlePositions();
    for (int i = 0; i < handles.length; i++) {
      if ((handles[i] - localPosition).distance < 20) { // Check if we clicked near a control point
        setState(() {
          isDragging = true;
          activeHandleIndex = i;
        });
        break;
      }
    }
  }

  // Handle drag update for moving control points
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!isDragging || activeHandleIndex == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;

    final currentCrop = controller.crop;

    setState(() {
      switch (activeHandleIndex) {
        case 4: // Top edge midpoint
          controller.crop = Rect.fromLTRB(
            currentCrop.left,
            localPosition.dy.clamp(0.0, currentCrop.bottom - 10),
            currentCrop.right,
            currentCrop.bottom,
          );
          break;
        case 5: // Right edge midpoint
          controller.crop = Rect.fromLTRB(
            currentCrop.left,
            currentCrop.top,
            localPosition.dx.clamp(currentCrop.left + 10, size.width - 10),
            currentCrop.bottom,
          );
          break;
        case 6: // Bottom edge midpoint
          controller.crop = Rect.fromLTRB(
            currentCrop.left,
            currentCrop.top,
            currentCrop.right,
            localPosition.dy.clamp(currentCrop.top + 10, size.height - 10),
          );
          break;
        case 7: // Left edge midpoint
          controller.crop = Rect.fromLTRB(
            localPosition.dx.clamp(0.0, currentCrop.right - 10),
            currentCrop.top,
            currentCrop.right,
            currentCrop.bottom,
          );
          break;
      }
    });
  }

  // End the drag interaction
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
      activeHandleIndex = null;
    });
  }

  // Handle the image cropping process
  Future<void> _handleImageCrop(BuildContext context) async {
    try {
      final ui.Image croppedUiImage = await _getUiImageFromWidget(
        await controller.croppedImage(),
      );

      final ByteData? byteData = await croppedUiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to process cropped image: No byte data received');
      }

      final Uint8List croppedImageBytes = byteData.buffer.asUint8List();

      final Uint8List? compressedImage = await FlutterImageCompress.compressWithList(
        croppedImageBytes,
        minWidth: 300,
        minHeight: 300,
        quality: 20,
      );

      if (compressedImage == null || compressedImage.isEmpty) {
        throw Exception('Failed to compress cropped image');
      }

      Navigator.pop(context, {
        'croppedImage': compressedImage,
        'index': widget.index,
      });
    } catch (e) {
      print("Error cropping image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to crop image: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Convert widget to ui.Image for cropping process
  Future<ui.Image> _getUiImageFromWidget(Image imageWidget) async {
    final Completer<ui.Image> completer = Completer();
    imageWidget.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
      }),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crop Image"),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () => _handleImageCrop(context),
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        child: Stack(
          children: [
            // Wrap the CropImage with a GestureDetector to block the default drag behavior
            GestureDetector(
              onPanUpdate: (_) {}, // Block default drag behavior
              child: CropImage(
                controller: controller,
                image: Image.memory(widget.image),
              ),
            ),
            // Add crop handles
            ...(_getHandlePositions().asMap().entries.map((entry) {
              final int index = entry.key;
              final Offset position = entry.value;
              return Positioned(
                left: position.dx - 10,
                top: position.dy - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:crop_image/crop_image.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
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
//       // Ensure you're getting a ui.Image from the controller.
//       final ui.Image croppedUiImage = await _getUiImageFromWidget(
//         await controller.croppedImage(),
//       );
//
//       final ByteData? byteData = await croppedUiImage.toByteData(
//         format: ui.ImageByteFormat.png,
//       );
//
//       if (byteData == null) {
//         throw Exception(
//           'Failed to process cropped image: No byte data received',
//         );
//       }
//
//       final Uint8List croppedImageBytes = byteData.buffer.asUint8List();
//
//       final Uint8List? compressedImage =
//       await FlutterImageCompress.compressWithList(
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
//       // Update the selected image after cropping
//       Navigator.pop(context, {
//         'croppedImage': compressedImage,
//         'index': widget.index,
//       });
//     } catch (e) {
//       print("Error cropping image: $e");
//
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
//   Future<ui.Image> _getUiImageFromWidget(Image imageWidget) async {
//     final Completer<ui.Image> completer = Completer();
//     imageWidget.image
//         .resolve(ImageConfiguration())
//         .addListener(
//       ImageStreamListener((ImageInfo info, bool synchronousCall) {
//         completer.complete(info.image);
//       }),
//     );
//     return completer.future;
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
//         image: Image.memory(
//           widget.image,
//         ), // Displaying image from memory (Uint8List)
//       ),
//     );
//   }
// }rr4