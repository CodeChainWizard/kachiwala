import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

import 'dart:async';

class ApiService {
  // static const String _baseUrl = 'http://db.pluserp.live/api/products';
  // static const String _baseUrl_GET = 'http://103.251.16.248:5000/api/products/test';
  // static const String _baseUrl_POST = 'http://103.251.16.248:5000/api/product';

  static const String _baseUrl_GET =
      'http://192.168.1.21:5000/api/products/test';
  static const String _baseUrl_POST = 'http://192.168.1.21:5000/api/product';

  // ?take&skip
  static Future<List<Product>> fetchProducts() async {
    try {
      final url = Uri.parse('$_baseUrl_GET');

      print("Fetching all products from URL: $url");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          print("No data received from API");
        }

        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        print("Error: ${response.statusCode}");
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw e;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$_baseUrl_GET/login");
      print("Send Login URL: ${url}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if(response.statusCode == 200){
        final responseData = jsonDecode(response.body);
        print("Response Data: $responseData");

        return responseData['success'] = true;
      }else{
        print("Login failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error while Login: $e");
      return false;
    }
  }

  // static Future<List<Product>> fetchProducts({int skip = 0, int take = 6}) async {
  //   try {
  //
  //     final url = Uri.parse('$_baseUrl_GET?skip=$skip&take=$take');
  //
  //     print("Fetching products from URL: $url");
  //
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //
  //       List<dynamic> data = jsonDecode(response.body);
  //
  //       if (data.isEmpty) {
  //         print("No data received from API");
  //       }
  //
  //       return data.map((json) => Product.fromJson(json)).toList();
  //     } else {
  //       print("Error: ${response.statusCode}");
  //       throw Exception('Failed to load products');
  //     }
  //   } catch (e) {
  //     print('Error fetching products: $e');
  //     throw e;  // Propagate error so calling code can handle it.
  //   }
  // }

  static Future<Response> addProduct(FormData formData) async {
    Dio dio = Dio();

    try {
      final response = await dio.post(
        _baseUrl_POST,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      // Log the response for debugging
      print("Response: ${response.statusCode}");

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to add product. Status Code: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  static Future<Response> deleteProducts(List<String> productIds) async {
    Dio dio = Dio();

    try {
      final response = await dio.delete(
        '$_baseUrl_POST/delete',
        data: {'productIds': productIds},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print("Response: ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete products. Status Code: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      print('Error deleting products: $e');
      rethrow;
    }
  }

  // static Future<http.Response> addProduct(Map<String, dynamic> product) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse(_baseUrl_POST),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(product),
  //     );
  //
  //     print("Response: ${response.statusCode}");
  //
  //     if (response.statusCode != 201) {
  //       final errorBody = jsonDecode(response.body);
  //       throw Exception('Failed to add product: ${errorBody['message']}');
  //     }
  //
  //     return response;
  //   } catch (e) {
  //     print('Error adding product: $e');
  //     rethrow;
  //   }
  // }

  static Future<List<Product>> onSearchChanged(String query) async {
    final String searchUrl = '$_baseUrl_GET?search=$query';

    print("Search URL: $searchUrl");

    try {
      print("Fetching products for query: $query");
      final response = await http.get(Uri.parse(searchUrl));

      print("Search Fetching Product: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("API Response: ${response.body}");
        List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          print("No products found for query: $query");
          return [];
        }

        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        print("Failed to fetch products. Status Code: ${response.statusCode}");
        throw Exception('Failed to fetch products for search query');
      }
    } catch (e) {
      print("Error during search: $e"); // Debug statement
      throw Exception('Error during search: $e');
    }
  }

  static Future<Response> updateProduct(
    String productId,
    FormData formData,
  ) async {
    Dio dio = Dio();

    try {
      final response = await dio.put(
        '$_baseUrl_POST/$productId',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print("Response: ${response.statusCode}");
      print("Response Data: ${response.data}");

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update product. Status Code: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
}

// static Future<void> addProduct(Map<String, dynamic> product) async {
//   try {
//     final response = await http.post(
//       Uri.parse(_baseUrl_POST),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(product),
//
//     );
//
//     print("Response: ${response.statusCode}");
//
//     if (response.statusCode != 201) {
//       final errorBody = jsonDecode(response.body);
//       throw Exception('Failed to add product: ${errorBody['message']}');
//     }
//   } catch (e) {
//     print('Error adding product: $e');
//     rethrow;
//   }
// }
