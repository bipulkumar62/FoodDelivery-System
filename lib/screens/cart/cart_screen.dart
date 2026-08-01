import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/cart_item.dart';
import '../../models/food_item.dart';
import '../../widgets/quantity_selector.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/availability_banner.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final rate = ref.watch(deliveryRateProvider);
    final settings = ref.watch(restaurantSettingsProvider);
    final orderingDisabled = !settings.acceptingOrders;
    final cartNotifier = ref.read(cartProvider.notifier);
    final menuAsync = ref.watch(menuProvider);
    final liveMenu = menuAsync.value ?? const <FoodItem>[];
    final menuLoaded = menuAsync.hasValue;
    final liveById = <String, FoodItem>{
      for (final item in liveMenu) item.id: item,
    };
    bool isArchivedNow(CartItem cartItem) {
      if (!menuLoaded) return false;
      return !liveById.containsKey(cartItem.foodItem.id);
    }

    bool isSoldOutNow(CartItem cartItem) {
      if (!menuLoaded) return false;
      final live = liveById[cartItem.foodItem.id];
      if (live == null) return false;
      return !live.available;
    }

    final archivedItems = cartItems.where(isArchivedNow).toList();
    final soldOutItems = cartItems.where(isSoldOutNow).toList();

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
          if (orderingDisabled) const AvailabilityBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                final food = cartItem.foodItem;
                final isArchived = isArchivedNow(cartItem);
                final isSoldOut = isSoldOutNow(cartItem);

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
                                  errorWidget: (_, url, error) {
                                    debugPrint('[Cart] Failed to load image: $url error: $error');
                                    return Center(
                                      child: Text(
                                        food.name.substring(0, 1),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  },
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
                            if (isArchived) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NO LONGER AVAILABLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else if (isSoldOut) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SOLD OUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
                        onIncrement: (isSoldOut || isArchived || orderingDisabled)
                            ? null
                            : () => cartNotifier.incrementQuantity(food.id),
                        onDecrement: orderingDisabled
                            ? null
                            : () =>
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
                  _buildPriceRow(
                    'Delivery Charge',
                    rate.hasValue
                        ? '${formatPrice(rate.value!)}/km · at checkout'
                        : 'At checkout',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: orderingDisabled
                          ? null
                          : () {
                              if (archivedItems.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${archivedItems.first.foodItem.name} is no longer available. Please remove it from your cart.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                                return;
                              }
                              if (soldOutItems.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${soldOutItems.first.foodItem.name} is currently sold out.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                                return;
                              }
                              Navigator.pushNamed(context, AppRoutes.checkout);
                            },
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
