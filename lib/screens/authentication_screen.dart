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
    final isJoin = controller.mode == AuthMode.join;
    final isForgotPassword = controller.isForgotPasswordMode;
    final isResetPassword = controller.isPasswordRecoveryMode;
    final hasAccountConfirmationMessage = isJoin &&
        (controller.statusMessage ?? '').startsWith('Account created.');
    final showEmailField = !isResetPassword;
    final showPasswordField =
        (isLogin || isJoin || isResetPassword) && !hasAccountConfirmationMessage;
    final showConfirmPasswordField = isResetPassword;
    final showSignupFields = !hasAccountConfirmationMessage;
    final showPanelIntro = !isResetPassword;
    final panelTitle = isForgotPassword
        ? 'Recover Access'
        : isResetPassword
        ? 'Choose a New Password'
        : hasAccountConfirmationMessage
        ? 'Check your email'
        : isJoin
        ? 'Create your archive account'
        : 'Access your archive';
    final panelDescription = isForgotPassword
        ? 'Enter your email and we will send you a secure reset link.'
        : isResetPassword
        ? 'This recovery link is active on this device. Set a new password to continue.'
        : hasAccountConfirmationMessage
        ? 'We sent a confirmation link to finish setting up your Ownzith account.'
        : 'Sign in or create an account to unlock your collection.';
    final submitLabel = isForgotPassword
        ? 'Send reset link'
        : isResetPassword
        ? 'Save new password'
        : hasAccountConfirmationMessage
        ? 'Back to login'
        : isLogin
        ? 'Access Archive'
        : 'Create Archive';
    final emailHint = isJoin ? 'you@ownzith.com' : 'name@email.com';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF111633),
                    AppColors.background,
                    Color(0xFF090C13),
                  ],
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/img/Splash_ownzith.png'),
                  fit: BoxFit.cover,
                  opacity: 0.06,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.01),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tertiary.withValues(alpha: 0.12),
                    AppColors.tertiary.withValues(alpha: 0.01),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthCompactHeader(
                        eyebrow: isForgotPassword
                            ? 'RESET ACCESS'
                            : isResetPassword
                            ? 'SECURE YOUR ARCHIVE'
                            : isJoin
                            ? 'START YOUR OWNZITH ARCHIVE'
                            : 'WELCOME BACK',
                        title: isForgotPassword
                            ? 'Recover your account'
                            : isResetPassword
                            ? 'Choose a new password'
                            : isJoin
                            ? 'Create your Ownzith account'
                            : 'Ownzith',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CollectorPanel(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        backgroundColor:
                            AppColors.surfaceContainer.withValues(alpha: 0.84),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isForgotPassword && !isResetPassword)
                              _ModeSwitcher(controller: controller),
                            if (!isForgotPassword && !isResetPassword)
                              const SizedBox(height: AppSpacing.xl),
                            if (showPanelIntro) ...[
                              Text(
                                panelTitle,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                panelDescription,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            if (hasAccountConfirmationMessage) ...[
                              _EmailConfirmationCard(
                                email: controller.emailController.text.trim(),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: CollectorButton(
                                  label: submitLabel,
                                  onPressed: () {
                                    controller.returnToLogin();
                                  },
                                ),
                              ),
                            ] else
                              AutofillGroup(
                                child: Column(
                                  children: [
                                    if (showEmailField && showSignupFields) ...[
                                      CollectorTextField(
                                        label: 'Email Address',
                                        hintText: emailHint,
                                        controller: controller.emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: showPasswordField
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                      ),
                                      if (showPasswordField)
                                        const SizedBox(height: AppSpacing.lg),
                                    ],
                                    if (showPasswordField) ...[
                                      if (!isResetPassword) ...[
                                        _PasswordHeader(
                                          showForgotAction: isLogin,
                                          onForgotPassword:
                                              controller.showForgotPassword,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                      ],
                                      CollectorTextField(
                                        label: isResetPassword
                                            ? 'New Password'
                                            : '',
                                        hintText: '••••••••',
                                        controller:
                                            controller.passwordController,
                                        obscureText: true,
                                        textInputAction: showConfirmPasswordField
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        autofillHints: isResetPassword
                                            ? const [
                                                AutofillHints.newPassword,
                                              ]
                                            : const [
                                                AutofillHints.password,
                                              ],
                                      ),
                                    ],
                                    if (showConfirmPasswordField) ...[
                                      const SizedBox(height: AppSpacing.lg),
                                      CollectorTextField(
                                        label: 'Confirm Password',
                                        hintText: '••••••••',
                                        controller:
                                            controller.confirmPasswordController,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                      ),
                                    ],
                                    if (controller.errorMessage != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _InlineMessage(
                                        message: controller.errorMessage!,
                                        color: AppColors.error,
                                        icon: Icons.error_outline_rounded,
                                      ),
                                    ],
                                    if (controller.statusMessage != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _InlineMessage(
                                        message: controller.statusMessage!,
                                        color: AppColors.primary,
                                        icon: Icons.mark_email_read_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.lg),
                                    SizedBox(
                                      width: double.infinity,
                                      child: CollectorButton(
                                        label: submitLabel,
                                        onPressed: controller.submit,
                                        isLoading: controller.isLoading,
                                      ),
                                    ),
                                    if (isForgotPassword ||
                                        isResetPassword) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      SizedBox(
                                        width: double.infinity,
                                        child: CollectorButton(
                                          label: 'Back to login',
                                          onPressed: () {
                                            controller.returnToLogin();
                                          },
                                          variant:
                                              CollectorButtonVariant.secondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _AuthFooterLine(),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.medium,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Log in',
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
        backgroundColor: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.14)
            : Colors.transparent,
        foregroundColor:
            selected ? AppColors.primary : AppColors.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.small,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}

class _AuthCompactHeader extends StatelessWidget {
  const _AuthCompactHeader({
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.primaryShadowStrong,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/logo_ownzith.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailConfirmationCard extends StatelessWidget {
  const _EmailConfirmationCard({
    required this.email,
  });

  final String email;

  @override
  Widget build(BuildContext context) {
    final displayEmail = email.isEmpty ? 'your email' : email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.34),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Confirmation email sent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Open the email we sent to $displayEmail and tap Confirm Email to activate your archive.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Check spam or promotions if it does not show up in a minute.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _AuthFooterLine extends StatelessWidget {
  const _AuthFooterLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ownzith keeps your scans, photos, and collection details together so every shelf feels easier to manage.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.45,
          ),
    );
  }
}

class _PasswordHeader extends StatelessWidget {
  const _PasswordHeader({
    required this.showForgotAction,
    this.onForgotPassword,
  });

  final bool showForgotAction;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'PASSWORD',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        if (showForgotAction)
          TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'FORGOT PASSWORD?',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
      ],
    );
  }
}
