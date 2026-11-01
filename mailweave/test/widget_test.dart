import 'package:flutter_test/flutter_test.dart';
import 'package:mailweave/models/email_message.dart';

void main() {
  test('EmailAddress parses a name + address pair', () {
    final a = EmailAddress.parse('Jane Doe <jane@example.com>');
    expect(a.name, 'Jane Doe');
    expect(a.email, 'jane@example.com');
  });

  test('EmailAddress parses a bare address', () {
    final a = EmailAddress.parse('jane@example.com');
    expect(a.name, isNull);
    expect(a.email, 'jane@example.com');
  });
}
