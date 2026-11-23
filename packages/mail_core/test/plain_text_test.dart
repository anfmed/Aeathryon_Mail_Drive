import 'package:mail_core/mail_core.dart';
import 'package:test/test.dart';

void main() {
  test('scripts, styles and comments are dropped', () {
    final t = htmlToPlainText(
      '<html><head><title>x</title><style>p{}</style></head><body>Hi<script>alert(1)</script><!-- c -->there</body></html>',
    );
    expect(t, 'Hithere');
  });
  test('block tags become newlines; entities decoded', () {
    expect(htmlToPlainText('<p>A &amp; B</p><p>x &lt; y</p>'), 'A & B\nx < y');
  });
  test('encoded markup stays inert text', () {
    expect(
      htmlToPlainText('&lt;script&gt;alert(1)&lt;/script&gt;'),
      '<script>alert(1)</script>',
    );
  });
  test('numeric entities, invalid ones removed', () {
    expect(htmlToPlainText('&#65;&#x42;&#0;&#xD800;'), 'AB');
  });
  test('img tags (tracking pixels) vanish, nothing is fetched', () {
    expect(htmlToPlainText('Hello<img src="http://t.example/p.gif">'), 'Hello');
  });
  test('whitespace collapsed', () {
    expect(htmlToPlainText('a   b<br><br><br><br>c'), 'a b\n\nc');
  });
}
