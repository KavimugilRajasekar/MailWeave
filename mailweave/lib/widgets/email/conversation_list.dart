import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/email_thread.dart';
import '../../models/inbox_category.dart';
import '../../services/gmail_service.dart';
import '../../services/mail_cache.dart';
import '../../screens/conversation_tree_screen.dart';
import '../common/empty_mail_view.dart';
import '../common/error_view.dart';
import '../common/loading_view.dart';
import 'conversation_card.dart';

/// Lets a parent (e.g. the home screen's "load older" button) trigger the
/// list's pagination manually.
class ConversationListController {
  Future<void> Function()? _loadMore;

  void _attach(Future<void> Function() loadMore) => _loadMore = loadMore;

  /// Manually fetch the next (older) page of conversations. No-op when the
  /// list is already loading more or there are no further pages.
  Future<void> loadMore() => _loadMore?.call() ?? Future<void>.value();
}

/// Paginated conversation list.
///
/// - Shows cached mail instantly, then refreshes from Gmail in the background.
/// - Auto-refreshes every few seconds (silently — no top loading spinner).
/// - Loads older conversations as the user scrolls down.
class ConversationList extends StatefulWidget {
  const ConversationList({
    super.key,
    required this.service,
    required this.category,
    this.autoRefreshInterval = const Duration(seconds: 3),
    this.cache,
    this.controller,
  });

  final GmailService service;
  final InboxCategory category;

  /// Optional handle a parent can use to trigger "load older" manually.
  final ConversationListController? controller;

  /// Background refresh cadence. Pass [Duration.zero] to disable (e.g. tests).
  final Duration autoRefreshInterval;

  /// Optional cache injection (tests pass an in-memory store).
  final MailCache? cache;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final ScrollController _controller = ScrollController();
  final List<EmailThread> _threads = <EmailThread>[];
  late final MailCache _cache;
  String? _nextPageToken;
  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _cache = widget.cache ?? MailCache();
    _controller.addListener(_onScroll);
    widget.controller?._attach(_loadMore);
    _init();
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cached = await _cache.load(widget.category);
    if (!mounted) return;
    if (cached != null) {
      _threads.addAll(cached.threads);
      _nextPageToken = cached.nextPageToken;
      setState(() {
        _loading = false;
        _error = null;
      });
      await _refresh(merge: false);
    } else {
      setState(() => _loading = true);
      await _refresh(merge: false);
    }
    if (!mounted || widget.autoRefreshInterval <= Duration.zero) return;
    _autoRefresh =
        Timer.periodic(widget.autoRefreshInterval, (_) => _autoRefreshTick());
  }

  void _autoRefreshTick() {
    if (!mounted || _loading || _refreshing || _loadingMore) return;
    _refresh(merge: true);
  }

  Future<void> _refresh({bool merge = false}) async {
    if (_refreshing || _loadingMore) return;
    final hadData = _threads.isNotEmpty;
    if (!hadData && !merge) setState(() => _loading = true);
    setState(() => _refreshing = true);
    try {
      final page =
          await widget.service.listConversations(category: widget.category);
      if (!mounted) return;

      // Fresh versions of every conversation returned in the latest first
      // page of the inbox.
      final freshById = <String, EmailThread>{
        for (final t in page.threads) t.id: t,
      };

      // Re-check every already-loaded conversation that wasn't in that fresh
      // first page, so branch growth (new replies) on older loaded threads is
      // detected too — not just the top of the inbox.
      if (merge && hadData) {
        final olderIds = _threads
            .where((t) => !freshById.containsKey(t.id))
            .map((t) => t.id)
            .toList();
        freshById.addAll(await _recheckThreads(olderIds));
      }

      setState(() {
        if (merge && hadData) {
          // Keep loaded older mail; insert brand-new conversations at the top
          // and refresh metadata of existing ones (no scroll jump).
          final existingIds = _threads.map((t) => t.id).toSet();
          final newOnes =
              page.threads.where((t) => !existingIds.contains(t.id)).toList();
          final updated = _threads.map((t) => freshById[t.id] ?? t).toList();
          _threads
            ..clear()
            ..addAll(newOnes)
            ..addAll(updated);
        } else {
          _threads
            ..clear()
            ..addAll(page.threads);
          _nextPageToken = page.nextPageToken;
        }
        _loading = false;
        _refreshing = false;
        _error = null;
      });
      await _persist();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        if (_threads.isEmpty) {
          _error = 'Unable to load mail. Check your connection and try again.';
          _loading = false;
        }
        // otherwise keep showing cached / loaded mail
      });
    }
  }

  /// Re-fetch the given conversation ids (in parallel) and return the ones
  /// whose reply tree has grown or whose metadata changed, keyed by thread id.
  Future<Map<String, EmailThread>> _recheckThreads(List<String> ids) async {
    if (ids.isEmpty) return <String, EmailThread>{};
    final fetched =
        await Future.wait(ids.map((id) => widget.service.fetchThread(id)));
    final changed = <String, EmailThread>{};
    for (var i = 0; i < ids.length; i++) {
      final fresh = fetched[i];
      if (fresh == null) continue;
      final old = _findThread(ids[i]);
      if (old == null) continue;
      if (_threadChanged(old, fresh)) changed[ids[i]] = fresh;
    }
    return changed;
  }

  EmailThread? _findThread(String id) {
    for (final t in _threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// True when [fresh] differs from [old] in a way the UI should reflect: a new
  /// or removed message (branch growth), a latest-date change, or a flip in
  /// read / replied / attachment flags.
  bool _threadChanged(EmailThread old, EmailThread fresh) {
    if (fresh.messageCount != old.messageCount) return true;
    if (fresh.latestDate != old.latestDate) return true;
    if (fresh.hasUnread != old.hasUnread) return true;
    if (fresh.hasUserReply != old.hasUserReply) return true;
    if (fresh.hasAttachments != old.hasAttachments) return true;
    final oldIds = old.messages.map((m) => m.id).toSet();
    final newIds = fresh.messages.map((m) => m.id).toSet();
    return oldIds.length != newIds.length || !oldIds.containsAll(newIds);
  }

  Future<void> _persist() async {
    try {
      await _cache.save(widget.category, _threads, _nextPageToken);
    } catch (_) {
      // Caching is best-effort; ignore storage failures.
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _refreshing || _nextPageToken == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.service.listConversations(
        category: widget.category,
        pageToken: _nextPageToken,
      );
      if (!mounted) return;
      final existing = _threads.map((t) => t.id).toSet();
      final added = page.threads.where((t) => !existing.contains(t.id)).toList();
      setState(() {
        _threads.addAll(added);
        _nextPageToken = page.nextPageToken;
        _loadingMore = false;
      });
      await _persist();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  /// Open a conversation in the full-screen tree visualiser.
  void _openTree(EmailThread t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationTreeScreen(
          service: widget.service,
          thread: t,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Loading your mail…');
    if (_error != null && _threads.isEmpty) {
      return ErrorView(message: _error!, onRetry: () => _refresh(merge: false));
    }
    if (_threads.isEmpty) return const EmptyMailView();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Date-grouped layout: a top divider, then per date group a header
    // followed by its mails. Every mail is trailed by a divider, which also
    // separates consecutive mails, separates groups, and closes the list —
    // matching the "divider, header, mail, divider, mail, divider, header…"
    // pattern.
    final rows = <Widget>[];
    String? lastDayKey;
    for (final t in _threads) {
      final d = t.latestDate;
      final dayKey = d == null ? '' : '${d.year}-${d.month}-${d.day}';
      if (dayKey != lastDayKey) {
        if (rows.isEmpty) rows.add(_divider(cs));
        rows.add(_dateHeader(_dateLabel(d), theme, cs));
        lastDayKey = dayKey;
      }
      rows.add(ConversationCard(
        key: ValueKey(t.id),
        thread: t,
        onOpen: () => _openTree(t),
      ));
      rows.add(_divider(cs));
    }

    // No pull-to-refresh spinner — the list silently auto-refreshes instead.
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: rows.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return rows[index];
      },
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, thickness: 0.5, color: cs.outlineVariant);

  Widget _dateHeader(String label, ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 6),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// "Today" / "Yesterday" / dd-MM-yyyy for everything older.
  String _dateLabel(DateTime? d) {
    if (d == null) return 'Undated';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}
