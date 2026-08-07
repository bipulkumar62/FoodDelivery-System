import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/cart_item.dart';
import '../../models/food_item.dart';
import '../../providers/order_provider.dart';
import '../../services/location_service.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';
import '../../network/api_exception.dart';
import '../../network/api_client.dart';
import '../../widgets/availability_banner.dart';

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
  bool _locationLoading = true;
  bool _quoteLoading = false;
  String? _locationError;
  double? _latitude;
  double? _longitude;
  double? _deliveryCharge;

  // Restaurant location (fixed)
  static const double _restaurantLat = LocationService.restaurantLat;
  static const double _restaurantLng = LocationService.restaurantLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _locationLoading = true);
    final hasPermission = await LocationService.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Location permission is required for delivery. Please enable it in settings.';
        });
      }
      return;
    }

    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Unable to get your location. Please enable GPS and try again.';
        });
      }
      return;
    }

    final distance = LocationService.calculateDistance(
      _restaurantLat, _restaurantLng,
      position.latitude, position.longitude,
    );

    if (distance > 15.0) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Sorry, we are currently not available in your area. We\'ll be available soon.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLoading = false;
        _locationError = null;
      });
    }

    await _loadDeliveryQuote();
  }

  Future<void> _loadDeliveryQuote() async {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return;

    if (mounted) {
      setState(() {
        _quoteLoading = true;
        _deliveryCharge = null;
      });
    }

    try {
      final response = await ApiClient.instance.post(
        '/orders/delivery-quote',
        data: {'latitude': lat, 'longitude': lng},
      );
      final data = response['data'] as Map<String, dynamic>;
      if (data['withinDeliveryRange'] != true) {
        if (mounted) {
          setState(() {
            _locationError = 'Sorry, we are currently not available in your area. We\'ll be available soon.';
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _deliveryCharge = (data['deliveryCharge'] as num).toDouble();
        });
      }
    } catch (_) {
      try {
        ref.invalidate(deliveryRateProvider);
        final rate = await ref.read(deliveryRateProvider.future);
        final distance = LocationService.getDistanceFromRestaurant(lat, lng);
        if (mounted) {
          setState(() {
            _deliveryCharge = distance.ceil() * rate;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _locationError = 'Unable to calculate delivery charge. Please try again.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _quoteLoading = false);
      }
    }
  }

  Future<void> _placeOrder() async {
    final settings = ref.read(restaurantSettingsProvider);
    if (!settings.acceptingOrders) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(offlineOrderingMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null || _deliveryCharge == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_locationError ?? 'Delivery charge not available. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final cartItems = ref.read(cartProvider);
    final menuAsync = ref.read(menuProvider);
    final liveMenu = menuAsync.value ?? const <FoodItem>[];
    final menuLoaded = menuAsync.hasValue;
    final liveById = <String, FoodItem>{
      for (final item in liveMenu) item.id: item,
    };
    final archivedItems = menuLoaded
        ? cartItems
            .where((ci) => !liveById.containsKey(ci.foodItem.id))
            .toList()
        : <CartItem>[];
    if (archivedItems.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${archivedItems.first.foodItem.name} is no longer available. '
              'Please remove it from your cart.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    final soldOutItems = cartItems
        .where((ci) {
          final live = liveById[ci.foodItem.id];
          if (live == null) return false;
          return !live.available;
        })
        .toList();
    if (soldOutItems.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${soldOutItems.first.foodItem.name} is currently sold out.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() => _isPlacing = true);

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
            latitude: _latitude,
            longitude: _longitude,
          );

      ref.read(cartProvider.notifier).clearCart();
      await savePhoneNumber(_phoneController.text.trim());
      ref.invalidate(cachedPhoneProvider);
      ref.invalidate(ordersForPhoneProvider);

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

  Widget _buildLocationStatus() {
    if (_locationLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    if (_latitude != null && _longitude != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location verified - within delivery range',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryCharge = _deliveryCharge ?? 0.0;
    final grandTotal = subtotal + deliveryCharge;
    final totalItems = ref.watch(cartTotalItemsProvider);
    final orderingDisabled = !ref.watch(restaurantSettingsProvider).acceptingOrders;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (orderingDisabled) const AvailabilityBanner(),
              _buildLocationStatus(),
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
                    _buildSummaryRow(
                      'Delivery',
                      _quoteLoading
                          ? 'Calculating...'
                          : (_deliveryCharge != null
                              ? formatPrice(_deliveryCharge!)
                              : 'At checkout'),
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Total',
                      _deliveryCharge != null
                          ? formatPrice(grandTotal)
                          : 'At checkout',
                      isBold: true,
                    ),
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
                  onPressed: (orderingDisabled ||
                          _isPlacing ||
                          _quoteLoading ||
                          _deliveryCharge == null)
                      ? null
                      : _placeOrder,
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