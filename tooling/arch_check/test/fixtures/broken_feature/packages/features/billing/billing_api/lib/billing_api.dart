/// The billing contract.
///
/// The re-export below started as a convenience — "callers need Result
/// anyway" — and republishes another package's surface as this one's.
library;

export 'package:core_kernel/core_kernel.dart';

export 'src/billing_failure.dart';
export 'src/billing_repository.dart';
export 'src/http_billing_repository.dart';
export 'src/invoice_dto.dart';
