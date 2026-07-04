import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/holla_background.dart';

const _kAdminColor = Color(0xFFE53935);

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tab;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _search = '';

  final _statuses = ['Tous', 'pending', 'confirmed', 'preparing', 'on_the_way', 'delivered', 'cancelled'];
  final _statusLabels = ['Tous', 'En attente', 'Confirmé', 'Préparation', 'En route', 'Livré', 'Annulé'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadOrders();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await _client
          .from('orders')
          .select('*, profiles!orders_client_id_fkey(full_name, email)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _orders;
    final status = _statuses[_tab.index];
    if (status != 'Tous') list = list.where((o) => o['status'] == status).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) =>
          (o['id'] ?? '').toString().toLowerCase().contains(q) ||
          ((o['profiles'] as Map?)??{})['full_name']?.toString().toLowerCase().contains(q) == true).toList();
    }
    return list;
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text('Supervision des commandes',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher commande ou client...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C2A) : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: _kAdminColor,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: _kAdminColor,
                tabs: _statusLabels.map((s) => Tab(text: s)).toList(),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kAdminColor))
                    : _filtered.isEmpty
                        ? Center(child: Text('Aucune commande',
                            style: GoogleFonts.poppins(color: AppColors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _OrderTile(
                              order: _filtered[i],
                              isDark: isDark,
                              onUpdateStatus: _updateStatus,
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

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;
  final Function(String, String) onUpdateStatus;

  const _OrderTile({required this.order, required this.isDark, required this.onUpdateStatus});

  Color _statusColor(String? s) => switch (s) {
    'pending'     => AppColors.warning,
    'confirmed'   => const Color(0xFF5C6BC0),
    'preparing'   => const Color(0xFFFF9800),
    'on_the_way'  => AppColors.secondary,
    'delivered'   => const Color(0xFF43A047),
    'cancelled'   => _kAdminColor,
    _             => AppColors.grey,
  };

  String _statusLabel(String? s) => switch (s) {
    'pending'     => 'En attente',
    'confirmed'   => 'Confirmé',
    'preparing'   => 'Préparation',
    'on_the_way'  => 'En route',
    'delivered'   => 'Livré',
    'cancelled'   => 'Annulé',
    _             => s ?? '—',
  };

  @override
  Widget build(BuildContext context) {
    final id = (order['id'] ?? '').toString();
    final shortId = id.length > 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id';
    final status = order['status'] as String?;
    final total  = order['total_amount'] as int? ?? 0;
    final client = (order['profiles'] as Map?)?['full_name'] ?? 'Client inconnu';
    final createdAt = (order['created_at'] as String? ?? '').replaceAll('T', ' ');
    final date = createdAt.length > 16 ? createdAt.substring(0, 16) : createdAt;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long_rounded, color: _statusColor(status), size: 22),
        ),
        title: Row(
          children: [
            Text(shortId, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_statusLabel(status),
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: $client', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
            Text('$date • $total FCFA', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          onSelected: (v) => onUpdateStatus(id, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'confirmed',  child: Text('Confirmer')),
            const PopupMenuItem(value: 'preparing',  child: Text('En préparation')),
            const PopupMenuItem(value: 'on_the_way', child: Text('En route')),
            const PopupMenuItem(value: 'delivered',  child: Text('Marquer livré')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'cancelled',
                child: Text('Annuler', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
