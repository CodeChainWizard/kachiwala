import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:newprg/models/product.dart';
import 'package:newprg/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final Product productData;
  final VoidCallback refreshProducts;

  const EditProductPage({
    Key? key,
    required this.productData,
    required this.refreshProducts,
  }) : super(key: key);

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
    FocusScope.of(context).unfocus();

    var status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 100,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          final imageBytes = await pickedFile.readAsBytes();
          final compressedImage = await _compressImage(imageBytes);
          if (compressedImage != null) {
            setState(() {
              newImages.add(compressedImage);
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting images: $e")),
      );
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
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");
      final personName = pref.getString("name");

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
        "existingImages": imageUrls,
        "images": multipartImages,
        "person": personName!,
      });

      if (token != null) {
        var response = await ApiService.updateProduct(
          widget.productData.id.toString(),
          formData,
          token,
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
            imagePaths: [
              ...imageUrls,
              ...newImages.map((_) => 'new_image_url'),
            ],

            person: personName,
          );

          Navigator.pop(context, updatedProduct);
          widget.refreshProducts();
        } else {
          _showDialog('Error', 'Update failed. Please try again.');
        }
      } else {
        _showDialog('Error', 'Access not provided');
      }
    } catch (e) {
      _showDialog('Error', 'Error updating product: $e');
    } finally {
      setState(() => isLoading = false);
      widget.refreshProducts();
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

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text('Discard Changes?'),
        content: Text('Are you sure you want to exit without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit'),
          ),
        ],
      ),
    )) ??
        false;
  }

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF432B1A)
          ),
        ),
        const SizedBox(height: 8),
        Text(
          newImages.isEmpty && imageUrls.isEmpty
              ? 'At least one image is required'
              : '${newImages.length + imageUrls.length} image(s) selected',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        newImages.isEmpty && imageUrls.isEmpty
            ? SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('SELECT IMAGES'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: ui.Color(0xFF1D3557)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: newImages.length + imageUrls.length,
          itemBuilder: (context, index) {
            if (index < newImages.length) {
              return _buildImageThumbnail(index, isNewImage: true);
            } else {
              return _buildImageThumbnail(index - newImages.length, isNewImage: false);
            }
          },
        ),
        if (newImages.isNotEmpty || imageUrls.isNotEmpty)
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
    );
  }

  Widget _buildImageThumbnail(int index, {required bool isNewImage}) {
    return GestureDetector(
      onTap: () => _showImageOptions(index, isNewImage: isNewImage),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isNewImage
                ? Image.memory(
              newImages[index],
              fit: BoxFit.cover,
            )
                : FutureBuilder<Uint8List?>(
              future: _fetchImageFromUrl(imageUrls[index]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showImageOptions(index, isNewImage: isNewImage),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isNewImage) {
                    newImages.removeAt(index);
                  } else {
                    imageUrls.removeAt(index);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[600],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(int index, {required bool isNewImage}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.zoom_out_map),
                title: const Text('View Full Image'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: isNewImage
                            ? Image.memory(
                          newImages[index],
                          fit: BoxFit.contain,
                        )
                            : FutureBuilder<Uint8List?>(
                          future: _fetchImageFromUrl(imageUrls[index]),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return CircularProgressIndicator();
                            }
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F2E4),
        appBar: AppBar(
          title: Text(
            "Edit Product",
            style: TextStyle(
              color: Color(0xFFFFFDD0),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF6F4E37),
          iconTheme: IconThemeData(color: Color(0xFFFFFDD0)),
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
              _buildImageSelectionSection(),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                )
                    : Text(
                  "Update Product",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
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

      child: TextFormField(
        textCapitalization: TextCapitalization.none,
        controller: controller,
          inputFormatters: isNumeric
              ? [] // no formatter for numbers
              : [UpperCaseTextFormatter()],
        keyboardType:
        isNumeric
            ? TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF432B1A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF3EBCB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF432B1A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
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
      backgroundColor: Color(0xFFF5F2E4),
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}