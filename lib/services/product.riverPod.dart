import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'api_service.dart'; // Import your API service

class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]);

  // Future<void> fetchProducts() async {
  //   try {
  //     final token
  //     final fetchedProducts = await ApiService.fetchProducts();
  //     state = fetchedProducts; // Updates UI automatically
  //     print("UI UPADTE: $state");
  //   } catch (e) {
  //     print('Error fetching products: $e');
  //   }
  // }

  void addProduct(Product newProduct) {
    state = [...state, newProduct];
  }

  void removeProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void updateProduct(Product updatedProduct) {
    state = state.map((product) {
      if (product.id == updatedProduct.id) {
        debugPrint("🔄 Updating product: ${updatedProduct.id}, New Name: ${updatedProduct.name}");
        return updatedProduct;
      }
      return product;
    }).toList();

    // Check if the product was actually updated
    bool productFound = state.any((product) => product.id == updatedProduct.id);

    if (!productFound) {
      debugPrint("❌ Product ID not found in list!");
    }

    debugPrint("✅ Updated product list: ${state.map((p) => p.toJson()).toList()}");
  }


}

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>(
      (ref) => ProductNotifier(),
);
