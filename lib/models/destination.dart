class Destination {
  final String id;
  final String name;
  final String region;
  // Koordinat normalized 0..1 terhadap ukuran kanvas peta (mapW x mapH)
  final double x;
  final double y;

  // Kata kunci alternatif untuk pencarian (e.g. 'danau toba')
  final List<String> keywords;

  final String? imageUrl;

  const Destination({
    required this.id,
    required this.name,
    required this.region,
    required this.x,
    required this.y,
    this.keywords = const [],
    this.imageUrl,
  });
}
