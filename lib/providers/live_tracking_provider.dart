import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/live_tracking_service.dart';

class LiveTrackingArgs {
  final String orderId;
  final String phone;

  const LiveTrackingArgs({required this.orderId, required this.phone});

  @override
  bool operator ==(Object other) =>
      other is LiveTrackingArgs &&
      other.orderId == orderId &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(orderId, phone);
}

final liveTrackingGatewayProvider =
    Provider<LiveTrackingGateway>((ref) => SocketLiveTrackingGateway());

/// One live-tracking notifier per order. Auto-disposes (and therefore stops
/// the subscription, leaves the socket room and clears state) when no UI is
/// watching it anymore — e.g. when the screen is closed or the order list
/// no longer shows the banner.
final liveTrackingProvider = NotifierProvider.autoDispose
    .family<LiveTrackingNotifier, LiveTrackingState, LiveTrackingArgs>(
  (args) => LiveTrackingNotifier(args),
);

class LiveTrackingNotifier extends Notifier<LiveTrackingState> {
  LiveTrackingNotifier(this.args);

  final LiveTrackingArgs args;
  LiveTrackingService? _service;

  @override
  LiveTrackingState build() {
    final service = LiveTrackingService(
      orderId: args.orderId,
      phone: args.phone,
      gateway: ref.read(liveTrackingGatewayProvider),
    );
    _service = service;
    service.addListener(() {
      if (ref.mounted) {
        state = service.state;
      }
    });
    ref.onDispose(service.dispose);
    return service.state;
  }

  /// Starts the subscription; a no-op before `out for delivery`.
  void ensureStarted(OrderStatus orderStatus) {
    _service?.start(orderStatus: orderStatus);
  }

  /// Called when the order flips to Delivered/Cancelled remotely.
  void notifyTerminalStatus() {
    _service?.notifyTerminalStatus();
  }
}