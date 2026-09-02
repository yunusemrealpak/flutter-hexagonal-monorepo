@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

/// The vocabulary a port answers a collection in.
///
/// It is here rather than in a feature for the reason `Result` is: it carries
/// no domain meaning at all. A `ShipmentSummary` is shipments'; *there are more
/// rows and here is where to resume* is nobody's, and a copy of it per feature
/// would be identical code in fourteen `_api` packages.
void main() {
  group('PageRequest', () {
    test('asks for a bounded number of rows by default', () {
      // The default exists so that a caller who has not thought about it still
      // cannot ask a server for a hundred thousand stops.
      expect(const PageRequest().limit, PageRequest.defaultLimit);
      expect(const PageRequest().after, isNull);
    });

    test('clamps a limit rather than failing on one', () {
      // A limit of zero or of ten thousand is a programming error, not user
      // input, and there is no screen that could show its failure. Clamping
      // keeps `PageRequest` free of a failure branch every call site would
      // have to write and none could act on.
      expect(const PageRequest(limit: 0).limit, 1);
      expect(const PageRequest(limit: 100000).limit, PageRequest.maxLimit);
    });

    test('carries the cursor it is resuming from', () {
      const request = PageRequest(after: PageCursor('SHP-42'));

      expect(request.after, const PageCursor('SHP-42'));
    });
  });

  group('Page', () {
    test('a page with no cursor is the last one', () {
      const page = Page<int>(items: [1, 2, 3]);

      expect(page.hasMore, isFalse);
    });

    test('a page with one has somewhere to resume from', () {
      const page = Page<int>(items: [1], next: PageCursor('c'));

      expect(page.hasMore, isTrue);
    });

    test('maps its rows without losing where it ends', () {
      // What an adapter does after decoding: the cursor belongs to the page,
      // not to the rows, so mapping the rows must not drop it.
      const page = Page<int>(items: [1, 2], next: PageCursor('c'));

      final mapped = page.map((value) => '$value');

      expect(mapped.items, ['1', '2']);
      expect(mapped.next, const PageCursor('c'));
    });

    test('an empty last page is not an error', () {
      // A courier with nothing on their manifest and a courier whose manifest
      // ran out on the previous page produce the same value, and neither went
      // wrong.
      expect(const Page<int>(items: []).hasMore, isFalse);
    });
  });

  group('PageCursor', () {
    test('two cursors over the same marker are the same cursor', () {
      expect(const PageCursor('a'), const PageCursor('a'));
    });

    test('is not interchangeable with the identifier it may look like', () {
      // The reason it is a wrapper. A cursor is opaque to everyone but the
      // source that produced it, and a bare `String` invites a caller to pass
      // the last row's id — which is only correct by accident.
      expect(const PageCursor('SHP-1').value, 'SHP-1');
      expect(const PageCursor('a').toString(), contains('a'));
    });
  });
}
