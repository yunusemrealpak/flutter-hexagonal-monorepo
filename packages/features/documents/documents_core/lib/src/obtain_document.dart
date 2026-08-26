import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Which document, for which parcel, and whether the archive may answer.
final class ObtainDocumentCommand {
  /// Creates the command.
  const ObtainDocumentCommand({
    required this.kind,
    required this.shipment,
    this.fresh = false,
  });

  /// Which piece of paperwork.
  final DocumentKind kind;

  /// Which parcel.
  final ShipmentId shipment;

  /// Whether to skip the archive and produce it again.
  ///
  /// A flag rather than a second use case, because everything after the first
  /// `if` is identical and two copies of "render, store, answer" would drift.
  final bool fresh;
}

/// Hands back a document, producing it only when it has to.
///
/// The whole feature in twenty lines: ask the archive, ask the renderer, keep
/// what came back. What makes it worth reading is the failure handling either
/// side of that.
///
/// **An archive that cannot be read does not stop a render.** The archive is a
/// cache; a device whose cache is broken should still be able to show somebody
/// a waybill. The failure is logged, because a cache that is failing silently
/// every time is a bug somebody should see.
///
/// **An archive that cannot be written does not fail the answer.** The
/// document was produced and the courier is holding out a phone. Failing here
/// would turn a full disk into a document nobody can see.
final class ObtainDocument
    implements
        UseCase<ObtainDocumentCommand, Result<Document, DocumentsFailure>> {
  /// Creates the use case.
  const ObtainDocument({
    required this._archive,
    required this._renderer,
    required this._logger,
  });

  final DocumentArchive _archive;
  final DocumentRenderer _renderer;
  final Logger _logger;

  @override
  Future<Result<Document, DocumentsFailure>> call(
    ObtainDocumentCommand command,
  ) async {
    if (!command.fresh) {
      final held = await _archive.read(
        DocumentId.of(kind: command.kind, shipment: command.shipment).value,
      );
      switch (held) {
        case Success(:final value):
          return Success(value);
        // Missing is the ordinary outcome for anything the archive evicted,
        // and it is not worth a log line every time somebody opens an old
        // parcel.
        case Failed(failure: DocumentMissing()):
          break;
        case Failed(:final failure):
          _logger.log(
            LogLevel.warning,
            'the archive could not be read: $failure',
          );
      }
    }

    final produced = await _renderer.render(
      kind: command.kind,
      shipmentId: command.shipment.value,
    );
    if (produced case Failed(:final failure)) {
      return Failed(failure);
    }

    final document = (produced as Success<Document, DocumentsFailure>).value;
    final stored = await _archive.put(document);
    if (stored case Failed(:final failure)) {
      _logger.log(LogLevel.warning, 'the document was not archived: $failure');
    }
    return Success(document);
  }
}
