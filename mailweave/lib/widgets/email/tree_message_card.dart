import 'package:flutter/material.dart';

import '../../models/email_message.dart';
import '../../services/email_opener.dart';

/// A compact, fixed-size card representing one message on the conversation
/// canvas. Tapping opens the original email in Gmail; the chevron folds the
/// branch (handled by the parent page's re-layout).
class TreeMessageCard extends StatelessWidget {
  const TreeMessageCard({
    super.key,
    required this.message,
    required this.isRoot,
    required this.hasChildren,
    required this.expanded,
    required this.onToggleExpand,
  });

  final EmailMessage message;
  final bool isRoot;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = message;

    final senderName = m.from.name ?? m.from.email ?? 'Unknown';
    final time = m.date == null ? '' : _formatTime(m.date!);
    final toNames = _names(m.to);
    final ccNames = _names(m.cc);
    final bccNames = _names(m.bcc);

    return Material(
      color: m.isFromCurrentUser
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : cs.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EmailOpener.openInGmail(m.threadId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: senderName, isYou: m.isFromCurrentUser),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: m.unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
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
                        const SizedBox(height: 4),
                        if (toNames.isNotEmpty)
                          _recipientLine('To', toNames, theme, cs),
                        if (ccNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          _recipientLine('Cc', ccNames, theme, cs),
                        ],
                        if (bccNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          _recipientLine('Bcc', bccNames, theme, cs),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _StatusIcons(message: m, cs: cs),
                  if (hasChildren)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onToggleExpand,
                      icon: Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: expanded ? 'Collapse branch' : 'Expand branch',
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                m.subject.isEmpty ? '(no subject)' : m.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Join up to two recipient names, with "+n" for the rest. '' when empty.
  String _names(List<EmailAddress> addrs) {
    final names = addrs
        .map((a) => a.name ?? a.email ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    final shown = names.take(2).join(', ');
    return names.length > 2 ? '$shown +${names.length - 2}' : shown;
  }

  /// A one-line, ellipsised "Label: names" row with the label emphasised so the
  /// recipient type (To / Cc / Bcc) is called out.
  Widget _recipientLine(
      String label, String names, ThemeData theme, ColorScheme cs) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: names),
        ],
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

class _StatusIcons extends StatelessWidget {
  const _StatusIcons({required this.message, required this.cs});

  final EmailMessage message;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.unread)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.circle, size: 8, color: cs.primary),
          ),
        if (message.forwarded)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.forward, size: 14, color: cs.onSurfaceVariant),
          ),
        if (message.hasAttachments)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.attach_file, size: 14, color: cs.onSurfaceVariant),
          ),
      ],
    );
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
