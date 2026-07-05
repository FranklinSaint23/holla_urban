import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});
  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  bool _isAvailable = false;
  bool _availabilityLoading = true;
  final _client = Supabase.instance.client;

  int _todayJobs = 0;
  int _todayRevenue = 0;
  double _rating = 0.0;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _todaySchedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) { setState(() { _loading = false; _availabilityLoading = false; }); return; }

    try {
      // Load provider profile for availability + rating
      final provider = await _client
          .from('service_providers')
          .select('is_available, rating')
          .eq('id', uid)
          .maybeSingle();

      // Load pending service requests for this provider
      final pending = await _client
          .from('service_requests')
          .select('*, profiles!service_requests_client_id_fkey(full_name, city)')
          .eq('provider_id', uid)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(5) as List;

      // Load today's confirmed/in-progress requests (schedule)
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final schedule = await _client
          .from('service_requests')
          .select('*, profiles!service_requests_client_id_fkey(full_name, city)')
          .eq('provider_id', uid)
          .inFilter('status', ['confirmed', 'in_progress'])
          .gte('scheduled_at', todayStr)
          .order('scheduled_at') as List;

      // Count today's completed jobs and revenue
      final completed = await _client
          .from('service_requests')
          .select('fee')
          .eq('provider_id', uid)
          .eq('status', 'completed')
          .gte('completed_at', todayStr) as List;

      int rev = 0;
      for (final r in completed) {
        rev += (r['fee'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _isAvailable = provider?['is_available'] as bool? ?? false;
          _rating = ((provider?['rating'] as num?) ?? 0).toDouble();
          _pendingRequests = List<Map<String, dynamic>>.from(pending);
          _todaySchedule = List<Map<String, dynamic>>.from(schedule);
          _todayJobs = completed.length;
          _todayRevenue = rev;
          _loading = false;
          _availabilityLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _availabilityLoading = false; });
    }
  }

  Future<void> _setAvailability(bool v) async {
    setState(() => _isAvailable = v);
    try {
      await _client.from('service_providers')
          .update({'is_available': v})
          .eq('id', _client.auth.currentUser!.id);
    } catch (_) {
      if (mounted) setState(() => _isAvailable = !v);
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _client.from('service_requests')
          .update({'status': 'confirmed'})
          .eq('id', requestId);
      await _loadData();
    } catch (_) {}
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await _client.from('service_requests')
          .update({'status': 'declined'})
          .eq('id', requestId);
      await _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _client.auth.currentUser?.userMetadata?['full_name'] ?? 'Prestataire';

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 16),

                      // ── Header ──────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.providerWelcome, style: GoogleFonts.poppins(fontSize: 13, color: context.subtextColor)),
                                Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.titleLarge?.color)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            activeColor: AppColors.success,
                            onChanged: _availabilityLoading ? null : _setAvailability,
                          ),
                          Text(_isAvailable ? l.available : l.unavailable,
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: _isAvailable ? AppColors.success : AppColors.error)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Stats ────────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(child: _StatTile(Icons.work_rounded, l.todayJobs, '$_todayJobs', AppColors.warning)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatTile(Icons.payments_rounded, l.todayRevenue,
                              '${_todayRevenue > 0 ? _formatAmount(_todayRevenue) : '0'}', AppColors.success)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatTile(Icons.star_rounded, l.rating,
                              _rating > 0 ? _rating.toStringAsFixed(1) : '—', AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Pending requests ─────────────────────────────────
                      if (_pendingRequests.isNotEmpty) ...[
                        Text(l.urgentRequest,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleMedium?.color)),
                        const SizedBox(height: 12),
                        ..._pendingRequests.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                            request: req,
                            onAccept: () => _acceptRequest(req['id'] as String),
                            onDecline: () => _declineRequest(req['id'] as String),
                            onChat: () => context.push(
                              '/provider/messages',
                            ),
                          ),
                        )),
                        const SizedBox(height: 12),
                      ],

                      // ── Today's schedule ─────────────────────────────────
                      Text(l.todaySchedule,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.titleMedium?.color)),
                      const SizedBox(height: 12),
                      if (_todaySchedule.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('Aucune intervention planifiée aujourd\'hui',
                                style: GoogleFonts.poppins(fontSize: 13, color: context.subtextColor),
                                textAlign: TextAlign.center),
                          ),
                        )
                      else
                        ..._todaySchedule.map((req) {
                          final scheduledAt = req['scheduled_at'] as String? ?? '';
                          final time = scheduledAt.length > 15
                              ? scheduledAt.substring(11, 16)
                              : '--:--';
                          final client = (req['profiles'] as Map?)?['full_name'] as String? ?? 'Client';
                          final city = (req['profiles'] as Map?)?['city'] as String? ?? '';
                          final description = req['description'] as String? ?? 'Intervention';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ScheduleCard(
                              time: time,
                              client: client,
                              task: description,
                              address: city,
                            ),
                          );
                        }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onChat;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final client = (request['profiles'] as Map?)?['full_name'] as String? ?? 'Client';
    final city = (request['profiles'] as Map?)?['city'] as String? ?? '';
    final description = request['description'] as String? ?? 'Intervention requise';
    final fee = (request['estimated_fee'] as num?)?.toInt();
    final createdAt = request['created_at'] as String?;

    String relTime = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt)?.toLocal();
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inSeconds < 60) relTime = 'à l\'instant';
        else if (diff.inMinutes < 60) relTime = 'il y a ${diff.inMinutes} min';
        else relTime = 'il y a ${diff.inHours} h';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text('Nouvelle demande',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.warning)),
              const Spacer(),
              if (relTime.isNotEmpty)
                Text(relTime, style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14,
                  color: Theme.of(context).textTheme.titleSmall?.color)),
          Text('$client${city.isNotEmpty ? ' · $city' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: context.subtextColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (fee != null)
                Text('~$fee FCFA',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.success)),
              const Spacer(),
              OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text('Refuser', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text('Accepter', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatTile(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: context.subtextColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time, client, task, address;
  const _ScheduleCard({required this.time, required this.client, required this.task, required this.address});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(time, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          Container(width: 2, height: 40, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13,
                    color: Theme.of(context).textTheme.titleSmall?.color)),
                Text('$client${address.isNotEmpty ? ' · $address' : ''}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
        ],
      ),
    );
  }
}
