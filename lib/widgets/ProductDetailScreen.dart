// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../models/product.dart';
// import 'EditProductDialog.dart';
//
// class ProductDetailScreen extends StatelessWidget {
//   final Product product;
//
//   const ProductDetailScreen({Key? key, required this.product})
//     : super(key: key);
//
//   String _resolveImageUrl(String path) {
//     return path.replaceAll(r'\\', '/');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final imagePaths = product.imagePaths ?? [];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(product.name),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.edit),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder:
//                     (context) => EditProductDialog(
//                       onProductUpdated: () {
//                         print('Product updated successfully!');
//                       },
//                       productData: product,
//                     ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             imagePaths.isNotEmpty
//                 ? (imagePaths.length > 1
//                     ? CarouselSlider(
//                       options: CarouselOptions(
//                         height: MediaQuery.of(context).size.height * 0.40,
//                         enlargeCenterPage: true,
//                         autoPlay: true,
//                         aspectRatio: 16 / 9,
//                       ),
//                       items:
//                           imagePaths.map((imagePath) {
//                             return Builder(
//                               builder: (BuildContext context) {
//                                 return Container(
//                                   width: MediaQuery.of(context).size.width,
//                                   margin: const EdgeInsets.symmetric(
//                                     horizontal: 5.0,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[200],
//                                     borderRadius: BorderRadius.circular(12.0),
//                                   ),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(12.0),
//                                     child: Image.network(
//                                       _resolveImageUrl(imagePath),
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (
//                                         context,
//                                         error,
//                                         stackTrace,
//                                       ) {
//                                         return const Center(
//                                           child: Icon(
//                                             Icons.broken_image,
//                                             size: 100,
//                                             color: Colors.grey,
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 );
//                               },
//                             );
//                           }).toList(),
//                     )
//                     : ClipRRect(
//                       borderRadius: BorderRadius.circular(12.0),
//                       child: Image.network(
//                         _resolveImageUrl(imagePaths[0]),
//                         fit: BoxFit.cover,
//                         width: MediaQuery.of(context).size.width,
//                         height: MediaQuery.of(context).size.height * 0.60,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Center(
//                             child: Icon(
//                               Icons.broken_image,
//                               size: 100,
//                               color: Colors.grey,
//                             ),
//                           );
//                         },
//                       ),
//                     ))
//                 : const Icon(Icons.image, size: 200, color: Colors.grey),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   children: [
//                     // Text(
//                     //   'Product Name: ',
//                     //   style: const TextStyle(
//                     //     fontSize: 26,
//                     //     fontWeight: FontWeight.bold,
//                     //     color: Colors.black87,
//                     //   ),
//                     // ),
//                     // Text(
//                     //   product.name,
//                     //   style: const TextStyle(
//                     //     fontSize: 26,
//                     //     fontWeight: FontWeight.bold,
//                     //     color: Colors.black87,
//                     //
//                     //   ),
//                     // ),
//                   ],
//                 )
//
//               ],
//             ),
//
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Price: ',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 Text(
//                   '₹${product.rate}',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.normal,
//                     color: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             // Row(
//             //   mainAxisAlignment: MainAxisAlignment.center,
//             //   children: [
//             //     Text(
//             //       'Description: ',
//             //       style: TextStyle(
//             //         fontSize: 20,
//             //         fontWeight: FontWeight.bold,
//             //         color: Colors.black87,
//             //       ),
//             //     ),
//             //     // Use Center widget here
//             //     Center(
//             //       child: Text(
//             //         product.description,
//             //         style: TextStyle(
//             //           fontSize: 20,
//             //           fontWeight: FontWeight.normal,
//             //           color: Colors.grey[700],
//             //           fontStyle: FontStyle.italic,
//             //         ),
//             //         textAlign: TextAlign.center,
//             //       ),
//             //     ),
//             //   ],
//             // ),
//             // const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Meter: ',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 // Use Center widget here
//                 Center(
//                   child: Text(
//                     product.size,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.normal,
//                       color: Colors.grey[700],
//                       fontStyle: FontStyle.italic,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/product.dart';
import 'EditProductDialog.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  String _resolveImageUrl(String path) {
    return path.replaceAll(r'\\', '/');
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = product.imagePaths ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => EditProductDialog(
                  onProductUpdated: () {
                    print('Product updated successfully!');
                  },
                  productData: product,
                ),
              );
            },
          ),
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
                  height: MediaQuery.of(context).size.height * 0.40, // 40% of screen height
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                ),
                items: imagePaths.map((imagePath) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            _resolveImageUrl(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  _resolveImageUrl(imagePaths[0]),
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.40, // 40% of screen height
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
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
                      product.name.isNotEmpty
                          ? '${product.name[0].toUpperCase()}${product.name.substring(1)}'
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
                    '₹${product.rate}',
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
                    style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,
        
                    ),
                  ),
                  Text(
                    product.size,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 30),
              Text("Product Details", style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),),
              const SizedBox(height: 3),
              Table(
                border: TableBorder.all(color: Colors.black54), // Optional: Adds border to the table
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Type',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.type ?? "IsEmpty",
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
                          'Code',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.code ?? "IsEmpty",
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
                          'DesignNo',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.designNo ?? "IsEmpty",
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
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.description ?? "IsEmpty",
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
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.color ?? "IsEmpty",
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
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.packing ?? "IsEmpty",
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
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.meter ?? "NULL DATA",
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
