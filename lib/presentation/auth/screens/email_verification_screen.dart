import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/user_entity.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

class EmailVerificationScreen extends StatelessWidget {
  final UserEntity user;

  const EmailVerificationScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 60,
                color: AppColors.accent,
              ),
              const SizedBox(height: 18),
              const Text('Verify your email', style: AppTextStyles.title1),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to ${user.email}. The app will continue automatically after verification.',
                style: AppTextStyles.body.copyWith(color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'I Verified My Email',
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthRefreshRequested()),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context
                    .read<AuthBloc>()
                    .add(AuthResendVerificationRequested()),
                child: const Text('Resend email'),
              ),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthSignOutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
