import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: LucideIcons.activity, label: 'Inicio'),
    (icon: LucideIcons.map, label: 'Ruta'),
    (icon: LucideIcons.history, label: 'Historial'),
  ];

  Color _accentColor(int index) {
    switch (index) {
      case 1:
        return AppTheme.rose500;
      case 2:
        return AppTheme.blue400;
      default:
        return AppTheme.emerald400;
    }
  }

  Color _iconColor(int index, bool selected) {
    if (index == 1) return AppTheme.rose500;
    if (index == 2) return AppTheme.blue400;
    return selected ? AppTheme.emerald400 : AppTheme.slate500;
  }

  Color _labelColor(int index, bool selected) {
    if (index == 1) return AppTheme.rose500;
    if (index == 2) return AppTheme.blue400;
    return selected ? AppTheme.emerald400 : AppTheme.slate500;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.slate950.withValues(alpha: 0.9),
            border: const Border(
              top: BorderSide(color: AppTheme.slate800),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = index == currentIndex;
                  final accent = _accentColor(index);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: selected
                                ? BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.45),
                                        blurRadius: 16,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              item.icon,
                              size: 26,
                              color: _iconColor(index, selected),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _labelColor(index, selected),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
