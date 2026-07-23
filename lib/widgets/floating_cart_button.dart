import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../utils/helpers.dart';

class FloatingCartButton extends ConsumerWidget {
  const FloatingCartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);

    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.primaryColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Badge(
                  label: Text('$totalItems'),
                  child: const Icon(Icons.shopping_cart,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatPrice(ref.watch(cartGrandTotalProvider)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
