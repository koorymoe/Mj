import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/product.dart';
import '../models/quotation.dart';

class ApiService {
  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(AppConfig.gasUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      final result = await _post({'action': 'getAllProducts'});
      if (result['success'] == true) {
        return (result['data'] as List)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<String> getNextQuotationNumber() async {
    try {
      final result = await _post({'action': 'getNextQuotationNumber'});
      return result['number'] as String? ?? 'AM-${DateTime.now().year}-0001';
    } catch (_) {
      return 'AM-${DateTime.now().year}-0001';
    }
  }

  static Future<Map<String, dynamic>> saveQuotation(Quotation q) async {
    try {
      return await _post({'action': 'saveQuotation', 'data': q.toJson()});
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> addProduct(Product p) async {
    try {
      return await _post({'action': 'addProduct', 'data': p.toJson()});
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(String name) async {
    try {
      return await _post({'action': 'deleteProduct', 'name': name});
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
}
