import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/email_thread.dart';
import '../../models/inbox_category.dart';
import '../../services/gmail_service.dart';
import '../../services/mail_cache.dart';
import '../common/empty_mail_view.dart';
import '../common/error_view.dart';
import '../common/loading_view.dart';
import 'conversation_card.dart';

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
  });

  final GmailService service;
  final InboxCategory category;

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
      setState(() {
        if (merge && hadData) {
          // Keep loaded older mail; insert brand-new conversations at the top
          // and refresh metadata of existing ones (no scroll jump).
          final freshById = {for (final t in page.threads) t.id: t};
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Loading your mail…');
    if (_error != null && _threads.isEmpty) {
      return ErrorView(message: _error!, onRetry: () => _refresh(merge: false));
    }
    if (_threads.isEmpty) return const EmptyMailView();

    // No pull-to-refresh spinner — the list silently auto-refreshes instead.
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _threads.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _threads.length) {
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
        return ConversationCard(
          key: ValueKey(_threads[index].id),
          thread: _threads[index],
        );
      },
    );
  }
}
