/// The colour one package type is drawn in, in every renderer.
///
/// One table rather than one per output format: a reader who learns that green
/// is a contract package in the Mermaid diagram should not have to learn it
/// again in the DOT one.
final class TypeStyle {
  /// Creates a style.
  const TypeStyle({
    required this.fill,
    required this.stroke,
    required this.label,
  });

  /// The node's background.
  final String fill;

  /// The node's border, and its text colour in the DOT output.
  final String stroke;

  /// What a legend calls this type.
  final String label;
}

/// The colour of every type the constitution recognises.
///
/// The grouping is by ring rather than by hue family: contracts are green,
/// use cases the lighter green beside them, adapters orange, UI pink, and the
/// core ring blue. Somebody scanning the diagram for "what may a use case
/// touch" is looking for one colour and its neighbours.
const Map<String, TypeStyle> typeStyles = {
  'core_kernel': TypeStyle(
    fill: '#e8eaf6',
    stroke: '#3949ab',
    label: 'core_kernel',
  ),
  'core_ports': TypeStyle(
    fill: '#e3f2fd',
    stroke: '#1976d2',
    label: 'core_ports',
  ),
  'core_navigation': TypeStyle(
    fill: '#e0f7fa',
    stroke: '#00838f',
    label: 'core_navigation',
  ),
  'core_testing': TypeStyle(
    fill: '#f3e5f5',
    stroke: '#6a1b9a',
    label: 'core_testing',
  ),
  'feature_api': TypeStyle(
    fill: '#e8f5e9',
    stroke: '#2e7d32',
    label: 'feature _api (contract)',
  ),
  'feature_application': TypeStyle(
    fill: '#f1f8e9',
    stroke: '#558b2f',
    label: 'feature _application (use cases)',
  ),
  'feature_infrastructure': TypeStyle(
    fill: '#fff3e0',
    stroke: '#ef6c00',
    label: 'feature _infrastructure (adapters)',
  ),
  'feature_core': TypeStyle(
    fill: '#f9fbe7',
    stroke: '#9e9d24',
    label: 'feature _core (reduced split)',
  ),
  'feature_presentation': TypeStyle(
    fill: '#fce4ec',
    stroke: '#c2185b',
    label: 'feature _presentation (UI)',
  ),
  'feature_testing': TypeStyle(
    fill: '#ede7f6',
    stroke: '#5e35b1',
    label: 'feature _testing (fakes)',
  ),
  'platform': TypeStyle(
    fill: '#fbe9e7',
    stroke: '#d84315',
    label: 'platform/* (technology)',
  ),
  'design_tokens': TypeStyle(
    fill: '#fffde7',
    stroke: '#f9a825',
    label: 'design_tokens',
  ),
  'design_system': TypeStyle(
    fill: '#fff8e1',
    stroke: '#ff8f00',
    label: 'design_system',
  ),
  'tooling': TypeStyle(
    fill: '#eceff1',
    stroke: '#455a64',
    label: 'tooling/*',
  ),
  'app': TypeStyle(
    fill: '#e0f2f1',
    stroke: '#00695c',
    label: 'apps/* (composition roots)',
  ),
};

/// The style for [typeId], falling back to a neutral one for an untyped
/// package so that a diagram still draws when the checker would complain.
TypeStyle styleFor(String? typeId) =>
    typeStyles[typeId] ??
    const TypeStyle(fill: '#ffffff', stroke: '#b71c1c', label: 'untyped');
