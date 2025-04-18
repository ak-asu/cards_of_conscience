import 'package:flutter/material.dart';
import '../models/policy_models.dart';
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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    domain.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth > 700
                  ? _buildGridLayout(constraints.maxWidth > 900 ? 3 : 2)
                  : _buildVerticalLayout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout(int crossAxisCount) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: domain.options.map((option) {
        return PolicyCard(
          policyOption: option,
          isSelected: selectedPolicies[domain.id]?.id == option.id,
          onSelect: onSelectPolicy,
          isDisabled: isDisabled,
        );
      }).toList(),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: domain.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
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