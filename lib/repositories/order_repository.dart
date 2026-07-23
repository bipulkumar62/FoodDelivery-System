// ignore_for_file: use_null_aware_elements
import '../network/api_client.dart';
import '../models/order.dart';

class OrderRepository {
  final ApiClient _client = ApiClient.instance;

  Future<Order> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    String? landmark,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final json = await _client.post('/orders', data: {
      'customerName': customerName,
      'phone': phone,
      'address': address,
      if (landmark != null) 'landmark': landmark,
      if (notes != null) 'notes': notes,
      'items': items,
    });
    final data = json['data'] as Map<String, dynamic>;
    return Order.fromJson(data);
  }

  Future<Order> getOrderById(String id) async {
    final json = await _client.get('/orders/$id');
    final data = json['data'] as Map<String, dynamic>;
    return Order.fromJson(data);
  }

  Future<List<Order>> getOrdersByPhone(String phone) async {
    final json = await _client.get('/orders/phone/$phone');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}
