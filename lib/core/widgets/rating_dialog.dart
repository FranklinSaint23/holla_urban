import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Dialog de notation affiché après une livraison ou prestation.
///
/// Usage :
/// ```dart
/// RatingDialog.show(context,
///   orderId: 'order-uuid',
///   targetId: 'partner-uuid',
///   targetType: 'partner',
/// );
/// ```
class RatingDialog extends StatefulWidget {
  final String orderId;
  final String targetId;
  final String targetType; // 'partner' | 'delivery' | 'provider'

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.targetId,
    required this.targetType,
  });

  /// Affiche le dialog depuis n'importe quel contexte.
  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String targetId,
    required String targetType,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        orderId: orderId,
        targetId: targetId,
        targetType: targetType,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _score = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String get _targetLabel {
    switch (widget.targetType) {
      case 'delivery':
        return 'le livreur';
      case 'provider':
        return 'le prestataire';
      default:
        return 'le partenaire';
    }
  }

  Future<void> _submit() async {
    if (_score == 0) {
      setState(() => _errorMessage = 'Veuillez sélectionner une note');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;

      if (uid == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Vous devez être connecté pour noter';
        });
        return;
      }

      await client.from('ratings').insert({
        'order_id': widget.orderId,
        'reviewer_id': uid,
        'target_id': widget.targetId,
        'target_type': widget.targetType,
        'score': _score,
        'comment': _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      });

      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Une erreur est survenue. Réessayez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icône ─────────────────────────────────────────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 32),
            ),
            const SizedBox(height: 16),

            // ── Titre ─────────────────────────────────────────────
            Text(
              'Évaluez votre expérience',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Comment s\'est passée votre commande avec $_targetLabel ?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Étoiles ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _score = starIndex),
                  child: AnimatedScale(
                    scale: _score >= starIndex ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _score >= starIndex
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _score >= starIndex
                            ? AppColors.warning
                            : context.borderColor,
                        size: 40,
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (_score > 0) ...[
              const SizedBox(height: 8),
              Text(
                _scoreLabel(_score),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Commentaire ───────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: context.subtextColor),
                filled: true,
                fillColor: context.isDark
                    ? const Color(0xFF1C1C2A)
                    : AppColors.light,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                counterStyle: GoogleFonts.poppins(
                    fontSize: 11, color: context.subtextColor),
              ),
            ),

            // ── Message d'erreur ──────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),

            // ── Boutons ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: context.borderColor),
                      ),
                    ),
                    child: Text(
                      'Plus tard',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.subtextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Envoyer',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scoreLabel(int score) {
    switch (score) {
      case 1:
        return 'Très décevant';
      case 2:
        return 'Décevant';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }
}
