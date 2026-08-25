/// Generates a new feature's package skeleton.
///
/// What it writes is not a suggestion: the pubspec of each generated package
/// carries exactly the dependency list section 2 of
/// `docs/DEPENDENCY_RULES.md` allows for that package's type.
library;

export 'src/feature_plan.dart';
export 'src/naming.dart' show Naming;
