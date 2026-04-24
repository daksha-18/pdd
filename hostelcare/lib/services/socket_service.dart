import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _connected = false;

  static bool get isConnected => _connected;

  /// Initialize socket connection
  static void connect(String userId) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      _connected = true;
      print('Socket connected');
      _socket!.emit('join_room', userId);
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      print('Socket disconnected');
    });
  }

  /// Listen for complaint updates
  static void onComplaintUpdate(Function(dynamic) callback) {
    _socket?.on('complaint_update', callback);
  }

  /// Listen for new assignments (staff)
  static void onNewAssignment(Function(dynamic) callback) {
    _socket?.on('new_assignment', callback);
  }

  /// Listen for new complaints (admin)
  static void onNewComplaint(Function(dynamic) callback) {
    _socket?.on('new_complaint', callback);
  }

  /// Disconnect socket
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  /// Remove all listeners
  static void removeAllListeners() {
    _socket?.clearListeners();
  }
}
