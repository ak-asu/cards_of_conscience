import 'package:flutter/material.dart';
import '../../../models/policy_models.dart';
import '../../../core/app_theme.dart';

/// A small policy card for displaying in dialogs
class PolicyCardMini extends StatelessWidget {
  final PolicyOption policy;
  
  const PolicyCardMini({
    super.key,
    required this.policy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getColorForDomain(policy.domain).withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForDomain(policy.domain),
                  size: 16,
                  color: _getColorForDomain(policy.domain),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDomainName(policy.domain),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getColorForDomain(policy.domain),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              policy.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              policy.description,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Cost: ${policy.cost} unit${policy.cost > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getColorForDomain(String domainId) {
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
  
  IconData _getIconForDomain(String domainId) {
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
  
  String _formatDomainName(String domainId) {
    final words = domainId.split('_');
    return words.map((word) => word.isNotEmpty 
        ? '${word[0].toUpperCase()}${word.substring(1)}' 
        : '').join(' ');
  }
}