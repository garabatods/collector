import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_text_field.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final isLogin = controller.mode == AuthMode.login;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.authGlow,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Text(
                        'THE DIGITAL CURATOR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      CollectorPanel(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        backgroundColor:
                            AppColors.surfaceContainer.withValues(alpha: 0.78),
                        child: Column(
                          children: [
                            _ModeSwitcher(controller: controller),
                            const SizedBox(height: AppSpacing.xxl),
                            AutofillGroup(
                              child: Column(
                                children: [
                                  CollectorTextField(
                                    label: 'Email Address',
                                    hintText: 'curator@archive.com',
                                    controller: controller.emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _PasswordHeader(isLogin: isLogin),
                                  const SizedBox(height: AppSpacing.xs),
                                  CollectorTextField(
                                    label: '',
                                    hintText: '••••••••',
                                    controller: controller.passwordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                  ),
                                  if (controller.errorMessage != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        controller.errorMessage!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.error,
                                            ),
                                      ),
                                    ),
                                  ],
                                  if (controller.statusMessage != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        controller.statusMessage!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.lg),
                                  SizedBox(
                                    width: double.infinity,
                                    child: CollectorButton(
                                      label: isLogin
                                          ? 'Access Archive'
                                          : 'Create Archive',
                                      onPressed: controller.submit,
                                      isLoading: controller.isLoading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'EVERY ACQUISITION METICULOUSLY CURATED.\nSECURE ACCESS TO THE COLLECTOR\'S VAULT.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Login',
              selected: controller.mode == AuthMode.login,
              onTap: () => controller.setMode(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Join',
              selected: controller.mode == AuthMode.join,
              onTap: () => controller.setMode(AuthMode.join),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor:
            selected ? AppColors.primaryContainer.withValues(alpha: 0.1) : null,
        foregroundColor:
            selected ? AppColors.primary : AppColors.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.small,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _PasswordHeader extends StatelessWidget {
  const _PasswordHeader({
    required this.isLogin,
  });

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'PASSWORD',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        if (isLogin)
          Text(
            'FORGOT PASSWORD?',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                ),
          ),
      ],
    );
  }
}
