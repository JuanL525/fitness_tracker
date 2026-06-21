import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_animations.dart';

/// Tarjeta animada con franja de acento sólida.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.child,
    this.animationIndex = 0,
    this.accentColor,
    this.icon,
  });

  final Widget child;
  final int animationIndex;
  final Color? accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.stepsAccent;

    return FadeSlideIn(
      delay: Duration(milliseconds: 120 + (animationIndex * 90)),
      child: Container(
        decoration: AppTheme.softCard(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, color: color),
            Padding(
              padding: AppTheme.cardPadding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge cuadrado con color plano para iconos de sección.
class AccentIconBadge extends StatelessWidget {
  const AccentIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Encabezado de sección con icono de color.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isActive,
    required this.onToggle,
    this.activeLabel = 'Detener',
    this.inactiveLabel = 'Iniciar',
    this.icon,
    this.accentColor,
    this.activeSubtitleColor,
  });

  final String title;
  final String? subtitle;
  final bool isActive;
  final VoidCallback onToggle;
  final String activeLabel;
  final String inactiveLabel;
  final IconData? icon;
  final Color? accentColor;
  final Color? activeSubtitleColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.stepsAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              AccentIconBadge(icon: icon!, color: color),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: AppTheme.animFast,
                      child: Text(
                        subtitle!,
                        key: ValueKey(subtitle),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? (activeSubtitleColor ?? color)
                                  : AppTheme.inkMuted,
                              fontWeight: isActive ? FontWeight.w600 : null,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SessionToggleButton(
              isActive: isActive,
              onPressed: onToggle,
              activeLabel: activeLabel,
              inactiveLabel: inactiveLabel,
              accentColor: color,
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SessionToggleButton extends StatelessWidget {
  const SessionToggleButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.activeLabel = 'Detener',
    this.inactiveLabel = 'Iniciar',
    this.accentColor,
  });

  final bool isActive;
  final VoidCallback onPressed;
  final String activeLabel;
  final String inactiveLabel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.stepsAccent;

    return AnimatedSwitcher(
      duration: AppTheme.animFast,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: isActive
          ? FilledButton.tonalIcon(
              key: const ValueKey('stop'),
              onPressed: onPressed,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(activeLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.redBg,
                foregroundColor: AppTheme.red,
              ),
            )
          : FilledButton.icon(
              key: const ValueKey('start'),
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(inactiveLabel),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        curve: AppTheme.animCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.cyan;
    final bg = backgroundColor ?? color.withValues(alpha: 0.15);

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: AppTheme.animFast,
            child: Text(
              value,
              key: ValueKey(value),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
  });

  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.yellowBg;
    final iconC = iconColor ?? AppTheme.orange;
    final border = borderColor ?? iconC;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconC),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink,
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
