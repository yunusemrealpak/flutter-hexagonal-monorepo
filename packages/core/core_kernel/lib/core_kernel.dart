/// The innermost ring of the architecture.
///
/// This package holds the handful of types every other package is allowed to
/// share, and nothing else. It has no dependencies — not the Flutter SDK, not
/// one third-party package — because every package in the workspace is allowed
/// to depend on it, and a dependency added here is a dependency added
/// everywhere.
///
/// Nothing in this library is generated. Code generation in the innermost ring
/// would put a regeneration cost on the whole repository every time it
/// changed, so `Result`, `Failure`, `ValueObject`, `Entity`, `UseCase` and
/// `DomainEvent` are hand-written and stay small enough to be read in one
/// sitting.
library;

export 'src/domain_event.dart';
export 'src/entity.dart';
export 'src/failure.dart';
export 'src/page.dart';
export 'src/result.dart';
export 'src/use_case.dart';
export 'src/value_object.dart';
