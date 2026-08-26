/// The three things a courier can come back with.
///
/// An enum rather than a union, because unlike a shipment's status these
/// really are interchangeable labels: the policy asks "which kinds are
/// present" and never asks a kind for its contents. The contents live in
/// `SignatureCapture`, `PhotoEvidence` and `ScanEvidence`.
enum EvidenceKind {
  /// Somebody signed for it.
  signature,

  /// A photograph of the hand-over or of where it was left.
  photo,

  /// A barcode was scanned at the door.
  scan,
}
