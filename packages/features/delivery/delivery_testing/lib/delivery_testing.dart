/// Fakes, fixtures and the contract kit for delivery.
///
/// **The kit that matters is `runProofStoreContract`.** Three implementations
/// of `ProofStorePort` run it: the encrypted local store and the remote one in
/// `delivery_infrastructure`, and `FakeProofStore` here. One description of
/// what a proof store must do, three answers held to it — the same shape as
/// routing's optimiser kit, and the same payoff: `app_courier` keeps a
/// courier's signatures encrypted on the device, `app_dispatcher` keeps them
/// on a server, and no use case changes.
///
/// It asserts what a caller may rely on — a proof goes in, a handle comes out,
/// the handle brings the proof back — and says nothing about the handle's
/// shape. A local store's reference is a row identifier and a remote one's is
/// whatever the server minted; a kit that pinned the format would fail the day
/// the server changed its identifiers.
///
/// **Fakes.** `FakeProofStore` really keeps what it is given and is also the
/// adapter `app_harness` binds. `FakeDeliveryGateway` accumulates attempts per
/// shipment and replaces by identifier, so a resent attempt does not look like
/// a second delivery. `FakeGeoFence` is pushed by hand, so a test about
/// starting an attempt three streets away is a statement rather than a
/// coordinate calculation. `FakeMediaCompressor` truncates — not what an
/// encoder does, and exactly the port's observable promise.
///
/// **Fixtures.** `DeliveryFixtures` builds a proof carrying one piece of
/// evidence by default, because a proof with none is refused by every grade
/// and a fixture that has to be repaired before use is a fixture nobody uses.
///
/// `test` is a runtime dependency of this package rather than a dev one,
/// because a contract kit *is* tests — it calls `group` and `test` from
/// `lib/`.
library;

export 'src/delivery_fixtures.dart';
export 'src/fake_delivery_gateway.dart';
export 'src/fake_geo_fence.dart';
export 'src/fake_media_compressor.dart';
export 'src/fake_proof_store.dart';
export 'src/proof_store_contract.dart';
