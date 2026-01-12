class AssetPath {
  static String normalize(String? input) {
    if (input == null) return '';
    var s = input.trim();
    if (s.isEmpty) return s;

    // Remove accidental leading "./"
    if (s.startsWith('./')) s = s.substring(2);

    // Fix repeated prefix: assets/assets/...
    while (s.startsWith('assets/assets/')) {
      s = s.replaceFirst('assets/', '');
    }

    // Fix leading slash variants: "/assets/..."
    if (s.startsWith('/assets/')) s = s.substring(1);

    return s;
  }
}
