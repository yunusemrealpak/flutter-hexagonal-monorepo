@Tags(['unit'])
library;

import 'package:connectivity_monitor/connectivity_monitor.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toNetworkCondition', () {
    test('reports offline for no transport and for an empty answer', () {
      expect(
        toNetworkCondition([ConnectivityResult.none]),
        NetworkCondition.offline,
      );
      expect(toNetworkCondition([]), NetworkCondition.offline);
    });

    test('treats wifi and ethernet as unmetered', () {
      expect(
        toNetworkCondition([ConnectivityResult.wifi]),
        NetworkCondition.unmetered,
      );
      expect(
        toNetworkCondition([ConnectivityResult.ethernet]),
        NetworkCondition.unmetered,
      );
    });

    test('treats every link of unknown cost as metered', () {
      // The expensive assumption is the safe one: treating an unknown link as
      // free is how a courier ends up paying for a photo upload.
      for (final result in const [
        ConnectivityResult.mobile,
        ConnectivityResult.satellite,
        ConnectivityResult.bluetooth,
        ConnectivityResult.other,
      ]) {
        expect(
          toNetworkCondition([result]),
          NetworkCondition.metered,
          reason: result.name,
        );
      }
    });

    test('lets metered win when both kinds are present', () {
      // A device on wifi and cellular at once may fall back to cellular
      // mid-transfer, and the cost of being wrong here is somebody's data
      // allowance.
      expect(
        toNetworkCondition([
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ]),
        NetworkCondition.metered,
      );
      expect(
        toNetworkCondition([
          ConnectivityResult.mobile,
          ConnectivityResult.satellite,
        ]),
        NetworkCondition.metered,
      );
    });

    test('treats a VPN with no visible transport as unmetered', () {
      // On iOS and macOS a VPN masks the underlying transport entirely, so
      // there is nothing better to go on.
      expect(
        toNetworkCondition([ConnectivityResult.vpn]),
        NetworkCondition.unmetered,
      );
    });
  });
}
