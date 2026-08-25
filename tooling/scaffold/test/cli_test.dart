@Tags(['unit'])
library;

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

import 'support/temp_workspace.dart';

void main() {
  late TempWorkspace workspace;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    workspace = TempWorkspace.create();
    out = StringBuffer();
    err = StringBuffer();
  });
  tearDown(() => workspace.dispose());

  int run(List<String> arguments) => runCli(arguments, out: out, err: err);

  List<String> newFeature(List<String> extra) => [
    'new-feature',
    '--root=${workspace.root}',
    ...extra,
  ];

  group('a good run', () {
    test('generates, registers, and says what it did', () {
      final code = run(newFeature(['--name=billing']));

      expect(code, ExitCodes.ok);
      expect(out.toString(), contains('created'));
      expect(out.toString(), contains('billing_api'));
      expect(out.toString(), contains('workspace: list'));
      expect(
        workspace.exists('packages/features/billing/billing_api/pubspec.yaml'),
        isTrue,
      );
    });

    test('names the dependency it had to leave out', () {
      // design_system arrives in a later phase. Saying so is the difference
      // between a deliberate omission and a bug someone finds later.
      run(newFeature(['--name=billing']));
      expect(
        out.toString(),
        contains('design_system is not in this workspace'),
      );
    });

    test('--dry-run leaves the workspace untouched', () {
      final code = run(newFeature(['--name=billing', '--dry-run']));

      expect(code, ExitCodes.ok);
      expect(out.toString(), contains('would create'));
      expect(
        workspace.exists('packages/features/billing/billing_api/pubspec.yaml'),
        isFalse,
      );
    });
  });

  group('arguments it refuses', () {
    test('a name pub would reject', () {
      expect(run(newFeature(['--name=Billing'])), ExitCodes.misconfigured);
      expect(err.toString(), contains('lower_snake_case'));
    });

    test('a missing name', () {
      expect(run(newFeature([])), ExitCodes.misconfigured);
    });

    test('an unknown split', () {
      expect(
        run(newFeature(['--name=billing', '--split=medium'])),
        ExitCodes.misconfigured,
      );
    });

    test('a presentation variant that is not snake_case', () {
      expect(
        run(newFeature(['--name=billing', '--presentation=Courier'])),
        ExitCodes.misconfigured,
      );
      expect(err.toString(), contains('--presentation'));
    });

    test('a root that does not exist', () {
      expect(
        run(['new-feature', '--name=billing', '--root=${workspace.root}/nope']),
        ExitCodes.misconfigured,
      );
      expect(err.toString(), contains('no such directory'));
    });

    test('a directory that is not a workspace root', () {
      final empty = TempWorkspace.create(corePackages: const []);
      workspace.write('elsewhere/marker.txt', 'x');
      expect(
        run([
          'new-feature',
          '--name=billing',
          '--root=${workspace.root}/elsewhere',
        ]),
        ExitCodes.misconfigured,
      );
      expect(err.toString(), contains('workspace root'));
      empty.dispose();
    });

    test('no command at all prints the usage and exits 64', () {
      expect(run([]), ExitCodes.misconfigured);
      expect(out.toString(), contains('Usage:'));
    });
  });

  group('--help', () {
    test('explains how to choose a split', () {
      expect(run(['--help']), ExitCodes.ok);
      expect(out.toString(), contains('Choosing a split'));
      expect(out.toString(), contains('--with-testing'));
    });
  });
}
