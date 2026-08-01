import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../network/api_client.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  bool isInCart(String foodId) => state.any((item) => item.foodItem.id == foodId);

  int itemQuantity(String foodId) {
    final index = state.indexWhere((item) => item.foodItem.id == foodId);
    return index >= 0 ? state[index].quantity : 0;
  }

  void addToCart(FoodItem foodItem, {List<String> notes = const []}) {
    final existingIndex =
        state.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (existingIndex >= 0) {
      state[existingIndex].incrementQuantity();
      state = [...state];
    } else {
      state = [
        ...state,
        CartItem(foodItem: foodItem, quantity: 1, selectedNotes: notes),
      ];
    }
  }

  void removeFromCart(String foodId) {
    state = state.where((item) => item.foodItem.id != foodId).toList();
  }

  void incrementQuantity(String foodId) {
    final index = state.indexWhere((item) => item.foodItem.id == foodId);
    if (index >= 0) {
      state[index].incrementQuantity();
      state = [...state];
    }
  }

  void decrementQuantity(String foodId) {
    final index = state.indexWhere((item) => item.foodItem.id == foodId);
    if (index >= 0) {
      if (state[index].quantity <= 1) {
        state = state.where((item) => item.foodItem.id != foodId).toList();
      } else {
        state[index].decrementQuantity();
        state = [...state];
      }
    }
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartTotalItemsProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// Current per-km delivery rate from the restaurant's public settings.
final deliveryRateProvider = FutureProvider<double>((ref) async {
  final response = await ApiClient.instance.get('/settings');
  final data = response['data'] as Map<String, dynamic>;
  return (data['deliveryRatePerKm'] as num).toDouble();
});
