import 'package:flutter/material.dart';

import '../../models/email_message.dart';

/// A compact metadata row under a message sender: recipients + status flags.
class EmailMetadata extends StatelessWidget {
  const EmailMetadata({super.key, required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final chips = <Widget>[];
    if (message.isFromCurrentUser) {
      chips.add(_chip(Icons.send_outlined, 'You', cs));
    } else {
      chips.add(_chip(Icons.download_outlined, 'Received', cs));
    }
    if (message.forwarded) {
      chips.add(_chip(Icons.forward_outlined, 'Fwd', cs));
    }
    if (message.hasAttachments) {
      chips.add(_chip(Icons.attach_file, '', cs, iconOnly: true));
    }
    if (message.unread) {
      chips.add(_chip(Icons.fiber_manual_record, '', cs, iconOnly: true));
    }

    final recipients = _recipientSummary(message);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (recipients.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              recipients,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ...chips,
      ],
    );
  }

  String _recipientSummary(EmailMessage m) {
    if (m.to.isEmpty) return '';
    final to = m.to.map((a) => a.name ?? a.email ?? '').where((s) => s.isNotEmpty).join(', ');
    return to.isEmpty ? '' : 'to $to';
  }

  Widget _chip(IconData icon, String label, ColorScheme cs, {bool iconOnly = false}) {
    final content = iconOnly
        ? Icon(icon, size: 12, color: cs.onSurfaceVariant)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 3 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: content,
    );
  }
}
