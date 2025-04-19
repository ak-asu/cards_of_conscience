import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnhancedTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final List<String> impacts;
  final List<String> tradeoffs;

  const EnhancedTooltip({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.impacts = const [],
    this.tradeoffs = const [],
  });

  @override
  State<EnhancedTooltip> createState() => _EnhancedTooltipState();
}

class _EnhancedTooltipState extends State<EnhancedTooltip> {
  final GlobalKey _childKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isTooltipVisible = false;
  
  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }
  
  void _showTooltip() {
    if (_isTooltipVisible) return;
    
    final RenderBox renderBox = _childKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height + 10,
        child: Material(
          color: Colors.transparent,
          child: _buildTooltipContent(context),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isTooltipVisible = true);
  }
  
  void _removeTooltip() {
    if (!_isTooltipVisible) return;
    
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isTooltipVisible = false);
  }
  
  Widget _buildTooltipContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.7;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.impacts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Impacts:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.impacts.map((impact) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        impact,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (widget.tradeoffs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Trade-offs:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.tradeoffs.map((tradeoff) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.balance, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tradeoff,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0, duration: 200.ms);
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _removeTooltip(),
      child: GestureDetector(
        onTap: () {
          if (_isTooltipVisible) {
            _removeTooltip();
          } else {
            _showTooltip();
          }
        },
        onLongPress: _showTooltip,
        child: KeyedSubtree(
          key: _childKey,
          child: widget.child,
        ),
      ),
    );
  }
}