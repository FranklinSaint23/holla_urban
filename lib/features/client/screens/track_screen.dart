import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class TrackScreen extends StatefulWidget {
  final String orderId;
  const TrackScreen({super.key, required this.orderId});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  final Completer<GoogleMapController> _mapController = Completer();

  // Yaoundé — coordonnées par défaut (fallback si GPS indisponible)
  static const LatLng _restaurant = LatLng(3.8620, 11.5200);
  static const LatLng _defaultClient = LatLng(3.8750, 11.5100);
  static const LatLng _defaultLivreur = LatLng(3.8680, 11.5150);

  // Variables d'état remplaçant les static const
  late LatLng _clientPos;
  late LatLng _livreurPos;

  Timer? _movementTimer;
  int _movementStep = 0;
  static const int _totalSteps = 20; // ~60 secondes à 3s/pas

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurant,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Pizzeria La Casa'),
        ),
        Marker(
          markerId: const MarkerId('client'),
          position: _clientPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Votre adresse'),
        ),
        Marker(
          markerId: const MarkerId('livreur'),
          position: _livreurPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: 'Jean-Baptiste K.'),
        ),
      };

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_restaurant, _livreurPos, _clientPos],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };

  // Current step index (0-4). Step 3 = "En route".
  final int _currentStep = 3;

  @override
  void initState() {
    super.initState();

    // Initialisation avec coordonnées par défaut
    _clientPos = _defaultClient;
    _livreurPos = _defaultLivreur;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    // Charger la vraie position GPS du client
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      // Vérifier si le service est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startLivreurSimulation();
        return;
      }

      // Vérifier/demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permission refusée → on garde les coordonnées Yaoundé par défaut
        _startLivreurSimulation();
        return;
      }

      // Obtenir la position réelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _clientPos = LatLng(position.latitude, position.longitude);
          // Positionner le livreur à ~500m du client (simulation)
          _livreurPos = LatLng(
            position.latitude - 0.004,
            position.longitude + 0.003,
          );
        });

        // Animer la caméra vers la vraie position
        _mapController.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _clientPos, zoom: 14.5),
            ),
          );
        });
      }
    } catch (_) {
      // En cas d'erreur, on conserve les coordonnées Yaoundé par défaut
    } finally {
      _startLivreurSimulation();
    }
  }

  /// Simule le déplacement du livreur vers le client (interpolation linéaire)
  void _startLivreurSimulation() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_movementStep >= _totalSteps) {
        timer.cancel();
        return;
      }

      _movementStep++;
      final t = _movementStep / _totalSteps;

      // Interpolation linéaire entre la position courante du livreur et le client
      final startLat = _defaultLivreur.latitude;
      final startLng = _defaultLivreur.longitude;
      final endLat = _clientPos.latitude;
      final endLng = _clientPos.longitude;

      // Légère oscillation pour rendre le mouvement naturel
      final noise = math.sin(_movementStep * 0.8) * 0.0002;

      setState(() {
        _livreurPos = LatLng(
          _lerp(startLat, endLat, t) + noise,
          _lerp(startLng, endLng, t) + noise,
        );
      });

      // Animer la caméra pour suivre le livreur
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _livreurPos, zoom: 14.5),
          ),
        );
      });
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _pulse.dispose();
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final steps = [
      (l.trackStepOrdered, '10:30'),
      (l.trackStepConfirmed, '10:32'),
      (l.trackStepPreparing, '10:35'),
      (l.trackStepOnTheWay, '10:48'),
      (l.trackStepDelivered, '--:--'),
    ];

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l.trackOrder,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('#${widget.orderId}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── ETA Banner ──────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Opacity(
                                opacity: _pulseAnim.value,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.delivery_dining_rounded,
                                      color: Colors.white,
                                      size: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.estimatedArrival,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.8))),
                                Text('12 min',
                                    style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white, size: 16),
                                Text('2.3 km',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text(l.fromYou,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Google Map ──────────────────────────────────
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            onMapCreated: (ctrl) =>
                                _mapController.complete(ctrl),
                            initialCameraPosition: CameraPosition(
                              target: _livreurPos,
                              zoom: 14.5,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Progress Steps ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          children: List.generate(steps.length, (i) {
                            final done = i < _currentStep;
                            final active = i == _currentStep;
                            final pending = i > _currentStep;
                            return _StepRow(
                              label: steps[i].$1,
                              time: steps[i].$2,
                              isDone: done,
                              isActive: active,
                              isPending: pending,
                              isLast: i == steps.length - 1,
                              pulseAnim: active ? _pulseAnim : null,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Livreur Card ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.yourDeliverer,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.color)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                          AppColors.primaryLight,
                                      child: Text('J',
                                          style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary)),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: context.cardBg,
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Jean-Baptiste K.',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.color)),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: AppColors.warning,
                                              size: 14),
                                          Text(' 4.8 · Moto · CM-123-XY',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: context
                                                      .subtextColor)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.call_rounded,
                                      color: AppColors.success,
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.chat_bubble_rounded,
                                      color: AppColors.primary,
                                      onTap: () => context.push(
                                          '/client/chat/Jean-Baptiste'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String label, time;
  final bool isDone, isActive, isPending, isLast;
  final Animation<double>? pulseAnim;

  const _StepRow({
    required this.label,
    required this.time,
    required this.isDone,
    required this.isActive,
    required this.isPending,
    required this.isLast,
    this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot + line
        SizedBox(
          width: 28,
          child: Column(
            children: [
              _buildDot(context),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color: isDone
                      ? AppColors.primary
                      : context.borderColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isPending
                              ? context.subtextColor
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color)),
                ),
                Text(time,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isPending
                            ? context.subtextColor
                            : AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(BuildContext context) {
    if (isDone) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            color: Colors.white, size: 14),
      );
    }
    if (isActive && pulseAnim != null) {
      return AnimatedBuilder(
        animation: pulseAnim!,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24 + (4 * (1 - pulseAnim!.value)),
              height: 24 + (4 * (1 - pulseAnim!.value)),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                    alpha: 0.25 * pulseAnim!.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radio_button_checked_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.borderColor, width: 2),
        color: context.cardBg,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
