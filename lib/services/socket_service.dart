import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/network_constants.dart';

class SocketService {
  static SocketService? _instance;
  late IO.Socket _socket;
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
    _socket = IO.io(
      NetworkConstants.baseUrl.replaceAll('/api/v1', ''),
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(10000)
          .setTimeout(10000)
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      print('Socket connected: ${_socket.id}');
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
    });

    _socket.onConnectError((data) {
      print('Socket connect error: $data');
    });

    _socket.onError((data) {
      print('Socket error: $data');
    });

    _socket.onReconnect((_) {
      print('Socket reconnected');
    });

    _socket.onReconnectAttempt((attempt) {
      print('Socket reconnect attempt: $attempt');
    });

    _socket.onReconnectFailed((_) {
      print('Socket reconnect failed');
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

  void offNewOrder() {
    _socket.off('order:new');
  }

  void offOrderStatusUpdate() {
    _socket.off('order:status-update');
  }

  bool get isConnected => _isConnected;
}