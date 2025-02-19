import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:newprg/widgets/shareProduct.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io;

import '../models/product.dart';
import '../widgets/ProductDetailScreen.dart';

final counterProvider = StateProvider<int>((ref) => 0);

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final int index;
  final bool isGlobalSelected;
  final VoidCallback onTap;
  final Function(bool) updateCounter;
  final bool isSelectAll;
  final List<String> selectedProductIds;

  ProductCard({
    required this.product,
    required this.index,
    required this.isGlobalSelected,
    required this.onTap,
    required this.updateCounter,
    required this.isSelectAll,
    required this.selectedProductIds,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool isSelected = false;
  Uint8List? compressedImage;
  bool isMultiSelectActive = false;

  @override
  void initState() {
    super.initState();
    _compressAndLoadImage();
  }

  void _handleSelectAll() {
    setState(() {
      if (widget.isSelectAll) {
        isSelected = !isSelected;
        widget.updateCounter(isSelected);
      }
    });
  }

  Future<void> _compressAndLoadImage() async {
    if (widget.product.imagePaths == null ||
        widget.product.imagePaths!.isEmpty) {
      print("No image paths found.");
      return;
    }

    final imagePath = widget.product.imagePaths![0];
    print("Processing image path: $imagePath");

    try {
      if (imagePath.startsWith('http')) {
        final response = await http.get(Uri.parse(imagePath));
        print("HTTP response status: ${response.statusCode}");
        if (response.statusCode == 200) {
          compressedImage = await _compressImage(response.bodyBytes);
        } else {
          print("Failed to fetch image from URL.");
        }
      } else {
        print("Decoding Base64 image.");
        final decodedBytes = base64Decode(imagePath);
        compressedImage = await _compressImage(decodedBytes);
      }

      if (compressedImage != null) {
        print(
          "Image successfully compressed. Length: ${compressedImage!.length}",
        );
      } else {
        print("Image compression returned null.");
      }

      setState(() {});
    } catch (e) {
      print('Error loading image: $e');
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
        minWidth: 250,
        minHeight: 250,
        quality: 10,
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

  bool sharedFlag = false;

  Future<void> _shareProducts(List<Product> products) async {
    if (sharedFlag) return;

    try {
      final List<XFile> imageFiles = [];
      final shareText = StringBuffer('Check out these products:\n\n');

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        shareText.write(
          'Design No: ${product.designNo}\n'
          'Price: ₹${product.rate}\n'
          'Unit: ${product.size}\n'
          'Meter: ${product.meter}\n\n',
        );

        if (product.imagePaths != null && product.imagePaths!.isNotEmpty) {
          final imagePath = product.imagePaths![0];
          final imageBytes =
              imagePath.startsWith('http')
                  ? (await http.get(Uri.parse(imagePath))).bodyBytes
                  : base64Decode(imagePath);

          final tempDir = await getTemporaryDirectory();
          final file = io.File('${tempDir.path}/product_$i.png');
          await file.writeAsBytes(imageBytes);
          imageFiles.add(XFile(file.path));
        }
      }

      if (imageFiles.isNotEmpty) {
        await Share.shareXFiles(imageFiles, text: shareText.toString());
      } else {
        await Share.share(shareText.toString());
      }

      sharedFlag = true;
    } catch (e) {
      print('Error sharing products: $e');
    }
  }

  String _resolveImageUrl(String path) {
    // return path.replaceAll("\\", "/");
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // print("Counter value in riverpods: $counterValue");

    print("isSelectAll Value in ProductCard Page: ${widget.isSelectAll}");
    print("isSelectAll Value in ProductCard Ids: ${widget.selectedProductIds}");

    final screenWidth = MediaQuery.of(context).size.width;

    final resolvedImagePath =
        widget.product.imagePaths != null &&
                widget.product.imagePaths!.isNotEmpty
            ? _resolveImageUrl(widget.product.imagePaths![0])
            : null;

    return GestureDetector(
      onLongPress: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("longPress", true);

        setState(() {
          isMultiSelectActive = true;
          if (!isSelected) {
            isSelected = true;
            widget.updateCounter(isSelected);
          }
        });
        widget.onTap();
      },

      onTap: () async {
        _handleSelectAll();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isLongPressActive = prefs.getBool("longPress") ?? false;

        if (isLongPressActive || widget.isSelectAll) {
          bool newSelectedState = !isSelected;

          widget.updateCounter(newSelectedState);
          setState(() {
            isSelected = newSelectedState;
          });

          print("NewSelect Value:- ${widget.updateCounter(isSelected)}");
          int updateCounter = widget.updateCounter(isSelected);
          if (updateCounter > 0 || widget.isSelectAll) {
            prefs.setBool("longPress", true);
          } else {
            prefs.setBool("longPress", false);
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProductDetailScreen(product: widget.product),
            ),
          );
        }
        widget.onTap();
      },

      child: Card(
        margin: EdgeInsets.all(2.0),
        color:
            widget.selectedProductIds.contains(widget.product.id) &&
                        widget.isSelectAll ||
                    isSelected
                ? Color(0xFFCCD5AE)
                // : Color(0xFF),
                : Color(0xFFE8E8E4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child:
                  widget.product.imagePaths != null &&
                          widget.product.imagePaths!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8.0),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Image.network(
                            // _resolveImageUrl(widget.product.imagePaths![0]),
                            // "http://192.168.1.2:5000/uploads/folder1/1734342621219-573985215.jpg",
                            resolvedImagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      )
                      : Icon(Icons.image, size: 100, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.0),
                              Text(
                                'Type : ${widget.product.type}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 15.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Price(₹) : ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '${widget.product.rate} Rs',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Tooltip(
                                      message:
                                          "Dataaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Person: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  "Dataaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                                              // The long name
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 14 : 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: () async {
                                      try {
                                        // Get the selected products
                                        final selectedProducts =
                                            widget.selectedProductIds.isNotEmpty
                                                ? widget.selectedProductIds
                                                    .map((id) => widget.product)
                                                    .toList()
                                                : [widget.product];

                                        // Iterate through the selected products
                                        for (var product in selectedProducts) {
                                          if (product.imagePaths != null &&
                                              product.imagePaths!.isNotEmpty) {
                                            if (product.imagePaths!.length ==
                                                1) {
                                              // Share normally if there's only one image
                                              await _shareProducts([product]);
                                            } else {
                                              // Share all images if there are multiple, ensuring details are added only once
                                              await _shareProductsWithMultipleImages(
                                                product,
                                              );
                                            }
                                          } else {
                                            print(
                                              "No images found for product: ${product.id}",
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print("Error sharing products: $e");
                                      }
                                    },
                                    iconSize: isSmallScreen ? 18 : 22,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProductsWithMultipleImages(Product product) async {
    try {
      List<XFile> imageFiles = [];
      StringBuffer shareTextBuffer = StringBuffer();

      // Add product details only once
      shareTextBuffer.write(
        'Check out this product:\n\n'
        'Design No: ${product.designNo}\n'
        'Price: ₹${product.rate}\n'
        // 'Unit: ${product.un}\n'
        'Size: ${product.size}\n\n',
      );

      // Add all images to the share list
      for (int index = 0; index < product.imagePaths!.length; index++) {
        final imagePath = product.imagePaths![index];

        if (imagePath.startsWith('http')) {
          final response = await http.get(Uri.parse(imagePath));
          if (response.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final filePath = '${directory.path}/product_image_$index.png';
            final file = io.File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            imageFiles.add(XFile(filePath));
          }
        } else {
          Uint8List productImageBytes = base64Decode(imagePath);
          final directory = await getTemporaryDirectory();
          final filePath = '${directory.path}/product_image_$index.png';
          final file = io.File(filePath);
          await file.writeAsBytes(productImageBytes);

          imageFiles.add(XFile(filePath));
        }
      }

      if (imageFiles.isNotEmpty) {
        await Share.shareXFiles(
          imageFiles,
          text: shareTextBuffer.toString(),
          subject: 'Product Sharing',
        );
      }
    } catch (e) {
      print("Error sharing multiple images for product: $e");
    }
  }

  /// Builds the product image widget.
  Widget _buildProductImage(String? imageUrl, bool isSmallScreen) {
    if (compressedImage != null) {
      return Image.memory(
        compressedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => _buildPlaceholder(isSmallScreen),
      );
    }

    if (imageUrl != null && imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, _) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, _, __) => _buildPlaceholder(isSmallScreen),
      );
    }

    return _buildPlaceholder(isSmallScreen);
  }

  /// Builds a placeholder image.
  Widget _buildPlaceholder(bool isSmallScreen) {
    return Icon(
      Icons.broken_image,
      size: isSmallScreen ? 60 : 100,
      color: Colors.grey,
    );
  }
}

// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:newprg/models/product.dart';
// import 'package:newprg/widgets/ProductDetailScreen.dart';
// import 'dart:io' as io;
//
// import '../models/product.dart';
//
// final counterProvider = StateProvider<int>((ref) => 0);
//
// class ProductCard extends ConsumerStatefulWidget {
//   final Product product;
//   final int index;
//   final bool isGlobalSelected;
//   final VoidCallback onTap;
//   final Function(bool) updateCounter;
//   final bool isSelectAll;
//   final List<String> selectedProductIds;
//
//   ProductCard({
//     required this.product,
//     required this.index,
//     required this.isGlobalSelected,
//     required this.onTap,
//     required this.updateCounter,
//     required this.isSelectAll,
//     required this.selectedProductIds,
//   });
//
//   @override
//   _ProductCardState createState() => _ProductCardState();
// }
//
// class _ProductCardState extends ConsumerState<ProductCard> {
//   bool isSelected = false;
//   bool isMultiSelectActive = false;
//
//   // @override
//   // void initState() {
//   //   // TODO: implement initState
//   //   super.initState();
//   //   ref.listen<int>(counterProvider, (previous, next){
//   //     print("Counter value in Riverpod changed: $next");
//   //   });
//   // }
//
//   @override
//   void didUpdateWidget(covariant ProductCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Ensure that global selection state is updated in each card
//     if (widget.isGlobalSelected != oldWidget.isGlobalSelected) {
//       setState(() {
//         isSelected = widget.isGlobalSelected;
//       });
//     }
//   }
//
//   // void updateCounter(bool isSelected) {
//   //   final counter = ref.read(counterProvider.state);
//   //   int oldValue = counter.state;
//   //
//   //   if (isSelected) {
//   //     counter.state++;
//   //   } else {
//   //     counter.state--;
//   //     if(counter.state < 0) counter.state = 0;
//   //   }
//   //
//   //   if(oldValue != counter.state){
//   //     print("Counter Updated: ${counter.state}");
//   //   }
//   // }
//
//   String _resolveImageUrl(String path) {
//     // return path.replaceAll("\\", "/");
//     return path;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // print("Counter value in riverpods: $counterValue");
//
//     print("isSelectAll Value in ProductCard Page: ${widget.isSelectAll}");
//     print("isSelectAll Value in ProductCard Ids: ${widget.selectedProductIds}");
//
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     final resolvedImagePath =
//         widget.product.imagePaths != null &&
//                 widget.product.imagePaths!.isNotEmpty
//             ? _resolveImageUrl(widget.product.imagePaths![0])
//             : null;
//
//     if (resolvedImagePath == null) {
//       return Center(child: Text("No Image Found"));
//     }
//
//     return GestureDetector(
//       onLongPress: () async {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         prefs.setBool("longPress", true);
//
//         setState(() {
//           isMultiSelectActive = true;
//           if (!isSelected) {
//             isSelected = true;
//             widget.updateCounter(isSelected);
//           }
//         });
//         widget.onTap();
//       },
//
//       onTap: () async {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         bool isLongPressActive = prefs.getBool("longPress") ?? false;
//
//         if (isLongPressActive || widget.isSelectAll) {
//           bool newSelectedState = !isSelected;
//
//           widget.updateCounter(newSelectedState);
//           setState(() {
//             isSelected = newSelectedState;
//           });
//
//           print("NewSelect Value:- ${widget.updateCounter(isSelected)}");
//           int updateCounter = widget.updateCounter(isSelected);
//           if (updateCounter > 0 || widget.isSelectAll) {
//             prefs.setBool("longPress", true);
//           } else {
//             prefs.setBool("longPress", false);
//           }
//         } else {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => ProductDetailScreen(product: widget.product),
//             ),
//           );
//         }
//         widget.onTap();
//       },
//
//       child: Card(
//         margin: EdgeInsets.all(8.0),
//         color:
//             widget.selectedProductIds.contains(widget.product.id) && isSelected
//                 ? Colors.blueAccent.withOpacity(0.1)
//                 : null,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child:
//                   widget.product.imagePaths != null &&
//                           widget.product.imagePaths!.isNotEmpty
//                       ? ClipRRect(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(8.0),
//                         ),
//                         child: Container(
//                           width: MediaQuery.of(context).size.width * 0.5,
//                           child: Image.network(
//                             // _resolveImageUrl(widget.product.imagePaths![0]),
//                             // "http://192.168.1.2:5000/uploads/folder1/1734342621219-573985215.jpg",
//                             resolvedImagePath!,
//                             fit: BoxFit.cover,
//                             // width: MediaQuery.of(context).size.width,
//                             width: double.infinity,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Icon(
//                                 Icons.broken_image,
//                                 size: 100,
//                                 color: Colors.grey,
//                               );
//                             },
//                           ),
//                         ),
//                       )
//                       : Icon(Icons.image, size: 100, color: Colors.grey),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.all(2.0),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   bool isSmallScreen = constraints.maxWidth < 600;
//
//                   return Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Type : ${widget.product.type}',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis, // Prevent overflow
//                             ),
//                             SizedBox(height: 15.0),
//                             RichText(
//                               text: TextSpan(
//                                 children: [
//                                   const TextSpan(
//                                     text: 'Desc : ',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                   TextSpan(
//                                     text: widget.product.description,
//                                     style: TextStyle(
//                                       fontSize: isSmallScreen ? 14 : 16,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Flexible(
//                                   child: RichText(
//                                     text: TextSpan(
//                                       children: [
//                                         const TextSpan(
//                                           text: 'Price(₹) : ',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.black,
//                                           ),
//                                         ),
//                                         TextSpan(
//                                           text: '${widget.product.rate} Rs',
//                                           style: TextStyle(
//                                             fontSize: isSmallScreen ? 14 : 16,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.share),
//                                   onPressed: () => _shareProducts([widget.product]),
//                                   iconSize: isSmallScreen ? 18 : 22,
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   //  http://103.251.16.248:5000/imageData/folder1/1734348107424-338314245.jfif
//   Future<void> _shareProducts(List<Product> products) async {
//     try {
//       List<XFile> imageFiles = [];
//       StringBuffer shareTextBuffer = StringBuffer(
//         'Check out these products:\n\n',
//       );
//
//       for (int index = 0; index < products.length; index++) {
//         final product = products[index];
//
//         shareTextBuffer.write(
//           'Design No: ${product.designNo}\nPrice: ₹${product.rate}\nUnit: ${product.size}\n Meter: ${product.meter}\n\n',
//         );
//
//         if (product.imagePaths != null) {
//           final imagePath = product.imagePaths![0];
//
//           if (imagePath.startsWith('http')) {
//             final response = await http.get(Uri.parse(imagePath));
//             if (response.statusCode == 200) {
//               final directory = await getTemporaryDirectory();
//               final filePath = '${directory.path}/product_$index.png';
//               final file = io.File(filePath);
//               await file.writeAsBytes(response.bodyBytes);
//
//               imageFiles.add(XFile(filePath));
//             } else {
//               print('Failed to download image: ${response.statusCode}');
//             }
//           } else {
//             // If it's a base64 string
//             Uint8List productImageBytes = base64Decode(imagePath);
//             final directory = await getTemporaryDirectory();
//             final filePath = '${directory.path}/product_$index.png';
//             final file = io.File(filePath);
//             await file.writeAsBytes(productImageBytes);
//
//             imageFiles.add(XFile(filePath));
//           }
//         }
//       }
//
//       print("Image File: ${imageFiles}");
//
//       if (imageFiles.isNotEmpty) {
//         await Share.shareXFiles(
//           imageFiles,
//           text: shareTextBuffer.toString(),
//           subject: 'Products Sharing',
//         );
//       } else {
//         await Share.share(
//           shareTextBuffer.toString(),
//           subject: 'Products Sharing',
//         );
//       }
//     } catch (e) {
//       print("Error sharing products: $e");
//     }
//   }
//
//   // Future<void> _shareProducts(List<Product> products) async {
//   //   try {
//   //     List<XFile> imageFiles = [];
//   //     StringBuffer shareTextBuffer =
//   //         StringBuffer('Check out these products:\n\n');
//   //
//   //     for (int index = 0; index < products.length; index++) {
//   //       final product = products[index];
//   //
//   //       print("Image Product: ${product}");
//   //
//   //       shareTextBuffer.write(
//   //           'Name: ${product.name}\nDescription: ${product.description}\nRate: ₹${product.rate}\n\n');
//   //
//   //       if (product.imagePaths != null) {
//   //         final imagePath = product.imagePaths![0];
//   //         Uint8List productImageBytes = base64Decode(product.imagePaths![0]);
//   //         final directory = await getTemporaryDirectory();
//   //         final filePath = '${directory.path}/product_$index.png';
//   //         final file = io.File(filePath);
//   //         await file.writeAsBytes(productImageBytes);
//   //
//   //         imageFiles.add(XFile(filePath));
//   //       }
//   //     }
//   //
//   //     print("Image File: ${imageFiles}");
//   //
//   //     if (imageFiles.isNotEmpty) {
//   //       await Share.shareXFiles(imageFiles,
//   //           text: shareTextBuffer.toString(), subject: 'Products Sharing');
//   //     } else {
//   //       await Share.share(shareTextBuffer.toString(),
//   //           subject: 'Products Sharing');
//   //     }
//   //   } catch (e) {
//   //     print("Error sharing products: $e");
//   //   }
//   // }
// }
