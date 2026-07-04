import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';

class DisputesScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const DisputesScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final _client = Supabase.instance.client;
  final _descCtrl = TextEditingController();

  String? _selectedReason;
  bool _cancelOrder = false;
  bool _loading = false;

  static const _reasons = [
    'Commande incomplète',
    'Articles manquants',
    'Mauvaise qualité',
    'Livreur impoli',
    'Commande non reçue',
    'Autre',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedReason == null) {
      _showValidationError('Veuillez sélectionner un motif.');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showValidationError('Veuillez décrire le problème rencontré.');
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Insérer le litige
      await _client.from('disputes').insert({
        'order_id': widget.orderId,
        'client_id': uid,
        'reason': _selectedReason,
        'description': _descCtrl.text.trim(),
        'status': 'open',
      });

      // Annuler la commande si demandé
      if (_cancelOrder) {
        await _client
            .from('orders')
            .update({'status': 'cancelled'})
            .eq('id', widget.orderId);
      }

      _showSuccess();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────

  void _showValidationError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'Litige soumis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre litige a été enregistré. Notre équipe vous contactera dans les 24h.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/client/history');
                },
                child: const Text('Retour à l\'historique'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              'Erreur',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──────────────────────────────────────────────
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
                            Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Signaler un problème',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ── Numéro de commande ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.error,
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande concernée',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: context.subtextColor),
                              ),
                              Text(
                                '#${widget.orderNumber}',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Motifs ───────────────────────────────────────
                    Text(
                      'Motif du litige',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.color),
                    ),
                    const SizedBox(height: 12),
                    ..._reasons.map((reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedReason = reason),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedReason == reason
                                    ? AppColors.error.withValues(alpha: 0.08)
                                    : context.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedReason == reason
                                      ? AppColors.error
                                      : context.borderColor,
                                  width:
                                      _selectedReason == reason ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight:
                                            _selectedReason == reason
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                        color: _selectedReason == reason
                                            ? AppColors.error
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _selectedReason == reason
                                        ? Icons.radio_button_checked_rounded
                                        : Icons
                                            .radio_button_unchecked_rounded,
                                    color: _selectedReason == reason
                                        ? AppColors.error
                                        : context.subtextColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),

                    const SizedBox(height: 20),

                    // ── Description ──────────────────────────────────
                    Text(
                      'Description détaillée',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.color),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 5,
                      maxLength: 500,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Décrivez le problème en détail (articles manquants, quantités, état de la commande…)',
                        hintMaxLines: 3,
                        alignLabelWithHint: true,
                        counterStyle: GoogleFonts.poppins(
                            fontSize: 11, color: context.subtextColor),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Option annuler la commande ────────────────────
                    GestureDetector(
                      onTap: () =>
                          setState(() => _cancelOrder = !_cancelOrder),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cancelOrder
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _cancelOrder
                                ? AppColors.warning
                                : context.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _cancelOrder
                                    ? AppColors.warning
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _cancelOrder
                                      ? AppColors.warning
                                      : context.subtextColor,
                                  width: 1.5,
                                ),
                              ),
                              child: _cancelOrder
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Annuler la commande',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _cancelOrder
                                          ? AppColors.warning
                                          : Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.color,
                                    ),
                                  ),
                                  Text(
                                    'La commande passera au statut "annulée"',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.subtextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Bouton soumettre ─────────────────────────────
                    HollaButton(
                      label: 'Soumettre le litige',
                      onPressed: _submit,
                      isLoading: _loading,
                      leading: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Notre équipe traitera votre demande sous 24h.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: context.subtextColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
