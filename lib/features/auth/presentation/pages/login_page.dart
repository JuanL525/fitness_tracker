import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_animations.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const LoginPage({super.key, required this.onAuthSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate950,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            widget.onAuthSuccess();
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.rose500,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical -
                    AppTheme.screenPadding.vertical,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.emerald400.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'FITNESS TRACKER',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.4,
                              color: AppTheme.emerald400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: child,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald400.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.emerald400,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.dumbbell,
                                size: 40,
                                color: AppTheme.emerald400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Fitness Tracker',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Accede de forma segura y comienza\na registrar tu actividad',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 28),
                            const Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _FeaturePill(
                                  icon: LucideIcons.footprints,
                                  label: 'Pasos',
                                  color: AppTheme.blue400,
                                ),
                                _FeaturePill(
                                  icon: LucideIcons.map,
                                  label: 'GPS',
                                  color: AppTheme.emerald400,
                                ),
                                _FeaturePill(
                                  icon: LucideIcons.shield_alert,
                                  label: 'Caídas',
                                  color: AppTheme.rose500,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return Column(
                          children: [
                            if (isLoading)
                              const SizedBox(
                                height: 120,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.emerald400,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthenticateRequested());
                                },
                                child: PulseRing(
                                  size: 132,
                                  color: AppTheme.emerald400,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald400,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.emerald400
                                              .withValues(alpha: 0.4),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      LucideIcons.fingerprint_pattern,
                                      size: 48,
                                      color: AppTheme.slate950,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 22),
                            Text(
                              isLoading
                                  ? 'Verificando identidad…'
                                  : 'Toca para autenticar con huella',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rápido, privado y seguro en tu dispositivo',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Tus datos se guardan solo en este teléfono',
                      style: Theme.of(context).textTheme.bodySmall,
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
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
