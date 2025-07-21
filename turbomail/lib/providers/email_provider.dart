import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/email_model.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';

class EmailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _currentEmail;
  List<EmailModel> _emails = [];
  bool _isLoading = false;
  String? _error;
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _deviceId;

  // Getters
  String? get currentEmail => _currentEmail;
  List<EmailModel> get emails => _emails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  String? get deviceId => _deviceId;
  List<String> get availableDomains => _apiService.getAvailableDomains();

  EmailProvider() {
    _initializeDeviceId();
  }

  Future<void> _initializeDeviceId() async {
    _deviceId = await DeviceService.getDeviceId();
    notifyListeners();
  }

  /// Set current email (for switching between emails)
  void setCurrentEmail(String email) {
    _currentEmail = email;
    _emails.clear();
    _error = null;
    notifyListeners();
    
    // Disconnect from previous email and connect to new one
    _disconnectSocket();
    _connectSocket();
    refreshInbox();
  }

  /// Generate a random email
  Future<void> generateRandomEmail() async {
    _setLoading(true);
    try {
      final generatedEmail = await _apiService.generateRandomEmail();
      _currentEmail = generatedEmail.email;
      _emails.clear();
      _error = null;
      
      // Connect to socket for real-time updates
      _connectSocket();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Generate a manual email with custom username
  Future<void> generateManualEmail(String username, String domain) async {
    _setLoading(true);
    try {
      final generatedEmail = await _apiService.generateManualEmail(username, domain);
      _currentEmail = generatedEmail.email;
      _emails.clear();
      _error = null;
      
      // Connect to socket for real-time updates
      _connectSocket();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Check if an email is available
  Future<bool> checkEmailAvailability(String email) async {
    try {
      return await _apiService.checkEmailAvailability(email);
    } catch (e) {
      return false;
    }
  }

  /// Refresh inbox messages
  Future<void> refreshInbox() async {
    if (_currentEmail == null) return;
    
    _setLoading(true);
    try {
      final messages = await _apiService.getInboxMessages(_currentEmail!);
      _emails = messages;
      _emails.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(int index) async {
    if (_currentEmail == null || index >= _emails.length) return;
    
    try {
      await _apiService.deleteMessage(_currentEmail!, index);
      _emails.removeAt(index);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Delete entire inbox
  Future<void> deleteInbox() async {
    if (_currentEmail == null) return;
    
    try {
      await _apiService.deleteInbox(_currentEmail!);
      _emails.clear();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Get email history for current device
  Future<EmailHistoryResponse> getEmailHistory({int page = 1, int limit = 20}) async {
    return await _apiService.getEmailHistory(page: page, limit: limit);
  }

  /// Toggle star status for an email
  Future<void> toggleEmailStar(String email, bool isStarred) async {
    await _apiService.toggleEmailStar(email, isStarred);
  }

  /// Get starred emails for current device
  Future<List<HistoryEmailModel>> getStarredEmails() async {
    return await _apiService.getStarredEmails();
  }

  /// Delete email from history
  Future<void> deleteEmailFromHistory(String email) async {
    await _apiService.deleteEmailFromHistory(email);
  }

  /// Connect to Socket.IO for real-time email updates
  void _connectSocket() {
    if (_currentEmail == null) return;
    
    try {
      _socket = IO.io('http://165.22.109.153:3001', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.on('connect', (_) {
        _isConnected = true;
        _socket!.emit('subscribe', _currentEmail);
        notifyListeners();
      });

      _socket!.on('disconnect', (_) {
        _isConnected = false;
        notifyListeners();
      });

      _socket!.on('new_mail', (data) {
        final newEmail = EmailModel.fromJson(data);
        _emails.insert(0, newEmail);
        _emails.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        notifyListeners();
      });

      _socket!.on('connect_error', (error) {
        _isConnected = false;
        notifyListeners();
      });
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Disconnect from Socket.IO
  void _disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Clear current email and disconnect
  void clearCurrentEmail() {
    _currentEmail = null;
    _emails.clear();
    _error = null;
    _disconnectSocket();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }
}