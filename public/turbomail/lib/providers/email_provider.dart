import 'dart:async';
import 'package:flutter/material.dart';
import '../models/email_models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class EmailProvider with ChangeNotifier {
  // State variables
  GeneratedEmail? _currentEmail;
  Inbox? _currentInbox;
  bool _isLoading = false;
  String? _errorMessage;
  List<GeneratedEmail> _generatedEmails = [];
  
  // WebSocket service
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _newEmailSubscription;
  String? _currentSubscribedEmail;
  
  // Constructor
  EmailProvider() {
    _initializeWebSocket();
  }
  
  // Initialize WebSocket connection and listeners
  void _initializeWebSocket() {
    _webSocketService.connect();
    
    // Listen for new email notifications
    _newEmailSubscription = _webSocketService.newEmailStream.listen(
      (emailData) {
        _handleNewEmailNotification(emailData);
      },
      onError: (error) {
        print('WebSocket stream error: $error');
      },
    );
  }
  
  // Handle new email notification from WebSocket
  void _handleNewEmailNotification(Map<String, dynamic> emailData) {
    print('Received new email notification: $emailData');
    
    // Check if this notification is for the current inbox
    if (_currentInbox != null && 
        _currentSubscribedEmail != null && 
        emailData['email'] == _currentSubscribedEmail) {
      
      // Automatically refresh the inbox to get the new email
      getInbox(_currentSubscribedEmail!, forceRefresh: true);
    }
  }

  // Getters
  GeneratedEmail? get currentEmail => _currentEmail;
  Inbox? get currentInbox => _currentInbox;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  List<GeneratedEmail> get generatedEmails => _generatedEmails;
  bool get hasEmails => _generatedEmails.isNotEmpty;
  int get totalMessages => _currentInbox?.count ?? 0;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Generate random email
  Future<void> generateRandomEmail() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.generateRandomEmail();
      final email = GeneratedEmail.fromJson(response);
      
      // Store in MongoDB with device ID
      await _storeEmailInMongoDB(email);
      
      _currentEmail = email;
      _generatedEmails.add(email);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to generate email: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Generate manual email
  Future<void> generateManualEmail(String username, String domain) async {
    if (username.isEmpty || domain.isEmpty) {
      _setError('Username and domain are required');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.generateManualEmail(username, domain);
      final email = GeneratedEmail.fromJson(response);
      
      // Store in MongoDB with device ID
      await _storeEmailInMongoDB(email);
      
      _currentEmail = email;
      _generatedEmails.add(email);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to generate manual email: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get inbox for email
  Future<void> getInbox(String email, {bool forceRefresh = false}) async {
    if (email.isEmpty) {
      _setError('Email address is required');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getInbox(email, forceRefresh: forceRefresh);
      final inbox = Inbox.fromJson(response);
      
      _currentInbox = inbox;
      
      // Subscribe to WebSocket notifications for this email
      _subscribeToEmailNotifications(email);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to get inbox: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get specific message
  Future<EmailMessage?> getSpecificMessage(String email, int index) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getSpecificMessage(email, index);
      final message = EmailMessage.fromJson(response['message']);
      return message;
    } catch (e) {
      _setError('Failed to get message: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }



  // Refresh current inbox
  Future<void> refreshInbox() async {
    if (_currentInbox != null) {
      await getInbox(_currentInbox!.email, forceRefresh: true);
    }
  }

  // Set current email (for switching between generated emails)
  void setCurrentEmail(GeneratedEmail email) {
    _currentEmail = email;
    notifyListeners();
  }

  // Remove email from generated list
  void removeGeneratedEmail(GeneratedEmail email) {
    _generatedEmails.remove(email);
    if (_currentEmail == email) {
      _currentEmail = _generatedEmails.isNotEmpty ? _generatedEmails.last : null;
    }
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _currentEmail = null;
    _currentInbox = null;
    _generatedEmails.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Subscribe to WebSocket notifications for email
  void _subscribeToEmailNotifications(String email) {
    // Unsubscribe from previous email if different
    if (_currentSubscribedEmail != null && _currentSubscribedEmail != email) {
      _webSocketService.unsubscribeFromEmail(_currentSubscribedEmail!);
    }
    
    // Subscribe to new email
    if (_currentSubscribedEmail != email) {
      _webSocketService.subscribeToEmail(email);
      _currentSubscribedEmail = email;
      print('Subscribed to WebSocket notifications for: $email');
    }
  }

  // Delete all messages from inbox
  Future<bool> deleteAllMessages(String email) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await ApiService.deleteAllMessages(email);
      
      // Clear current inbox if it matches the deleted email
      if (_currentInbox?.email == email) {
        _currentInbox = Inbox(
          email: email,
          messages: [],
          count: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to delete messages: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete specific message by index
  Future<bool> deleteMessage(String email, int index) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await ApiService.deleteMessage(email, index);
      
      // Update current inbox if it matches the email
      if (_currentInbox?.email == email && _currentInbox != null) {
        final updatedMessages = List<EmailMessage>.from(_currentInbox!.messages);
        if (index >= 0 && index < updatedMessages.length) {
          updatedMessages.removeAt(index);
          _currentInbox = Inbox(
            email: email,
            messages: updatedMessages,
            count: updatedMessages.length,
            timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _setError('Failed to delete message: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Store email in MongoDB
  Future<void> _storeEmailInMongoDB(GeneratedEmail email) async {
    try {
      await ApiService.storeGeneratedEmail(email);
    } catch (e) {
      // Log error but don't fail the email generation
      print('Failed to store email in MongoDB: $e');
    }
  }
  
  // Load user's generated emails from MongoDB
  Future<void> loadUserGeneratedEmails({bool activeOnly = false}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final emails = await ApiService.getUserGeneratedEmails();
      
      if (activeOnly) {
        _generatedEmails = emails.where((email) => email.isActive).toList();
      } else {
        _generatedEmails = emails;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user emails: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Switch to a different email (set as active)
  Future<void> switchToEmail(GeneratedEmail email) async {
    try {
      // Deactivate current email if exists
      if (_currentEmail != null && _currentEmail!.id != null) {
        await ApiService.updateEmailStatus(_currentEmail!.id!, false);
      }
      
      // Activate selected email
      if (email.id != null) {
        await ApiService.updateEmailStatus(email.id!, true);
        email.isActive = true;
      }
      
      _currentEmail = email;
      
      // Update the email in the list
      final index = _generatedEmails.indexWhere((e) => e.id == email.id);
      if (index != -1) {
        _generatedEmails[index] = email;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to switch email: $e');
    }
  }
  
  // Delete a generated email
  Future<void> deleteGeneratedEmail(GeneratedEmail email) async {
    try {
      if (email.id != null) {
        await ApiService.deleteGeneratedEmail(email.id!);
        
        // Remove from local list
        _generatedEmails.removeWhere((e) => e.id == email.id);
        
        // If this was the current email, clear it
        if (_currentEmail?.id == email.id) {
          _currentEmail = null;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete email: $e');
    }
  }
  
  // Get device info
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      return await ApiService.getDeviceInfo();
    } catch (e) {
      _setError('Failed to get device info: $e');
      return null;
    }
  }
  
  // Dispose method to clean up resources
  @override
  void dispose() {
    // Unsubscribe from WebSocket notifications
    if (_currentSubscribedEmail != null) {
      _webSocketService.unsubscribeFromEmail(_currentSubscribedEmail!);
    }
    
    // Cancel stream subscription
    _newEmailSubscription?.cancel();
    
    // Dispose WebSocket service
    _webSocketService.dispose();
    
    super.dispose();
  }

  // Get available domains (hardcoded for now)
  List<String> getAvailableDomains() {
    return [
      'oplex.online',
      'agrovia.store',
      'example.com',
    ];
  }
}