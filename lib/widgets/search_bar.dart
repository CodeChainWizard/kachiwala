import 'package:flutter/material.dart';
import 'package:newprg/models/product.dart';
import 'package:newprg/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(List<Product>) onSearchResultsUpdated;
  final VoidCallback refreshProducts;
  final TextEditingController searchController;
  final List<Product> products;

  const CustomSearchBar({
    super.key,
    required this.onSearchResultsUpdated,
    required this.refreshProducts,
    required this.searchController,
    required this.products,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final List<String> filterOptions = ['All', 'Type', 'Price', 'Meter', 'Color'];

  List<Product> filteredProducts = [];
  List<String> selectedFilters = ['All'];
  bool isTextFieldFocused = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(widget.products);
    _loadFilters().then((_) {
      _filterProducts(widget.searchController.text);
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

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('selectedFilters');
    setState(() {
      selectedFilters = stored ?? ['All'];
    });
  }

  Future<void> _saveFilters(List<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedFilters', filters);
  }

  Future<void> _filterProducts(String query) async {
    setState(() => isLoading = true);

    if (query.isEmpty) {
      setState(() {
        filteredProducts = List.from(widget.products);
        isLoading = false;
      });
      widget.onSearchResultsUpdated(filteredProducts);
      return;
    }

    try {
      final results = await ApiService.onSearchChanged(query, selectedFilters);
      debugPrint('Filtered products IMAGES: ${results.map((p) => p.imagePaths).toList()}');

      setState(() {
        filteredProducts = results;
        isLoading = false;
      });
      widget.onSearchResultsUpdated(filteredProducts);
    } catch (e) {
      setState(() {
        filteredProducts = [];
        isLoading = false;
      });
      widget.onSearchResultsUpdated([]);
    }
  }

  Future<void> _showFilterDialog() async {
    List<String> tempSelected = List.from(selectedFilters);

    final List<String>? newSelected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ...filterOptions.map((option) {
                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(option),
                      value: tempSelected.contains(option),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            if (option == 'All') {
                              tempSelected = ['All'];
                            } else {
                              tempSelected.remove('All');
                              tempSelected.add(option);
                            }
                          } else {
                            tempSelected.remove(option);
                            if (tempSelected.isEmpty) tempSelected = ['All'];
                          }
                        });
                      },
                      activeColor: const Color(0xFF6F4E37),
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F4E37))),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempSelected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Apply', style: TextStyle(color: Color(0xFFFFFDD0)),),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newSelected != null) {
      setState(() => selectedFilters = newSelected);
      await _saveFilters(selectedFilters);
      _filterProducts(widget.searchController.text);
    }
  }


  @override
  Widget build(BuildContext context) {
    print("ALL PRODUCT GET FROM THE SEARCH: ${widget.products}");
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
      child: Row(
        children: [
          // Filter Dropdown
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              height: 35,
              width: 100,
              margin: const EdgeInsets.only(left: 5.0),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6F4E37)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedFilters.length == filterOptions.length || selectedFilters.contains('All')
                          ? 'All'
                          : selectedFilters.join(', '),
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),

          // Search Field
          Expanded(
            child: Container(
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: widget.searchController,
                focusNode: _focusNode,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  labelText: 'Search Product',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color(0xFF6F4E37)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color(0xFF6F4E37)),
                  ),
                  suffixIcon: isTextFieldFocused || widget.searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.searchController.clear();
                      _focusNode.unfocus();
                      widget.refreshProducts();
                      _filterProducts('');
                    },
                  )
                      : const Icon(Icons.search, color: Colors.black54),
                ),
                onChanged: _filterProducts,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
