import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/policy_models.dart';

class PolicyCard extends StatefulWidget {
  final PolicyOption policyOption;
  final bool isSelected;
  final Function(PolicyOption) onSelect;
  final bool isDisabled;

  const PolicyCard({
    super.key,
    required this.policyOption,
    required this.isSelected,
    required this.onSelect,
    this.isDisabled = false,
  });

  @override
  State<PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<PolicyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PolicyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled ? null : () => widget.onSelect(widget.policyOption),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: SizedBox(
              width: double.infinity,
              height: 180, // Fixed height for all cards
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: widget.isSelected 
                      ? AppTheme.secondaryColor.withOpacity(0.1) 
                      : Theme.of(context).cardTheme.color,
                  borderRadius: AppTheme.cardBorderRadius,
                  border: Border.all(
                    color: widget.isSelected 
                        ? AppTheme.secondaryColor 
                        : widget.isDisabled 
                            ? AppTheme.disabledColor 
                            : Colors.grey.shade300,
                    width: widget.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.secondaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.policyOption.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDisabled 
                          ? AppTheme.disabledColor 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildCostIndicator(widget.policyOption.cost, context),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                widget.policyOption.description,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDisabled 
                      ? AppTheme.disabledColor 
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isSelected)
              FadeTransition(
                opacity: _opacityAnimation,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostIndicator(int cost, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isDisabled
            ? AppTheme.disabledColor
            : cost == 1
                ? Colors.green
                : cost == 2
                    ? Colors.orange
                    : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            cost.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}