import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductApiException implements Exception {
  const ProductApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductApi {
  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://dummyjson.com';
  final http.Client _client;

  Future<List<Product>> fetchProducts() async {
    final response = await _get('/products?limit=24');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['products'] as List? ?? const [];
    return items
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(Product product) async {
    final response = await _send(
      method: 'POST',
      path: '/products/add',
      body: product.toJson(),
    );
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>)
        .copyWith(
      description: product.description,
      brand: product.brand,
      category: product.category,
      price: product.price,
      stock: product.stock,
    );
  }

  Future<Product> updateProduct(Product product) async {
    final response = await _send(
      method: 'PUT',
      path: '/products/${product.id}',
      body: product.toJson(),
      allowNotFound: true,
    );
    if (response.statusCode == 404) return product;
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>)
        .copyWith(
      thumbnail: product.thumbnail,
      images: product.images,
      rating: product.rating,
    );
  }

  Future<void> deleteProduct(int id) async {
    await _send(method: 'DELETE', path: '/products/$id', allowNotFound: true);
  }

  Future<http.Response> _get(String path) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl$path'));
      _ensureSuccess(response);
      return response;
    } on ProductApiException {
      rethrow;
    } catch (_) {
      throw const ProductApiException(
        'Could not reach DummyJSON. Check your internet connection.',
      );
    }
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool allowNotFound = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = {'Content-Type': 'application/json'};
      final response = await switch (method) {
        'POST' => _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          ),
        'PUT' => _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body),
          ),
        'DELETE' => _client.delete(uri),
        _ => throw ProductApiException('Unsupported method: $method'),
      };
      _ensureSuccess(response, allowNotFound: allowNotFound);
      return response;
    } on ProductApiException {
      rethrow;
    } catch (_) {
      throw const ProductApiException(
        'Could not reach DummyJSON. Check your internet connection.',
      );
    }
  }

  void _ensureSuccess(http.Response response, {bool allowNotFound = false}) {
    if (allowNotFound && response.statusCode == 404) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException(
        'Request failed (${response.statusCode}). Please try again.',
      );
    }
  }
}
