// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double width;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);

    return SizedBox(
      width: width,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: variant == ButtonVariant.primary
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: variant != ButtonVariant.primary ? colors.background : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: variant == ButtonVariant.primary
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: variant == ButtonVariant.secondary
              ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: colors.foreground, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonColors _resolveColors(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return _ButtonColors(
          background: const Color(0xFF4CAF50),
          foreground: Colors.white,
        );
      case ButtonVariant.secondary:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: const Color(0xFF4CAF50),
        );
      case ButtonVariant.danger:
        return _ButtonColors(
          background: const Color(0xFFEF5350),
          foreground: Colors.white,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  const _ButtonColors({required this.background, required this.foreground});
}
