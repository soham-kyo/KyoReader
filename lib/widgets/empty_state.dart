import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Animate(
              effects: [
                ScaleEffect(duration: 400.ms, curve: Curves.elasticOut),
                FadeEffect(duration: 300.ms),
              ],
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Animate(
              delay: 100.ms,
              effects: [
                FadeEffect(duration: 300.ms),
                SlideEffect(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
              ],
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Animate(
              delay: 150.ms,
              effects: [FadeEffect(duration: 300.ms)],
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              Animate(
                delay: 200.ms,
                effects: [
                  FadeEffect(duration: 300.ms),
                  SlideEffect(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                    duration: 300.ms,
                  ),
                ],
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
