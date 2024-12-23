import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
// import 'package:newprg//models/product.dart' as model;
import 'package:newprg/models/product.dart' as model;

import 'api_service.dart';

final productProvider = FutureProvider<List<model.Product>>((ref) async {
  try {
    final fetchedProducts = await ApiService.fetchProducts();

    // Ensure fetchedProducts is a list and print the list of Product objects
    if (fetchedProducts is List) {
      // Print each product using the overridden toString method
      fetchedProducts.forEach((product) {
        print("Product details: ${product.type}"); // This will print the details of each product
      });

      // Map the list of maps to Product objects
      return fetchedProducts
          .map((product) => model.Product.fromJson(product as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Fetched data is not a list.");
    }
  } catch (error) {
    print("Error fetching products: $error");
    throw error; // Re-throw the error to handle it in the UI
  }
});

