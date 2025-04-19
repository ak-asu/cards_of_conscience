import 'package:flutter/material.dart';

class DomainUtils {
  /// Formats a domain ID from snake_case to Title Case
  /// Example: 'criminal_justice' -> 'Criminal Justice'
  static String formatDomainName(String domainId) {
    final words = domainId.split('_');
    return words.map((word) => word.isNotEmpty 
        ? '${word[0].toUpperCase()}${word.substring(1)}' 
        : '').join(' ');
  }
  
  /// Returns a short version of the domain name
  /// For display in space-constrained areas
  static String getShortDomainName(String domainId) {
    switch (domainId) {
      case 'criminal_justice':
        return 'Justice';
      case 'environment':
        return 'Environ';
      case 'immigration':
        return 'Immigr';
      default:
        final words = domainId.split('_');
        return words.first[0].toUpperCase() + words.first.substring(1);
    }
  }

  /// Returns the color associated with a policy domain
  static Color getColorForDomain(String domainId) {
    switch (domainId) {
      case 'economy':
        return Colors.green;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.blue;
      case 'environment':
        return Colors.teal;
      case 'immigration':
        return Colors.orange;
      case 'criminal_justice':
        return Colors.purple;
      case 'defense':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
  
  /// Returns the icon associated with a policy domain
  static IconData getIconForDomain(String domainId) {
    switch (domainId) {
      case 'economy':
        return Icons.attach_money;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'environment':
        return Icons.eco;
      case 'immigration':
        return Icons.public;
      case 'criminal_justice':
        return Icons.balance;
      case 'defense':
        return Icons.security;
      default:
        return Icons.policy;
    }
  }
}