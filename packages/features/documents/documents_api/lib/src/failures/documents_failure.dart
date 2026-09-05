import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the documents ports.
sealed class DocumentsFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const DocumentsFailure();
}

/// The document could not be produced.
final class RenderFailed extends DocumentsFailure {
  /// Records that rendering did not complete, with [detail] for the log.
  const RenderFailed({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'RenderFailed(${detail ?? 'no detail'})';
}

/// The operation will not produce this document, and asking again will not
/// help.
///
/// A waybill for a parcel that was never accepted, a receipt for a delivery
/// that has not happened. Distinct from [RenderFailed] because one is worth
/// retrying and the other is worth explaining.
final class DocumentRefused extends DocumentsFailure {
  /// Records the refusal, with [reason] for a person to read.
  const DocumentRefused({required this.reason});

  /// Why the operation said no.
  final String reason;

  @override
  String toString() => 'DocumentRefused($reason)';
}

/// The archive could not be read or written.
final class ArchiveUnavailable extends DocumentsFailure {
  /// Records that the archive did not answer, with [detail] for the log.
  const ArchiveUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'ArchiveUnavailable(${detail ?? 'no detail'})';
}

/// There is no document under the identifier that was asked for.
///
/// The ordinary outcome of an archive that evicts: a document from three weeks
/// ago is gone, and the answer is to produce it again rather than to report a
/// fault.
final class DocumentMissing extends DocumentsFailure {
  /// Records that [id] is not in the archive.
  const DocumentMissing(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'DocumentMissing($id)';
}

/// A value a document carries was refused at construction.
final class MalformedDocument extends DocumentsFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedDocument({required this.field, required this.reason});

  /// Which part refused its value.
  final String field;

  /// Why it was refused.
  final String reason;

  @override
  String toString() => 'MalformedDocument($field: $reason)';
}
