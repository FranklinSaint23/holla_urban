import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

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

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String targetId,
    required String targetType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  bool _submitting = false;

  static const _labels = ['', 'Mauvais', 'Passable', 'Correct', 'Bien', 'Excellent'];

  String get _typeLabel {
    switch (widget.targetType) {
      case 'partner':
        return 'le restaurant';
      case 'delivery':
        return 'le livreur';
      case 'provider':
        return 'le prestataire';
      default:
        return 'le service';
    }
  }

  Future<void> _submit() async {
    if (_score == 0) return;
    setState(() => _submitting = true);

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      await Supabase.instance.client.from('ratings').insert({
        'order_id': widget.orderId,
        'reviewer_id': uid,
        'target_id': widget.targetId,
        'target_type': widget.targetType,
        'score': _score,
        'comment': _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merci pour votre avis !',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'avis',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text('Évaluer $_typeLabel',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
          const SizedBox(height: 6),
          Text('Votre avis aide notre communauté',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.subtextColor)),
          const SizedBox(height: 24),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final selected = star <= _score;
              return GestureDetector(
                onTap: () => setState(() => _score = star),
                child: AnimatedScale(
                  scale: selected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      selected ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: selected
                          ? AppColors.warning
                          : context.borderColor,
                    ),
                  ),
                ),
              );
            }),
          ),

          // Score label
          AnimatedOpacity(
            opacity: _score > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _labels[_score],
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Comment
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: context.subtextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: GoogleFonts.poppins(
                    fontSize: 11, color: context.subtextColor),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Plus tard',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: context.subtextColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _score > 0 && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Envoyer',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
