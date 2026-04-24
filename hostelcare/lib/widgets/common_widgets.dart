import 'package:flutter/material.dart';

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  Color get _color {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'in_progress': return Colors.indigo;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get _label => status.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(_label, style: TextStyle(color: _color, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
  }
}

/// Priority indicator widget
class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _color {
    switch (priority) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.deepOrange;
      case 'urgent': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(priority[0].toUpperCase() + priority.substring(1), style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Empty state placeholder widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ]),
      ),
    );
  }
}

/// Gradient card wrapper
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsets? padding;

  const GradientCard({super.key, required this.colors, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// Shimmer loading placeholder
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({super.key, this.width = double.infinity, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
