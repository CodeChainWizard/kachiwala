import 'package:flutter/material.dart';
import 'package:newprg/models/product.dart';

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

  // Dropdown values
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Type', 'Price', 'Meter', 'Color'];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(widget.products);
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
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 7.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 35,
                  width: 80,
                  margin: EdgeInsets.only(left: 3.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    // isDense: true,
                    alignment: Alignment.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                    underline: SizedBox(),
                    items:
                        filterOptions.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(left: 9.0),
                                child: Text(
                                  category,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        filterProducts(widget.searchController.text);
                      });
                    },
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
                            widget.searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    widget.refreshProducts();
                                    widget.searchController.clear();
                                    filterProducts('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                                : Icon(Icons.search, color: Colors.black54),
                      ),
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
