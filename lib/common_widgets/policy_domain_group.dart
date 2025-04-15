import 'package:flutter/material.dart';
import '../features/phase_one/models/policy_models.dart';
import 'policy_card.dart';

class PolicyDomainGroup extends StatelessWidget {
  final PolicyDomain domain;
  final Map<String, PolicyOption> selectedPolicies;
  final Function(PolicyOption) onSelectPolicy;
  final bool isDisabled;

  const PolicyDomainGroup({
    super.key,
    required this.domain,
    required this.selectedPolicies,
    required this.onSelectPolicy,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  domain.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth > 700
                  ? _buildHorizontalLayout()
                  : _buildVerticalLayout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: domain.options.map((option) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: PolicyCard(
              policyOption: option,
              isSelected: selectedPolicies[domain.id]?.id == option.id,
              onSelect: onSelectPolicy,
              isDisabled: isDisabled,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: domain.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PolicyCard(
            policyOption: option,
            isSelected: selectedPolicies[domain.id]?.id == option.id,
            onSelect: onSelectPolicy,
            isDisabled: isDisabled,
          ),
        );
      }).toList(),
    );
  }
}