import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;

  CustomSearchBar({required this.onSearchChanged, required });

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search Product',
            border: OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                FocusScope.of(context).requestFocus(FocusNode());
                widget.onSearchChanged('');
              },
            )
                : Icon(Icons.search),
          ),
          onChanged: (value) {
            widget.onSearchChanged(value);
          },
        ),
      ),
    );
  }
}
