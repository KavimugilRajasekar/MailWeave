import 'package:flutter/material.dart';

import '../../models/email_message.dart';
import '../../services/note_store.dart';
import 'email_metadata.dart';

/// A compact card representing a single message inside a conversation tree.
///
/// Tapping the card hands off to the Gmail app (no in-app reading). A pencil
/// icon lets the user attach a private note, stored on-device.
class EmailMessageCard extends StatefulWidget {
  const EmailMessageCard({
    super.key,
    required this.message,
    required this.isRoot,
    required this.hasChildren,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTap,
  });

  final EmailMessage message;
  final bool isRoot;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;

  @override
  State<EmailMessageCard> createState() => _EmailMessageCardState();
}

class _EmailMessageCardState extends State<EmailMessageCard> {
  final NoteStore _notes = NoteStore();
  String? _note;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await _notes.read(widget.message.id);
    if (!mounted) return;
    setState(() => _note = (note == null || note.isEmpty) ? null : note);
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Add a note for this email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _notes.write(widget.message.id, result);
    if (!mounted) return;
    setState(() => _note = result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = widget.message;

    final senderName = m.from.name ?? m.from.email ?? 'Unknown';
    final time = m.date == null ? '' : _formatTime(m.date!);

    return Material(
      color: m.isFromCurrentUser
          ? cs.primaryContainer.withValues(alpha: 0.25)
          : cs.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: senderName, isYou: m.isFromCurrentUser),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: m.unread ? FontWeight.w700 : FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        EmailMetadata(message: m),
                      ],
                    ),
                  ),
                  // Pencil: attach / edit a private note for this email.
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _editNote,
                    icon: Icon(
                      _note == null ? Icons.edit_outlined : Icons.edit_note,
                      color: cs.onSurfaceVariant,
                    ),
                    tooltip: _note == null ? 'Add note' : 'Edit note',
                  ),
                  if (widget.hasChildren)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onToggleExpand,
                      icon: Icon(
                        widget.expanded ? Icons.expand_less : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: widget.expanded ? 'Collapse' : 'Expand',
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Subject — wraps fully instead of being cut to one line.
              Text(
                m.subject.isEmpty ? '(no subject)' : m.subject,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
              if (_note != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 13, color: cs.onSecondaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isYou});

  final String name;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isYou ? cs.primary : cs.surfaceContainerHighest,
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isYou ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts[0][0];
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts[1][0]).toUpperCase();
  }
}
