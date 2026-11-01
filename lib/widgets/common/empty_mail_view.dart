import 'package:flutter/material.dart';

/// Centered empty state when there are no conversations.
class EmptyMailView extends StatelessWidget {
  const EmptyMailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No conversations here', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Conversations you receive will appear as trees here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
