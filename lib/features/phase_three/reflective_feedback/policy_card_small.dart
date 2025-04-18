import 'package:flutter/material.dart';
import '../../../models/policy_models.dart';

class PolicyCardSmall extends StatelessWidget {
  final PolicyOption policy;

  const PolicyCardSmall({
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
          color: _getDomainColor(policy.domain).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDomainColor(policy.domain).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDomainName(policy.domain),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getDomainColor(policy.domain),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Policy title
            Text(
              policy.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            
            // Cost
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cost: ${policy.cost} units',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDomainColor(String domainId) {
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

  String _formatDomainName(String domainId) {
    final words = domainId.split('_');
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}