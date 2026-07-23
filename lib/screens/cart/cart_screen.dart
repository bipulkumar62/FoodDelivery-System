import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/quantity_selector.dart';
import '../../widgets/empty_state.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryCharge = ref.watch(cartDeliveryProvider);
    final grandTotal = ref.watch(cartGrandTotalProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          subtitle: 'Browse the menu and add items to your cart',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                final food = cartItem.foodItem;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: food.image.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: food.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Center(
                                    child: Text(
                                      food.name.substring(0, 1),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  food.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (cartItem.selectedNotes.isNotEmpty)
                              Text(
                                cartItem.selectedNotes.join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              formatPrice(food.price),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      QuantitySelector(
                        quantity: cartItem.quantity,
                        onIncrement: () =>
                            cartNotifier.incrementQuantity(food.id),
                        onDecrement: () =>
                            cartNotifier.decrementQuantity(food.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', formatPrice(subtotal)),
                  const SizedBox(height: 8),
                  _buildPriceRow('Delivery Charge', formatPrice(deliveryCharge)),
                  const Divider(height: 20),
                  _buildPriceRow('Total', formatPrice(grandTotal),
                      isTotal: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.checkout),
                      child: const Text('Proceed to Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
