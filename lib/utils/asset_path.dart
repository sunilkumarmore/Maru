class AssetPath {
  static String normalize(String? raw) {
    if (raw == null) return '';
    var p = raw.trim();
    if (p.isEmpty) return '';

    // Convert backslashes (Windows) to forward slashes
    p = p.replaceAll('\\', '/');

    // If someone accidentally stored "assets/assets/..", collapse to "assets/.."
    while (p.startsWith('assets/assets/')) {
      p = p.replaceFirst('assets/assets/', 'assets/');
    }

    // Some JSON might start with "/assets/..." or "./assets/..."
    if (p.startsWith('/')) p = p.substring(1);
    if (p.startsWith('./')) p = p.substring(2);

    // Ensure it starts with "assets/"
    if (!p.startsWith('assets/')) {
      p = 'assets/$p';
    }

    return p;
  }
}
