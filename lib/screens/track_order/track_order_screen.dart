import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/live_tracking_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/live_tracking_service.dart';
import '../../widgets/tracking_map_view.dart';

/// Full-screen live delivery tracking for a single order.
///
/// The map and subscription exist only while the order is out for delivery:
/// - before that, an explainer is shown and nothing is subscribed;
/// - after Delivered/Cancelled the subscription is stopped and the map
///   disappears immediately.
class TrackOrderScreen extends ConsumerWidget {
  final String orderId;
  final String phone;
  final String? displayOrderId;

  const TrackOrderScreen({
    super.key,
    required this.orderId,
    required this.phone,
    this.displayOrderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayOrderId != null ? 'Track $displayOrderId' : 'Track Order',
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                Text(
                  'Could not load order details.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(orderByIdProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (order) => _TrackBody(
          orderId: orderId,
          phone: phone,
          displayOrderId: displayOrderId ?? order.orderId,
          order: order,
        ),
      ),
    );
  }
}

class _TrackBody extends ConsumerStatefulWidget {
  final String orderId;
  final String phone;
  final String displayOrderId;
  final Order order;

  const _TrackBody({
    required this.orderId,
    required this.phone,
    required this.displayOrderId,
    required this.order,
  });

  @override
  ConsumerState<_TrackBody> createState() => _TrackBodyState();
}

class _TrackBodyState extends ConsumerState<_TrackBody> {
  @override
  void initState() {
    super.initState();
    _syncStatus(widget.order.orderStatus);
  }

  @override
  void didUpdateWidget(covariant _TrackBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderStatus != widget.order.orderStatus) {
      _syncStatus(widget.order.orderStatus);
    }
  }

  void _syncStatus(OrderStatus status) {
    final args = LiveTrackingArgs(
      orderId: widget.orderId,
      phone: widget.phone,
    );
    final notifier = ref.read(liveTrackingProvider(args).notifier);
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
    final status = widget.order.orderStatus;
    final args = LiveTrackingArgs(
      orderId: widget.orderId,
      phone: widget.phone,
    );
    final tracking = ref.watch(liveTrackingProvider(args));

    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return _MessageView(
        icon: Icons.check_circle_outline,
        title:
            'Order ${status == OrderStatus.delivered ? 'Delivered' : 'Cancelled'}',
        subtitle:
            'Live tracking has ended. The rider location is no longer shared.',
        showMap: false,
      );
    }

    if (status == OrderStatus.pending ||
        status == OrderStatus.accepted ||
        status == OrderStatus.preparing) {
      return _MessageView(
        icon: Icons.local_shipping_outlined,
        title: 'On its way soon',
        subtitle:
            'Live rider tracking becomes available when your order is out for delivery.',
        showMap: false,
      );
    }

    if (tracking.phase == LiveTrackingPhase.stopped) {
      return const _MessageView(
        icon: Icons.info_outline,
        title: 'Tracking ended',
        subtitle:
            'Update your order list for the latest status. The rider location is no longer shared.',
        showMap: false,
      );
    }

    if (tracking.phase == LiveTrackingPhase.waiting) {
      return _MessageView(
        icon: Icons.local_shipping_outlined,
        title: 'Waiting for the rider',
        subtitle: 'The rider will share their live location once they start the delivery.',
        showMap: true,
        tracking: tracking,
        order: widget.order,
      );
    }

    if (tracking.phase == LiveTrackingPhase.unavailable) {
      return _MessageView(
        icon: Icons.gps_off,
        title: 'Location temporarily unavailable',
        subtitle:
            'Please wait — the rider may be in an area without network coverage. Tracking resumes automatically.',
        showMap: true,
        tracking: tracking,
        order: widget.order,
        locationUnavailable: true,
      );
    }

    return _MessageView(
      icon: Icons.local_shipping_outlined,
      title: null,
      subtitle: null,
      showMap: true,
      tracking: tracking,
      order: widget.order,
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String? subtitle;
  final bool showMap;
  final LiveTrackingState? tracking;
  final Order? order;
  final bool locationUnavailable;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showMap,
    this.tracking,
    this.order,
    this.locationUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final location = tracking?.location;
    final hasLocation = location != null && !locationUnavailable;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showMap && order != null)
          TrackingMapView(
            location: hasLocation ? location : null,
            destinationLat: order!.latitude,
            destinationLng: order!.longitude,
            height: 340,
          ),
        if (showMap && order != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasLocation
                      ? const Color(0xFF2E7D32)
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasLocation
                    ? 'LIVE — Rider en route'
                    : 'Rider location pending',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hasLocation
                      ? const Color(0xFF2E7D32)
                      : Colors.orange.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 6),
            Text(
              'Updated ${_formatAge(location.timestamp)} • '
              'accuracy ±${location.accuracy.round()} m',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        if (title != null || subtitle != null) ...[
          const SizedBox(height: 20),
          Icon(icon, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Your location is never collected or shared. Rider location is only '
            'shared while the order is out for delivery and stops as soon as the '
            'order is delivered or cancelled.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _formatAge(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp.toLocal());
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}