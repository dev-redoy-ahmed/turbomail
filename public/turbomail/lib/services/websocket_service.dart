import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  final Set<String> _subscribedEmails = {};
  
  // Stream controllers for real-time notifications
  final StreamController<Map<String, dynamic>> _newEmailController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get newEmailStream => _newEmailController.stream;
  
  // Initialize WebSocket connection
  void connect() {
    if (_socket != null && _isConnected) {
      print('WebSocket already connected');
      return;
    }
    
    try {
      _socket = IO.io('http://localhost:3001', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _socket!.connect();
      
      // Connection events
      _socket!.on('connect', (_) {
        print('Connected to WebSocket server');
        _isConnected = true;
        
        // Re-subscribe to previously subscribed emails
        for (String email in _subscribedEmails) {
          _socket!.emit('subscribe-email', email);
        }
      });
      
      _socket!.on('disconnect', (_) {
        print('Disconnected from WebSocket server');
        _isConnected = false;
      });
      
      _socket!.on('connect_error', (error) {
        print('WebSocket connection error: $error');
        _isConnected = false;
      });
      
      // Email notification events
      _socket!.on('new-email', (data) {
        print('New email received: $data');
        _newEmailController.add(Map<String, dynamic>.from(data));
      });
      
      _socket!.on('subscribed', (data) {
        print('Successfully subscribed to: ${data['email']}');
      });
      
      _socket!.on('unsubscribed', (data) {
        print('Successfully unsubscribed from: ${data['email']}');
      });
      
    } catch (e) {
      print('Error initializing WebSocket: $e');
      _isConnected = false;
    }
  }
  
  // Subscribe to email notifications
  void subscribeToEmail(String email) {
    if (_socket == null || !_isConnected) {
      print('WebSocket not connected. Cannot subscribe to $email');
      return;
    }
    
    if (_subscribedEmails.contains(email)) {
      print('Already subscribed to $email');
      return;
    }
    
    _subscribedEmails.add(email);
    _socket!.emit('subscribe-email', email);
    print('Subscribing to email notifications for: $email');
  }
  
  // Unsubscribe from email notifications
  void unsubscribeFromEmail(String email) {
    if (_socket == null || !_isConnected) {
      print('WebSocket not connected. Cannot unsubscribe from $email');
      return;
    }
    
    if (!_subscribedEmails.contains(email)) {
      print('Not subscribed to $email');
      return;
    }
    
    _subscribedEmails.remove(email);
    _socket!.emit('unsubscribe-email', email);
    print('Unsubscribing from email notifications for: $email');
  }
  
  // Disconnect WebSocket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _subscribedEmails.clear();
      print('WebSocket disconnected');
    }
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    _newEmailController.close();
  }
}