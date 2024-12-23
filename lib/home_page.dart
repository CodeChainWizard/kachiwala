// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'package:newprg/widgets/shareProduct.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:newprg/main.dart';
// import 'package:newprg/widgets/Login.page.dart';
// import 'models/product.dart';
// import 'services/api_service.dart';
// import 'widgets/product_card.dart';
// import 'widgets/add_product_dialog.dart';
// import 'widgets/search_bar.dart';
// import 'dart:async';
//
//
// // --- Apply ReiverPod ---
// final counterProvider = StateProvider<int>((ref) => 0);
//
// class HomePage extends ConsumerStatefulWidget {
//   const HomePage({Key? key}) : super(key: key);
//
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends ConsumerState<HomePage> {
//   List<Product> products = [];
//   List<Product> filteredProducts = [];
//   String searchQuery = "";
//   bool isSelectAll = false;
//   bool productSelection = false;
//   String? selectedProductId;
//
//   bool isMenuOpen = false;
//
//   // --- Loading ---
//   bool isLoading = true;
//
//   // --- set the timer for API Called ---
//   Timer? _debounce;
//
//   bool getData = false;
//   bool hasMore = true;
//
//   late SharedPreferences pref;
//   String selectedProductType = '';
//
//   List<String> selectedProductIds = [];
//
//   // ---- Apply Page ----
//   int currentPage = 0;
//   int totalPages = 0;
//   final int itemsPerPage = 6;
//
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchProducts(skip: 0, take: itemsPerPage);
//     _initializePrefs();
//
//     _scrollController.addListener(_scrollListener);
//   }
//
//   void _scrollListener() {
//     if (_scrollController.position.atEdge && _scrollController.position.pixels != 0) {
//       if (currentPage < totalPages) {
//         _loadMoreProducts();
//       }
//     }
//   }
//
//   Future<void> _initializePrefs() async {
//     pref = await SharedPreferences.getInstance();
//     setState(() {
//       getData = pref.getBool("longPress") ?? false;
//     });
//     print("Data state:- $getData");
//   }
//
//   void _refreshProducts() {
//     setState(() {
//       isSelectAll = false;
//       selectedProductIds = [];
//       ref.read(counterProvider.notifier).state = 0;
//     });
//     _fetchProducts();
//   }
//
//   Future<void> _fetchProducts({int skip = 0, int take = 6}) async {
//     try {
//       setState(() {
//         isLoading = true;
//       });
//
//       // Fetch the products with pagination
//       List<Product> fetchedProducts = await ApiService.fetchProducts(
//         skip: skip,
//         take: take,
//       );
//
//       setState(() {
//         products.addAll(fetchedProducts);
//         filteredProducts = products;
//         isLoading = false;
//         totalPages = (fetchedProducts.length / take).ceil();
//       });
//     } catch (e) {
//       print('Error fetching products: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _loadMoreProducts() {
//     if (!isLoading && currentPage < totalPages) {
//       setState(() {
//         isLoading = true;
//         currentPage++;
//       });
//       _fetchProducts(skip: currentPage * itemsPerPage, take: itemsPerPage);
//     } else {
//       print("No more products to load");
//     }
//   }
//
//   void _toggleSelectAll() {
//     setState(() {
//       isSelectAll = !isSelectAll;
//       if (isSelectAll) {
//         selectedProductIds =
//             filteredProducts.map((product) => product.id).toList();
//         ref.read(counterProvider.notifier).state = filteredProducts.length;
//       } else {
//         isSelectAll = false;
//         selectedProductIds = [];
//         ref.read(counterProvider.notifier).state = 0;
//       }
//     });
//     print("All the Product Id:- $selectedProductIds");
//   }
//
//   final FocusNode _searchFocusNode = FocusNode();
//
//   void _onSearchChanged(String query) async {
//     setState(() {
//       searchQuery = query;
//     });
//
//     if (_debounce?.isActive ?? false) {
//       _debounce?.cancel();
//     }
//
//     _debounce = Timer(const Duration(milliseconds: 500), () async {
//       if (query.isEmpty) {
//         setState(() {
//           filteredProducts = List.from(products);
//           isLoading = false;
//         });
//
//         // Unfocus when search query is empty
//         _searchFocusNode.unfocus();
//       } else {
//         try {
//           setState(() {
//             isLoading = true;
//           });
//
//           // Fetch filtered results based on the search query
//           List<Product> results = await ApiService.onSearchChanged(query);
//
//           setState(() {
//             filteredProducts = results;
//             isLoading = false;
//           });
//         } catch (e) {
//           setState(() {
//             filteredProducts = [];
//             isLoading = false;
//           });
//           print("Search error: $e");
//         }
//       }
//     });
//   }
//
//   int updateCounter(bool isSelected) {
//     final counter = ref.read(counterProvider.state);
//     int oldValue = counter.state;
//
//     if (isSelected) {
//       counter.state++;
//     } else {
//       counter.state--;
//       if (counter.state < 0) counter.state = 0;
//     }
//
//     if (oldValue != counter.state) {
//       print("Counter Updated: ${counter.state}");
//     }
//     return counter.state;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var counterValue = ref.watch(counterProvider.state).state;
//
//     print("Select All Product: $isSelectAll");
//
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Product List'),
//           leading: IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await setLoginStatus(false);
//
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => LoginPage()),
//               );
//             }, // Call your logout function
//             tooltip: 'Logout',
//           ),
//           actions: [
//             filteredProducts.isNotEmpty
//                 ? OutlinedButton(
//                   onPressed: _toggleSelectAll,
//                   style: OutlinedButton.styleFrom(
//                     // primary: Colors.blue,
//                     side: const BorderSide(color: Colors.blue), // Border color
//                   ),
//                   child: Text(isSelectAll ? 'Deselect All' : 'Select All'),
//                 )
//                 : SizedBox(),
//
//             // IconButton(
//             //   icon: Icon(isSelectAll
//             //       ? Icons.check_box
//             //       : Icons.check_box_outline_blank),
//             //   onPressed: _toggleSelectAll,
//             //   tooltip: isSelectAll ? 'Deselect All' : 'Select All',
//             // ),
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _fetchProducts,
//             ),
//           ],
//         ),
//         body: Column(
//           children: [
//             CustomSearchBar(onSearchChanged: _onSearchChanged),
//             const Center(child: CircularProgressIndicator()),
//           ],
//         ),
//       );
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Product List'),
//         leading: IconButton(
//           icon: const Icon(Icons.logout), // Logout icon
//           onPressed: () async {
//             await setLoginStatus(false);
//
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => LoginPage()),
//             );
//           },
//           tooltip: 'Logout',
//         ),
//         actions: [
//           filteredProducts.isNotEmpty
//               ? OutlinedButton(
//                 onPressed: _toggleSelectAll,
//                 style: OutlinedButton.styleFrom(
//                   // primary: Colors.blue,
//                   side: const BorderSide(color: Colors.blue),
//                 ),
//                 child: Text(isSelectAll ? 'Deselect All' : 'Select All'),
//               )
//               : SizedBox(),
//
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _refreshProducts,
//           ),
//         ],
//       ),
//
//       body: Column(
//         children: [
//           CustomSearchBar(onSearchChanged: _onSearchChanged),
//           Expanded(
//             child:
//                 filteredProducts.isEmpty
//                     ? const Center(
//                       child: Text(
//                         "No Products Found",
//                         style: TextStyle(
//                           fontSize: 22,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     )
//                     : GridView.builder(
//                       controller: _scrollController,
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             mainAxisSpacing: 8.0,
//                             crossAxisSpacing: 8.0,
//                             childAspectRatio: 3 / 4,
//                           ),
//                       itemCount: filteredProducts.length + (isLoading ? 1 : 0),
//                       itemBuilder: (context, index) {
//                         if (index == filteredProducts.length && isLoading) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }
//                         final product = products[index];
//                         // print("All data: $products");
//                         return ProductCard(
//                           product: filteredProducts[index],
//                           index: index,
//                           isGlobalSelected: isSelectAll,
//                           isSelectAll: isSelectAll,
//                           onTap: () {
//                             setState(() {
//                               if (!selectedProductIds.contains(
//                                 filteredProducts[index].id,
//                               )) {
//                                 selectedProductIds.add(
//                                   filteredProducts[index].id,
//                                 );
//                               } else {
//                                 selectedProductIds.remove(
//                                   filteredProducts[index].id,
//                                 );
//                               }
//                               print(
//                                 "Selected Product IDs: $selectedProductIds",
//                               );
//                             });
//                           },
//                           updateCounter: updateCounter,
//                         );
//                       },
//                     ),
//           ),
//         ],
//       ),
//
//       floatingActionButton:
//           counterValue > 0
//               ? SpeedDial(
//                 animatedIcon: AnimatedIcons.menu_close,
//                 animatedIconTheme: IconThemeData(size: 30.0),
//                 curve: Curves.easeInOut,
//                 onOpen: () => setState(() => isMenuOpen = true),
//                 onClose: () => setState(() => isMenuOpen = false),
//                 backgroundColor: Colors.blueAccent,
//                 foregroundColor: Colors.white,
//                 elevation: 10.0,
//                 shape: CircleBorder(),
//                 children: [
//                   SpeedDialChild(
//                     child: Icon(Icons.share),
//                     backgroundColor: Colors.green,
//                     label: 'Share',
//                     labelStyle: TextStyle(fontSize: 16.0, color: Colors.white),
//                     labelBackgroundColor: Colors.green,
//                     onTap: () async {
//                       if (counterValue > 0) {
//                         List<Product> selectedProducts =
//                             filteredProducts
//                                 .where(
//                                   (product) =>
//                                       selectedProductIds.contains(product.id),
//                                 )
//                                 .toList();
//
//                         if (selectedProducts.isNotEmpty) {
//                           final shareProduct = ShareProduct();
//                           await shareProduct.shareAllProducts(selectedProducts);
//
//                           setState(() {
//                             isMenuOpen = false;
//                             selectedProductIds = [];
//                           });
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 "No valid products selected for sharing.",
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       }
//                     },
//                   ),
//
//                   SpeedDialChild(
//                     child: Icon(Icons.delete),
//                     backgroundColor: Colors.red,
//                     label: 'Delete',
//                     labelStyle: TextStyle(fontSize: 16.0, color: Colors.white),
//                     labelBackgroundColor: Colors.red,
//                     onTap: () async {
//                       if (counterValue > 0 && selectedProductIds.isNotEmpty) {
//                         // Show a confirmation dialog before deleting products
//                         bool? confirmDelete = await showDialog(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return AlertDialog(
//                               backgroundColor: Colors.white, // Background color of the dialog
//                               title: Text(
//                                 'Confirm Deletion',
//                                 style: TextStyle(
//                                   fontSize: 18.0,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.red, // Title color
//                                 ),
//                               ),
//                               content: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   'Are you sure you want to delete the selected products?',
//                                   style: TextStyle(fontSize: 16.0),
//                                 ),
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15.0), // Rounded corners
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.of(context).pop(false); // User tapped 'No'
//                                   },
//                                   child: Text(
//                                     'No',
//                                     style: TextStyle(
//                                       fontSize: 16.0,
//                                       color: Colors.blue, // Change text color
//                                     ),
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.of(context).pop(true); // User tapped 'Yes'
//                                   },
//                                   child: Text(
//                                     'Yes',
//                                     style: TextStyle(
//                                       fontSize: 16.0,
//                                       color: Colors.green, // Change text color
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         );
//
//                         // If the user confirms, proceed with deletion
//                         if (confirmDelete == true) {
//                           try {
//                             print("Deleted Product Id: $selectedProductIds");
//                             var response = await ApiService.deleteProducts(
//                               selectedProductIds,
//                             );
//
//                             print("DELETE PRODUCT RESPONSE: $response");
//
//                             if (response.statusCode == 200) {
//                               setState(() {
//                                 selectedProductIds = [];
//                                 counterValue = 0;
//                               });
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(
//                                     'Products deleted successfully',
//                                   ),
//                                 ),
//                               );
//                             } else {
//                               // Handle any errors from the API response
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('Failed to delete products'),
//                                 ),
//                               );
//                             }
//                           } catch (e) {
//                             // Handle any errors during the API call
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('An error occurred: $e')),
//                             );
//                           }
//                         }
//                       }
//                     },
//                   ),
//                 ],
//               )
//               : FloatingActionButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder:
//                         (_) =>
//                             AddProductDialog(onProductAdded: _refreshProducts),
//                   );
//                 },
//                 backgroundColor: Colors.blue,
//                 child: Icon(Icons.add, color: Colors.white),
//               ),
//     );
//   }
// }
//
//


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:newprg/widgets/shareProduct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newprg/main.dart';
import 'package:newprg/widgets/Login.page.dart';
import 'models/product.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/search_bar.dart';
import 'dart:async';


// --- Apply RiverPod ---
final counterProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  String searchQuery = "";
  bool isSelectAll = false;
  bool productSelection = false;
  String? selectedProductId;

  bool isMenuOpen = false;

  // --- Loading ---
  bool isLoading = false;

  // --- set the timer for API Called ---
  Timer? _debounce;

  bool getData = false;
  bool hasMore = true;

  late SharedPreferences pref;
  String selectedProductType = '';

  List<String> selectedProductIds = [];

  // ---- Apply Page ----
  int currentPage = 0;
  int totalPages = 0;
  final int itemsPerPage = 6;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProducts(skip: 0, take: itemsPerPage);
    _initializePrefs();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge && _scrollController.position.pixels != 0) {
      if (currentPage < totalPages) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _initializePrefs() async {
    pref = await SharedPreferences.getInstance();
    setState(() {
      getData = pref.getBool("longPress") ?? false;
    });
  }

  void _refreshProducts() {
    setState(() {
      isSelectAll = false;
      selectedProductIds = [];
      ref.read(counterProvider.notifier).state = 0;
      products.clear();
      currentPage = 0;
    });
    _fetchProducts();
  }

  Future<void> _fetchProducts({int skip = 0, int take = 6}) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Fetch the products with pagination
      List<Product> fetchedProducts = await ApiService.fetchProducts(
        skip: skip,
        take: take,
      );

      setState(() {
        products.addAll(fetchedProducts);
        filteredProducts = products;
        isLoading = false;
        totalPages = (fetchedProducts.length / take).ceil();
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadMoreProducts() {
    if (!isLoading && currentPage < totalPages) {
      setState(() {
        isLoading = true;
        currentPage++;
      });
      _fetchProducts(skip: currentPage * itemsPerPage, take: itemsPerPage);
    } else {
      print("No more products to load");
    }
  }

  void _toggleSelectAll() {
    setState(() {
      isSelectAll = !isSelectAll;
      if (isSelectAll) {
        selectedProductIds = filteredProducts.map((product) => product.id).toList();
        ref.read(counterProvider.notifier).state = filteredProducts.length;
      } else {
        isSelectAll = false;
        selectedProductIds = [];
        ref.read(counterProvider.notifier).state = 0;
      }
    });
  }

  final FocusNode _searchFocusNode = FocusNode();

  void _onSearchChanged(String query) async {
    setState(() {
      searchQuery = query;
    });

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          filteredProducts = List.from(products);
          isLoading = false;
        });
        _searchFocusNode.unfocus();
      } else {
        try {
          setState(() {
            isLoading = true;
          });

          List<Product> results = await ApiService.onSearchChanged(query);

          setState(() {
            filteredProducts = results;
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            filteredProducts = [];
            isLoading = false;
          });
        }
      }
    });
  }

  int updateCounter(bool isSelected) {
    final counter = ref.read(counterProvider.state);
    int oldValue = counter.state;

    if (isSelected) {
      counter.state++;
    } else {
      counter.state--;
      if (counter.state < 0) counter.state = 0;
    }

    return counter.state;
  }

  @override
  Widget build(BuildContext context) {
    var counterValue = ref.watch(counterProvider.state).state;

    if (isLoading && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product List'),
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await setLoginStatus(false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            tooltip: 'Logout',
          ),
          actions: [
            filteredProducts.isNotEmpty
                ? OutlinedButton(
              onPressed: _toggleSelectAll,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
              ),
              child: Text(isSelectAll ? 'Deselect All' : 'Select All'),
            )
                : SizedBox(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProducts,
            ),
          ],
        ),
        body: Column(
          children: [
            CustomSearchBar(onSearchChanged: _onSearchChanged),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await setLoginStatus(false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          tooltip: 'Logout',
        ),
        actions: [
          filteredProducts.isNotEmpty
              ? OutlinedButton(
            onPressed: _toggleSelectAll,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
            ),
            child: Text(isSelectAll ? 'Deselect All' : 'Select All'),
          )
              : SizedBox(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(onSearchChanged: _onSearchChanged),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
              child: Text(
                "No Products Found",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 3 / 4,
              ),
              itemCount: filteredProducts.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredProducts.length && isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final product = filteredProducts[index];
                return ProductCard(
                  product: product,
                  index: index,
                  isGlobalSelected: isSelectAll,
                  isSelectAll: isSelectAll,
                  onTap: () {
                    setState(() {
                      if (!selectedProductIds.contains(product.id)) {
                        selectedProductIds.add(product.id);
                      } else {
                        selectedProductIds.remove(product.id);
                      }
                    });
                  },
                  updateCounter: updateCounter,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: counterValue > 0
          ? SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 30.0),
        curve: Curves.easeInOut,
        onOpen: () => setState(() => isMenuOpen = true),
        onClose: () => setState(() => isMenuOpen = false),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 10.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
            child: Icon(Icons.share),
            backgroundColor: Colors.green,
            label: 'Share',
            labelStyle: TextStyle(fontSize: 16.0, color: Colors.white),
            labelBackgroundColor: Colors.green,
            onTap: () async {
              if (counterValue > 0) {
                List<Product> selectedProducts = filteredProducts
                    .where((product) => selectedProductIds.contains(product.id))
                    .toList();

                if (selectedProducts.isNotEmpty) {
                  final shareProduct = ShareProduct();
                  await shareProduct.shareAllProducts(selectedProducts);

                  setState(() {
                    isMenuOpen = false;
                    selectedProductIds = [];
                  });
                }
              }
            },
          ),

          SpeedDialChild(
            child: Icon(Icons.delete),
            backgroundColor: Colors.red,
            label: 'Delete',
            labelStyle: TextStyle(fontSize: 16.0, color: Colors.white),
            labelBackgroundColor: Colors.red,
            onTap: () async {
              if (counterValue > 0 && selectedProductIds.isNotEmpty) {
                bool? confirmDelete = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text(
                          'Are you sure you want to delete the selected products?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text('Yes'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  try {
                    var response = await ApiService.deleteProducts(selectedProductIds);
                    if (response.statusCode == 200) {
                      setState(() {
                        selectedProductIds = [];
                        counterValue = 0;
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      )
          : FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddProductDialog(onProductAdded: _refreshProducts),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
