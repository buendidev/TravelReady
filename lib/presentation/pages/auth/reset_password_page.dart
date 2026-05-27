import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_text_field.dart';

/// Pantalla para restablecer la contraseña por email.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading    = false;
  bool _sent       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final result = await getIt<AuthRepository>()
        .resetPassword(_emailCtrl.text.trim().toLowerCase());

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).resetPasswordTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPaddingH),
          child: _sent ? _SuccessView(email: _emailCtrl.text) : _FormView(
            formKey: _formKey,
            emailCtrl: _emailCtrl,
            loading: _loading,
            isDark: isDark,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final bool isDark;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(AppLocalizations.of(context).forgotPasswordQuestion,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSizes.sm),
          Text(
            AppLocalizations.of(context).forgotPasswordDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: AppSizes.xl),
          TRTextField(
            label: AppLocalizations.of(context).email,
            hint: AppLocalizations.of(context).hintEmail,
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              final l10n = AppLocalizations.of(context);
              if (v == null || v.isEmpty) return l10n.requiredField;
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(v.trim())) {
                return l10n.emailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.xl),
          TRButton(
            label: AppLocalizations.of(context).sendLink,
            isLoading: loading,
            onPressed: loading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppColors.success, size: 40),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(AppLocalizations.of(context).emailSentTitle,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSizes.sm),
        Text(
          AppLocalizations.of(context).emailSentDesc(email),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xl),
        TRButton(
          label: AppLocalizations.of(context).backToLogin,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
