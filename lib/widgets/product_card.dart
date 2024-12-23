import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newprg/models/product.dart';
import 'package:newprg/widgets/ProductDetailScreen.dart';
import 'dart:io' as io;

import '../models/product.dart';

final counterProvider = StateProvider<int>((ref) => 0);

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final int index;
  final bool isGlobalSelected;
  final VoidCallback onTap;
  final Function(bool) updateCounter;
  final bool isSelectAll;

  ProductCard({
    required this.product,
    required this.index,
    required this.isGlobalSelected,
    required this.onTap,
    required this.updateCounter,
    required this.isSelectAll,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool isSelected = false;
  bool isMultiSelectActive = false;


  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   ref.listen<int>(counterProvider, (previous, next){
  //     print("Counter value in Riverpod changed: $next");
  //   });
  // }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure that global selection state is updated in each card
    if (widget.isGlobalSelected != oldWidget.isGlobalSelected) {
      setState(() {
        isSelected = widget.isGlobalSelected;
      });
    }
  }

  // void updateCounter(bool isSelected) {
  //   final counter = ref.read(counterProvider.state);
  //   int oldValue = counter.state;
  //
  //   if (isSelected) {
  //     counter.state++;
  //   } else {
  //     counter.state--;
  //     if(counter.state < 0) counter.state = 0;
  //   }
  //
  //   if(oldValue != counter.state){
  //     print("Counter Updated: ${counter.state}");
  //   }
  // }

  String _resolveImageUrl(String path) {
    // return path.replaceAll("\\", "/");
    return path;
  }

  // String _resolveImageUrl(String path) {
  //   const String baseUrl = 'Shubham URL for Access Images URL';
  //   return baseUrl + path.replaceAll("\\", "/");
  // }

  @override
  Widget build(BuildContext context) {
    // print("Counter value in riverpods: $counterValue");

    print("isSelectAll Value in ProductCard Page: ${widget.isSelectAll}");

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
        margin: EdgeInsets.all(8.0),
        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : null,
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
                      )
                      : Icon(Icons.image, size: 100, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Desc : ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.product.description,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed:
                                      () => _shareProducts([widget.product]),
                                  iconSize: isSmallScreen ? 20 : 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Expanded(
            //   child: widget.product.image != null
            //       ? ClipRRect(
            //     borderRadius:
            //     BorderRadius.vertical(top: Radius.circular(8.0)),
            //     child: Image.memory(
            //       base64Decode(widget.product.image!),
            //       fit: BoxFit.cover,
            //       width: double.infinity,
            //     ),
            //   )
            //       : Icon(
            //     Icons.image,
            //     size: 100,
            //     color: Colors.grey,
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Name : ${widget.product.name}',
            //               style: const TextStyle(
            //                 fontSize: 16,
            //                 fontWeight: FontWeight.bold,
            //               ),
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //             ),
            //             SizedBox(height: 4.0),
            //             RichText(
            //               text: TextSpan(
            //                 children: [
            //                   const TextSpan(
            //                     text: 'Desc : ',
            //                     style: TextStyle(
            //                       fontSize: 16,
            //                       fontWeight: FontWeight.bold,
            //                       color: Colors.black,
            //                     ),
            //                   ),
            //                   TextSpan(
            //                     text: widget.product.description,
            //                     style: TextStyle(
            //                       fontSize: 14,
            //                       color: Colors.grey[600],
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(height: 4.0),
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 RichText(
            //                   text: TextSpan(
            //                     children: [
            //                       const TextSpan(
            //                         text: 'Price(₹) : ',
            //                         style: TextStyle(
            //                           fontSize: 16,
            //                           fontWeight: FontWeight.bold,
            //                           color: Colors.black,
            //                         ),
            //                       ),
            //                       TextSpan(
            //                         text: '${widget.product.rate} Rs',
            //                         style: TextStyle(
            //                           fontSize: 14,
            //                           color: Colors.grey[600],
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //                 IconButton(
            //                   icon: const Icon(Icons.share),
            //                   onPressed: () => _shareProducts([widget.product]),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Row(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Name : ${widget.product.name}',
            //               style: const TextStyle(
            //                   fontSize: 16, fontWeight: FontWeight.bold),
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //             ),
            //             SizedBox(height: 4.0),
            //             RichText(
            //               text: TextSpan(
            //                 children: [
            //                   const TextSpan(
            //                     text: 'Desc : ',
            //                     style: TextStyle(
            //                         fontSize: 16,
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.black),
            //                   ),
            //                   TextSpan(
            //                     text: widget.product.description,
            //                     style: TextStyle(
            //                         fontSize: 14, color: Colors.grey[600]),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(height: 4.0),
            //             RichText(
            //               text: TextSpan(
            //                 children: [
            //                   const TextSpan(
            //                     text: 'Price(₹) : ',
            //                     style: TextStyle(
            //                         fontSize: 16,
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.black),
            //                   ),
            //                   TextSpan(
            //                     text: '${widget.product.rate} Rs',
            //                     style: TextStyle(
            //                         fontSize: 14, color: Colors.grey[600]),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //       IconButton(
            //         icon: Icon(Icons.share),
            //         onPressed: () => _shareProducts([widget.product]),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  //  http://103.251.16.248:5000/imageData/folder1/1734348107424-338314245.jfif
  Future<void> _shareProducts(List<Product> products) async {
    try {
      List<XFile> imageFiles = [];
      StringBuffer shareTextBuffer = StringBuffer(
        'Check out these products:\n\n',
      );

      for (int index = 0; index < products.length; index++) {
        final product = products[index];

        print("Image Product: ${product}");

        shareTextBuffer.write(
          'Design No: ${product.designNo}\nPrice: ₹${product.rate}\nUnit: ${product.size}\n\n',
        );

        if (product.imagePaths != null) {
          final imagePath = product.imagePaths![0];

          if (imagePath.startsWith('http')) {
            final response = await http.get(Uri.parse(imagePath));
            if (response.statusCode == 200) {
              final directory = await getTemporaryDirectory();
              final filePath = '${directory.path}/product_$index.png';
              final file = io.File(filePath);
              await file.writeAsBytes(response.bodyBytes);

              imageFiles.add(XFile(filePath));
            } else {
              print('Failed to download image: ${response.statusCode}');
            }
          } else {
            // If it's a base64 string
            Uint8List productImageBytes = base64Decode(imagePath);
            final directory = await getTemporaryDirectory();
            final filePath = '${directory.path}/product_$index.png';
            final file = io.File(filePath);
            await file.writeAsBytes(productImageBytes);

            imageFiles.add(XFile(filePath));
          }
        }
      }

      print("Image File: ${imageFiles}");

      if (imageFiles.isNotEmpty) {
        await Share.shareXFiles(
          imageFiles,
          text: shareTextBuffer.toString(),
          subject: 'Products Sharing',
        );
      } else {
        await Share.share(
          shareTextBuffer.toString(),
          subject: 'Products Sharing',
        );
      }
    } catch (e) {
      print("Error sharing products: $e");
    }
  }

  // Future<void> _shareProducts(List<Product> products) async {
  //   try {
  //     List<XFile> imageFiles = [];
  //     StringBuffer shareTextBuffer =
  //         StringBuffer('Check out these products:\n\n');
  //
  //     for (int index = 0; index < products.length; index++) {
  //       final product = products[index];
  //
  //       print("Image Product: ${product}");
  //
  //       shareTextBuffer.write(
  //           'Name: ${product.name}\nDescription: ${product.description}\nRate: ₹${product.rate}\n\n');
  //
  //       if (product.imagePaths != null) {
  //         final imagePath = product.imagePaths![0];
  //         Uint8List productImageBytes = base64Decode(product.imagePaths![0]);
  //         final directory = await getTemporaryDirectory();
  //         final filePath = '${directory.path}/product_$index.png';
  //         final file = io.File(filePath);
  //         await file.writeAsBytes(productImageBytes);
  //
  //         imageFiles.add(XFile(filePath));
  //       }
  //     }
  //
  //     print("Image File: ${imageFiles}");
  //
  //     if (imageFiles.isNotEmpty) {
  //       await Share.shareXFiles(imageFiles,
  //           text: shareTextBuffer.toString(), subject: 'Products Sharing');
  //     } else {
  //       await Share.share(shareTextBuffer.toString(),
  //           subject: 'Products Sharing');
  //     }
  //   } catch (e) {
  //     print("Error sharing products: $e");
  //   }
  // }
}
