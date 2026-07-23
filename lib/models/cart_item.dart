import 'food_item.dart';

class CartItem {
  final FoodItem foodItem;
  int quantity;
  final List<String> selectedNotes;

  CartItem({
    required this.foodItem,
    this.quantity = 1,
    this.selectedNotes = const [],
  });

  double get totalPrice => foodItem.price * quantity;

  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }
}
