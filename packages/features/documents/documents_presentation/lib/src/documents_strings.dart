import 'package:documents_api/documents_api.dart';

/// Every string key this package asks an app to answer.
abstract final class DocumentsStrings {
  /// The document screen's title.
  static const String title = 'documents.title';

  /// The action that hands the document to another app.
  static const String share = 'documents.share';

  /// How large the document is. Takes a `bytes` argument.
  ///
  /// A key rather than a formatted number, because "1.2 MB" and "1,2 MB" are
  /// the same size written two ways and only the app knows which is right.
  static const String size = 'documents.size';

  /// The document could not be produced, and trying again may work.
  static const String failureRenderFailed = 'documents.failure.renderFailed';

  /// The operation will not produce it. Takes a `reason` argument.
  static const String failureRefused = 'documents.failure.refused';

  /// The stored copy could not be read.
  static const String failureArchiveUnavailable =
      'documents.failure.archiveUnavailable';

  /// The document is no longer stored.
  static const String failureMissing = 'documents.failure.missing';

  /// The stored copy could not be understood.
  static const String failureMalformed = 'documents.failure.malformed';

  /// The key for one kind of document.
  static String kind(DocumentKind kind) => 'documents.kind.${kind.name}';

  /// Every key above, for an app's coverage test.
  static final List<String> all = [
    title,
    share,
    size,
    failureRenderFailed,
    failureRefused,
    failureArchiveUnavailable,
    failureMissing,
    failureMalformed,
    for (final value in DocumentKind.values) kind(value),
  ];
}
