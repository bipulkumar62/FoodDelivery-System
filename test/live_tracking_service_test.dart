import 'package:flutter_test/flutter_test.dart';
import 'package:pawan_biryani/models/live_location.dart';
import 'package:pawan_biryani/models/order.dart';
import 'package:pawan_biryani/services/live_tracking_service.dart';

class FakeGateway implements LiveTrackingGateway {
  int joinCount = 0;
  int leaveCount = 0;
  int offLocationCount = 0;
  int offStoppedCount = 0;
  int offJoinErrorCount = 0;
  bool joined = false;
  dynamic locationCallback;
  dynamic stoppedCallback;
  dynamic joinErrorCallback;
  LiveLocation? restLocation;

  @override
  void joinOrderRoom(String orderId, String phone) {
    joinCount++;
    joined = true;
  }

  @override
  void leaveOrderRoom(String orderId) {
    leaveCount++;
    joined = false;
  }

  @override
  void onTrackingLocation(Function(dynamic data) callback) {
    locationCallback = callback;
  }

  @override
  void offTrackingLocation() {
    offLocationCount++;
    locationCallback = null;
  }

  @override
  void onTrackingStopped(Function(dynamic data) callback) {
    stoppedCallback = callback;
  }

  @override
  void offTrackingStopped() {
    offStoppedCount++;
    stoppedCallback = null;
  }

  @override
  void onTrackingJoinError(Function(dynamic data) callback) {
    joinErrorCallback = callback;
  }

  @override
  void offTrackingJoinError() {
    offJoinErrorCount++;
    joinErrorCallback = null;
  }

  @override
  Future<LiveLocation?> fetchLocation(String orderId, String phone) async {
    return restLocation;
  }

  void pushLocation(Map<String, dynamic> data) {
    locationCallback?.call(data);
  }

  void pushStopped({String reason = 'order_terminal'}) {
    stoppedCallback?.call({'orderId': 'order-1', 'reason': reason});
  }
}

LiveLocation loc(String orderId,
    {double lat = 26.22, double lng = 84.34, DateTime? at}) {
  return LiveLocation(
    orderId: orderId,
    riderId: 'rider-1',
    latitude: lat,
    longitude: lng,
    accuracy: 10,
    timestamp: at ?? DateTime(2026, 8, 19, 10, 0, 0),
  );
}

void main() {
  DateTime fakeNow = DateTime(2026, 8, 19, 10, 0, 0);
  late FakeGateway gateway;
  late LiveTrackingService service;

  setUp(() {
    fakeNow = DateTime(2026, 8, 19, 10, 0, 0);
    gateway = FakeGateway();
    service = LiveTrackingService(
      orderId: 'order-1',
      phone: '9876543210',
      gateway: gateway,
      now: () => fakeNow,
    );
  });

  tearDown(() {
    service.dispose();
  });

  group('no tracking before out for delivery', () {
    for (final status in [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]) {
      test('status $status: refuses to start, nothing joined', () {
        service.start(orderStatus: status);
        expect(service.state.phase, LiveTrackingPhase.idle);
        expect(gateway.joinCount, 0);
        expect(gateway.locationCallback, isNull);
      });
    }
  });

  test('starts tracking only when out for delivery and receives updates', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    expect(service.state.phase, LiveTrackingPhase.waiting);
    expect(gateway.joinCount, 1);

    gateway.pushLocation({
      'orderId': 'order-1',
      'riderId': 'rider-1',
      'latitude': 26.22,
      'longitude': 84.34,
      'accuracy': 10,
      'timestamp': '2026-08-19T10:00:00.000Z',
    });
    expect(service.state.phase, LiveTrackingPhase.active);
    expect(service.state.location!.latitude, 26.22);
  });

  test('duplicate start taps are safe: single join, no duplicates', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    service.start(orderStatus: OrderStatus.outForDelivery);
    service.start(orderStatus: OrderStatus.outForDelivery);
    expect(gateway.joinCount, 1);
  });

  test('location events for another order are never shown', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    gateway.pushLocation({
      'orderId': 'order-999',
      'riderId': 'rider-1',
      'latitude': 1.0,
      'longitude': 1.0,
      'accuracy': 5,
      'timestamp': '2026-08-19T10:00:00.000Z',
    });
    expect(service.state.location, isNull);
    expect(service.state.phase, LiveTrackingPhase.waiting);
  });

  test('delivered status received remotely stops tracking', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    gateway.pushLocation({
      'orderId': 'order-1',
      'riderId': 'rider-1',
      'latitude': 26.22,
      'longitude': 84.34,
      'accuracy': 10,
      'timestamp': '2026-08-19T10:00:00.000Z',
    });
    expect(service.state.phase, LiveTrackingPhase.active);

    service.notifyTerminalStatus();
    expect(service.state.phase, LiveTrackingPhase.stopped);
    expect(service.state.location, isNull);
    expect(gateway.joined, false);
    expect(gateway.offLocationCount, 1);
    expect(gateway.leaveCount, 1);
  });

  test('cancelled status received remotely stops tracking', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    gateway.pushStopped();
    expect(service.state.phase, LiveTrackingPhase.stopped);
  });

  test('stop() is idempotent: repeated calls are safe', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    service.stop('first');
    service.stop('second');
    expect(service.state.phase, LiveTrackingPhase.stopped);
    expect(gateway.offLocationCount, 1);
    expect(gateway.leaveCount, 1);
  });

  test('stopped service ignores late location events', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    service.stop();
    gateway.pushLocation({
      'orderId': 'order-1',
      'riderId': 'rider-1',
      'latitude': 26.22,
      'longitude': 84.34,
      'accuracy': 10,
      'timestamp': '2026-08-19T10:00:01.000Z',
    });
    expect(service.state.phase, LiveTrackingPhase.stopped);
    expect(service.state.location, isNull);
  });

  test('old coordinates are treated as unavailable (stale TTL)', () {
    service.start(orderStatus: OrderStatus.outForDelivery);
    final recent = DateTime(2026, 8, 19, 9, 59, 30);
    gateway.pushLocation({
      'orderId': 'order-1',
      'riderId': 'rider-1',
      'latitude': 26.22,
      'longitude': 84.34,
      'accuracy': 10,
      'timestamp': recent.toUtc().toIso8601String(),
    });
    expect(service.state.phase, LiveTrackingPhase.active);

    // 60 s later: location is stale → unavailable.
    fakeNow = DateTime(2026, 8, 19, 10, 0, 30);
    service.evaluateStaleness();
    expect(service.state.phase, LiveTrackingPhase.unavailable);

    // Fresh update arrives → back to active.
    gateway.pushLocation({
      'orderId': 'order-1',
      'riderId': 'rider-1',
      'latitude': 26.23,
      'longitude': 84.35,
      'accuracy': 8,
      'timestamp': DateTime(2026, 8, 19, 10, 0, 31).toUtc().toIso8601String(),
    });
    expect(service.state.phase, LiveTrackingPhase.active);
    expect(service.state.location!.latitude, 26.23);
  });

  test('REST fallback restores location after network loss and recovery', () async {
    service.start(orderStatus: OrderStatus.outForDelivery);
    expect(service.state.phase, LiveTrackingPhase.waiting);

    gateway.restLocation = loc('order-1', at: fakeNow);
    await service.refreshFromRestForTest();

    expect(service.state.phase, LiveTrackingPhase.active);
    expect(service.state.location!.longitude, 84.34);
  });

  test('marker interpolation lerps between old and new coordinates', () {
    final a = loc('order-1', lat: 26.22, lng: 84.34);
    final b = loc('order-1', lat: 26.24, lng: 84.36);
    final mid = LiveLocation.lerp(a, b, 0.5);
    expect(mid.latitude, closeTo(26.23, 0.0001));
    expect(mid.longitude, closeTo(84.35, 0.0001));
    expect(LiveLocation.lerp(a, b, 0).latitude, 26.22);
    expect(LiveLocation.lerp(a, b, 1).latitude, 26.24);
  });
}