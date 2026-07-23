import '../network/api_client.dart';
import '../network/api_response.dart';
import '../models/food_item.dart';

class MenuRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<FoodItem>> getAllMenuItems() async {
    final json = await _client.get('/menu');
    final response = ApiResponse<List<FoodItem>>.fromJson(
      json,
      (data) => (data as List<dynamic>)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
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
