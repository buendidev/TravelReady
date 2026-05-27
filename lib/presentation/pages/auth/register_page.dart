import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(AuthSignUpRequested(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
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
        // Registro exitoso → ir a login con mensaje y email prellenado
        if (state is AuthRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.accountCreatedSnack),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault)),
          ));
          // Navega a login pasando el email como extra para prellenarlo
          context.go(AppRoutes.login, extra: state.email);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
              vertical: AppSizes.screenPaddingV,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.register,
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    l10n.subtitleRegister,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Nombre
                  TRTextField(
                    label: l10n.name,
                    hint: l10n.hintName,
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.errorEmptyField;
                      }
                      if (v.trim().length < 2) {
                        return 'Mínimo 2 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Email
                  TRTextField(
                    label: AppStrings.email,
                    hint: l10n.hintEmail,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                    hint: l10n.hintPassword,
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.next,
                    suffix: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.errorEmptyField;
                      }
                      if (v.length < 6) return AppStrings.errorWeakPassword;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Confirmar contraseña
                  TRTextField(
                    label: l10n.confirmPassword,
                    hint: l10n.hintConfirmPassword,
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.errorEmptyField;
                      }
                      if (v != _passCtrl.text) {
                        return AppStrings.errorPasswordMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => TRButton(
                      label: l10n.register,
                      isLoading: state is AuthLoading,
                      onPressed: state is AuthLoading ? null : _submit,
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(l10n.hasAccount,
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '  ${l10n.login}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
