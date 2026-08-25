/// Generates a new feature's package skeleton.
///
/// What it writes is not a suggestion: the pubspec of each generated package
/// carries exactly the dependency list section 2 of
/// `docs/DEPENDENCY_RULES.md` allows for that package's type.
///
/// Every seed source under `lib/src` compiles and is covered by a test, and
/// every one of them is meant to be deleted. A scaffolded file that survives
/// untouched into a real feature is a file nobody read.
library;

export 'src/feature_plan.dart';
export 'src/naming.dart' show Naming;
export 'src/templates.dart' show filesFor;
