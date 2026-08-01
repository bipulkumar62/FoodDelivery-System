import 'package:flutter/material.dart';
import '../config/theme.dart';

const String offlineOrderingMessage =
    'We are currently offline. Ordering is temporarily unavailable. '
    'Please try again later.';

class AvailabilityBanner extends StatelessWidget {
  const AvailabilityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, color: AppTheme.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              offlineOrderingMessage,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
