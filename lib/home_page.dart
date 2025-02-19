import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:newprg/widgets/AddPersonPage.dart';
import 'package:newprg/widgets/CreateNewProduct.dart';
import 'package:newprg/widgets/shareProduct.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newprg/main.dart';
import 'package:newprg/widgets/Login.page.dart';
import 'models/product.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/search_bar.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

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
  String? storedEmail = "";

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

  void updateSelectedProductIds(List<String> updatedIds) {
    setState(() {
      selectedProductIds = updatedIds;
    });
  }

  // ---- Apply Page ----
  int currentPage = 0;
  int totalPages = 0;
  final int itemPerPage = 6;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = "A-Z";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    // _fetchProducts(skip: 0, take: itemsPerPage);
    _initializePrefs();

    _scrollController.addListener(_scrollListener);
    // _requestStoragePermission(context);
    getStoredEmail();
  }

  Future<void> _requestStoragePermission(BuildContext context) async {
    // Check the current permission status
    PermissionStatus status = await Permission.storage.status;

    // If permission is already granted, no need to request again
    if (status.isGranted) {
      print("Storage permission is already granted!");
      return;
    }

    // If permission is denied, restricted, or limited, request it
    final result = await Permission.storage.request();

    // Handle the result of the permission request
    if (result.isGranted) {
      // Permission granted, proceed with necessary functionality
      print("Storage permission granted!");
    } else if (result.isDenied) {
      // Permission explicitly denied, show an error dialog
      _showPermissionDialog(
        context,
        'Storage Permission Denied',
        'Storage permission is required to access product files. Without it, some features may not work properly. Please grant access.',
      );
    } else if (result.isPermanentlyDenied) {
      // Permission permanently denied, suggest going to app settings
      _showPermissionDialog(
        context,
        'Storage Permission Permanently Denied',
        'You have permanently denied storage permission. Please enable it from app settings to continue using the app.',
        openSettings: true,
      );
    } else if (result.isRestricted) {
      // Permission restricted (e.g., parental controls), show info
      _showPermissionDialog(
        context,
        'Storage Permission Restricted',
        'Storage permission is restricted on your device. Please check your device settings.',
      );
    }
  }

  void _showPermissionDialog(
    BuildContext context,
    String title,
    String content, {
    bool openSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            // "Cancel" button for users who don't want to proceed
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            // "Okay" or "Open Settings" button depending on the context
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                if (openSettings) {
                  openAppSettings(); // Redirect user to app settings
                }
              },
              child: Text(
                openSettings ? 'Open Settings' : 'Okay',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels != 0) {
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
      _searchController.clear();

      FocusScope.of(context).requestFocus(FocusNode());
    });
    _searchController.clear();
    _fetchProducts();
  }

  Future<void> _refreshProducts_RefreshIndi() async {
    setState(() {
      isSelectAll = false;
      selectedProductIds = [];
      ref.read(counterProvider.notifier).state = 0;
      products.clear();
      currentPage = 0;
      _searchController.clear();

      FocusScope.of(context).requestFocus(FocusNode());
    });

    _searchController.clear();
    await _fetchProducts(); // Make sure _fetchProducts is async
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Fetch all products
      List<Product> fetchedProducts = await ApiService.fetchProducts();

      print("API RESPONSE: $fetchedProducts");

      setState(() {
        products = fetchedProducts;
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> _fetchProducts({int skip = 0, int take = 6}) async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     // Fetch the products with pagination
  //     List<Product> fetchedProducts = await ApiService.fetchProducts(
  //       skip: skip,
  //       take: take,
  //     );
  //
  //     print("API RESPONSE: $fetchedProducts");
  //
  //     setState(() {
  //       products.addAll(fetchedProducts);
  //       filteredProducts = products;
  //       isLoading = false;
  //       totalPages = (fetchedProducts.length / take).ceil();
  //     });
  //   } catch (e) {
  //     print('Error fetching products: $e');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  void _loadMoreProducts() {
    if (!isLoading && currentPage < totalPages) {
      setState(() {
        isLoading = true;
        currentPage++;
      });
      _fetchProducts();
      // _fetchProducts(skip: currentPage * itemsPerPage, take: itemsPerPage);
    } else {
      print("No more products to load");
    }
  }

  void _toggleSelectAll() {
    setState(() {
      bool areAllSelected = selectedProductIds.length == products.length;
      if (areAllSelected) {
        selectedProductIds.clear();
        isSelectAll = false;
        ref.read(counterProvider.notifier).state = products.length;
        selectedProductIds = [];
        ref.read(counterProvider.notifier).state = 0;
      } else {
        selectedProductIds = products.map((p) => p.id).toSet().toList();
        isSelectAll = selectedProductIds.length == products.length;
        ref.read(counterProvider.notifier).state = selectedProductIds.length;
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

        print("Search Product: $filteredProducts");
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

  Future<void> clearCache() async {
    if (kIsWeb) {
      print("Cache clearing is not supported on Flutter Web.");
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final tempDir = Directory(directory.path);
      if (tempDir.existsSync()) {
        print("Cache directory: ${tempDir.path}");
        tempDir.listSync().forEach((file) {
          if (file is File) {
            print(
              "Deleting file: ${file.path} (Size: ${file.lengthSync()} bytes)",
            );
            file.deleteSync();
          } else if (file is Directory) {
            print("Deleting directory: ${file.path}");
            file.deleteSync(recursive: true);
          }
        });
      } else {
        print("Cache directory does not exist.");
      }
    } catch (e) {
      print("Cache directory does not exist.$e");
    }
  }

  void _applyFilter(String filter) {
    List<Product> productsCopy = List.from(products);

    switch (filter) {
      case 'A-Z':
        productsCopy.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Z-A':
        productsCopy.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Price: High to Low':
        productsCopy.sort((a, b) => b.rate.compareTo(a.rate));
        break;
      case 'Price: Low to High':
        productsCopy.sort((a, b) => a.rate.compareTo(b.rate));
        break;
    }

    setState(() {
      filteredProducts = productsCopy;
    });
  }

  bool get isAllSelected {
    if (products.isEmpty) return false;
    return selectedProductIds.length == products.length;
  }

  Future<void> getStoredEmail() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    storedEmail = sp.getString("email");
  }

  @override
  Widget build(BuildContext context) {
    var counterValue = ref.watch(counterProvider.state).state;
    print("EMIALs:s  $storedEmail}");
    if (isLoading && products.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kachiwala'),
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool? confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Confirm Logout',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      // '$storedEmail',
                      '$storedEmail  Are you sure you want to logout?',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Cancel logout
                        },
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white, // Text color
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold, // Bold text
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(true); // Confirm logout
                        },
                        child: Text(
                          'Yes',
                          style: TextStyle(color: Colors.blue, fontSize: 16.0),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                await clearCache();
                await setLoginStatus(false);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
            tooltip: 'Logout',
          ),

          actions: [
            filteredProducts.isNotEmpty
                ? OutlinedButton(
                  onPressed: _toggleSelectAll,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 12,
                    ),
                    // Padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Rounded corners
                    ),
                    elevation: 5, // Shadow effect
                  ),
                  child: Text(
                    isAllSelected ? 'Deselect All' : 'Select All',
                    style: const TextStyle(
                      fontSize: 16, // Text size
                      fontWeight: FontWeight.bold, // Text weight
                      color: Colors.blue, // Text color
                    ),
                  ),
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
            CustomSearchBar(
              onSearchResultsUpdated: (filteredList) {
                setState(() {
                  filteredProducts = filteredList;
                });
                print("FILTER PRODUCT: $filteredProducts");
              },
              refreshProducts: () {
                setState(() {
                  filteredProducts = List.from(products);
                });
              },
              products: products,
              searchController: _searchController,
            ),
            // Shimmer loading effect
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade500,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Display product list when not loading
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF1D3557),
        title: const Text('Kachiwala', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            bool? confirmLogout = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    'Confirm Logout',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '"${storedEmail?.toUpperCase()}" ',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: 'Are you sure you want to logout?',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'YES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'NO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirmLogout == true) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              await clearCache();
              await setLoginStatus(false);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
          },
          tooltip: 'Logout',
        ),
        actions: [
          filteredProducts.isNotEmpty
              ? OutlinedButton(
                onPressed: _toggleSelectAll,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 12,
                  ),
                  // Padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  elevation: 5, // Shadow effect
                ),
                child: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    fontSize: 16, // Text size
                    fontWeight: FontWeight.bold, // Text weight
                    color: Colors.white, // Text color
                  ),
                ),
              )
              // ? OutlinedButton(
              //   onPressed: _toggleSelectAll,
              //   style: OutlinedButton.styleFrom(
              //     side: const BorderSide(color: Colors.blue),
              //   ),
              //   child: Text(isAllSelected ? 'Deselect All' : 'Selectsss All'),
              // )
              : SizedBox(),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String choice) async {
              if (choice == 'Refresh') {
                _refreshProducts();
              } else if (choice == 'Add Person') {
                SharedPreferences sp = await SharedPreferences.getInstance();
                String? storedEmail = sp.getString("email");
                String? storedPassword = sp.getString("password");

                if (storedEmail == "narayan" && storedPassword == "kachiwala") {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPersonPage()),
                  );
                  if (result == true) {
                    _refreshProducts();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Access Denied: Unauthorized User")),
                  );
                }
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh, color: Colors.blue),
                      title: Text('Refresh'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Add Person',
                    child: ListTile(
                      leading: Icon(Icons.person_add, color: Colors.green),
                      title: Text('Add New Person'),
                    ),
                  ),
                ],
          ),

          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _refreshProducts,
          // ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshProducts_RefreshIndi,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Search Bar
                  Expanded(
                    child: CustomSearchBar(
                      onSearchResultsUpdated: (filteredList) {
                        setState(() {
                          filteredProducts = filteredList;
                        });
                        print("FILTER PRODUCT: $filteredProducts");
                      },
                      refreshProducts: () {
                        setState(() {
                          filteredProducts = List.from(products);
                        });
                      },
                      products: products,
                      searchController: _searchController,
                    ),
                  ),

                  // Dropdown for Filter
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0, top: 8.0, right: 3.0),
                    child: SizedBox(
                      height: 35,
                      width: 35,
                      // decoration: BoxDecoration(
                      //   border: Border.all(color: Colors.grey, width: 1.0),
                      //   borderRadius: BorderRadius.circular(50.0),
                      //   color: Colors.white, // Background color
                      // ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 3.0),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.filter_list, color: Colors.black, size: 20),
                          padding: EdgeInsets.zero, // Removes extra padding
                          constraints: BoxConstraints(), // Prevents unnecessary expansion
                          onSelected: (String newFilter) {
                            setState(() {
                              selectedFilter = newFilter;
                            });
                            _applyFilter(newFilter);
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              'A-Z',
                              'Z-A',
                              'Price: High to Low',
                              'Price: Low to High',
                            ].map((String filter) {
                              return PopupMenuItem<String>(
                                value: filter,
                                child: Text(
                                  filter,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),

                ],
              ),

              // Product Grid View
              Expanded(
                child:
                    filteredProducts.isEmpty
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8.0,
                                crossAxisSpacing: 8.0,
                                childAspectRatio: 3 / 4,
                              ),
                          itemCount:
                              filteredProducts.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredProducts.length && isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final product = filteredProducts[index];
                            return ProductCard(
                              product: product,
                              index: index,
                              isGlobalSelected: isSelectAll,
                              isSelectAll: isSelectAll,
                              onTap: () {
                                setState(() {
                                  if (!selectedProductIds.contains(
                                    product.id,
                                  )) {
                                    selectedProductIds.add(product.id);
                                  } else {
                                    selectedProductIds.remove(product.id);
                                  }
                                });
                              },
                              updateCounter: updateCounter,
                              selectedProductIds: selectedProductIds,
                              // updateSelectedProductIds: updateSelectedProductIds,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton:
          counterValue > 0
              ? SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                animatedIconTheme: IconThemeData(size: 30.0),
                curve: Curves.easeInOut,
                onOpen: () => setState(() => isMenuOpen = true),
                onClose: () => setState(() => isMenuOpen = false),
                backgroundColor: Color(0xFF1D3557),
                foregroundColor: Colors.white,
                elevation: 10.0,
                shape: CircleBorder(),
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.share, color: Colors.white,),
                    backgroundColor: Colors.green,
                    // label: 'Share',
                    labelStyle: TextStyle(fontSize: 16.0, color: Colors.white),
                    labelBackgroundColor: Colors.green,
                    onTap: () async {
                      if (counterValue > 0) {
                        List<Product> selectedProducts =
                            filteredProducts
                                .where(
                                  (product) =>
                                      selectedProductIds.contains(product.id),
                                )
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
                    child: Icon(Icons.delete, color: Colors.white),
                    backgroundColor: Colors.red,
                    // label: 'Delete',
                    labelStyle: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    labelBackgroundColor: Colors.redAccent,
                    onTap: () async {
                      if (counterValue > 0 && selectedProductIds.isNotEmpty) {
                        bool? confirmDelete = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                'Confirm Deletion',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete the selected products?',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              backgroundColor: Colors.white,
                              actionsPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text(
                                    'Yes',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmDelete == true) {
                          try {
                            var response = await ApiService.deleteProducts(
                              selectedProductIds,
                            );
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
                    builder:
                        (_) => AddProductPage(
                          onProductAdded: _refreshProducts,
                          // isLoading: isLoading,
                        ),

                    // builder: (_) => AddProductDialog(
                    //   onProductAdded: _refreshProducts,
                    //   isLoading: isLoading,
                    // ),
                  );
                },
                backgroundColor: Color(0xFF1D3557),
                child: Icon(Icons.add, color: Colors.white,),
              ),
    );
  }
}
