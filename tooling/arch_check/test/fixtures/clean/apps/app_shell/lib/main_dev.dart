import 'src/composition.dart';

/// A second entry point, one per flavour.
///
/// This is the shape rule S1's app row exists for: `flutter run -t
/// lib/main_dev.dart` is how a flavour is selected, so an app legitimately has
/// several files directly under lib/ and none of them is a barrel.
void main() => compose('dev');
