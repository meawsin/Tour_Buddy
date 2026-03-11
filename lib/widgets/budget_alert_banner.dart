import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tour_buddy/services/budget_alert_service.dart';

class BudgetAlertBanner extends StatelessWidget {
  final BudgetAlert alert;
  final VoidCallback onDismiss;

  const BudgetAlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  Color _bgColor(BuildContext context) {
    switch (alert.level) {
      case BudgetAlertLevel.half:
        return const Color(0xFF1A6B4A); // dark green
      case BudgetAlertLevel.warning:
        return const Color(0xFF7A4A00); // dark amber
      case BudgetAlertLevel.exceeded:
        return const Color(0xFF7A1A2A); // dark red
      case BudgetAlertLevel.none:
        return Colors.transparent;
    }
  }

  Color _accentColor() {
    switch (alert.level) {
      case BudgetAlertLevel.half:
        return const Color(0xFF4ADE80); // green
      case BudgetAlertLevel.warning:
        return const Color(0xFFFBBF24); // amber
      case BudgetAlertLevel.exceeded:
        return const Color(0xFFFF6A9B); // pink/red
      case BudgetAlertLevel.none:
        return Colors.transparent;
    }
  }

  IconData _icon() {
    switch (alert.level) {
      case BudgetAlertLevel.half:
        return Icons.info_outline_rounded;
      case BudgetAlertLevel.warning:
        return Icons.warning_amber_rounded;
      case BudgetAlertLevel.exceeded:
        return Icons.error_outline_rounded;
      case BudgetAlertLevel.none:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final bg = _bgColor(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(), color: accent, size: 18),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: accent.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Dismiss button
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16, color: accent.withValues(alpha: 0.6)),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
