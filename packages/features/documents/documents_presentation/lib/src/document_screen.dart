import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter/widgets.dart';

import 'document_controller.dart';
import 'document_state.dart';
import 'documents_strings.dart';

/// Where a piece of paperwork is shown.
///
/// **It does not render the document.** A PDF viewer is a platform capability
/// and this package may not depend on one; what the screen shows is the
/// document's identity and size, and an app that has a viewer puts it where
/// the placeholder is.
final class DocumentScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const DocumentScreen({required this.controller, super.key});

  /// What drives it.
  final DocumentController controller;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `DocumentsFailure`. The two that matter to a courier are
  /// the first two, and they are different keys on purpose: one says try
  /// again, the other says stop trying.
  @visibleForTesting
  static String describe(DocumentsFailure failure) => switch (failure) {
    RenderFailed() => DocumentsStrings.failureRenderFailed,
    DocumentRefused() => DocumentsStrings.failureRefused,
    ArchiveUnavailable() => DocumentsStrings.failureArchiveUnavailable,
    DocumentMissing() => DocumentsStrings.failureMissing,
    MalformedDocument() => DocumentsStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(DocumentsFailure failure) =>
      switch (failure) {
        DocumentRefused(:final reason) => {'reason': reason},
        RenderFailed() ||
        ArchiveUnavailable() ||
        DocumentMissing() ||
        MalformedDocument() => const {},
      };

  /// Whether producing it again is the answer to [failure].
  ///
  /// A refusal is not: the operation has decided, and asking twice gets the
  /// same answer with a longer wait. Everything else is transient — including
  /// a corrupt stored copy, because this is the one archive in the workspace
  /// whose contents can be produced again.
  @visibleForTesting
  static bool canRetry(DocumentsFailure failure) => switch (failure) {
    DocumentRefused() => false,
    RenderFailed() ||
    ArchiveUnavailable() ||
    DocumentMissing() ||
    MalformedDocument() => true,
  };
}

class _DocumentScreenState extends State<DocumentScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(DocumentsStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          DocumentIdle() || DocumentLoading() => const PeykLoadingView(),
          DocumentReady(:final document) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PeykListRow(
                title: strings.resolve(
                  DocumentsStrings.kind(document.kind),
                ),
                subtitle: strings.resolve(
                  DocumentsStrings.size,
                  arguments: {'bytes': document.sizeInBytes},
                ),
              ),
              if (widget.controller.canShare) ...[
                const PeykGap.vertical(PeykGapSize.betweenGroups),
                PeykButton(
                  label: strings.resolve(DocumentsStrings.share),
                  onPressed: widget.controller.share,
                  tone: PeykButtonTone.primary,
                ),
              ],
            ],
          ),
          DocumentFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              DocumentScreen.describe(failure),
              arguments: DocumentScreen.argumentsFor(failure),
            ),
            onRetry: DocumentScreen.canRetry(failure)
                ? () => unawaited(widget.controller.load())
                : null,
          ),
        },
      ),
    );
  }
}
