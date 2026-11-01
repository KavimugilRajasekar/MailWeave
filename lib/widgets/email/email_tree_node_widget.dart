import 'package:flutter/material.dart';

import '../../models/email_tree_node.dart';
import '../../services/email_opener.dart';
import 'email_connector.dart';
import 'email_message_card.dart';

/// Renders one node of the conversation tree and (when expanded) its replies.
class EmailTreeNodeWidget extends StatefulWidget {
  const EmailTreeNodeWidget({super.key, required this.node, this.gap = 22});

  final EmailTreeNode node;
  final double gap;

  @override
  State<EmailTreeNodeWidget> createState() => _EmailTreeNodeWidgetState();
}

class _EmailTreeNodeWidgetState extends State<EmailTreeNodeWidget> {
  // Show the first two levels by default; collapse deeper replies.
  late bool _expanded = widget.node.depth < 2;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    // Cap indentation so deep threads never push content off narrow screens.
    final displayDepth = n.depth.clamp(0, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmailConnector(gap: widget.gap, depth: displayDepth),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 2, bottom: 6),
                child: EmailMessageCard(
                  message: n.message,
                  isRoot: n.depth == 0,
                  hasChildren: n.hasChildren,
                  expanded: _expanded,
                  onToggleExpand: _toggle,
                  onTap: () => EmailOpener.openInGmail(n.message.threadId),
                ),
              ),
            ),
          ],
        ),
        if (_expanded && n.hasChildren)
          ...n.children.map(
            (c) => EmailTreeNodeWidget(key: ValueKey(c.key), node: c, gap: widget.gap),
          ),
      ],
    );
  }
}
