/// Gmail inbox category tabs, mapped to their Gmail API label ids.
///
/// Used as filter tags above the conversation list. Selecting one restricts
/// `threads.list` to that category label.
enum InboxCategory {
  primary('Primary', 'CATEGORY_PERSONAL'),
  promotions('Promotions', 'CATEGORY_PROMOTIONS'),
  social('Social', 'CATEGORY_SOCIAL'),
  updates('Updates', 'CATEGORY_UPDATES');

  const InboxCategory(this.label, this.gmailLabelId);

  /// Human-readable tab name.
  final String label;

  /// Gmail API label id to pass as `labelIds`.
  final String gmailLabelId;
}
