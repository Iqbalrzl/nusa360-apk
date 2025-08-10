import '../models/destination.dart';

/// Data contoh; koordinat kira-kira di siluet Indonesia (normalized)
const destinations = <Destination>[
  Destination(
    id: 'labuan-bajo',
    name: 'Labuan Bajo',
    region: 'Nusa Tenggara Timur',
    x: 0.220,
    y: 0.580,
    keywords: ['labuan bajo', 'labuanbajo', 'bajo'],
    imageUrl: 'http://103.63.25.133:8080/opt/nusa360/uploads/public/bajo.png',
  ),
  Destination(
    id: 'toba-lake',
    name: 'Toba Lake',
    region: 'Sumatera Utara',
    x: 0.055,
    y: 0.436,
    keywords: ['danau toba', 'lake toba', 'toba'],
    imageUrl: 'http://103.63.25.133:8080/opt/nusa360/uploads/public/toba.png',
  ),
  Destination(
    id: 'raja-ampat',
    name: 'Raja Ampat',
    region: 'Papua Barat',
    x: 0.89,
    y: 0.48,
    keywords: ['raja ampat', 'rajaampat', 'waigeo'],
    imageUrl: 'http://103.63.25.133:8080/opt/nusa360/uploads/public/raja.png',
  ),
  Destination(
    id: 'borobudur',
    name: 'Borobudur',
    region: 'Jawa Tengah',
    x: 0.51,
    y: 0.57,
    keywords: ['borobudur', 'magelang'],
    imageUrl:
        'http://103.63.25.133:8080/opt/nusa360/uploads/public/borobudur.png',
  ),
];
