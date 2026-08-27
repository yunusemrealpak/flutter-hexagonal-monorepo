/// How much weight a button carries on the screen it is on.
///
/// Three, and a screen may show one [primary] at a time. That is a design rule
/// rather than a compiler rule, and it is written here because the enum is
/// where somebody looks when they are about to add a second one.
enum PeykButtonTone {
  /// The one action the screen exists for. Filled with the brand colour.
  primary,

  /// An action worth offering but not the point of the screen. Outlined.
  secondary,

  /// An action that destroys something or gives up. Outlined in danger.
  destructive,
}
