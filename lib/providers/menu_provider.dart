import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) => MenuRepository());

final menuProvider = FutureProvider<List<FoodItem>>((ref) async {
  return ref.read(menuRepositoryProvider).getAllMenuItems();
});

final menuItemProvider = FutureProvider.family<FoodItem, String>((ref, id) async {
  return ref.read(menuRepositoryProvider).getMenuItemById(id);
});
