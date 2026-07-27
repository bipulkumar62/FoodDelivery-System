import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../utils/helpers.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as Order?;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your delicious food is being prepared.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (order != null) ...[
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
                      const Text(
                        'Order ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: AppTheme.primaryColor, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Delivery Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                order.estimatedDeliveryTime != null
                                    ? _formatTime(order.estimatedDeliveryTime!)
                                    : '30 - 40 Minutes',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            formatPrice(order.total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => route.isFirst,
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _toIst(DateTime dt) => dt.toUtc().add(const Duration(hours: 5, minutes: 30));

  String _formatTime(DateTime dt) {
    final ist = _toIst(dt);
    final hour = ist.hour.toString().padLeft(2, '0');
    final minute = ist.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
