import 'package:flutter/material.dart';

import '../../models/email_thread.dart';

/// A conversation summary. Tapping opens the full conversation tree page.
class ConversationCard extends StatefulWidget {
  const ConversationCard({super.key, required this.thread, required this.onOpen});

  final EmailThread thread;

  /// Invoked when the card is tapped — opens the conversation tree page.
  final VoidCallback onOpen;

  @override
  State<ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<ConversationCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = widget.thread;
    final time = t.latestDate == null ? '' : _format(t.latestDate!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                t.subject.isEmpty ? '(no subject)' : t.subject,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: t.hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, runSpacing: 2, children: _participantChips(t, cs)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (t.hasAttachments)
                            Icon(Icons.attach_file, size: 14, color: cs.onSurfaceVariant),
                          if (t.hasAttachments) const SizedBox(width: 4),
                          Text('${t.messageCount}',
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
              if (t.hasUserReply) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [_tag(Icons.reply, 'Replied', cs)]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _participantChips(EmailThread t, ColorScheme cs) {
    final chips = <Widget>[];
    for (final a in t.participants.take(3)) {
      final label = a.name ?? a.email ?? '';
      chips.add(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    if (t.participants.length > 3) {
      chips.add(
        Text('+${t.participants.length - 3}',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      );
    }
    return chips;
  }

  Widget _tag(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onPrimaryContainer),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer)),
        ],
      ),
    );
  }

  String _format(DateTime d) {
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}';
  }
}
