import '../models/email_message.dart';
import '../models/email_tree_node.dart';

/// Reconstructs the parent-child hierarchy of a conversation from email
/// headers (`Message-ID`, `In-Reply-To`, `References`), with sensible
/// fallbacks for missing or malformed data.
///
/// Pure logic — no UI, no network.
class EmailTreeBuilder {
  const EmailTreeBuilder();

  /// Build the forest of root [EmailTreeNode]s for [messages]. Every message
  /// is placed — none are discarded, even when their headers are missing or
  /// malformed.
  List<EmailTreeNode> build(List<EmailMessage> messages) {
    if (messages.isEmpty) return const <EmailTreeNode>[];

    // Defensive chronological sort (Gmail returns threads sorted by
    // internalDate, but don't depend on it).
    final ordered = List<EmailMessage>.from(messages)
      ..sort((a, b) {
        final ad = a.date?.millisecondsSinceEpoch;
        final bd = b.date?.millisecondsSinceEpoch;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });

    final nodes = <EmailTreeNode>[
      for (final m in ordered) EmailTreeNode(message: m),
    ];

    // Map a normalized Message-ID -> node (first occurrence wins for dupes).
    final byId = <String, EmailTreeNode>{};
    for (final node in nodes) {
      final mid = node.message.messageId;
      if (mid != null && mid.isNotEmpty) {
        byId.putIfAbsent(mid, () => node);
      }
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final parent = _resolveParent(node, i, nodes, byId);
      if (parent != null &&
          !identical(parent, node) &&
          !_createsCycle(node, parent)) {
        parent.children.add(node);
        node.parent = parent;
      }
      // else: stays a root (never discarded)
    }

    _assignDepths(nodes.where((n) => n.parent == null), 0);
    return nodes.where((n) => n.parent == null).toList(growable: false);
  }

  EmailTreeNode? _resolveParent(
    EmailTreeNode node,
    int index,
    List<EmailTreeNode> nodes,
    Map<String, EmailTreeNode> byId,
  ) {
    // 1. In-Reply-To → a message with that Message-ID.
    final irt = node.message.inReplyTo;
    if (irt != null && irt.isNotEmpty) {
      final match = byId[irt];
      if (match != null && !identical(match, node)) return match;
    }

    // 2. References chain — last matching id first.
    final refs = node.message.references;
    for (var r = refs.length - 1; r >= 0; r--) {
      final match = byId[refs[r]];
      if (match != null && !identical(match, node)) return match;
    }

    // 3. Fallback: the previous message in the thread (chronological).
    if (index > 0) return nodes[index - 1];

    return null;
  }

  /// True when making [parent] an ancestor of [node] would close a loop.
  bool _createsCycle(EmailTreeNode node, EmailTreeNode parent) {
    EmailTreeNode? cursor = parent;
    while (cursor != null) {
      if (identical(cursor, node)) return true;
      cursor = cursor.parent;
    }
    return false;
  }

  void _assignDepths(Iterable<EmailTreeNode> roots, int depth) {
    for (final n in roots) {
      n.depth = depth;
      _assignDepths(n.children, depth + 1);
    }
  }
}
