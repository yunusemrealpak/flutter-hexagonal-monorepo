import 'package:design_system/design_system.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../documents_strings.dart';
import 'document_bloc.dart';
import 'document_event.dart';
import 'document_state.dart';

/// Where a piece of paperwork is shown.
///
/// **It does not render the document.** A PDF viewer is a platform capability
/// and this package may not depend on one; what the screen shows is the
/// document's identity and size, and an app that has a viewer puts it where
/// the placeholder is.
/// The bloc arrives through the widget tree: whoever mounts this screen puts a
/// [DocumentBloc] above it with `BlocProvider`.
final class DocumentScreen extends StatefulWidget {
  /// Creates the screen.
  const DocumentScreen({super.key});

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
    // Asking is the screen's job. An app that had to remember to dispatch this
    // would be an app that forgets it on the second route that mounts the
    // screen.
    context.read<DocumentBloc>().add(const DocumentRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(DocumentsStrings.title),
      // No `buildWhen`. `DocumentReady` can follow `DocumentReady` — that is
      // what producing the document again does — so narrowing on the state's
      // case would leave the previous render's size on screen. `buildWhen`
      // pays where a `BlocSelector` sits under it and the repeated case is
      // drawn by the selector, which is `CollectionScreen`'s shape.
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) => switch (state) {
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
              if (context.read<DocumentBloc>().canShare) ...[
                const PeykGap.vertical(PeykGapSize.betweenGroups),
                PeykButton(
                  label: strings.resolve(DocumentsStrings.share),
                  onPressed: () => context.read<DocumentBloc>().add(
                    const DocumentShared(),
                  ),
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
                ? () => context.read<DocumentBloc>().add(
                    const DocumentRequested(),
                  )
                : null,
          ),
        },
      ),
    );
  }
}
