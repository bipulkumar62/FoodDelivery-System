import 'package:flutter/material.dart';
import '../models/order.dart';
import '../config/theme.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  final double fontSize;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _backgroundColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _backgroundColor,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.preparing:
        return AppTheme.accentColor;
      case OrderStatus.outForDelivery:
        return Colors.deepPurple;
      case OrderStatus.delivered:
        return AppTheme.successColor;
      case OrderStatus.cancelled:
        return Colors.grey;
      case OrderStatus.rejected:
        return AppTheme.errorColor;
    }
  }
}
