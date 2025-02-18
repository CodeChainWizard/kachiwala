// import 'package:flutter/material.dart';
//
// class CustomSearchBar extends StatefulWidget {
//   final Function(String) onSearchChanged;
//
//   CustomSearchBar({required this.onSearchChanged, required });
//
//   @override
//   _CustomSearchBarState createState() => _CustomSearchBarState();
// }
//
// class _CustomSearchBarState extends State<CustomSearchBar> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller.addListener(() {
//       setState(() {});
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//     _focusNode.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTap: (){
//         FocusScope.of(context).requestFocus(FocusNode());
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: TextField(
//           controller: _controller,
//           focusNode: _focusNode,
//           decoration: InputDecoration(
//             labelText: 'Search Product',
//             border: OutlineInputBorder(),
//             suffixIcon: _controller.text.isNotEmpty
//                 ? IconButton(
//               icon: Icon(Icons.clear),
//               onPressed: () {
//                 _controller.clear();
//                 FocusScope.of(context).requestFocus(FocusNode());
//                 widget.onSearchChanged('');
//               },
//             )
//                 : Icon(Icons.search),
//           ),
//           onChanged: (value) {
//             widget.onSearchChanged(value);
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback refreshProducts;
  final TextEditingController searchController;

  CustomSearchBar({
    required this.onSearchChanged,
    required this.refreshProducts,
    required this.searchController,
  });

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  String selectedFilter = 'A-Z';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            TextField(
              controller: widget.searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Search Product',
                border: OutlineInputBorder(),
                suffixIcon:
                    widget.searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            widget.refreshProducts();
                            widget.searchController.clear();
                            FocusScope.of(context).requestFocus(FocusNode());
                            widget.onSearchChanged('');
                          },
                        )
                        : Icon(Icons.search),
              ),
              onChanged: (value) {
                // Call the onSearchChanged function with the current value
                widget.onSearchChanged(value);

                // Print the current value of the search input
                print("Inside a Search Bar Pagesss: $value");
              },
            ),
            // TextField(
            //   controller: widget.searchController,
            //   focusNode: _focusNode,
            //   decoration: InputDecoration(
            //     labelText: 'Search Product',
            //     border: OutlineInputBorder(),
            //     suffixIcon: widget.searchController.text.isNotEmpty
            //         ? IconButton(
            //       icon: Icon(Icons.clear),
            //       onPressed: () {
            //         widget.refreshProducts();
            //         widget.searchController.clear();
            //         FocusScope.of(context).requestFocus(FocusNode());
            //       },
            //     )
            //         : Icon(Icons.search),
            //   ),
            //   onChanged: (value) {
            //     widget.onSearchChanged(value);
            //     print("Inside a Search Bar Pagess: ${widget.onSearchChanged}");
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
