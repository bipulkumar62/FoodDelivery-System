import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';
import '../models/food_item.dart';

class MenuRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<FoodItem>> getAllMenuItems() async {
    final json = await _client.get('/menu');
    final response = ApiResponse<List<FoodItem>>.fromJson(
      json,
      (data) {
        final items = <FoodItem>[];
        for (final entry in (data as List<dynamic>)) {
          try {
            items.add(FoodItem.fromJson(entry as Map<String, dynamic>));
          } catch (e) {
            debugPrint('[MenuRepository] Skipping malformed menu item: $e');
          }
        }
        return items;
      },
    );
    return response.data ?? [];
  }

  Future<FoodItem> getMenuItemById(String id) async {
    final json = await _client.get('/menu/$id');
    final response = ApiResponse<FoodItem>.fromJson(
      json,
      (data) => FoodItem.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }
}
