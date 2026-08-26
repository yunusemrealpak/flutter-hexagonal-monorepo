import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

/// One product intention: read a sync record by its identifier.
///
/// Every collaborator arrives through the constructor. That constructor is
/// the whole dependency story of the class — there is no locator inside a
/// package and no global to reach for — which is why a test can run this
/// against a fake without any setup at all.
final class LoadSync implements UseCase<String, Result<String, SyncFailure>> {
  /// Creates the use case over the port it reads through.
  ///
  /// Positional and private: a named parameter cannot be an initializing
  /// formal for a private field, and spelling the assignment out instead
  /// trips `prefer_initializing_formals`. One collaborator does not need a
  /// label to be readable.
  const LoadSync(this._repository);

  final SyncRepository _repository;

  @override
  Future<Result<String, SyncFailure>> call(String input) =>
      _repository.byId(input);
}
