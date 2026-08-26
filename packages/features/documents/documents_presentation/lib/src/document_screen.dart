import 'dart:async';

import 'package:documents_api/documents_api.dart';
import 'package:flutter/widgets.dart';

import 'document_controller.dart';
import 'document_state.dart';

/// Where a piece of paperwork is shown.
///
/// **It does not render the document.** A PDF viewer is a platform capability
/// and this package may not depend on one; what the screen shows is the
/// document's identity and size, and an app that has a viewer puts it where
/// the placeholder is. Deliberately plain otherwise: `design_system` arrives in
/// phase 7.
final class DocumentScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const DocumentScreen({required this.controller, super.key});

  /// What drives it.
  final DocumentController controller;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `DocumentsFailure`. The two that matter to a courier are
  /// the first two, and they are different sentences on purpose: one says try
  /// again, the other says stop trying.
  static String describe(DocumentsFailure failure) => switch (failure) {
    RenderFailed() => 'This document could not be produced. Try again.',
    DocumentRefused(:final reason) =>
      'The operation will not produce it: '
          '$reason',
    ArchiveUnavailable() => 'The stored copy could not be read.',
    DocumentMissing() => 'That document is no longer stored.',
    MalformedDocument() => 'That document could not be read.',
  };
}

class _DocumentScreenState extends State<DocumentScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      DocumentIdle() || DocumentLoading() => const Text('documents.loading'),
      DocumentReady(:final document) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('documents.kind.${document.kind.name}'),
          Text('${document.sizeInBytes}'),
          if (widget.controller.canShare)
            GestureDetector(
              onTap: widget.controller.share,
              child: const Text('documents.share'),
            ),
        ],
      ),
      DocumentFailed(:final failure) => Text(
        DocumentScreen.describe(failure),
      ),
    },
  );
}
