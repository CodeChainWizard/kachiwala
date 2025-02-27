import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:newprg/models/product.dart';
import 'package:newprg/services/api_service.dart';

class EditProductPage extends StatefulWidget {
  final Product productData;

  const EditProductPage({Key? key, required this.productData})
    : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController nameController;
  late TextEditingController designNoController;
  late TextEditingController meterController;
  late TextEditingController sizeController;
  late TextEditingController priceController;
  late TextEditingController typeController;
  late TextEditingController packingController;
  late TextEditingController colorController;

  bool isLoading = false;
  List<String> imageUrls = [];
  List<Uint8List> newImages = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingImages();
  }

  void _initializeControllers() {
    nameController = TextEditingController(text: widget.productData.name);
    designNoController = TextEditingController(
      text: widget.productData.designNo,
    );
    meterController = TextEditingController(text: widget.productData.meter);
    sizeController = TextEditingController(text: widget.productData.size);
    priceController = TextEditingController(
      text: widget.productData.rate.toString(),
    );
    typeController = TextEditingController(text: widget.productData.type);
    packingController = TextEditingController(text: widget.productData.packing);
    colorController = TextEditingController(text: widget.productData.color);
  }

  void _loadExistingImages() {
    if (widget.productData.imagePaths != null &&
        widget.productData.imagePaths!.isNotEmpty) {
      setState(() {
        imageUrls = List.from(widget.productData.imagePaths!);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        final compressedImage = await _compressImage(imageBytes);
        if (compressedImage != null) {
          setState(() {
            newImages.add(compressedImage);
          });
        }
      }
    } catch (e) {
      _showDialog('Error', 'Failed to select image: $e');
    }
  }

  Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) return null;

    try {
      return await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 300,
        minHeight: 300,
        quality: 20,
      );
    } catch (e) {
      print("Error during image compression: $e");
      return null;
    }
  }

  Future<void> _updateProduct() async {
    if (nameController.text.isEmpty ||
        (imageUrls.isEmpty && newImages.isEmpty)) {
      _showDialog(
        'Error',
        'Please fill in all fields and select at least one image.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<MultipartFile> multipartImages =
          newImages.map((image) {
            return MultipartFile.fromBytes(image, filename: 'image.jpg');
          }).toList();

      FormData formData = FormData.fromMap({
        "id": widget.productData.id,
        "name": nameController.text,
        "designNo": designNoController.text,
        "meter": meterController.text,
        "size": sizeController.text,
        "rate": priceController.text,
        "type": typeController.text,
        "color": colorController.text,
        "packing": packingController.text,
        "images": multipartImages,
        "existingImages": imageUrls,
      });

      var response = await ApiService.updateProduct(
        widget.productData.id.toString(),
        formData,
      );
      if (response.statusCode == 200) {
        Product updatedProduct = Product(
          id: widget.productData.id,
          name: nameController.text,
          designNo: designNoController.text,
          meter: meterController.text,
          size: sizeController.text,
          rate: int.parse(priceController.text),
          type: typeController.text,
          color: colorController.text,
          packing: packingController.text,
          code: "",
          description: '',
          imagePaths: [...imageUrls, ...newImages.map((_) => 'new_image_url')],
        );

        Navigator.pop(context, updatedProduct); // ✅ Return updated product
      } else {
        _showDialog('Error', 'Update failed. Please try again.');
      }
    } catch (e) {
      _showDialog('Error', 'Error updating product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Uint8List?> _fetchImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
    return null;
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1D3557),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(nameController, "Name"),
            _buildTextField(designNoController, "Design No"),
            _buildTextField(meterController, "Meter", isNumeric: true),
            _buildTextField(sizeController, "Size"),
            _buildTextField(priceController, "Price", isNumeric: true),
            _buildTextField(typeController, "Type"),
            _buildTextField(colorController, "Color"),
            _buildTextField(packingController, "Packing"),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: newImages.isNotEmpty ? null : _pickImage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Color(0xFF1D3557),
                ),
                child: Text(
                  'Select Image',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ...imageUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return FutureBuilder<Uint8List?>(
                    future: _fetchImageFromUrl(url),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      return _buildImageWidget(snapshot.data!, index, url);
                    },
                  );
                }).toList(),

                ...newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return _buildImageWidget(image, index, '');
                }).toList(),

                if (imageUrls.isNotEmpty || newImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 22.0),
                    child: Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.05,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _updateProduct,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Color(0xFF1D3557),
              ),
              child:
                  isLoading
                      ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                      : Text(
                        "Update Product",
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType:
            isNumeric
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Uint8List image, int index, String url) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) =>
                      Dialog(child: Image.memory(image, fit: BoxFit.contain)),
            );
          },
          child: Image.memory(
            image,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (url.isNotEmpty) {
                  imageUrls.removeAt(index);
                } else {
                  newImages.removeAt(index);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CropScreen(
                        image: image,
                        index: index,
                        originalUrl: url,
                      ),
                ),
              );
              if (result != null) {
                final Uint8List? croppedImage = result['croppedImage'];
                final int updatedIndex = result['index'];

                if (croppedImage != null) {
                  setState(() {
                    if (url.isNotEmpty) {
                      imageUrls.removeAt(index);
                    } else {
                      newImages.removeAt(index);
                    }
                    newImages.add(croppedImage);
                  });
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.crop, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class CropScreen extends StatefulWidget {
  final Uint8List image;
  final int index;
  final String originalUrl;

  const CropScreen({
    Key? key,
    required this.image,
    required this.index,
    required this.originalUrl,
  }) : super(key: key);

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final controller = CropController();

  Future<Uint8List> _getCroppedImageBytes() async {
    final ui.Image? croppedUiImage = await controller.croppedBitmap();
    if (croppedUiImage == null) {
      throw Exception('Failed to retrieve cropped image.');
    }

    final ByteData? byteData = await croppedUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to process cropped image.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _handleImageCrop(BuildContext context) async {
    try {
      final Uint8List croppedImageBytes = await _getCroppedImageBytes();

      final Uint8List? compressedImage =
          await FlutterImageCompress.compressWithList(
            croppedImageBytes,
            minWidth: 300,
            minHeight: 300,
            quality: 20,
          );

      if (compressedImage == null || compressedImage.isEmpty) {
        throw Exception('Failed to compress cropped image');
      }

      Navigator.pop(context, {
        'croppedImage': compressedImage,
        'index': widget.index,
        'originalUrl': widget.originalUrl,
      });
    } catch (e) {
      print("Error cropping image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to crop image: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crop Image"),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () => _handleImageCrop(context),
          ),
        ],
      ),
      body: CropImage(
        controller: controller,
        image: Image.memory(widget.image),
      ),
    );
  }
}
