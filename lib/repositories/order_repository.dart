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
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'customerName': customerName,
      'phone': phone,
      'address': address,
      if (landmark != null) 'landmark': landmark,
      if (notes != null) 'notes': notes,
      'items': items,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    print('[placeOrder] sending latitude: $latitude, longitude: $longitude');
    final json = await _client.post('/orders', data: body);
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
    final List<dynamic> data = json is List ? json : (json['data'] as List<dynamic>? ?? []);
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}
