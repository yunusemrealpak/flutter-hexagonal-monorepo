// The three types below are one vocabulary and are read together, so they
// share a library for the same reason `Result`'s three do.
//
// `avoid_equals_and_hash_code_on_mutable_classes` wants an `@immutable`
// annotation as proof of immutability, and that annotation lives in
// `package:meta`. core_kernel takes no third-party dependency, so the proof is
// structural instead: every field is final and every constructor is const.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

// Imported so that the doc reference to [Result] resolves. It is the type this
// one is argued against, and the argument is the reason the file exists.
import 'result.dart';

/// One page of a collection a port would not send all of.
///
/// **Why this is in core_kernel and a `ShipmentSummary` is not.** The test is
/// whether the type carries domain meaning. *There are more rows, and here is
/// where to resume* carries none: it is the same statement for a courier's
/// manifest, a shipment's delivery history and a dispatcher's board, and a
/// copy of it per feature would be identical code in fourteen `_api` packages
/// with fourteen chances to disagree about what an absent cursor means. That
/// is the same argument [Result] makes, and it is the only argument that gets
/// a type in here — a type with domain meaning belongs to the feature that
/// owns the meaning.
///
/// **An empty page is not a failure.** A courier with nothing assigned and a
/// courier whose manifest ran out on the previous page produce the same value,
/// and nothing went wrong in either case.
final class Page<T> {
  /// Creates a page over [items], resumable at [next] when there is more.
  const Page({required this.items, this.next});

  /// The rows, in the order the port promised.
  final List<T> items;

  /// Where to resume, or `null` when this is the last page.
  ///
  /// The absence of a cursor is the *only* signal that a collection is
  /// exhausted. A short page is not one: a filtered source can answer fewer
  /// rows than asked for and still have more behind them, and a caller that
  /// stopped on `items.length < limit` would silently truncate.
  final PageCursor? next;

  /// Whether asking again would produce anything.
  bool get hasMore => next != null;

  /// Applies [transform] to every row, keeping where the page ends.
  ///
  /// What an adapter reaches for after decoding. The cursor belongs to the
  /// page rather than to the rows, so mapping the rows must not drop it —
  /// which is exactly what a bare `items.map(...)` at a call site would do.
  Page<R> map<R>(R Function(T item) transform) =>
      Page<R>(items: [for (final item in items) transform(item)], next: next);

  @override
  String toString() => 'Page(${items.length} items, next: $next)';
}

/// What a caller asks a port for when the collection is too big to send.
///
/// It is not a value object with a validating factory, and that is deliberate.
/// A limit of zero or of ten thousand is a programming error rather than user
/// input: there is no screen that could render its failure and no person who
/// could correct it. Clamping keeps a failure branch out of every call site
/// that none of them could act on — the same reasoning §3 of CLAUDE.md gives
/// for `Clock.now()` returning a plain value.
final class PageRequest {
  /// Asks for at most [limit] rows, resuming after [after].
  const PageRequest({int limit = defaultLimit, this.after})
    : limit = limit < 1 ? 1 : (limit > maxLimit ? maxLimit : limit);

  /// How many rows a caller that has not thought about it gets.
  ///
  /// Fifty, which is roughly two screens on a phone. The number matters less
  /// than the default existing at all: without one, a caller who forgot to
  /// pass a limit would ask a server for every stop the operation has.
  static const int defaultLimit = 50;

  /// The most rows any single request may ask for.
  ///
  /// A ceiling rather than a suggestion. It is the thing that stops a bug — or
  /// a caller trying to be clever about round trips — from turning a paged
  /// port back into an unbounded one.
  static const int maxLimit = 200;

  /// How many rows this request wants, clamped to `[1, maxLimit]`.
  final int limit;

  /// Where the previous page ended, or `null` for the first page.
  final PageCursor? after;

  /// The request that continues [page], or `null` when there is nothing left.
  PageRequest? following(Page<Object?> page) =>
      page.next == null ? null : PageRequest(limit: limit, after: page.next);

  @override
  String toString() => 'PageRequest(limit: $limit, after: $after)';
}

/// A marker naming where a page ended.
///
/// **Opaque to everyone but the source that produced it.** It may be an
/// identifier, an offset, a signed token or a timestamp — that is the
/// adapter's business, and a caller that reads one has coupled itself to an
/// adapter it is not allowed to name.
///
/// The consequence is worth stating because it is easy to get wrong: a cursor
/// from one adapter is meaningless to another, so a use case that falls back
/// from a gateway to a cache mid-sequence cannot carry the cursor across. It
/// has to start again, or refuse. `LoadManifest` refuses, and says why.
///
/// A wrapper rather than a bare `String` for the reason `ValueObject`'s doc
/// gives: it distinguishes this string from every other one in the system, and
/// in particular from the row identifier it will often resemble.
final class PageCursor {
  /// Wraps [value], whatever the source meant by it.
  const PageCursor(this.value);

  /// The marker, as the source wrote it.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageCursor &&
          other.runtimeType == runtimeType &&
          other.value == value);

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'PageCursor($value)';
}
