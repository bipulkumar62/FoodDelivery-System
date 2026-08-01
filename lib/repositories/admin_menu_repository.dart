import '../network/api_client.dart';
import '../models/admin_menu_item.dart';

class AdminMenuRepository {
  Future<List<AdminMenuItem>> getMenuItems() async {
    final response = await ApiClient.instance.get('/admin/menu');
    final data = response['data'] as List<dynamic>;
    return data
        .map((item) => AdminMenuItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAvailability(String id, bool available) async {
    await ApiClient.instance.patch(
      '/admin/menu/$id/availability',
      data: {'available': available},
    );
  }

  Future<AdminMenuItem> createMenuItem({
    required String name,
    required double price,
    required String category,
    String description = '',
    String image = '',
    bool veg = false,
    bool available = true,
  }) async {
    final response = await ApiClient.instance.post('/admin/menu', data: {
      'name': name,
      'price': price,
      'category': category,
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (image.trim().isNotEmpty) 'image': image.trim(),
      'veg': veg,
      'available': available,
    });
    return AdminMenuItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminMenuItem> updateMenuItem(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await ApiClient.instance.patch('/admin/menu/$id', data: payload);
    return AdminMenuItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> archiveItem(String id) async {
    await ApiClient.instance.delete('/admin/menu/$id');
  }
}
