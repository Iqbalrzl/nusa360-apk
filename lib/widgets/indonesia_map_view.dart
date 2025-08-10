import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show MatrixUtils;
import 'package:flutter_svg/svg.dart';
import '../models/destination.dart';

typedef DestinationTap = void Function(Destination);

class IndonesiaMapView extends StatefulWidget {
  final List<Destination> destinations;
  final DestinationTap onTapDestination;
  final ValueChanged<Destination>? onZoomedTo; // callback setelah zoom
  final bool
  debugTapToGetCoords; // jika true, tap akan menampilkan koordinat normalized

  // Opsional: atur zoom dan pusat awal (normalized 0..1)
  final double initialZoomFactor; // multiplier untuk "cover" scale
  final Offset initialCenterNormalized; // pusat awal fokus

  const IndonesiaMapView({
    super.key,
    required this.destinations,
    required this.onTapDestination,
    this.onZoomedTo,
    this.debugTapToGetCoords = false,
    this.initialZoomFactor = 1.25, // default lebih dekat dari sekadar fit
    this.initialCenterNormalized = const Offset(
      0.56,
      0.54,
    ), // fokus area kepulauan
  });

  @override
  State<IndonesiaMapView> createState() => IndonesiaMapViewState();
}

class IndonesiaMapViewState extends State<IndonesiaMapView>
    with SingleTickerProviderStateMixin {
  // Ukuran kanvas dasar (rujukan normalisasi koordinat)
  static const double mapW = 1000;
  static const double mapH = 600;

  final TransformationController _controller = TransformationController();
  Animation<Matrix4>? _animation;
  late final AnimationController _animController =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 460),
        )
        ..addListener(() {
          if (_animation != null) {
            _controller.value = _animation!.value;
            _updateSelectedScreenPos();
          }
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              _selected != null &&
              widget.onZoomedTo != null) {
            widget.onZoomedTo!(_selected!);
          }
        });

  Size _viewportSize = const Size(0, 0);
  bool _initializedTransform = false;
  double _baseScale = 1.0;

  Destination? _selected;
  Offset? _selectedScreenPos;

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Matrix awal: "cover" + zoom factor, fokus ke pusat awal yang ditentukan
  Matrix4 _baseMatrix(Size viewport) {
    // COVER: pakai max (bukan min) agar mengisi layar secara penuh
    final coverScale = [
      viewport.width / mapW,
      viewport.height / mapH,
    ].reduce((a, b) => a > b ? a : b);

    _baseScale = coverScale * widget.initialZoomFactor;

    // Pusat fokus awal (normalized -> pixel)
    final initCenter = Offset(
      widget.initialCenterNormalized.dx.clamp(0.0, 1.0) * mapW,
      widget.initialCenterNormalized.dy.clamp(0.0, 1.0) * mapH,
    );

    final dx = -initCenter.dx * _baseScale + viewport.width / 2;
    final dy = -initCenter.dy * _baseScale + viewport.height / 2;

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(_baseScale);
  }

  void _ensureInitialized() {
    if (_initializedTransform) return;
    _controller.value = _baseMatrix(_viewportSize);
    _initializedTransform = true;
  }

  void _updateSelectedScreenPos() {
    if (_selected == null) return;
    final childPoint = Offset(_selected!.x * mapW, _selected!.y * mapH);
    final screenPoint = MatrixUtils.transformPoint(
      _controller.value,
      childPoint,
    );
    setState(() {
      _selectedScreenPos = screenPoint;
    });
  }

  void zoomTo(Destination d, {double? scale}) {
    _selected = d;
    final s = (scale ?? (_baseScale * 1.6)).clamp(
      _baseScale * 0.9,
      _baseScale * 6.0,
    );
    final target = Offset(d.x * mapW, d.y * mapH);
    final dx = -target.dx * s + _viewportSize.width / 2;
    final dy = -target.dy * s + _viewportSize.height / 2;

    final begin = _controller.value;
    final end =
        Matrix4.identity()
          ..translate(dx, dy)
          ..scale(s);

    _animation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
    _animController.forward(from: 0);
  }

  // Reset ke default yang "cover" dan fokus tengah Indonesia (tidak kecil)
  void resetView() {
    _selected = null;
    _selectedScreenPos = null;

    final begin = _controller.value;
    final end = _baseMatrix(_viewportSize);

    _animation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
    _animController.forward(from: 0);
    setState(() {}); // update untuk menyembunyikan bubble segera
  }

  @override
  Widget build(BuildContext context) {
    const mapColor = Color(0xFFC84E4E);

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        // Inisialisasi transform supaya peta full screen "cover" dan terpusat sesuai fokus
        _ensureInitialized();

        return Stack(
          children: [
            InteractiveViewer(
              minScale: _baseScale * 0.9, // boleh sedikit zoom-out dari default
              maxScale: _baseScale * 6,
              transformationController: _controller,
              onInteractionStart: (_) {
                // Sembunyikan bubble saat user mulai menggeser/zoom
                if (_selected != null) {
                  setState(() {
                    _selected = null;
                    _selectedScreenPos = null;
                  });
                }
              },
              onInteractionUpdate: (_) {
                // Pastikan bubble tetap tersembunyi selama gerakan
                if (_selected != null) {
                  setState(() {
                    _selected = null;
                    _selectedScreenPos = null;
                  });
                }
              },
              child: SizedBox(
                width: mapW,
                height: mapH,
                child: Stack(
                  children: [
                    // Placeholder peta: siluet sederhana (ganti dengan asset final bila siap)
                    Positioned.fill(
                      child: SvgPicture.asset("assets/id.svg", color: mapColor),
                    ),
                    // Marker destinasi
                    ...widget.destinations.map((d) {
                      final left = d.x * mapW;
                      final top = d.y * mapH;
                      return Positioned(
                        left: left - 6,
                        top: top - 6,
                        child: GestureDetector(
                          onTap: () => zoomTo(d),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.2,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Optional: tap anywhere untuk mendapatkan koordinat normalized
            if (widget.debugTapToGetCoords)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final inv = Matrix4.inverted(_controller.value);
                    final childPoint = MatrixUtils.transformPoint(
                      inv,
                      details.localPosition,
                    );
                    final nx = (childPoint.dx / mapW).clamp(0.0, 1.0);
                    final ny = (childPoint.dy / mapH).clamp(0.0, 1.0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Koordinat: x=${nx.toStringAsFixed(3)}, y=${ny.toStringAsFixed(3)}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    // ignore: avoid_print
                    print('Normalized => x:$nx, y:$ny');
                  },
                ),
              ),

            // Kartu detail mengambang dekat titik (posisi layar)
            if (_selected != null && _selectedScreenPos != null)
              Positioned(
                left: (_selectedScreenPos!.dx - 110).clamp(
                  8,
                  _viewportSize.width - 220,
                ),
                top: (_selectedScreenPos!.dy - 90).clamp(
                  80,
                  _viewportSize.height - 140,
                ),
                child: _DestinationBubble(
                  destination: _selected!,
                  onTap: () => widget.onTapDestination(_selected!),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DestinationBubble extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _DestinationBubble({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                destination.region,
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Color color;
  _SilhouettePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    Path sumatra =
        Path()
          ..moveTo(size.width * 0.10, size.height * 0.35)
          ..quadraticBezierTo(
            size.width * 0.18,
            size.height * 0.25,
            size.width * 0.26,
            size.height * 0.30,
          )
          ..quadraticBezierTo(
            size.width * 0.30,
            size.height * 0.42,
            size.width * 0.22,
            size.height * 0.50,
          )
          ..quadraticBezierTo(
            size.width * 0.14,
            size.height * 0.48,
            size.width * 0.10,
            size.height * 0.40,
          )
          ..close();

    Path javaBali =
        Path()
          ..moveTo(size.width * 0.32, size.height * 0.58)
          ..quadraticBezierTo(
            size.width * 0.44,
            size.height * 0.54,
            size.width * 0.56,
            size.height * 0.58,
          )
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.62,
            size.width * 0.46,
            size.height * 0.64,
          )
          ..quadraticBezierTo(
            size.width * 0.36,
            size.height * 0.64,
            size.width * 0.32,
            size.height * 0.60,
          )
          ..close();

    Path kalSul =
        Path()
          ..moveTo(size.width * 0.46, size.height * 0.34)
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.24,
            size.width * 0.66,
            size.height * 0.34,
          )
          ..quadraticBezierTo(
            size.width * 0.64,
            size.height * 0.44,
            size.width * 0.50,
            size.height * 0.42,
          )
          ..close();

    Path ntt =
        Path()
          ..moveTo(size.width * 0.60, size.height * 0.60)
          ..quadraticBezierTo(
            size.width * 0.70,
            size.height * 0.58,
            size.width * 0.78,
            size.height * 0.60,
          )
          ..quadraticBezierTo(
            size.width * 0.74,
            size.height * 0.64,
            size.width * 0.62,
            size.height * 0.64,
          )
          ..close();

    Path papua =
        Path()
          ..moveTo(size.width * 0.78, size.height * 0.40)
          ..quadraticBezierTo(
            size.width * 0.92,
            size.height * 0.34,
            size.width * 0.96,
            size.height * 0.46,
          )
          ..quadraticBezierTo(
            size.width * 0.90,
            size.height * 0.52,
            size.width * 0.80,
            size.height * 0.48,
          )
          ..close();

    canvas.drawPath(sumatra, paint);
    canvas.drawPath(javaBali, paint);
    canvas.drawPath(kalSul, paint);
    canvas.drawPath(ntt, paint);
    canvas.drawPath(papua, paint);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) => false;
}
