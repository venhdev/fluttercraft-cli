/// Interactive Mode for menu selection
enum InteractiveMode {
  /// Arrow-key navigation (default, better UX)
  arrow,
  
  /// Numeric selection (works everywhere)
  numeric,
}

/// Parse interactive mode from string
InteractiveMode parseInteractiveMode(String? value) {
  switch (value?.toLowerCase()) {
    case 'numeric':
      return InteractiveMode.numeric;
    case 'arrow':
    default:
      return InteractiveMode.arrow;
  }
}
