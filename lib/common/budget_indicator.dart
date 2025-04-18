import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class BudgetIndicator extends StatefulWidget {
  final int currentBudget;
  final int maxBudget;

  const BudgetIndicator({
    super.key,
    required this.currentBudget,
    required this.maxBudget,
  });

  @override
  State<BudgetIndicator> createState() => _BudgetIndicatorState();
}

class _BudgetIndicatorState extends State<BudgetIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  int _lastBudget = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.currentBudget / widget.maxBudget,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _lastBudget = widget.currentBudget;
    _controller.forward();
  }

  @override
  void didUpdateWidget(BudgetIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBudget != _lastBudget) {
      _progressAnimation = Tween<double>(
        begin: _lastBudget / widget.maxBudget,
        end: widget.currentBudget / widget.maxBudget,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _lastBudget = widget.currentBudget;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget = widget.currentBudget > widget.maxBudget;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Usage',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '${widget.currentBudget} / ${widget.maxBudget} units',
                      key: ValueKey<int>(widget.currentBudget),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? AppTheme.warningColor : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  color: _getBudgetColor(_progressAnimation.value),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isOverBudget
                  ? 'Over budget! Please reduce your selections.'
                  : 'Remaining: ${widget.maxBudget - widget.currentBudget} units',
              key: ValueKey<bool>(isOverBudget),
              style: TextStyle(
                fontSize: 12,
                color: isOverBudget ? AppTheme.warningColor : Colors.grey.shade700,
                fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBudgetColor(double percentage) {
    if (percentage >= 1.0) {
      return AppTheme.warningColor;
    } else if (percentage >= 0.75) {
      return Colors.orange;
    } else if (percentage >= 0.5) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }
}