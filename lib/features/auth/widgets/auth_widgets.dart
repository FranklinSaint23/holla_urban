import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.grey)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class SocialIconBtn extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const SocialIconBtn({super.key, required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252535) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? const Color(0xFF2E2E42) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            )
          ],
        ),
        child: Center(
          child: Image.asset(asset, width: 24, height: 24),
        ),
      ),
    );
  }
}

class SocialButtonsRow extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onApple;

  const SocialButtonsRow({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    required this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: SocialIconBtn(
                asset: 'assets/icons/google.png', onTap: onGoogle)),
        const SizedBox(width: 12),
        Expanded(
            child: SocialIconBtn(
                asset: 'assets/icons/facebook.png', onTap: onFacebook)),
        const SizedBox(width: 12),
        Expanded(
            child: SocialIconBtn(
                asset: 'assets/icons/apple.png', onTap: onApple)),
      ],
    );
  }
}
