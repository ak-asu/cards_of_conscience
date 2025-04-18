import 'package:flutter/foundation.dart';

import '../services/chat_service.dart';
import '../models/enhanced_reflection_data.dart';

class EnhancedReflectionProvider with ChangeNotifier {
  EnhancedReflectionData _enhancedData = EnhancedReflectionData.empty();
  bool _isLoading = true;
  String? _error;
  final ChatService _chatService;

  EnhancedReflectionData get enhancedData => _enhancedData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EnhancedReflectionProvider({required ChatService chatService}) 
      : _chatService = chatService {
    _loadEnhancedReflectionData();
  }

  Future<void> _loadEnhancedReflectionData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create an instance of the data provider to use its methods
      final dataProvider = EnhancedReflectionDataProvider(
        chatService: _chatService,
      );
      
      // Load the enhanced data
      await dataProvider.loadEnhancedReflectionData();
      
      // Check for errors
      if (dataProvider.error != null) {
        _error = dataProvider.error;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get the enhanced data
      _enhancedData = dataProvider.reflectionData;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading enhanced reflection data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _loadEnhancedReflectionData();
  }
}