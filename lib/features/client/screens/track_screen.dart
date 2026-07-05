import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _client = Supabase.instance.client;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  final Completer<GoogleMapController> _mapController = Completer();

  // Yaoundé defaults
  static const LatLng _defaultClient = LatLng(3.8750, 11.5100);
  static const LatLng _defaultLivreur = LatLng(3.8680, 11.5150);

  late LatLng _clientPos;
  late LatLng _livreurPos;

  // Real order data
  Map<String, dynamic>? _order;
  String? _delivererId;
  String _delivererName = 'Livreur';
  double _delivererRating = 0.0;

  int _currentStep = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _orderSub;
  StreamSubscription<List<Map<String, dynamic>>>? _posSub;
  Timer? _movementTimer;
  int _movementStep = 0;
  static const int _totalSteps = 20;

  static const _statusIndex = {
    'pending': 0,
    'confirmed': 1,
    'preparing': 2,
    'on_the_way': 3,
    'delivered': 4,
  };

  Set<Marker> get _markers => {
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
          infoWindow: InfoWindow(title: _delivererName),
        ),
      };

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_livreurPos, _clientPos],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };

  @override
  void initState() {
    super.initState();
    _clientPos = _defaultClient;
    _livreurPos = _defaultLivreur;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _loadOrderAndSubscribe();
    _initGps();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _orderSub?.cancel();
    _posSub?.cancel();
    _movementTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderAndSubscribe() async {
    try {
      final data = await _client
          .from('orders')
          .select(
              '*, profiles!orders_client_id_fkey(full_name),'
              'delivery_agents:delivery_agent_id(id, profiles(full_name, phone), rating)')
          .eq('id', widget.orderId)
          .maybeSingle();

      if (data != null && mounted) {
        _applyOrderData(Map<String, dynamic>.from(data as Map));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() {});
    }

    // Subscribe to order status changes
    _orderSub = _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((rows) {
      if (rows.isNotEmpty && mounted) {
        _applyOrderData(rows.first);
      }
    });
  }

  void _applyOrderData(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    final stepIdx = _statusIndex[status] ?? 0;

    final agentRaw = data['delivery_agents'];
    String delivererName = 'Livreur';
    double delivererRating = 0.0;
    String? delivererId;

    if (agentRaw is Map) {
      delivererId = agentRaw['id'] as String?;
      delivererRating =
          (agentRaw['rating'] as num?)?.toDouble() ?? 0.0;
      final profile = agentRaw['profiles'] as Map?;
      delivererName =
          profile?['full_name'] as String? ?? 'Livreur';
    }

    setState(() {
      _order = data;
      _currentStep = stepIdx;
      _delivererName = delivererName;
      _delivererRating = delivererRating;
      _delivererId = delivererId;
    });

    // Subscribe to delivery agent position if available
    if (delivererId != null && _posSub == null) {
      _subscribeDelivererPosition(delivererId);
    }
  }

  void _subscribeDelivererPosition(String agentId) {
    _posSub = _client
        .from('delivery_positions')
        .stream(primaryKey: ['delivery_agent_id'])
        .eq('delivery_agent_id', agentId)
        .listen((rows) {
      if (rows.isNotEmpty && mounted) {
        final row = rows.first;
        final lat = (row['latitude'] as num?)?.toDouble();
        final lng = (row['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() => _livreurPos = LatLng(lat, lng));
          _mapController.future.then((ctrl) {
            ctrl.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _livreurPos, zoom: 14.5),
            ));
          });
        }
      }
    });
  }

  Future<void> _initGps() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startSimulation();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _startSimulation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _clientPos =
              LatLng(position.latitude, position.longitude);
          if (_posSub == null) {
            // No real deliverer position; start simulation
            _livreurPos = LatLng(
              position.latitude - 0.004,
              position.longitude + 0.003,
            );
          }
        });
        _mapController.future.then((ctrl) {
          ctrl.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _clientPos, zoom: 14.5),
          ));
        });
      }
    } catch (_) {
    } finally {
      if (_posSub == null) _startSimulation();
    }
  }

  void _startSimulation() {
    _movementTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_posSub != null) { timer.cancel(); return; }
      if (_movementStep >= _totalSteps) { timer.cancel(); return; }

      _movementStep++;
      final t = _movementStep / _totalSteps;
      final noise = math.sin(_movementStep * 0.8) * 0.0002;

      setState(() {
        _livreurPos = LatLng(
          _lerp(_defaultLivreur.latitude, _clientPos.latitude, t) +
              noise,
          _lerp(_defaultLivreur.longitude, _clientPos.longitude,
              t) + noise,
        );
      });

      _mapController.future.then((ctrl) {
        ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _livreurPos, zoom: 14.5),
        ));
      });
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shortId = widget.orderId.length >= 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId;

    final steps = [
      (l.trackStepOrdered, _order?['created_at'] != null
          ? _fmtTime(_order!['created_at'] as String)
          : '--:--'),
      (l.trackStepConfirmed, '--:--'),
      (l.trackStepPreparing, '--:--'),
      (l.trackStepOnTheWay, '--:--'),
      (l.trackStepDelivered, '--:--'),
    ];

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
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
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
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
                        color: AppColors.primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('#$shortId',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── ETA banner ────────────────────────────
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
                                      Icons
                                          .delivery_dining_rounded,
                                      color: Colors.white,
                                      size: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(l.estimatedArrival,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(
                                                alpha: 0.8))),
                                Text(
                                  _currentStep >= 3
                                      ? 'En route'
                                      : 'En attente',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Google Map ────────────────────────────
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: context.borderColor),
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

                      // ── Progress steps ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          children:
                              List.generate(steps.length, (i) {
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
                              pulseAnim:
                                  active ? _pulseAnim : null,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Deliverer card ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      AppColors.primaryLight,
                                  child: Text(
                                      _delivererName.isNotEmpty
                                          ? _delivererName[0]
                                              .toUpperCase()
                                          : 'L',
                                      style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.w700,
                                          color:
                                              AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_delivererName,
                                          style:
                                              GoogleFonts.poppins(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.color)),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.star_rounded,
                                              color:
                                                  AppColors.warning,
                                              size: 14),
                                          Text(
                                              _delivererRating > 0
                                                  ? ' ${_delivererRating.toStringAsFixed(1)} · Moto'
                                                  : ' — · Moto',
                                              style: GoogleFonts
                                                  .poppins(
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
                                      icon: Icons
                                          .chat_bubble_rounded,
                                      color: AppColors.primary,
                                      onTap: () {
                                        if (_delivererId != null) {
                                          context.push(
                                            '/client/chat/$_delivererId',
                                            extra: _delivererName,
                                          );
                                        }
                                      },
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

  String _fmtTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

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
            color: AppColors.primary, shape: BoxShape.circle),
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
                  shape: BoxShape.circle),
              child: const Icon(
                  Icons.radio_button_checked_rounded,
                  color: Colors.white,
                  size: 14),
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
      {required this.icon,
      required this.color,
      required this.onTap});

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
