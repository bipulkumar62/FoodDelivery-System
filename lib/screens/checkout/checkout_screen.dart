import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';
import '../../network/api_exception.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _isPlacing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacing = true);

    final cartItems = ref.read(cartProvider);

    try {
      final items = cartItems.map((ci) => {
            'menuItemId': ci.foodItem.id,
            'quantity': ci.quantity,
          }).toList();

      final order = await ref.read(orderRepositoryProvider).placeOrder(
            customerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            landmark: _landmarkController.text.trim().isEmpty
                ? null
                : _landmarkController.text.trim(),
            items: items,
          );

      ref.read(cartProvider.notifier).clearCart();
      await savePhoneNumber(_phoneController.text.trim());
      ref.invalidate(cachedPhoneProvider);
      ref.invalidate(ordersByPhoneProvider);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.orderSuccess,
          (route) => route.isFirst,
          arguments: order,
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'Failed to place order';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryCharge = ref.watch(cartDeliveryProvider);
    final grandTotal = ref.watch(cartGrandTotalProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Items', '$totalItems'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Subtotal', formatPrice(subtotal)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Delivery', formatPrice(deliveryCharge)),
                    const Divider(height: 16),
                    _buildSummaryRow('Total', formatPrice(grandTotal),
                        isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  if (v.trim().length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark (Optional)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacing ? null : _placeOrder,
                  child: _isPlacing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Place Order'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
