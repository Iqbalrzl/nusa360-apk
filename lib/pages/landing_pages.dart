import 'package:flutter/material.dart';
import 'package:nusa360/pages/chatbot_screen.dart';
import 'package:nusa360/pages/destination_detail.dart';
import 'package:nusa360/pages/profile.dart';
import '../data/destinations.dart';
import '../models/destination.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/floating_search_bar.dart';
import '../widgets/indonesia_map_view.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Destination> _filtered = destinations;
  bool _debugCoords = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    final only = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return only.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _onSearchChanged(String q) {
    final query = _normalize(q);
    setState(() {
      _filtered =
          destinations.where((d) {
            final name = _normalize(d.name);
            final region = _normalize(d.region);
            final keys = d.keywords.map(_normalize).toList();
            return name.contains(query) ||
                region.contains(query) ||
                keys.any((k) => k.contains(query));
          }).toList();
    });

    // Auto-zoom jika match tepat satu best candidate
    if (query.length >= 3) {
      final first = destinations.firstWhere(
        (d) {
          final all = [
            _normalize(d.name),
            _normalize(d.region),
            ...d.keywords.map(_normalize),
          ];
          return all.contains(query) || all.any((t) => t == query);
        },
        orElse:
            () => _filtered.isNotEmpty ? _filtered.first : destinations.first,
      );
      _mapKey.currentState?.zoomTo(first);
    }
  }

  void _onSubmitted(String q) {
    final query = _normalize(q);
    // Cari kandidat paling cocok
    final exact =
        destinations.where((d) {
          final all = [
            _normalize(d.name),
            _normalize(d.region),
            ...d.keywords.map(_normalize),
          ];
          return all.contains(query);
        }).toList();

    final target =
        exact.isNotEmpty
            ? exact.first
            : (_filtered.isNotEmpty ? _filtered.first : destinations.first);
    _focusNode.unfocus();
    _mapKey.currentState?.zoomTo(target);
  }

  void _openDetail(Destination d) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DestinationDetailPage(destination: d)),
    );
  }

  final GlobalKey<_MapHolderState> _mapKey = GlobalKey<_MapHolderState>();

  @override
  Widget build(BuildContext context) {
    final showResults = _focusNode.hasFocus && _searchCtrl.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map holder
            Positioned.fill(
              child: _MapHolder(
                key: _mapKey,
                onTapDestination: _openDetail,
                debugMode: _debugCoords,
              ),
            ),

            // Top bar: brand kecil + search minimalis
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      setState(() => _debugCoords = !_debugCoords);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _debugCoords
                                ? 'Debug koordinat: ON (tap pada peta untuk dapatkan x,y)'
                                : 'Debug koordinat: OFF',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/logo.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FloatingSearchBar(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSubmitted,
                      onClear: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Suggestion dropdown
            if (showResults)
              Positioned(
                top: 62,
                left: 110,
                right: 16,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final d = _filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            d.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(d.region),
                          onTap: () {
                            _focusNode.unfocus();
                            _mapKey.currentState?.zoomTo(d);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Bottom floating nav
            Positioned(
              left: 16,
              right: 16,
              bottom: 8,
              child: Center(
                child: FloatingNavBar(
                  currentIndex: 1,
                  onAiTap: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => ChatScreen()));
                  },
                  onHomeTap: () {
                    // NEW: reset ke tampilan awal
                    _mapKey.currentState?.resetView();
                  },
                  onProfileTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHolder extends StatefulWidget {
  final void Function(Destination) onTapDestination;
  final bool debugMode;
  const _MapHolder({
    super.key,
    required this.onTapDestination,
    this.debugMode = false,
  });

  @override
  State<_MapHolder> createState() => _MapHolderState();
}

class _MapHolderState extends State<_MapHolder> {
  final GlobalKey _innerKey = GlobalKey();

  void zoomTo(Destination d) {
    final state = _innerKey.currentState;
    if (state is IndonesiaMapViewState) {
      state.zoomTo(d);
    }
  }

  void resetView() {
    final state = _innerKey.currentState;
    if (state is IndonesiaMapViewState) {
      state.resetView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: IndonesiaMapView(
        key: _innerKey,
        destinations: destinations,
        onTapDestination: widget.onTapDestination,
        onZoomedTo: (_) {},
        debugTapToGetCoords: widget.debugMode,
      ),
    );
  }
}
