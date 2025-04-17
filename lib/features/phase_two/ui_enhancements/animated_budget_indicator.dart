import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedBudgetIndicator extends StatefulWidget {
  final int currentBudget;
  final int maxBudget;
  
  const AnimatedBudgetIndicator({
    super.key,
    required this.currentBudget,
    required this.maxBudget,
  });

  @override
  State<AnimatedBudgetIndicator> createState() => _AnimatedBudgetIndicatorState();
}

class _AnimatedBudgetIndicatorState extends State<AnimatedBudgetIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isNearLimit = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkBudgetLimit();
  }
  
  @override
  void didUpdateWidget(AnimatedBudgetIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBudget != oldWidget.currentBudget) {
      _checkBudgetLimit();
    }
  }
  
  void _checkBudgetLimit() {
    final budgetPercentage = widget.currentBudget / widget.maxBudget;
    final isNearLimit = budgetPercentage >= 0.8;
    
    if (isNearLimit && !_isNearLimit) {
      // Start pulsing when near limit
      _pulseController.repeat(reverse: true);
    } else if (!isNearLimit && _isNearLimit) {
      // Stop pulsing when no longer near limit
      _pulseController.stop();
      _pulseController.reset();
    }
    
    setState(() {
      _isNearLimit = isNearLimit;
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetPercentage = widget.currentBudget / widget.maxBudget;
    final exceededBudget = widget.currentBudget > widget.maxBudget;
    
    final progressColor = exceededBudget
        ? Colors.red
        : budgetPercentage >= 0.8
            ? Colors.orange
            : Colors.green;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Used:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Text(
                    '${widget.currentBudget} / ${widget.maxBudget}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: exceededBudget
                          ? Colors.red
                          : _isNearLimit
                              ? Color.lerp(
                                  Colors.orange,
                                  Colors.red,
                                  _pulseController.value,
                                )
                              : progressColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Stack(
          children: [
            // Base progress bar
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Colored progress
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 10,
              width: exceededBudget
                  ? double.infinity
                  : MediaQuery.of(context).size.width * budgetPercentage,
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Pulse animation for exceeded budget
            if (exceededBudget)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .custom(
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color.lerp(
                          Colors.red.withOpacity(0),
                          Colors.red.withOpacity(0.3),
                          value,
                        ),
                      ),
                      child: child,
                    ),
                  ),
              ),
          ],
        ),
        if (exceededBudget)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Budget exceeded by ${widget.currentBudget - widget.maxBudget} units!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (_isNearLimit)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Nearly at budget limit!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}