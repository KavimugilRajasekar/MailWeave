import 'package:flutter/material.dart';

import '../../models/email_thread.dart';
import 'email_tree_node_widget.dart';

/// Renders a conversation's reply tree.
class EmailTreeView extends StatelessWidget {
  const EmailTreeView({super.key, required this.thread, this.gap = 22});

  final EmailThread thread;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (thread.roots.isEmpty) {
      // Defensive fallback: never discard messages — show them flat.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in thread.messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                m.from.name ?? m.from.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final root in thread.roots)
          EmailTreeNodeWidget(key: ValueKey(root.key), node: root, gap: gap),
      ],
    );
  }
}
