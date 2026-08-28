import 'model/test_package.dart';
import 'timings.dart';

/// Splits packages across parallel machines so they finish together.
///
/// Longest-processing-time first: sort by cost descending, then hand each
/// package to whichever bucket is currently emptiest. It is the classic greedy
/// approximation for multiway partitioning, it is within 4/3 of optimal, and
/// it is four lines — which matters more here than optimality, because the
/// input is a guess from the last run either way.
///
/// Ties break on the package name so that the same input always produces the
/// same split. A bucketing that shuffled would make a flaky failure impossible
/// to reproduce on the machine that saw it.
List<TestPackage> bucketOf(
  List<TestPackage> packages,
  Timings timings, {
  required int index,
  required int total,
}) {
  if (total <= 1) return packages;

  final ordered = [...packages]
    ..sort((a, b) {
      final byCost = timings.costOf(b.name).compareTo(timings.costOf(a.name));
      return byCost != 0 ? byCost : a.name.compareTo(b.name);
    });

  final buckets = List.generate(total, (_) => <TestPackage>[]);
  final loads = List<double>.filled(total, 0);

  for (final package in ordered) {
    var lightest = 0;
    for (var i = 1; i < total; i++) {
      if (loads[i] < loads[lightest]) lightest = i;
    }
    buckets[lightest].add(package);
    loads[lightest] += timings.costOf(package.name);
  }

  final selected = buckets[index];
  // Back into workspace order, so a bucket's log reads like a slice of the
  // whole run rather than like a cost table.
  final position = {
    for (final (at, package) in packages.indexed) package.name: at,
  };
  selected.sort(
    (a, b) => position[a.name]!.compareTo(position[b.name]!),
  );
  return selected;
}
