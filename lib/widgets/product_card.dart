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
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _compressAndLoadImage();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.toInt() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    const baseUrl = 'http://103.251.16.248:5000';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path.replaceAll("\\", "/");
    }
    return '$baseUrl/$path'.replaceAll("\\", "/");
  }


  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Delete"),
              content: Text("Are you sure you want to delete this product?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // print("Counter value in riverpods: $counterValue");
    int imageCount = widget.product.imagePaths?.length ?? 0;

    print("isSelectAll Value in ProductCard Page: ${widget.isSelectAll}");
    print("isSelectAll Value in ProductCard Ids: ${widget.selectedProductIds}");

    final screenWidth = MediaQuery.of(context).size.width;

    final resolvedImagePath = widget.product.imagePaths != null &&
        widget.product.imagePaths!.isNotEmpty
        ? _resolveImageUrl(widget.product.imagePaths!.first)
        : null;

    print("resolvedImagePath $resolvedImagePath");

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
                  widget.product.imagePaths != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8.0),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Stack(
                            children: [
                              Image.network(
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

                              // in this code i need to when i have 3 image and i current show 2 then show 3 dot and higligth the 2nd dot
                              Positioned(
                                top: 8,
                                right: 8,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentPage = 0;
                                      _pageController = PageController(initialPage: 0);
                                    });
                                    showDialog(
                                      context: context,
                                      builder: (context) => StatefulBuilder(
                                        builder: (context, setState) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: EdgeInsets.zero,
                                            child: Container(
                                              width: MediaQuery.of(context).size.width * 0.7,
                                              height: MediaQuery.of(context).size.height * 0.5,
                                              color: Colors.black,
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                      '$imageCount Images',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Stack(
                                                      children: [
                                                        PageView.builder(
                                                          controller: _pageController,
                                                          itemCount: imageCount,
                                                          onPageChanged: (index) {
                                                            setState(() {
                                                              _currentPage = index;
                                                            });
                                                          },
                                                          itemBuilder: (context, index) {
                                                            final imageUrl = _resolveImageUrl(
                                                                widget.product.imagePaths![index]);
                                                            return GestureDetector(
                                                              onTap: () => Navigator.of(context).pop(),
                                                              child: InteractiveViewer(
                                                                child: Image.network(
                                                                  imageUrl,
                                                                  fit: BoxFit.contain,
                                                                  width: double.infinity,
                                                                  height: double.infinity,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Icon(
                                                                      Icons.broken_image,
                                                                      size: 100,
                                                                      color: Colors.grey,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        Positioned(
                                                          bottom: 10,
                                                          left: 0,
                                                          right: 0,
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: List.generate(imageCount, (index) {
                                                              return Container(
                                                                margin: EdgeInsets.symmetric(horizontal: 5),
                                                                width: 8,
                                                                height: 8,
                                                                decoration: BoxDecoration(
                                                                  color: index == _currentPage
                                                                      ? Colors.blue
                                                                      : Colors.white.withOpacity(0.5),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              );
                                                            }),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Preview ($imageCount Images)",
                                    style: TextStyle(color: Color(0xFFFFFDD0)),
                                  ),
                                ),
                              ),
                            ],
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
                                'Design Number : ${widget.product.designNo}',
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
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                      message: widget.product.meter,
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Meter: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: widget.product.meter,
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

                                  // Expanded(
                                  //   child: Tooltip(
                                  //     message: widget.product.person,
                                  //     child: RichText(
                                  //       overflow: TextOverflow.ellipsis,
                                  //       text: TextSpan(
                                  //         children: [
                                  //           const TextSpan(
                                  //             text: 'Person: ',
                                  //             style: TextStyle(
                                  //               fontSize: 14,
                                  //               fontWeight: FontWeight.bold,
                                  //               color: Colors.black,
                                  //             ),
                                  //           ),
                                  //           TextSpan(
                                  //             text: widget.product.person,
                                  //             // The long name
                                  //             style: TextStyle(
                                  //               fontSize:
                                  //                   isSmallScreen ? 14 : 16,
                                  //               color: Colors.grey[600],
                                  //             ),
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
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
