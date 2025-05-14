import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
//
// class ShareProduct {
//   Future<void> shareAllProducts(List<Product> products) async {
//     try {
//       final StringBuffer shareTextBuffer = StringBuffer();
//       final List<XFile> imageFiles = [];
//
//       for (int i = 0; i < products.length; i++) {
//         final product = products[i];
//
//         shareTextBuffer.write(
//           'Name: ${product.name}\nDescription: ${product.description}\nRate: ₹${product.rate}\n\n',
//         );
//
//         if (product.imagePaths != null && product.imagePaths!.isNotEmpty) {
//           final imagePath = product.imagePaths![0];
//
//           if (imagePath.startsWith('http')) {
//             final file = await _downloadImage(imagePath, 'product_$i');
//             if (file != null) {
//               imageFiles.add(XFile(file.path));
//             }
//           } else {
//             // Decode the base64 image and save to a file
//             final file = await _saveBase64Image(imagePath, 'product_$i');
//             if (file != null) {
//               imageFiles.add(XFile(file.path));
//             }
//           }
//         }
//       }
//
//       if (imageFiles.isNotEmpty) {
//         await Share.shareXFiles(
//           imageFiles,
//           // text: shareTextBuffer.toString(),
//           // subject: 'Check out these products!',
//         );
//       } else {
//         // await Share.share(
//         //   shareTextBuffer.toString(),
//         //   subject: 'Check out these products!',
//         // );
//       }
//     } catch (e) {
//       print('Error sharing products: $e');
//     }
//   }
//
//   Future<void> shareProductDetails(int selectedIndex, List<Product> products) async {
//     try {
//       final product = products[selectedIndex];
//       final StringBuffer shareTextBuffer = StringBuffer();
//       final List<XFile> imageFiles = [];
//
//       // shareTextBuffer.write(
//       //   'Name: ${product.name}\nDescription: ${product.description}\nRate: ₹${product.rate}\n\n',
//       // );
//
//
//       if (product.imagePaths != null && product.imagePaths!.isNotEmpty) {
//         final imagePath = product.imagePaths![0];
//
//         if (imagePath.startsWith('http')) {
//
//           final file = await _downloadImage(imagePath, 'product_$selectedIndex');
//           if (file != null) {
//             imageFiles.add(XFile(file.path));
//           }
//         } else {
//
//           final file = await _saveBase64Image(imagePath, 'product_$selectedIndex');
//           if (file != null) {
//             imageFiles.add(XFile(file.path));
//           }
//         }
//       }
//
//
//       if (imageFiles.isNotEmpty) {
//         await Share.shareXFiles(
//           imageFiles,
//           // text: shareTextBuffer.toString(),
//           // subject: 'Check out this product!',
//         );
//       } else {
//         // await Share.share(
//         //   shareTextBuffer.toString(),
//         //   subject: 'Check out this product!',
//         // );
//       }
//     } catch (e) {
//       print('Error sharing product: $e');
//     }
//   }
//
//   Future<File?> _downloadImage(String url, String fileName) async {
//     try {
//       final response = await HttpClient().getUrl(Uri.parse(url));
//       final result = await response.close();
//
//       if (result.statusCode == 200) {
//         final bytes = await consolidateHttpClientResponseBytes(result);
//         final directory = await getTemporaryDirectory();
//         final filePath = '${directory.path}/$fileName.png';
//         final file = File(filePath);
//         await file.writeAsBytes(bytes);
//         return file;
//       } else {
//         print('Failed to download image: ${result.statusCode}');
//       }
//     } catch (e) {
//       print('Error downloading image: $e');
//     }
//     return null;
//   }
//
//   Future<File?> _saveBase64Image(String base64Image, String fileName) async {
//     try {
//       final bytes = base64Decode(base64Image);
//       final directory = await getTemporaryDirectory();
//       final filePath = '${directory.path}/$fileName.png';
//       final file = File(filePath);
//       await file.writeAsBytes(bytes);
//       return file;
//     } catch (e) {
//       print('Error saving base64 image: $e');
//     }
//     return null;
//   }
// }


class ShareProduct {
  Future<void> shareAllProducts(List<Product> products) async {
    try {
      final StringBuffer shareTextBuffer = StringBuffer();
      final List<XFile> imageFiles = [];

      for (int i = 0; i < products.length; i++) {
        final product = products[i];



        // Handle multiple images for each product
        if (product.imagePaths != null && product.imagePaths!.isNotEmpty) {
          for (int j = 0; j < product.imagePaths!.length; j++) {
            final imagePath = product.imagePaths![j];

            if (imagePath.startsWith('http')) {
              final file = await _downloadImage(imagePath, 'product_${i}_image_$j');
              if (file != null) {
                imageFiles.add(XFile(file.path));
              }
            } else {
              final file = await _saveBase64Image(imagePath, 'product_${i}_image_$j');
              if (file != null) {
                imageFiles.add(XFile(file.path));
              }
            }
          }
        }
      }

      if (imageFiles.isNotEmpty) {
        await Share.shareXFiles(
          imageFiles,
        );
      }
      // else {
      //   await Share.share(
      //     shareTextBuffer.toString(),
      //     subject: 'Check out these products!',
      //   );
      // }
    } catch (e) {
      print('Error sharing products: $e');
    }
  }

  Future<void> shareProductDetails(int selectedIndex, List<Product> products) async {
    try {
      final product = products[selectedIndex];
      final StringBuffer shareTextBuffer = StringBuffer();
      final List<XFile> imageFiles = [];

      print("Meter Data: ${product.meter}");
      shareTextBuffer.write(
        'Design No: ${product.designNo}\nPrice: ₹${product.rate}\nUnit: ${product.size}\nMeter: ${product.meter}',
      );

      print("DATA: ${product}");

      if (product.imagePaths != null && product.imagePaths!.isNotEmpty) {
        for (int i = 0; i < product.imagePaths!.length; i++) {
          final imagePath = product.imagePaths![i];

          if (imagePath.startsWith('http')) {
            final file = await _downloadImage(imagePath, 'product_${selectedIndex}_image_$i');
            if (file != null) {
              imageFiles.add(XFile(file.path));
            }
          } else {
            final file = await _saveBase64Image(imagePath, 'product_${selectedIndex}_image_$i');
            if (file != null) {
              imageFiles.add(XFile(file.path));
            }
          }
        }
      }

      if (imageFiles.isNotEmpty) {
        await Share.shareXFiles(
          imageFiles,
          text: shareTextBuffer.toString(),
          subject: 'Check out this product!',
        );
      } else {
        await Share.share(
          shareTextBuffer.toString(),
          subject: 'Check out this product!',
        );
      }
    } catch (e) {
      print('Error sharing product: $e');
    }
  }

  Future<File?> _downloadImage(String url, String fileName) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(url));
      final result = await response.close();

      if (result.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(result);
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return file;
      } else {
        print('Failed to download image: ${result.statusCode}');
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  Future<File?> _saveBase64Image(String base64Image, String fileName) async {
    try {
      final bytes = base64Decode(base64Image);
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error saving base64 image: $e');
    }
    return null;
  }
}
