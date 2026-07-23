import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

const _phoneKey = 'customer_phone';

final cachedPhoneProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_phoneKey);
});

Future<void> savePhoneNumber(String phone) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_phoneKey, phone);
}

final ordersByPhoneProvider = FutureProvider<List<Order>>((ref) async {
  final phone = await ref.watch(cachedPhoneProvider.future);
  if (phone == null || phone.isEmpty) return [];
  return ref.read(orderRepositoryProvider).getOrdersByPhone(phone);
});

final placeOrderProvider = FutureProvider.family<Order, Map<String, dynamic>>((ref, data) async {
  return ref.read(orderRepositoryProvider).placeOrder(
    customerName: data['customerName'] as String,
    phone: data['phone'] as String,
    address: data['address'] as String,
    landmark: data['landmark'] as String?,
    notes: data['notes'] as String?,
    items: data['items'] as List<Map<String, dynamic>>,
  );
});

final orderByIdProvider = FutureProvider.family<Order, String>((ref, id) async {
  return ref.read(orderRepositoryProvider).getOrderById(id);
});
