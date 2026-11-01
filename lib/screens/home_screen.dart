import 'package:flutter/material.dart';

import '../models/inbox_category.dart';
import '../services/auth_service.dart';
import '../services/gmail_service.dart';
import '../widgets/common/empty_mail_view.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/email/conversation_list.dart';

/// The main mail browsing surface shown after a successful OAuth sign-in.
/// The threaded conversation viewer lives here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _lightBlue = Color(0xFF4A9FE3);

  final AuthService _auth = AuthService();
  GmailService? _service;
  bool _loading = true;
  String? _error;
  InboxCategory _category = InboxCategory.primary;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Reuse the existing authenticated Gmail session (read-only scope) and the
  /// user's profile email (to tell sent-vs-received apart).
  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gmail = await _auth.gmailApi();
      if (gmail == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in.';
          _loading = false;
        });
        return;
      }

      String? email;
      try {
        email = (await gmail.users.getProfile('me')).emailAddress;
      } catch (_) {
        // Profile is best-effort; the viewer can still work without it.
      }

      if (!mounted) return;
      setState(() {
        _service = GmailService(gmail, currentUserEmail: email);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load mail.';
        _loading = false;
      });
    }
  }

  /// Top bar: the account icon sits at the top-left, next to the decorative
  /// search field. Neither has functionality yet.
  Widget _topBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _accountButton(cs),
          const SizedBox(width: 10),
          Expanded(child: _searchField(theme, cs)),
        ],
      ),
    );
  }

  /// Blue, circle-outlined account button (no action) — formerly the FAB.
  Widget _accountButton(ColorScheme cs) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(side: BorderSide(color: _lightBlue, width: 2)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: const Icon(Icons.account_circle_outlined, color: _lightBlue),
        ),
      ),
    );
  }

  Widget _searchField(ThemeData theme, ColorScheme cs) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Text(
            'Search mail',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Inbox category filter chips — Primary / Promotions / Social / Updates.
  /// Selecting one reloads the conversation list scoped to that Gmail label.
  Widget _categoryTabs(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            for (var i = 0; i < InboxCategory.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _categoryChip(InboxCategory.values[i], cs, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(InboxCategory c, ColorScheme cs, ThemeData theme) {
    final selected = c == _category;
    return GestureDetector(
      onTap: () => setState(() => _category = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          c.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Widget body;
    if (_loading) {
      body = const LoadingView(message: 'Loading your mail…');
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _bootstrap);
    } else if (_service == null) {
      body = const EmptyMailView();
    } else {
      body = ConversationList(
        service: _service!,
        category: _category,
        key: ValueKey(_category),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _categoryTabs(context),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
