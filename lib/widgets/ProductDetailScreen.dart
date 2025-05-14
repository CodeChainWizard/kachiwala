import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newprg/home_page.dart';
import 'package:newprg/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/product.riverPod.dart';
import 'EditProductPage.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<Uint8List> compressedImages;
  bool isLoading = true;

  late Product _product;

  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    compressedImages = [];
    _compressAndLoadImages();
    _product = widget.product;
    // print("PRODUCT ID: ${widget.product.id}");
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _compressAndLoadImages() async {
    try {
      final imagePaths = widget.product.imagePaths ?? [];
      List<Uint8List> tempCompressedImages = [];

      for (var imagePath in imagePaths) {
        if (imagePath.isNotEmpty) {
          try {
            Uint8List decodedBytes;

            if (imagePath.startsWith('data:image') || imagePath.contains(',')) {
              decodedBytes = base64Decode(imagePath.split(',').last);
            } else {
              final file = File(imagePath);
              if (!await file.exists()) {
                print("File does not exist: $imagePath");
                continue;
              }
              decodedBytes = await file.readAsBytes();
            }

            final compressedImage = await FlutterImageCompress.compressWithList(
              decodedBytes,
              minWidth: 150,
              minHeight: 150,
              quality: 5,
            );

            if (compressedImage != null) {
              tempCompressedImages.add(compressedImage);
            } else {
              print("Failed to compress image: $imagePath");
            }
          } catch (e) {
            print("Error processing image: $imagePath. Error: $e");
          }
        } else {
          print("Empty image path found, skipping compression.");
        }
      }

      if (mounted) {
        setState(() {
          compressedImages = tempCompressedImages;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error compressing images: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _resolveImageUrl(String path) {
    return path.replaceAll(r'\\', '/');
  }

  Future<bool> _deleteProduct(BuildContext context) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Access not provided")),
        );
        return false;
      }

      print("Deleting Product ID: ${widget.product.id}");

      final response = await ApiService.deleteProducts(
        [widget.product.id.toString()],
        token,
      );

      if (response.statusCode == 200) {
        // Close the dialog
        if (context.mounted) Navigator.of(context).pop();

        // Refresh product list in parent widget
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete product")),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
      return false;
    }
  }


  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product) {
      setState(() {
        _product = widget.product;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Details Page Product: ${widget.product}");
    print("Price per meter CHECKER: ${_product.pricepermeter}");

    final imagePaths = widget.product.imagePaths ?? [];
    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: Color(0xFF6F4F37),
        iconTheme: IconThemeData(color: Color(0xFFFFFDD0)),
        title: Text(_product.name, style: TextStyle(color: Colors.white),),
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          },
          icon: Icon(Icons.arrow_back),
        ),

        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final updatedProduct = await Navigator.push<Product>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditProductPage(
                            productData: _product,
                            refreshProducts: () {},
                          ),
                    ),
                  );

                  if (updatedProduct != null && context.mounted) {
                    final ref = ProviderScope.containerOf(context);
                    ref
                        .read(productProvider.notifier)
                        .updateProduct(updatedProduct);

                    setState(() {
                      _product = updatedProduct;
                    });
                  }
                },
              ),

              // IconButton(
              //   icon: const Icon(Icons.edit),
              //   onPressed: () async {
              //     final updatedProduct = await Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder:
              //             (context) => EditProductPage(productData: _product),
              //       ),
              //     );
              //
              //     if (updatedProduct != null && mounted) {
              //       context.read(productProvider.notifier).updateProduct(updatedProduct);
              //       // setState(() {
              //       //   _product = updatedProduct;
              //       // });
              //     }
              //   },
              // ),

              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Confirm Deletion"),
                        content: Text(
                          "Are you sure you want to delete this item('${widget.product.name}')?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(
                                context,
                              ).pop(); // Close the dialog first

                              bool isDeleted = await _deleteProduct(context);

                              if (isDeleted && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                  ),
                                );
                              }
                            },

                            child: Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // IconButton(
          //   icon: const Icon(Icons.edit),
          //   onPressed: () {
          //     showDialog(
          //       context: context,
          //       builder:
          //           (context) => EditProductDialog(
          //             onProductUpdated: () {
          //               print('Product updated successfully!');
          //             },
          //             productData: widget.product,
          //           ),
          //     );
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imagePaths.isNotEmpty
                  ? (imagePaths.length > 1
                      ? CarouselSlider(
                        options: CarouselOptions(
                          height: MediaQuery.of(context).size.height * 0.40,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          aspectRatio: 16 / 9,
                        ),
                        items:
                            compressedImages.isEmpty
                                ? imagePaths.map((imagePath) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: _resolveImageUrl(
                                              imagePath,
                                            ),
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) => Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 100,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList()
                                : compressedImages.map((compressedImage) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child: Image.memory(
                                            compressedImage,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child:
                            compressedImages.isEmpty
                                ? CachedNetworkImage(
                                  imageUrl: _resolveImageUrl(imagePaths[0]),
                                  fit: BoxFit.contain,
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.40,
                                  placeholder:
                                      (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 100,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                : Image.memory(
                                  compressedImages[0],
                                  fit: BoxFit.contain,
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.40,
                                ),
                      ))
                  : const Icon(Icons.image, size: 200, color: Colors.grey),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.product.name.isNotEmpty
                          ? '${_product.name[0].toUpperCase()}${_product.name.substring(1)}'
                          : '',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Price: ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '₹${_product.rate}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Sizes: ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _product.size,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                "Product Details",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Table(
                border: TableBorder.all(color: Colors.black54),
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Design No',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.designNo ?? "IsEmpty",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Meter',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.meter ?? "IsEmpty",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Size',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.size ?? "IsEmpty",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Price',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.rate.toString() ?? "0",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Type',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.type ?? "IsEmpty",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Color',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.color ?? "IsEmpty",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Packing',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.packing ?? "NULL DATA",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Price Per Meter',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '₹${_product.pricepermeter}',  // Directly use the string value
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Person',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _product.person ?? "NULL DATA",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
