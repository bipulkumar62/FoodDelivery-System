import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/live_location.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/order.dart';
import 'socket_service.dart';

/// Injectable transport for live tracking so the state machine can be tested
/// without a real socket or network.
abstract class LiveTrackingGateway {
  void joinOrderRoom(String orderId, String phone);

  void leaveOrderRoom(String orderId);

  void onTrackingLocation(void Function(dynamic data) callback);

  void offTrackingLocation();

  void onTrackingStopped(void Function(dynamic data) callback);

  void offTrackingStopped();

  void onTrackingJoinError(void Function(dynamic data) callback);

  void offTrackingJoinError();

  Future<LiveLocation?> fetchLocation(String orderId, String phone);
}

/// Production gateway backed by the project's Socket.IO architecture.
class SocketLiveTrackingGateway implements LiveTrackingGateway {
  final SocketService _socket = SocketService.instance;

  @override
  void joinOrderRoom(String orderId, String phone) {
    _socket.connect();
    _socket.joinOrderRoom(orderId, phone);
  }

  @override
  void leaveOrderRoom(String orderId) {
    _socket.leaveOrderRoom(orderId);
  }

  @override
  void onTrackingLocation(Function(dynamic data) callback) {
    _socket.onTrackingLocation(callback);
  }

  @override
  void offTrackingLocation() {
    _socket.offTrackingLocation();
  }

  @override
  void onTrackingStopped(Function(dynamic data) callback) {
    _socket.onTrackingStopped(callback);
  }

  @override
  void offTrackingStopped() {
    _socket.offTrackingStopped();
  }

  @override
  void onTrackingJoinError(Function(dynamic data) callback) {
    _socket.onTrackingJoinError(callback);
  }

  @override
  void offTrackingJoinError() {
    _socket.offTrackingJoinError();
  }

  @override
  Future<LiveLocation?> fetchLocation(String orderId, String phone) async {
    try {
      final response = await ApiClient.instance.get(
        '/tracking/$orderId/location',
        queryParameters: {'phone': phone},
      );
      final data = response['data'] as Map<String, dynamic>? ?? const {};
      final location = data['location'] as Map<String, dynamic>?;
      final active = data['active'] == true;
      if (!active || location == null) {
        return null;
      }
      return LiveLocation.fromJson(location);
    } on ApiException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

enum LiveTrackingPhase {
  /// Not subscribed yet (order not out for delivery).
  idle,

  /// Subscribed and waiting for the first location (or the rider to start).
  waiting,

  /// Receiving live locations.
  active,

  /// Subscribed but the last location is too old to be shown.
  unavailable,

  /// Tracking ended (delivered / cancelled / stopped / screen closed).
  stopped,
}

class LiveTrackingState {
  final LiveTrackingPhase phase;
  final LiveLocation? location;
  final String? message;

  const LiveTrackingState({
    this.phase = LiveTrackingPhase.idle,
    this.location,
    this.message,
  });

  bool get isActive => phase == LiveTrackingPhase.active;

  LiveTrackingState copyWith({
    LiveTrackingPhase? phase,
    LiveLocation? location,
    String? message,
  }) {
    return LiveTrackingState(
      phase: phase ?? this.phase,
      location: location ?? this.location,
      message: message ?? this.message,
    );
  }
}

/// Customer-side live tracking state machine.
///
/// Guarantees:
/// - Refuses to track unless the order status is `outForDelivery`.
/// - Treats locations older than [staleAfter] as unavailable.
/// - `stop()` is idempotent: repeated calls and disposal are safe.
/// - Disconnects listeners and leaves the room on stop/dispose.
class LiveTrackingService extends ChangeNotifier {
  final String orderId;
  final String phone;
  final LiveTrackingGateway gateway;
  final DateTime Function() now;

  static const Duration staleAfter = Duration(seconds: 45);
  static const Duration staleCheckInterval = Duration(seconds: 5);
  static const Duration restRefreshInterval = Duration(seconds: 15);

  LiveTrackingState _state = const LiveTrackingState();
  bool _started = false;
  bool _stopped = false;
  Timer? _staleTimer;
  Timer? _refreshTimer;

  LiveTrackingService({
    required this.orderId,
    required this.phone,
    required this.gateway,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  LiveTrackingState get state => _state;

  /// Starts tracking. Has no effect (and is safe) when:
  /// - called before the order is out for delivery,
  /// - called twice for the same order,
  /// - tracking was already stopped.
  void start({required OrderStatus orderStatus}) {
    if (_stopped) return;
    if (orderStatus != OrderStatus.outForDelivery) {
      _state = const LiveTrackingState(
        phase: LiveTrackingPhase.idle,
        message: 'Tracking is only available while the order is out for delivery.',
      );
      notifyListeners();
      return;
    }
    if (_started) return;

    _started = true;
    _state = LiveTrackingState(
      phase: LiveTrackingPhase.waiting,
      message: 'Waiting for the rider to start the delivery...',
    );

    gateway.onTrackingLocation(_onLocationEvent);
    gateway.onTrackingStopped(_onStoppedEvent);
    gateway.onTrackingJoinError((data) {
      if (_stopped) return;
      _setState(LiveTrackingPhase.unavailable,
          message: 'Unable to access live tracking for this order.');
    });
    gateway.joinOrderRoom(orderId, phone);

    _staleTimer = Timer.periodic(staleCheckInterval, (_) => _checkStaleness());
    _refreshTimer = Timer.periodic(restRefreshInterval, (_) => _refreshFromRest());

    _refreshFromRest();
    notifyListeners();
  }

  /// Handles a remote status flip to Delivered/Cancelled. Idempotent.
  void notifyTerminalStatus() {
    stop('Order is no longer active.');
  }

  void _onLocationEvent(dynamic data) {
    if (_stopped) return;
    try {
      final json = (data as Map).cast<String, dynamic>();
      final location = LiveLocation.fromJson(json);
      if (location.orderId != orderId) {
        return; // Never show another order's location.
      }
      _state = LiveTrackingState(
        phase: LiveTrackingPhase.active,
        location: location,
        message: null,
      );
      notifyListeners();
    } catch (_) {
      // Malformed payload: ignore, keep previous state.
    }
  }

  void _onStoppedEvent(dynamic data) {
    stop(
      'Live tracking has ended for this order.',
    );
  }

  void _checkStaleness() {
    if (_stopped) return;
    final location = _state.location;
    if (location == null) return;
    final age = now().difference(location.timestamp);
    if (age > staleAfter && _state.isActive) {
      _setState(LiveTrackingPhase.unavailable,
          message: 'Rider location is temporarily unavailable.');
    }
  }

  /// Runs the staleness evaluation immediately (used by tests; the periodic
  /// timer normally calls it every [staleCheckInterval]).
  void evaluateStaleness() => _checkStaleness();

  /// Performs the REST refresh immediately (used by tests; the periodic
  /// timer normally calls it every [restRefreshInterval]).
  Future<void> refreshFromRestForTest() => _refreshFromRest();

  Future<void> _refreshFromRest() async {
    if (_stopped) return;
    final location = await gateway.fetchLocation(orderId, phone);
    if (_stopped || location == null) return;
    if (location.orderId != orderId) return;
    _state = LiveTrackingState(phase: LiveTrackingPhase.active, location: location);
    notifyListeners();
  }

  void _setState(LiveTrackingPhase phase, {String? message}) {
    if (_stopped) return;
    _state = _state.copyWith(phase: phase, message: message);
    notifyListeners();
  }

  /// The single idempotent termination flow. Safe to call repeatedly:
  /// stops updates, disconnects listeners, leaves the room, clears state.
  void stop([String? message]) {
    if (_stopped) return;
    _stopped = true;
    _started = false;

    _staleTimer?.cancel();
    _staleTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;

    gateway.offTrackingLocation();
    gateway.offTrackingStopped();
    gateway.offTrackingJoinError();
    gateway.leaveOrderRoom(orderId);

    _state = LiveTrackingState(
      phase: LiveTrackingPhase.stopped,
      location: null,
      message: message,
    );
    notifyListeners();
  }
}