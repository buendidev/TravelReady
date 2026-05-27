import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_storage.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_text_field.dart';

class LoginPage extends StatefulWidget {
  /// Email pre-rellenado cuando se llega desde el registro.
  final String? prefillEmail;
  const LoginPage({super.key, this.prefillEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey       = GlobalKey<FormState>();
  late final _emailCtrl    = TextEditingController(text: widget.prefillEmail ?? '');
  final _passwordCtrl  = TextEditingController();
  bool _obscure        = true;
  bool _isFirstTime    = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final onboarded = await SecureStorageService.isOnboarded();
    if (mounted) setState(() => _isFirstTime = !onboarded);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));
  }

  void _googleSignIn() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusDefault)),
            ));
        }
        // AuthAuthenticated → el guard del router redirige a /home automáticamente
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
              vertical:   AppSizes.screenPaddingV,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.xl),

                  // Logo
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.luggage_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Text(AppStrings.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: AppColors.primary)),
                  ]),

                  const SizedBox(height: AppSizes.xxxl),

                  Text(
                    _isFirstTime ? l10n.welcomeFirstTime : l10n.welcomeBack,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _isFirstTime ? l10n.subtitleFirstTime : l10n.subtitleLogin,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),

                  // Banner si viene del registro
                  if (widget.prefillEmail != null) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusDefault),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            l10n.accountCreatedBanner,
                            style: TextStyle(
                                color: AppColors.success, fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: AppSizes.xl),

                  // Email
                  TRTextField(
                    label: AppStrings.email,
                    hint: l10n.hintEmail,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofocus: widget.prefillEmail == null,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.errorEmptyField;
                      }
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$')
                          .hasMatch(v.trim())) {
                        return AppStrings.errorInvalidEmail;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Contraseña
                  TRTextField(
                    label: AppStrings.password,
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    // Si viene del registro, hacer foco automático en contraseña
                    autofocus: widget.prefillEmail != null,
                    onFieldSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: AppSizes.iconMd,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.errorEmptyField;
                      }
                      if (v.length < 6) return AppStrings.errorWeakPassword;
                      return null;
                    },
                  ),

                  // ¿Olvidaste contraseña?
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.resetPassword),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Botón login
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => TRButton(
                      label: AppStrings.login,
                      isLoading: state is AuthLoading,
                      onPressed: state is AuthLoading ? null : _submit,
                    ),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Divisor
                  Row(children: [
                    Expanded(child: Container(
                        height: 1,
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md),
                      child: Text(l10n.or,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(child: Container(
                        height: 1,
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight)),
                  ]),

                  const SizedBox(height: AppSizes.md),

                  // Google
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => TRButton(
                      label: AppStrings.signInGoogle,
                      isOutlined: true,
                      isLoading: state is AuthLoading,
                      onPressed: state is AuthLoading ? null : _googleSignIn,
                      icon: const Icon(Icons.g_mobiledata_rounded,
                          size: 24, color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // Link registro
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(AppStrings.noAccount,
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '  ${AppStrings.register}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
