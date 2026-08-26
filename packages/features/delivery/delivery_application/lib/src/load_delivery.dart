import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// One product intention: read a delivery record by its identifier.
///
/// Every collaborator arrives through the constructor. That constructor is
/// the whole dependency story of the class — there is no locator inside a
/// package and no global to reach for — which is why a test can run this
/// against a fake without any setup at all.
final class LoadDelivery
    implements UseCase<String, Result<String, DeliveryFailure>> {
  /// Creates the use case over the port it reads through.
  ///
  /// Positional and private: a named parameter cannot be an initializing
  /// formal for a private field, and spelling the assignment out instead
  /// trips `prefer_initializing_formals`. One collaborator does not need a
  /// label to be readable.
  const LoadDelivery(this._repository);

  final DeliveryRepository _repository;

  @override
  Future<Result<String, DeliveryFailure>> call(String input) =>
      _repository.byId(input);
}
