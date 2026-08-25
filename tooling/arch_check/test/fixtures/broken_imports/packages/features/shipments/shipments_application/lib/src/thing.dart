import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// A use case that owns a retry policy, resolves its own collaborators, and
/// announces itself to a generator. Three rules, one class.
@injectable
final class LoadShipment {
  /// Runs it.
  Future<Response<dynamic>> call() => GetIt.I<Dio>().get<dynamic>('/shipments');
}
