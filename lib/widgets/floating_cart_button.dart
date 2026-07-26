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

    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
      backgroundColor: AppTheme.primaryColor,
      elevation: 8,
      icon: Badge(
        label: Text('$totalItems'),
        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
      ),
      label: Row(
        children: [
          const Text(
            'View Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
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
    );
  }
}
