import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

import 'dart:async';

class ApiService {
  // static const String _baseUrl = 'http://db.pluserp.live/api/products';
  // static const String _baseUrl_GET = 'http://103.251.16.248:5000/api/products/test';
  // static const String _baseUrl_POST = 'http://103.251.16.248:5000/api/product';

  // --- FOR MY LOCAL ----
  // static const String _baseUrl_GET = 'http://localhost:5000/api/products/test';
  // static const String _baseUrl_POST = 'http://localhost:5000/api/product';
  // static const String _baseUrl_DELETE = 'http://localhost:5000/api/delete';
  // static const String _baseUrl_User = 'http://localhost:5000/api';

  // static const String _baseUrl_GET = 'http://192.168.1.21:5000/api/products/test';
  // static const String _baseUrl_POST = 'http://192.168.1.21:5000/api/product';
  // static const String _baseUrl_DELETE = 'http://192.168.1.21:5000/api/delete';
  // static const String _baseUrl_User = 'http://103.251.16.248:5000/api';

  // ----- Server data ------
  static const String _baseUrl_GET = 'http://103.251.16.248:5000/api/products/test';
  static const String _baseUrl_POST = 'http://103.251.16.248:5000/api/product';
  static const String _baseUrl_DELETE = 'http://103.251.16.248:5000/api/delete';
  static const String _baseUrl_User = 'http://103.251.16.248:5000/api';
  static const String _baseUrl_search = 'http://103.251.16.248:5000/api/search';
  // ----- XXXXX ------

  // static const String _baseUrl_GET = 'http://192.168.42.90:5000/api/products/test';
  // static const String _baseUrl_POST = 'http://192.168.42.90:5000/api/product';
  // static const String _baseUrl_DELETE = 'http://192.168.90.246:5000/api/delete';
  // static const String _baseUrl_User = 'http://192.168.42.90:5000/api';
  // static const String _baseUrl_search = 'http://192.168.42.90:5000/api/search';

  // ?take&skip
  static Future<List<Product>> fetchProducts(String token) async {
    try {
      final url = Uri.parse('$_baseUrl_GET');

      print("Fetching all products from URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Adding the token here
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          print("No data received from API");
        }

        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        print("Error: ${response.statusCode}, Response: ${response.body}");
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>?> login(String email,String password,) async {
    try {
      final url = Uri.parse("$_baseUrl_User/login");
      print("Sending Login Request to: $url");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final responseData = jsonDecode(response.body);
      print("Response Data: $responseData");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print("Login failed: ${responseData['error']}");
        return null;
      }
    } catch (e) {
      print("Error while logging in: $e");
      return null;
    }
  }

  static Future<Response> addProduct(FormData formData, String token) async {
    Dio dio = Dio();

    try {
      final response = await dio.post(
        _baseUrl_POST,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
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

  static Future<Response> addUser(String name,String email,String password,String role,) async {
    Dio dio = Dio();

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString("token");
      if (token == null) {
        throw Exception("Authentication token not found");
      }

      String url = "$_baseUrl_User/add-user";

      Map<String, dynamic> payload = {
        "name": name,
        "email": email,
        "password": password,
        "role": role,
      };

      final response = await dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 201) {
        return response;
      } else {
        throw Exception("Failed to add user: ${response.statusCode}");
      }
    } catch (e) {
      print("Error adding user: $e");
      rethrow;
    }
  }

  //http://localhost:5000/api/users?search=shu&take=5&skip=0
  // get users api
  static Future<List<Map<String, dynamic>>> getUsers({required String search, int take = 5, int skip = 0,}) async {
    final Uri url = Uri.parse("$_baseUrl_User/users?search=$search&take=$take&skip=$skip");

    SharedPreferences pref = await SharedPreferences.getInstance();
    final token = pref.getString("token");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey("users") && responseData["users"] is List) {
          return List<Map<String, dynamic>>.from(responseData["users"]);
        } else {
          print("Invalid API response format: 'users' key missing or incorrect");
          return [];
        }
      } else {
        print("Failed to fetch users: ${response.body}");
        return [];
      }
    } catch (error) {
      print("Error fetching users: $error");
      return [];
    }
  }

  static Future<bool> deleteUser(List<int> ids, String token) async {
    final Uri url = Uri.parse("$_baseUrl_User/users/delete");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"ids": ids}),
      );

      if (response.statusCode == 200) {
        print("User(s) deleted successfully.");
        return true;
      } else {
        print("Failed to delete user(s): ${response.body}");
        return false;
      }
    } catch (error) {
      print("Error deleting user(s): $error");
      return false;
    }
  }

  // update password http://localhost:5000/api/users/{id}/password
  // payload {
  // "currentPassword":"password",
  // "newPassword":"password@123"
  // }
  // method put

  static Future<Map<String, dynamic>?> getUserId(int id, String token) async {
    final url = Uri.parse("$_baseUrl_User/users/$id");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error fetching user: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  static Future<bool> changePassword(
      int userId,
      String currentPassword,
      String newPassword,
      String token
      ) async {
    final Uri url = Uri.parse("$_baseUrl_User/users/$userId/password");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print("Password updated successfully.");
        return true;
      } else {
        print("Failed to update password: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Error updating password: $error");
      return false;
    }
  }

  static Future<bool> updateUser(int userId, String name, String email, String password) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      final response = await http.put(
        Uri.parse("$_baseUrl_User/users/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        print("User updated successfully!");
        return true;
      } else {
        print("Failed to update user: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  // http://localhost:5000/api/users?search=shu&take=5&skip=0
  static Future<List<dynamic>> getUser(
    String search,
    int take,
    int skip,
  ) async {
    final Uri url = Uri.parse(
      "$_baseUrl_User/users?search=$search&take=$take&skip=$skip",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        return users;
      } else {
        throw Exception(
          "Failed to load users. Status Code: ${response.statusCode}",
        );
      }
    } catch (error) {
      print("Error fetching users: $error");
      return [];
    }
  }

  // http://localhost:5000/api/delete/2
  static Future<Response> deleteProducts(
    List<String> productIds,
    String token,
  ) async {
    Dio dio = Dio();

    try {
      final response = await dio.delete(
        _baseUrl_DELETE,
        data: jsonEncode({'ids': productIds}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
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

// services/api_service.dart
  static Future<List<Product>> onSearchChanged(String query, List<String> filters) async {
    final List<String> sanitizedFilters = filters.contains('All') ? [] : filters;
    final String filterParam = sanitizedFilters.join(',');
    final String searchUrl =
        '$_baseUrl_search?search=${Uri.encodeQueryComponent(query)}&filters=${Uri.encodeQueryComponent(filterParam)}';

    print("Search URL: $searchUrl");

    final response = await http.get(Uri.parse(searchUrl));

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to search products: ${response.statusCode} ${response.body}');
    }
  }



  // http://localhost:5000/api/product/1 -> put
  static Future<Response> updateProduct(
    String productId,
    FormData formData,
    String token,
  ) async {
    Dio dio = Dio();

    try {
      final response = await dio.put(
        '$_baseUrl_POST/$productId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
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
