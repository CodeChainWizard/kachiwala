import 'package:flutter/material.dart';
import 'package:newprg/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(List<Product>) onSearchResultsUpdated;
  final VoidCallback refreshProducts;
  final TextEditingController searchController;
  final List<Product> products;

  CustomSearchBar({
    required this.onSearchResultsUpdated,
    required this.refreshProducts,
    required this.searchController,
    required this.products,
  });

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  List<Product> filteredProducts = [];
  bool isMenuOpen = false;

  bool isTextFieldFocused = false;

  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Type', 'Price', 'Meter', 'Color'];

  void saveFilter(String filter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFilter', filter);
  }

  Future<void> loadFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFilter = prefs.getString('selectedFilter') ?? 'All';
    });
  }

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(widget.products);

    loadFilter().then((_) {
      filterProducts(widget.searchController.text);
    });

    _focusNode.addListener(() {
      setState(() {
        isTextFieldFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Search function with filtering logic
  void filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(widget.products);
      } else {
        filteredProducts =
            widget.products.where((product) {
              String lowerQuery = query.toLowerCase();
              switch (selectedFilter) {
                case 'Type':
                  return product.type.toLowerCase().contains(lowerQuery);
                case 'Price':
                  return product.rate.toString().contains(lowerQuery);
                case 'Meter':
                  return product.meter.toString().contains(lowerQuery);
                case 'Color':
                  return product.color.toLowerCase().contains(lowerQuery);
                case 'All':
                default:
                  return product.name.toLowerCase().contains(lowerQuery) ||
                      product.type.toLowerCase().contains(lowerQuery) ||
                      product.rate.toString().contains(lowerQuery) ||
                      product.meter.toString().contains(lowerQuery) ||
                      product.color.toLowerCase().contains(lowerQuery);
              }
            }).toList();
      }
    });

    widget.onSearchResultsUpdated(filteredProducts);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          isMenuOpen = !isMenuOpen;
          isTextFieldFocused = false;
        });

      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 7.0),
        child: Column(
          children: [
            Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      selectedFilter = value;
                      saveFilter(value);
                    });
                    filterProducts(widget.searchController.text);
                  },
                  itemBuilder: (BuildContext context) {
                    return filterOptions.map((String category) {
                      return PopupMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      );
                    }).toList();
                  },
                  offset: Offset(0, 50),
                  child: Container(
                    height: 35,
                    width: 80,
                    margin: EdgeInsets.only(left: 3.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedFilter,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                // SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02,
                      vertical: MediaQuery.of(context).size.height * 0.005,
                    ),
                    child: TextField(
                      cursorHeight: 15.0,

                      controller: widget.searchController,
                      focusNode: _focusNode,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        labelText: 'Search Product',
                        labelStyle: TextStyle(color: Colors.black54),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 33,
                          horizontal: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ), // Color when not focused
                        ),
                        suffixIcon:
                            isTextFieldFocused || widget.searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    widget.refreshProducts();
                                    widget.searchController.clear();
                                    filterProducts('');
                                    _focusNode.unfocus();
                                    setState(() {
                                      isTextFieldFocused = false;
                                    });
                                  },
                                )
                                : Icon(Icons.search, color: Colors.black54),
                      ),
                      onTap: (){
                        setState(() {
                          isTextFieldFocused = true;
                        });
                      },
                      onChanged: (value) {
                        filterProducts(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:newprg/models/product.dart';
//
// class CustomSearchBar extends StatefulWidget {
//   final Function(List<Product>) onSearchResultsUpdated;
//   final VoidCallback refreshProducts;
//   final TextEditingController searchController;
//   final List<Product> products;
//
//   CustomSearchBar({
//     required this.onSearchResultsUpdated,
//     required this.refreshProducts,
//     required this.searchController,
//     required this.products,
//   });
//
//   @override
//   _CustomSearchBarState createState() => _CustomSearchBarState();
// }
//
// class _CustomSearchBarState extends State<CustomSearchBar> {
//   final FocusNode _focusNode = FocusNode();
//   List<Product> filteredProducts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     filteredProducts = List.from(widget.products);
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   // Search function
//   void filterProducts(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredProducts = List.from(widget.products);
//       } else {
//         filteredProducts =
//             widget.products
//                 .where(
//                   (product) =>
//                       product.name.toLowerCase().contains(
//                         query.toLowerCase(),
//                       ) ||
//                       product.packing.toLowerCase().contains(
//                         query.toLowerCase(),
//                       ) ||
//                       product.type.toLowerCase().contains(
//                         query.toLowerCase(),
//                       ) ||
//                       product.rate.toString().contains(query.toLowerCase()),
//                 )
//                 .toList();
//       }
//     });
//
//     // Send filtered list back to parent widget
//     widget.onSearchResultsUpdated(filteredProducts);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(5.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: widget.searchController,
//               focusNode: _focusNode,
//               decoration: InputDecoration(
//                 labelText: 'Search Product',
//                 border: OutlineInputBorder(),
//                 suffixIcon:
//                     widget.searchController.text.isNotEmpty
//                         ? IconButton(
//                           icon: Icon(Icons.clear),
//                           onPressed: () {
//                             widget.refreshProducts();
//                             widget.searchController.clear();
//                             filterProducts('');
//                             FocusScope.of(context).unfocus();
//                           },
//                         )
//                         : Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 filterProducts(value);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:newprg/models/product.dart';
//
// class CustomSearchBar extends StatefulWidget {
//   final Function(List<Product>) onSearchResultsUpdated;
//   final VoidCallback refreshProducts;
//   final TextEditingController searchController;
//   final List<Product> products;
//
//   CustomSearchBar({
//     required this.onSearchResultsUpdated,
//     required this.refreshProducts,
//     required this.searchController,
//     required this.products,
//   });
//
//   @override
//   _CustomSearchBarState createState() => _CustomSearchBarState();
// }
//
// class _CustomSearchBarState extends State<CustomSearchBar> {
//   FocusNode _focusNode = FocusNode();
//   List<Product> filteredProducts = [];
//
//   // Dropdown values
//   String selectedFilter = 'All';
//   final List<String> filterOptions = ['All', 'Type', 'Price', 'Meter', 'Color'];
//   OverlayEntry? _overlayEntry;
//   final LayerLink _layerLink = LayerLink();
//   bool isDropdownOpen = false;
//
//   void toggleDropdown() {
//     if (isDropdownOpen) {
//       _overlayEntry?.remove();
//       _overlayEntry = null;
//     } else {
//       _overlayEntry = _createOverlayEntry();
//       Overlay.of(context).insert(_overlayEntry!);
//     }
//     setState(() {
//       isDropdownOpen = !isDropdownOpen;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     filteredProducts = List.from(widget.products);
//
//     _focusNode = FocusNode();
//
//     _focusNode.addListener(() {
//       if (_focusNode.hasFocus && isDropdownOpen) {
//         toggleDropdown();
//       }
//     });
//
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   OverlayEntry _createOverlayEntry() {
//     RenderBox renderBox = context.findRenderObject() as RenderBox;
//     Offset position = renderBox.localToGlobal(Offset.zero);
//     double screenWidth = MediaQuery.of(context).size.width;
//
//     // Adjust width to be responsive
//     double dropdownWidth = renderBox.size.width * 1.2;
//     dropdownWidth = dropdownWidth > screenWidth * 0.3 ? screenWidth * 0.3 : dropdownWidth;
//
//     // Dynamically position dropdown below the button
//     double dropdownTop = position.dy + renderBox.size.height + 5; // 5px gap below button
//
//     return OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: () {
//               toggleDropdown(); // Closes dropdown when clicking outside
//             },
//             child: Container(
//               width: double.infinity,
//               height: double.infinity,
//               color: Colors.transparent,
//             ),
//           ),
//
//           // Positioned dropdown menu
//           Positioned(
//             left: position.dx,
//             top: dropdownTop, // Dynamic top position
//             width: dropdownWidth,
//             child: Material(
//               elevation: 4,
//               borderRadius: BorderRadius.circular(12),
//               color: Colors.white,
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: filterOptions.map((String category) {
//                     return InkWell(
//                       onTap: () {
//                         setState(() {
//                           selectedFilter = category;
//                         });
//
//                         filterProducts(category); // Perform your operation
//                         toggleDropdown(); // Close dropdown after selection
//                       },
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(
//                           vertical: 10,
//                           horizontal: 8,
//                         ),
//                         child: Center(
//                           child: Text(
//                             category,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void filterProducts(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredProducts = List.from(widget.products);
//       } else {
//         filteredProducts =
//             widget.products.where((product) {
//               String lowerQuery = query.toLowerCase();
//               switch (selectedFilter) {
//                 case 'Type':
//                   return product.type.toLowerCase().contains(lowerQuery);
//                 case 'Price':
//                   return product.rate.toString().contains(lowerQuery);
//                 case 'Meter':
//                   return product.meter.toString().contains(lowerQuery);
//                 case 'Color':
//                   return product.color.toLowerCase().contains(lowerQuery);
//                 case 'All':
//                 default:
//                   return product.name.toLowerCase().contains(lowerQuery) ||
//                       product.type.toLowerCase().contains(lowerQuery) ||
//                       product.rate.toString().contains(lowerQuery) ||
//                       product.meter.toString().contains(lowerQuery) ||
//                       product.color.toLowerCase().contains(lowerQuery);
//               }
//             }).toList();
//       }
//     });
//
//     widget.onSearchResultsUpdated(filteredProducts);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8.0, top: 7.0),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 CompositedTransformTarget(
//                   link: _layerLink,
//                   child: GestureDetector(
//                     onTap: toggleDropdown,
//                     child: Container(
//                       height: 35,
//                       width: 100,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(50),
//                         color: Colors.white,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             selectedFilter,
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 14,
//                             ),
//                           ),
//                           SizedBox(width: 5),
//                           isDropdownOpen
//                               ? Icon(Icons.arrow_drop_up, color: Colors.grey)
//                               : Icon(Icons.arrow_drop_down, color: Colors.grey),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(width: 5),
//
//                 Expanded(
//                   child: Container(
//                     height: 45,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: MediaQuery.of(context).size.width * 0.02,
//                       vertical: MediaQuery.of(context).size.height * 0.005,
//                     ),
//                     child: TextField(
//                       cursorHeight: 15.0,
//                       controller: widget.searchController,
//                       focusNode: _focusNode,
//                       textAlignVertical: TextAlignVertical.center,
//                       decoration: InputDecoration(
//                         labelText: 'Search Product',
//                         labelStyle: TextStyle(color: Colors.black54),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 15,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(50.0),
//                           borderSide: BorderSide(color: Colors.grey),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(50.0),
//                           borderSide: BorderSide(
//                             color: Colors.grey,
//                           ), // Color when not focused
//                         ),
//                         suffixIcon:
//                             widget.searchController.text.isNotEmpty
//                                 ? IconButton(
//                                   icon: Icon(Icons.clear),
//                                   onPressed: () {
//                                     widget.refreshProducts();
//                                     widget.searchController.clear();
//                                     FocusScope.of(context).unfocus();
//                                   },
//                                 )
//                                 : Icon(Icons.search, color: Colors.black54),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           // Handle filtering if needed
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   return GestureDetector(
//   //     behavior: HitTestBehavior.translucent,
//   //     onTap: () {
//   //       FocusScope.of(context).unfocus();
//   //     },
//   //     child: Padding(
//   //       padding: const EdgeInsets.only(bottom: 8.0, top: 7.0),
//   //       child: Column(
//   //         children: [
//   //           Row(
//   //             children: [
//   //               Container(
//   //                 height: 35,
//   //                 width: 80,
//   //                 decoration: BoxDecoration(
//   //                   border: Border.all(color: Colors.grey),
//   //                   borderRadius: BorderRadius.circular(50),
//   //                   color: Colors.white, // Optional: Add a background color
//   //                 ),
//   //                 child: DropdownButtonHideUnderline(
//   //                   child: DropdownButton<String>(
//   //                     value: selectedFilter,
//   //                     alignment: Alignment.center,
//   //                     style: TextStyle(color: Colors.black54, fontSize: 14),
//   //                     menuMaxHeight: 300, // Limit dropdown height to avoid overflow
//   //                     padding: EdgeInsets.symmetric(horizontal: 8), // Better spacing inside dropdown
//   //                     borderRadius: BorderRadius.circular(12), // Rounded corners for dropdown list
//   //                     icon: Icon(Icons.arrow_drop_down, color: Colors.grey), // Custom dropdown icon
//   //                     dropdownColor: Colors.white, // Background color for dropdown
//   //                     items: filterOptions.map((String category) {
//   //                       return DropdownMenuItem<String>(
//   //                         value: category,
//   //                         child: Center(
//   //                           child: Text(
//   //                             category,
//   //                             textAlign: TextAlign.center,
//   //                             style: TextStyle(fontSize: 14, color: Colors.black),
//   //                           ),
//   //                         ),
//   //                       );
//   //                     }).toList(),
//   //                     onChanged: (newValue) {
//   //                       setState(() {
//   //                         selectedFilter = newValue!;
//   //                         filterProducts(widget.searchController.text);
//   //                       });
//   //                     },
//   //                   ),
//   //                 ),
//   //               ),
//   //
//   //               // Container(
//   //               //   height: 35,
//   //               //   width: 80,
//   //               //   // margin: EdgeInsets.only(left: 3.0),
//   //               //   decoration: BoxDecoration(
//   //               //     border: Border.all(color: Colors.grey),
//   //               //     borderRadius: BorderRadius.circular(50),
//   //               //   ),
//   //               //   child: DropdownButton<String>(
//   //               //     value: selectedFilter,
//   //               //     // isDense: true,
//   //               //     alignment: Alignment.center,
//   //               //     style: TextStyle(color: Colors.black54, fontSize: 16),
//   //               //     menuMaxHeight: 3000,
//   //               //     underline: SizedBox(),
//   //               //     items:
//   //               //         filterOptions.map((String category) {
//   //               //           return DropdownMenuItem<String>(
//   //               //             value: category,
//   //               //             child: Center(
//   //               //               child: Padding(
//   //               //                 padding: EdgeInsets.only(left: 1.0),
//   //               //                 child: Text(
//   //               //                   category,
//   //               //                   textAlign: TextAlign.center,
//   //               //                 ),
//   //               //               ),
//   //               //             ),
//   //               //           );
//   //               //         }).toList(),
//   //               //     onChanged: (newValue) {
//   //               //       setState(() {
//   //               //         selectedFilter = newValue!;
//   //               //         filterProducts(widget.searchController.text);
//   //               //       });
//   //               //     },
//   //               //   ),
//   //               // ),
//   //
//   //               // SizedBox(width: 5),
//   //
//   //               Expanded(
//   //                 child: Container(
//   //                   height: 45,
//   //                   padding: EdgeInsets.symmetric(
//   //                     horizontal: MediaQuery.of(context).size.width * 0.02,
//   //                     vertical: MediaQuery.of(context).size.height * 0.005,
//   //                   ),
//   //                   child: TextField(
//   //                     cursorHeight: 15.0,
//   //
//   //                     controller: widget.searchController,
//   //                     focusNode: _focusNode,
//   //                     textAlignVertical: TextAlignVertical.center,
//   //                     decoration: InputDecoration(
//   //                       labelText: 'Search Product',
//   //                       labelStyle: TextStyle(color: Colors.black54),
//   //                       contentPadding: EdgeInsets.symmetric(
//   //                         vertical: 33,
//   //                         horizontal: 15,
//   //                       ),
//   //                       border: OutlineInputBorder(
//   //                         borderRadius: BorderRadius.circular(50.0),
//   //                         borderSide: BorderSide(color: Colors.grey),
//   //                       ),
//   //                       enabledBorder: OutlineInputBorder(
//   //                         borderRadius: BorderRadius.circular(50.0),
//   //                         borderSide: BorderSide(
//   //                           color: Colors.grey,
//   //                         ), // Color when not focused
//   //                       ),
//   //                       suffixIcon:
//   //                           widget.searchController.text.isNotEmpty
//   //                               ? IconButton(
//   //                                 icon: Icon(Icons.clear),
//   //                                 onPressed: () {
//   //                                   widget.refreshProducts();
//   //                                   widget.searchController.clear();
//   //                                   filterProducts('');
//   //                                   FocusScope.of(context).unfocus();
//   //                                 },
//   //                               )
//   //                               : Icon(Icons.search, color: Colors.black54),
//   //                     ),
//   //                     onChanged: (value) {
//   //                       filterProducts(value);
//   //                     },
//   //                   ),
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
// }
//
// // import 'package:flutter/material.dart';
// // import 'package:newprg/models/product.dart';
// //
// // class CustomSearchBar extends StatefulWidget {
// //   final Function(List<Product>) onSearchResultsUpdated;
// //   final VoidCallback refreshProducts;
// //   final TextEditingController searchController;
// //   final List<Product> products;
// //
// //   CustomSearchBar({
// //     required this.onSearchResultsUpdated,
// //     required this.refreshProducts,
// //     required this.searchController,
// //     required this.products,
// //   });
// //
// //   @override
// //   _CustomSearchBarState createState() => _CustomSearchBarState();
// // }
// //
// // class _CustomSearchBarState extends State<CustomSearchBar> {
// //   final FocusNode _focusNode = FocusNode();
// //   List<Product> filteredProducts = [];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     filteredProducts = List.from(widget.products);
// //   }
// //
// //   @override
// //   void dispose() {
// //     _focusNode.dispose();
// //     super.dispose();
// //   }
// //
// //   // Search function
// //   void filterProducts(String query) {
// //     setState(() {
// //       if (query.isEmpty) {
// //         filteredProducts = List.from(widget.products);
// //       } else {
// //         filteredProducts =
// //             widget.products
// //                 .where(
// //                   (product) =>
// //                       product.name.toLowerCase().contains(
// //                         query.toLowerCase(),
// //                       ) ||
// //                       product.packing.toLowerCase().contains(
// //                         query.toLowerCase(),
// //                       ) ||
// //                       product.type.toLowerCase().contains(
// //                         query.toLowerCase(),
// //                       ) ||
// //                       product.rate.toString().contains(query.toLowerCase()),
// //                 )
// //                 .toList();
// //       }
// //     });
// //
// //     // Send filtered list back to parent widget
// //     widget.onSearchResultsUpdated(filteredProducts);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       behavior: HitTestBehavior.translucent,
// //       onTap: () {
// //         FocusScope.of(context).unfocus();
// //       },
// //       child: Padding(
// //         padding: const EdgeInsets.all(5.0),
// //         child: Column(
// //           children: [
// //             TextField(
// //               controller: widget.searchController,
// //               focusNode: _focusNode,
// //               decoration: InputDecoration(
// //                 labelText: 'Search Product',
// //                 border: OutlineInputBorder(),
// //                 suffixIcon:
// //                     widget.searchController.text.isNotEmpty
// //                         ? IconButton(
// //                           icon: Icon(Icons.clear),
// //                           onPressed: () {
// //                             widget.refreshProducts();
// //                             widget.searchController.clear();
// //                             filterProducts('');
// //                             FocusScope.of(context).unfocus();
// //                           },
// //                         )
// //                         : Icon(Icons.search),
// //               ),
// //               onChanged: (value) {
// //                 filterProducts(value);
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
