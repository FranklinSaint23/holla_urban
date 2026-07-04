import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';

enum _PayMethod { mtn, orange, card, cash }

class PaymentScreen extends StatefulWidget {
  final int total;
  const PaymentScreen({super.key, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _method = _PayMethod.mtn;
  bool _loading = false;
  final _phoneCtrl = TextEditingController();

  static const _camPayUrl = 'https://demo.campay.net/api';
  static const _camPayToken = String.fromEnvironment(
    'CAMPAY_TOKEN',
    defaultValue: 'YOUR_CAMPAY_TOKEN',
  );

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  bool get _isMobilePayment =>
      _method == _PayMethod.mtn || _method == _PayMethod.orange;

  int get _deliveryFee => 1500;
  int get _grandTotal => widget.total + _deliveryFee;

  String get _orderRef =>
      'HOLLA-${DateTime.now().millisecondsSinceEpoch}';

  String get _orderDesc =>
      'Commande HOLLA #HL-${DateTime.now().millisecondsSinceEpoch % 10000}';

  // ── Payment logic ─────────────────────────────────────────────────────

  Future<void> _pay() async {
    if (_isMobilePayment) {
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _showError('Veuillez saisir votre numéro de téléphone.');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      if (_isMobilePayment) {
        await _payCamPay();
      } else {
        await _payOffline();
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payCamPay() async {
    final phone = _phoneCtrl.text.trim();
    final externalRef = _orderRef;

    // 1. Initier la collecte
    final collectRes = await http.post(
      Uri.parse('$_camPayUrl/collect/'),
      headers: {
        'Authorization': 'Token $_camPayToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': _grandTotal.toString(),
        'currency': 'XAF',
        'from': phone,
        'description': _orderDesc,
        'external_reference': externalRef,
      }),
    );

    if (collectRes.statusCode != 200) {
      throw Exception('Erreur CamPay: ${collectRes.body}');
    }

    final collectData = jsonDecode(collectRes.body) as Map<String, dynamic>;
    final ref = collectData['reference'] as String;

    // 2. Polling du statut (max 30 s, toutes les 3 s)
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 3));

      final statusRes = await http.get(
        Uri.parse('$_camPayUrl/transaction/$ref/'),
        headers: {'Authorization': 'Token $_camPayToken'},
      );

      if (statusRes.statusCode == 200) {
        final st = jsonDecode(statusRes.body) as Map<String, dynamic>;
        final status = st['status'] as String?;

        if (status == 'SUCCESSFUL') {
          // 3. Enregistrer dans Supabase
          await Supabase.instance.client.from('payments').insert({
            'amount': _grandTotal,
            'method': _method == _PayMethod.mtn ? 'mtn' : 'orange',
            'phone': phone,
            'campay_ref': ref,
            'status': 'successful',
          });
          _showSuccess();
          return;
        } else if (status == 'FAILED') {
          throw Exception('Paiement refusé par l\'opérateur');
        }
      }
    }

    throw Exception('Délai d\'attente dépassé. Vérifiez votre solde.');
  }

  Future<void> _payOffline() async {
    // Simuler un court délai pour le feedback visuel
    await Future.delayed(const Duration(seconds: 1));

    final method = _method == _PayMethod.card ? 'card' : 'cash';

    await Supabase.instance.client.from('payments').insert({
      'amount': _grandTotal,
      'method': method,
      'phone': null,
      'campay_ref': null,
      'status': 'pending',
    });

    _showSuccess();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────

  void _showSuccess() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Paiement réussi !',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre commande a été confirmée.',
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
                  context.go('/client/home');
                },
                child: const Text('Retour à l\'accueil'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            const SizedBox(height: 16),
            Text(
              'Paiement échoué',
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
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Réessayer'),
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
    final l = AppLocalizations.of(context);

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
                    Text(
                      l.paymentTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.jpeg',
                            width: 36, fit: BoxFit.cover),
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
                    // ── Summary ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l.summary,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.color),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'COMMANDE #HL-892',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _Row(
                              label: l.subtotal,
                              value: '${widget.total} FCFA'),
                          const SizedBox(height: 6),
                          _Row(
                              label: l.deliveryFee,
                              value: '$_deliveryFee FCFA'),
                          Divider(height: 20, color: context.borderColor),
                          _Row(
                            label: l.total,
                            value: '$_grandTotal FCFA',
                            bold: true,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Payment methods ─────────────────────────────
                    Text(
                      l.paymentMethod,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.color),
                    ),
                    const SizedBox(height: 14),

                    _PayOption(
                      method: _PayMethod.mtn,
                      selected: _method,
                      title: 'MTN Mobile Money',
                      subtitle: l.mtnDesc,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC02),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'MTN',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black),
                          ),
                        ),
                      ),
                      onTap: () =>
                          setState(() => _method = _PayMethod.mtn),
                    ),
                    const SizedBox(height: 10),

                    _PayOption(
                      method: _PayMethod.orange,
                      selected: _method,
                      title: 'Orange Money',
                      subtitle: l.orangeDesc,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6600),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'OM',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      onTap: () =>
                          setState(() => _method = _PayMethod.orange),
                    ),
                    const SizedBox(height: 10),

                    _PayOption(
                      method: _PayMethod.card,
                      selected: _method,
                      title: 'Carte Bancaire',
                      subtitle: l.cardDesc,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.credit_card_rounded,
                            color: AppColors.primary),
                      ),
                      onTap: () =>
                          setState(() => _method = _PayMethod.card),
                    ),
                    const SizedBox(height: 10),

                    _PayOption(
                      method: _PayMethod.cash,
                      selected: _method,
                      title: l.cashTitle,
                      subtitle: l.cashDesc,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.payments_outlined,
                            color: AppColors.success),
                      ),
                      onTap: () =>
                          setState(() => _method = _PayMethod.cash),
                    ),

                    // ── Champ téléphone (MTN / Orange uniquement) ────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _isMobilePayment
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Numéro de téléphone',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.color),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: _method == _PayMethod.mtn
                                          ? '6XX XXX XXX (MTN)'
                                          : '6XX XXX XXX (Orange)',
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _method == _PayMethod.mtn
                                                ? const Color(0xFFFFCC02)
                                                : const Color(0xFFFF6600),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '+237',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _method == _PayMethod.mtn
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 14, color: AppColors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Vous recevrez une demande de confirmation sur votre téléphone.',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: context.subtextColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 28),
                    HollaButton(
                      label: l.payBtn('$_grandTotal'),
                      onPressed: _pay,
                      isLoading: _loading,
                      leading: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        l.securedBy,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.subtextColor),
                      ),
                    ),
                    const SizedBox(height: 24),
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _PayOption extends StatelessWidget {
  final _PayMethod method, selected;
  final String title, subtitle;
  final Widget leading;
  final VoidCallback onTap;

  const _PayOption({
    required this.method,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = method == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : context.borderColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: active
                            ? AppColors.primary
                            : Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: context.subtextColor),
                  ),
                ],
              ),
            ),
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: active ? AppColors.primary : context.subtextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold
                  ? Theme.of(context).textTheme.titleMedium?.color
                  : context.subtextColor),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
              fontSize: bold ? 17 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ??
                  Theme.of(context).textTheme.titleSmall?.color),
        ),
      ],
    );
  }
}
