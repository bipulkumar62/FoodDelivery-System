import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/network_constants.dart';

class SocketService {
  static SocketService? _instance;
  late io.Socket _socket;
  bool _isConnected = false;
  static const maxReconnectAttempts = 5;

  SocketService._internal() {
    _initSocket();
  }

  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  void _initSocket() {
    _socket = io.io(
      NetworkConstants.baseUrl.replaceAll('/api/v1', ''),
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(10000)
          .setTimeout(10000)
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      debugPrint('Socket connected: ${_socket.id}');
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
    });

    _socket.onConnectError((data) {
      debugPrint('Socket connect error: $data');
    });

    _socket.onError((data) {
      debugPrint('Socket error: $data');
    });

    _socket.onReconnect((_) {
      debugPrint('Socket reconnected');
    });

    _socket.onReconnectAttempt((attempt) {
      debugPrint('Socket reconnect attempt: $attempt');
    });

    _socket.onReconnectFailed((_) {
      debugPrint('Socket reconnect failed');
    });
  }

  void connect() {
    if (!_isConnected) {
      _socket.connect();
    }
  }

  void disconnect() {
    _socket.disconnect();
    _isConnected = false;
  }

  void onNewOrder(Function(dynamic) callback) {
    _socket.on('order:new', (data) {
      callback(data);
    });
  }

  void onOrderStatusUpdate(Function(dynamic) callback) {
    _socket.on('order:status-update', (data) {
      callback(data);
    });
  }

  void onMenuAvailabilityUpdated(Function(dynamic) callback) {
    _socket.on('menu:availability-updated', callback);
  }

  void offMenuAvailabilityUpdated() {
    _socket.off('menu:availability-updated');
  }

  void onMenuCreated(Function(dynamic) callback) {
    _socket.on('menu:created', callback);
  }

  void offMenuCreated() {
    _socket.off('menu:created');
  }

  void onMenuUpdated(Function(dynamic) callback) {
    _socket.on('menu:updated', callback);
  }

  void offMenuUpdated() {
    _socket.off('menu:updated');
  }

  void onMenuDeleted(Function(dynamic) callback) {
    _socket.on('menu:deleted', callback);
  }

  void offMenuDeleted() {
    _socket.off('menu:deleted');
  }

  void offNewOrder() {
    _socket.off('order:new');
  }

  void offOrderStatusUpdate() {
    _socket.off('order:status-update');
  }

  bool get isConnected => _isConnected;
}