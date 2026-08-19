import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/order.dart';
import '../providers/live_tracking_provider.dart';
import '../services/live_tracking_service.dart';
import 'tracking_map_view.dart';

/// Compact live-tracking banner that appears inside an order card while the
/// order is out for delivery. Disappears the moment the status flips to
/// Delivered/Cancelled (subscription stops, room left, listeners removed).
class RiderTrackingCard extends ConsumerStatefulWidget {
  final Order order;

  const RiderTrackingCard({super.key, required this.order});

  @override
  ConsumerState<RiderTrackingCard> createState() => _RiderTrackingCardState();
}

class _RiderTrackingCardState extends ConsumerState<RiderTrackingCard> {
  @override
  void initState() {
    super.initState();
    _syncStatus(widget.order.orderStatus);
  }

  @override
  void didUpdateWidget(covariant RiderTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderStatus != widget.order.orderStatus) {
      _syncStatus(widget.order.orderStatus);
    }
  }

  void _syncStatus(OrderStatus status) {
    final notifier = ref.read(
      liveTrackingProvider(
        LiveTrackingArgs(
          orderId: widget.order.id,
          phone: widget.order.phone,
        ),
      ).notifier,
    );
    if (status == OrderStatus.outForDelivery) {
      notifier.ensureStarted(status);
    } else if (status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.rejected) {
      notifier.notifyTerminalStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;

    // The banner exists only while tracking is allowed.
    if (status != OrderStatus.outForDelivery) {
      return const SizedBox.shrink();
    }

    final tracking = ref.watch(
      liveTrackingProvider(
        LiveTrackingArgs(orderId: order.id, phone: order.phone),
      ),
    );
    final location = tracking.location;
    final showMap = tracking.phase == LiveTrackingPhase.active ||
        tracking.phase == LiveTrackingPhase.waiting ||
        tracking.phase == LiveTrackingPhase.unavailable;

    if (!showMap) {
      return const SizedBox.shrink();
    }

    final locationVisible =
        tracking.phase == LiveTrackingPhase.active && location != null;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locationVisible
                      ? const Color(0xFF2E7D32)
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationVisible
                      ? 'Rider on the way'
                      : (tracking.phase == LiveTrackingPhase.unavailable
                          ? 'Rider location temporarily unavailable'
                          : 'Waiting for rider to start...'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.trackOrder,
                    arguments: {
                      'orderId': order.id,
                      'phone': order.phone,
                      'displayOrderId': order.orderId,
                    },
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Track'),
              ),
            ],
          ),
          if (locationVisible) ...[
            const SizedBox(height: 8),
            TrackingMapView(
              location: location,
              destinationLat: order.latitude,
              destinationLng: order.longitude,
              height: 150,
            ),
          ],
        ],
      ),
    );
  }
}