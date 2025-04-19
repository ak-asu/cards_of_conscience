import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/policy_models.dart';

enum PolicyCardSize {
  mini,
  small,
  full
}

class PolicyCard extends StatefulWidget {
  final PolicyOption policy;
  final PolicyCardSize size;
  final bool isSelected;
  final bool isDisabled;
  final Function(PolicyOption)? onSelect;
  final Widget? backContent;
  final bool enableFlip;
  
  const PolicyCard({
    super.key,
    required this.policy,
    this.size = PolicyCardSize.full,
    this.isSelected = false,
    this.isDisabled = false,
    this.onSelect,
    this.backContent,
    this.enableFlip = false,
  });

  @override
  State<PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<PolicyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isFrontVisible = true;
  bool _isHovering = false;

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
    
    if (widget.isSelected) {
      _controller.forward();
    }
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

  void _toggleCard() {
    if (!widget.enableFlip || widget.backContent == null) return;
    
    setState(() {
      _isFrontVisible = !_isFrontVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget card = _buildCardBySize();
    
    if (widget.isSelected) {
      card = _applySelectAnimation(card);
    } else if (_isHovering && !widget.isDisabled && widget.onSelect != null) {
      card = _applyHoverAnimation(card);
    }
    
    if (widget.enableFlip && widget.backContent != null) {
      card = _applyFlipAnimation(card);
    }
    
    return widget.onSelect != null 
        ? MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: widget.isDisabled ? null : () {
                if (widget.enableFlip) {
                  _toggleCard();
                } else if (widget.onSelect != null) {
                  widget.onSelect!(widget.policy);
                }
              },
              child: card,
            ),
          )
        : card;
  }
  
  Widget _buildCardBySize() {
    switch (widget.size) {
      case PolicyCardSize.mini:
        return _buildMiniCard();
      case PolicyCardSize.small:
        return _buildSmallCard();
      case PolicyCardSize.full:
        return _buildFullCard();
    }
  }
  
  Widget _buildMiniCard() {
    return Card(
      elevation: widget.isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getColorForDomain(widget.policy.domain).withOpacity(widget.isSelected ? 0.6 : 0.4),
          width: widget.isSelected ? 1.5 : 1.0,
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
                  _getIconForDomain(widget.policy.domain),
                  size: 16,
                  color: _getColorForDomain(widget.policy.domain),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDomainName(widget.policy.domain),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getColorForDomain(widget.policy.domain),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.policy.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.isDisabled ? AppTheme.disabledColor : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.policy.description,
              style: TextStyle(
                fontSize: 11,
                color: widget.isDisabled ? AppTheme.disabledColor : Colors.grey,
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
                'Cost: ${widget.policy.cost} unit${widget.policy.cost > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.isDisabled ? AppTheme.disabledColor : AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard() {
    return Card(
      elevation: widget.isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getColorForDomain(widget.policy.domain).withOpacity(widget.isSelected ? 0.6 : 0.3),
          width: widget.isSelected ? 1.5 : 1.0,
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
                color: _getColorForDomain(widget.policy.domain).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDomainName(widget.policy.domain),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.isDisabled ? AppTheme.disabledColor : _getColorForDomain(widget.policy.domain),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Policy title
            Text(
              widget.policy.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: widget.isDisabled ? AppTheme.disabledColor : null,
              ),
            ),
            const SizedBox(height: 4),
            
            // Cost
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 12,
                  color: widget.isDisabled ? AppTheme.disabledColor : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cost: ${widget.policy.cost} units',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDisabled ? AppTheme.disabledColor : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _scaleAnimation.value : 1.0,
          child: SizedBox(
            width: double.infinity,
            height: 180,
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
                  widget.policy.title,
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
              _buildCostIndicator(widget.policy.cost, context),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              widget.policy.description,
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
  
  // Animation methods
  Widget _applySelectAnimation(Widget child) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    )
      .shimmer(
        duration: const Duration(seconds: 2),
        color: Colors.white.withOpacity(0.3),
        curve: Curves.easeInOutSine,
      )
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
  }

  Widget _applyHoverAnimation(Widget child) {
    return child.animate(
      onPlay: (controller) => controller.forward(),
    )
      .elevation(
        begin: 2,
        end: 8,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      )
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.03, 1.03),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
  }

  Widget _applyFlipAnimation(Widget frontContent) {
    final backContent = widget.backContent ?? const SizedBox.shrink();
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: _isFrontVisible ? pi : 0.0, end: _isFrontVisible ? 0.0 : pi)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
            
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (BuildContext context, Widget? child) {
            final angle = rotate.value;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: angle < pi/2 
                  ? frontContent
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: backContent,
                    ),
            );
          },
        );
      },
      child: _isFrontVisible 
          ? Container(key: const ValueKey('front'), child: frontContent)
          : Container(key: const ValueKey('back'), child: backContent),
    );
  }

  // Utility methods  
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