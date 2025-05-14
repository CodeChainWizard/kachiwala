import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// ProductNotifier manages the state of all products
class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return await fetchProducts();
  }

  /// Fetch all products from API
  Future<List<Product>> fetchProducts() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      final products = await ApiService.fetchProducts(token!);
      return products;
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  /// Update an existing product in the list
  void updateProduct(Product updatedProduct) {
    state = AsyncData([
      updatedProduct,
      ...(state.value?.where((p) => p.id != updatedProduct.id) ?? [])
    ]);
  }

  /// Add a new product
  void addProduct(Product newProduct) {
    state = AsyncData([
      ...state.value ?? [],
      newProduct,
    ]);
  }

  /// Delete a product by ID
  void deleteProduct(String productId) {
    state = AsyncData([
      ...(state.value?.where((p) => p.id != productId) ?? [])
    ]);
  }
}

/// Riverpod provider for product management
final productProvider =
AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);
