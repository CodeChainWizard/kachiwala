import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:newprg/services/product.riverPod.dart';
import 'package:newprg/services/user_provider.dart';
import 'package:newprg/widgets/AddPersonPage.dart';
import 'package:newprg/widgets/ChangePasswordPage.dart';
import 'package:newprg/widgets/CreateNewProduct.dart';
import 'package:newprg/widgets/EditProductPage.dart';
import 'package:newprg/widgets/ProductDetailScreen.dart';
import 'package:newprg/widgets/getUserDetails.dart';
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
  String? storedEmail;
  String? storedName;

  bool isMenuOpen = false;

  // --- Loading ---
  bool isLoading = false;

  // --- set the timer for API Called ---
  Timer? _debounce;

  bool getData = false;
  bool hasMore = true;
  bool hasFetchedOnce = false;

  late SharedPreferences pref;
  String selectedProductType = '';

  List<String> selectedProductIds = [];

  UniqueKey _futureBuilderKey = UniqueKey();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool isDropdownOpen = false;

  String? userRole;

  Future<void> _fetchUserRole()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    userRole = pref.getString("role");
    print("USER ROLE: $userRole");
  }

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
  int count = 0;

  String? token;

  late Future<List<Product>> _productFuture;

  @override
  void initState() {
    super.initState();
    getStoredEmail();
    // _fetchProducts();

    Future.delayed(Duration.zero, () {
      _fetchProducts();
    });

    // _productFuture = ApiService.fetchProducts();

    // Future.microtask(() => _fetchProducts());
    print("Init");
    // _fetchProducts(skip: 0, take: itemsPerPage);
    _initializePrefs();

    _scrollController.addListener(_scrollListener);
    // _requestStoragePermission(context);

    _loadFilter();
    _fetchUserRole();
  }

  void _loadFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFilter = prefs.getString('selectedFilter') ?? 'A-Z';
    });
  }

  void toggleDropdown() {
    if (isDropdownOpen) {
      _overlayEntry?.remove();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {
      isDropdownOpen = !isDropdownOpen;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);
    double width = renderBox.size.width;

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: toggleDropdown,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                left: position.dx,
                top: position.dy + renderBox.size.height + 5,
                width: width,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          [
                            'A-Z',
                            'Z-A',
                            'Price: High to Low',
                            'Price: Low to High',
                          ].map((String filter) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedFilter = filter;
                                  _applyFilter(filter);
                                });
                                toggleDropdown();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                child: Center(
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
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
                Navigator.of(context).pop();
                if (openSettings) {
                  openAppSettings();
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
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (token == null) {
        print("Error: Token is missing");
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Product> fetchedProducts = await ApiService.fetchProducts(token!);

      print("API RESPONSE: $fetchedProducts");

      if (mounted) {
        setState(() {
          products = fetchedProducts;
          filteredProducts = List.from(products);
          isLoading = false;
          hasFetchedOnce = true; // Set after loading completes
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
        hasFetchedOnce = true;
      });
    }
  }

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

          List<Product> results = await ApiService.onSearchChanged(query, selectedFilter as List<String>);

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

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");
      print("IDSsss:${selectedProductIds}");

      final response = await ApiService.deleteProducts(
        selectedProductIds,
        token!,
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete product")));
      }
    } catch (e) {
      print("Error while deletong product: $e");
    }
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
        productsCopy.sort((a, b) => a.designNo.compareTo(b.designNo));
        break;
      case 'Z-A':
        productsCopy.sort((a, b) => b.designNo.compareTo(a.designNo));
        break;
      case 'Price: High to Low':
        productsCopy.sort((a, b) => b.rate.compareTo(a.rate));
        break;
      case 'Price: Low to High':
        productsCopy.sort((a, b) => a.rate.compareTo(b.rate));
        break;
      default:
        productsCopy = List.from(products);
    }

    setState(() {
      filteredProducts = [...productsCopy]; // ✅ Assign new list reference
    });
    print("🔄 Filter applied: $filter");
    print("📌 Filtered Products Count: ${filteredProducts.length}");
  }

  bool get isAllSelected {
    if (products.isEmpty) return false;
    return selectedProductIds.length == products.length;
  }

  Future<void> getStoredEmail() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    storedEmail = sp.getString("email") ?? "No Email Found";
    storedName = sp.getString("name") ?? "No Name Found";
    token = sp.getString("token");

    print("Stored Email: ${storedEmail!}");
    print("Stored Name: ${storedName!}");
  }

  // void _navigateToEditPage(Product product) async {
  //   final updatedProduct = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EditProductPage(productData: product),
  //     ),
  //   );
  //
  //   if (updatedProduct != null) {
  //     ref.read(productProvider.notifier).updateProduct(updatedProduct);
  //     // setState(() {
  //     //   // Find and update the edited product in the list
  //     //   int index = filteredProducts.indexWhere(
  //     //         (p) => p.id == updatedProduct.id,
  //     //   );
  //     //   if (index != -1) {
  //     //     filteredProducts[index] = updatedProduct;
  //     //   }
  //     // });
  //   }
  // }

  void _updateProductList(Product updatedProduct) {
    setState(() {
      int productIndex = products.indexWhere((p) => p.id == updatedProduct.id);
      if (productIndex != -1) {
        products[productIndex] = updatedProduct;
      }

      int filteredIndex = filteredProducts.indexWhere(
        (p) => p.id == updatedProduct.id,
      );
      if (filteredIndex != -1) {
        filteredProducts[filteredIndex] = updatedProduct;
      }

      products = List.from(products);
      filteredProducts = List.from(filteredProducts);
    });
  }

  void _applyFilter_SharedPref(String newFilter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFilter', newFilter);
    setState(() {
      selectedFilter = newFilter;
    });
  }

  Future<int> getUserId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final idString = pref.getString("userId");
    print("USER ID GETTING: $idString");

    return int.tryParse(idString ?? "0") ?? 0;
  }


  @override
  Widget build(BuildContext context) {
    ref.listen(productProvider, (previous, next) {
      if (previous == null) {
        _fetchProducts();
        print("Products fetched via ref.listen");
      }
    });
    var counterValue = ref.watch(counterProvider.state).state;
    ref.listen(productProvider, (previous, next) {
      print("Product state changed!");
      setState(() {}); // Only trigger UI update
    });
    // print("PRODUCT LIST: ${productList.}");

    if (isLoading && products.isEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F2E4),
        appBar: AppBar(
          backgroundColor: Color(0xFF6F4F37),
          title: const Text('P.V. Kachiwala', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              bool? confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xFFFFFDD0),
                    title: Text(
                      'Confirm Logout',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F4E37),
                      ),
                    ),
                    content: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16.0, color: Color(0xFF6F4E37)),
                        children: <TextSpan>[
                          TextSpan(
                            text: '"${storedEmail?.toUpperCase()}" ',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'Are you sure you want to logout?',
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
                          backgroundColor: Color(0xFF6F4E37),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          'YES',
                          style: TextStyle(
                            color: Color(0xFFFFFDD0),
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                            color: Color(0xFFFFFDD0),
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
                  if (userRole == 'admin') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GetUserDetails()),
                    );
                    if (!mounted) return;
                    if (result == true) {
                      _refreshProducts();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Access Denied: Unauthorized User")),
                    );
                  }
                } else if (choice == 'Change Password') {
                  final userId = await getUserId();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangePasswordPage(userId: userId)),
                  );
                  if (!mounted) return;
                  if (result == true) {
                    _refreshProducts();
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'Refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Color(0xFF6F4E37)),
                    title: Text('Refresh'),
                  ),
                ),
                if (userRole == 'admin')
                  const PopupMenuItem<String>(
                    value: 'Add Person',
                    child: ListTile(
                      leading: Icon(Icons.person_add, color: Color(0xFF6F4E37)),
                      title: Text('Add New Person'),
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'Change Password',
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Color(0xFF6F4E37)),
                    title: Text('Change Password'),
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

        body: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.2,
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: Image.asset(
                    'assets/images/kachiwala.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            RefreshIndicator(
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
                          padding: EdgeInsets.only(
                            bottom: 8.0,
                            top: 8.0,
                            right: 3.0,
                          ),
                          child: SizedBox(
                            height: 35,
                            width: 35,
                            child: Padding(
                              padding: EdgeInsets.only(top: 3.0),
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.filter_list,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                // Removes extra padding
                                constraints: BoxConstraints(),
                                // Prevents unnecessary expansion
                                onSelected: (String newFilter) {
                                  setState(() {
                                    selectedFilter = newFilter;
                                  });
                                  _applyFilter(newFilter);
                                  _applyFilter_SharedPref(newFilter);
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
                      child: !hasFetchedOnce ? const Center(
                        child: CircularProgressIndicator(),
                      ):
                      filteredProducts.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.5,
                              child: Image.asset(
                                'assets/images/kachiwala.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 100),
                            const Text(
                              "No Products Found",
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                          : GridView.builder(
                        key: ValueKey(selectedFilter),
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
                          if (index == filteredProducts.length &&
                              isLoading) {
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
                            // onTap: () {
                            //   setState(() {
                            //     if (!selectedProductIds.contains(
                            //       product.id,
                            //     )) {
                            //       selectedProductIds.add(product.id);
                            //     } else {
                            //       selectedProductIds.remove(product.id);
                            //     }
                            //   });
                            // },
                            onTap: () async {
                              final updatedProduct = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ProductDetailScreen(
                                    product: product,
                                    // onProductUpdated: (Product newProduct) {
                                    //   _updateProductList(newProduct);
                                    // },
                                  ),
                                ),
                              );
                              // if (updatedProduct != null) {
                              //   await _refreshProducts();
                              // }
                              if (updatedProduct != null) {
                                setState(() {
                                  int index = products.indexWhere(
                                        (p) => p.id == updatedProduct.id,
                                  );
                                  if (index == -1) {
                                    products[index] = updatedProduct;
                                  }
                                });
                                print(
                                  "⬅️ Returned Updated Product: ${updatedProduct.id}",
                                );
                                ref
                                    .read(productProvider.notifier)
                                    .updateProduct(updatedProduct);
                                _refreshProducts();
                              }
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
          ]
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
                      child: Icon(Icons.share, color: Colors.white),
                      backgroundColor: Colors.green,
                      // label: 'Share',
                      labelStyle: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
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
                            await shareProduct.shareAllProducts(
                              selectedProducts,
                            );

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
                            await _deleteProduct(context);
                            await _fetchProducts();
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
                  child: Icon(Icons.add, color: Colors.white),
                ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F2E4),
      appBar: AppBar(
        backgroundColor: Color(0xFF6F4F37),
        title: const Text(
          'P.V. Kachiwala',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            bool? confirmLogout = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Color(0xFFFFFDD0),
                  title: Text(
                    'Confirm Logout',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F4E37),
                    ),
                  ),
                  content: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16.0, color: Color(0xFF6F4E37)),
                      children: <TextSpan>[
                        TextSpan(
                          text: '"${storedEmail?.toUpperCase()}" ',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Are you sure you want to logout?',
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
                        backgroundColor: Color(0xFF6F4E37),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'YES',
                        style: TextStyle(
                          color: Color(0xFFFFFDD0),
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                          color: Color(0xFFFFFDD0),
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
              side: const BorderSide(color: Color(0xFFFFFDD0)),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            child: Text(
              isAllSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
              : SizedBox(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String choice) async {
              if (choice == 'Refresh') {
                _refreshProducts();
              } else if (choice == 'Add Person') {
                await getStoredEmail();

                if (userRole == "admin") {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GetUserDetails()),
                  );

                  if (result == true) {
                    _refreshProducts();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Access Denied: Unauthorized User"),
                    ),
                  );
                }
              } else if (choice == 'Change Password') {
                final userId = await getUserId();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage(userId: userId)),
                );

                if (result == true) {
                  _refreshProducts();
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh, color: Color(0xFF6F4E37)),
                  title: Text('Refresh', style: TextStyle(color: Color(0xFF6F4E37))),
                ),
              ),
              if (userRole == 'admin')
                const PopupMenuItem<String>(
                  value: 'Add Person',
                  child: ListTile(
                    leading: Icon(Icons.person_add, color: Color(0xFF6F4E37)),
                    title: Text('Add New Person', style: TextStyle(color: Color(0xFF6F4E37))),
                  ),
                ),
              PopupMenuItem<String>(
                value: 'Change Password',
                child: FutureBuilder<int>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Change Password', style: TextStyle(color: Color(0xFF6F4E37))),
                      );
                    }
                    if (snapshot.hasError) {
                      return const ListTile(
                        leading: Icon(Icons.error, color: Color(0xFF6F4E37)),
                        title: Text('Error fetching user ID', style: TextStyle(color: Color(0xFF6F4E37))),
                      );
                    }
                    return const ListTile(
                      leading: Icon(Icons.password, color: Color(0xFF6F4E37)),
                      title: Text('Change Password', style: TextStyle(color: Color(0xFF6F4E37))),
                    );
                  },
                ),
              ),
            ],
          )


        ],
      ),


      body: Stack(
        children:[
          Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.2,
              child: SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(
                  'assets/images/kachiwala.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),


          RefreshIndicator(
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

                          child: Padding(
                            padding: EdgeInsets.only(top: 3.0),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.filter_list,
                                color: Colors.black,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              // Prevents unnecessary expansion
                              offset: Offset(0, 50),
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
                        ?  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Opacity(
                          //   opacity: 0.5,
                          //   child: Image.asset(
                          //     'assets/images/kachiwala.png',
                          //     width: 100,
                          //     height: 100,
                          //     fit: BoxFit.cover,
                          //   ),
                          // ),
                          SizedBox(height: 230),
                          const Text(
                            "No Products Found",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                        print("CLICKECD PRODUCT: $product");
                        print("CLICKECD PRODUCT: $product");
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

                          // onTap: () async {
                          //   final updatedProduct = await Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder:
                          //           (context) => ProductDetailScreen(
                          //             product: product,
                          //             // onProductUpdated: (Product newProduct) {
                          //             //   _updateProductList(newProduct);
                          //             // },
                          //           ),
                          //     ),
                          //   );
                          //   if (updatedProduct != null) {
                          //     print(
                          //       "⬅️ Returned Updated Product: ${updatedProduct.id}",
                          //     );
                          //     ref
                          //         .read(productProvider.notifier)
                          //         .updateProduct(updatedProduct);
                          //   }
                          // },

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
        ]
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
                    child: Icon(Icons.share, color: Colors.white),
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
                      _deleteProduct(context);
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
                          SharedPreferences pref =
                              await SharedPreferences.getInstance();
                          final token = pref.getString("token");
                          if (token != null) {
                            try {
                              var response = await ApiService.deleteProducts(
                                selectedProductIds,
                                token,
                              );
                              if (response.statusCode == 200) {
                                setState(() {
                                  selectedProductIds = [];
                                  counterValue = 0;
                                });
                                _refreshProducts();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('An error occurred: $e'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('access not provide')),
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
                backgroundColor: Color(0xFF6F4E37),
                child: Icon(Icons.add, color: Color(0xFFFFFDD0)),
              ),
    );
  }
}
