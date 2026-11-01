import 'email_message.dart';

/// A node in a reconstructed conversation tree.
class EmailTreeNode {
  EmailTreeNode({required this.message, this.depth = 0});

  final EmailMessage message;

  /// Indentation level; assigned after the tree is built.
  int depth;

  /// The logical parent of this message, or `null` for a root.
  EmailTreeNode? parent;

  /// Direct replies to this message.
  final List<EmailTreeNode> children = [];

  bool get hasChildren => children.isNotEmpty;

  /// Stable identity for widget keys (Gmail message id).
  String get key => message.id;
}
