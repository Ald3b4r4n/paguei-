import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paguei/presentation/theme/app_colors.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// BillPaidSuccessOverlay  — T126
// ---------------------------------------------------------------------------

/// Full-screen modal overlay shown after a bill is marked as paid.
///
/// Features:
/// - Celebratory check-mark animation (scale + fade via flutter_animate)
/// - Light confetti burst drawn with a [CustomPainter] (no third-party library)
/// - Subtle haptic feedback on appearance
/// - Auto-dismisses after [autoDismissDelay] (default 2.8 s) or on tap
///
/// ## Usage
///
/// ```dart
/// await BillPaidSuccessOverlay.show(
///   context,
///   title: 'Boleto pago!',
///   subtitle: 'R$ 789,00 debitado da Conta Principal',
/// );
/// ```
class BillPaidSuccessOverlay extends StatefulWidget {
  const BillPaidSuccessOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.autoDismissDelay = const Duration(milliseconds: 2800),
  });

  final String title;
  final String? subtitle;
  final Duration autoDismissDelay;

  /// Shows the overlay as a [ModalRoute] and waits for dismissal.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    Duration autoDismissDelay = const Duration(milliseconds: 2800),
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => BillPaidSuccessOverlay(
          title: title,
          subtitle: subtitle,
          autoDismissDelay: autoDismissDelay,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  State<BillPaidSuccessOverlay> createState() => _BillPaidSuccessOverlayState();
}

class _BillPaidSuccessOverlayState extends State<BillPaidSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Haptic on mount — feels satisfying on successful payment
    HapticFeedback.mediumImpact();

    // Auto-dismiss
    Future.delayed(widget.autoDismissDelay, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Confetti burst ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(progress: _confettiController.value),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Central content ─────────────────────────────────────────────
            Center(
              child: _SuccessContent(
                title: widget.title,
                subtitle: widget.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content card
// ---------------------------------------------------------------------------

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Check icon ────────────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: AppColors.success,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 200.ms),

          const SizedBox(height: AppSpacing.xl),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 250.ms, duration: 350.ms)
              .slideY(begin: 0.15, end: 0),

          // ── Subtitle ──────────────────────────────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Tap to dismiss hint ───────────────────────────────────────────
          Text(
            'Toque para fechar',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti painter — lightweight, no third-party lib required
// ---------------------------------------------------------------------------

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static final _rng = math.Random(42); // fixed seed for deterministic layout

  /// 60 particles; each has a pseudo-random angle, speed, and colour.
  static final _particles = List.generate(60, (i) {
    final angle = _rng.nextDouble() * math.pi * 2;
    final speed = 0.35 + _rng.nextDouble() * 0.65;
    final size = 4.0 + _rng.nextDouble() * 6.0;
    final isRect = _rng.nextBool();
    const colors = [
      Color(0xFF2D6A4F), // green
      Color(0xFF52B788), // light green
      Color(0xFFD4A017), // amber
      Color(0xFFF9C74F), // yellow
      Color(0xFF40916C), // teal-green
      Color(0xFFB7E4C7), // pale green
    ];
    final color = colors[i % colors.length];
    return _Particle(
        angle: angle, speed: speed, size: size, isRect: isRect, color: color);
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out in the last 30% of the animation
    final opacity = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);

    for (final p in _particles) {
      final distance = p.speed * progress * size.height * 0.55;
      final x = size.width / 2 + math.cos(p.angle) * distance;
      // Gravity: y increases faster than x to simulate arc
      final y = size.height / 2 +
          math.sin(p.angle) * distance +
          progress * progress * size.height * 0.12;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      if (p.isRect) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * math.pi * 3 * p.speed);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.isRect,
    required this.color,
  });

  final double angle;
  final double speed;
  final double size;
  final bool isRect;
  final Color color;
}

// ---------------------------------------------------------------------------
// Convenience function
// ---------------------------------------------------------------------------

/// Show a bill-paid success overlay from anywhere in the widget tree.
///
/// ```dart
/// await showBillPaidSuccess(
///   context,
///   title: 'Boleto pago!',
///   subtitle: CurrencyFormatter.format(paidAmount),
/// );
/// ```
Future<void> showBillPaidSuccess(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return BillPaidSuccessOverlay.show(context, title: title, subtitle: subtitle);
}
