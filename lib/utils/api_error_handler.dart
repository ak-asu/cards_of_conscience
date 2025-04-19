import 'package:flutter/foundation.dart';

mixin ApiErrorHandler {
  /// Provides standardized error handling for API calls
  /// 
  /// @param apiCall The future API call to execute
  /// @param defaultValue The fallback value to return in case of error
  /// @param logMessage Optional custom message to log with the error
  Future<T> handleApiCall<T>(
    Future<T> Function() apiCall,
    T defaultValue, {
    String? logMessage,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      debugPrint('${logMessage ?? 'API Error'}: $e');
      return defaultValue;
    }
  }
  
  /// Provides standardized error handling for synchronous operations
  /// 
  /// @param operation The operation to execute
  /// @param defaultValue The fallback value to return in case of error
  /// @param logMessage Optional custom message to log with the error
  T handleOperation<T>(
    T Function() operation,
    T defaultValue, {
    String? logMessage,
  }) {
    try {
      return operation();
    } catch (e) {
      debugPrint('${logMessage ?? 'Operation Error'}: $e');
      return defaultValue;
    }
  }
}