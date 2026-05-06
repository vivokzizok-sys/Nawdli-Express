import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../domain/entities/user_entity.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

class PendingApprovalScreen extends StatelessWidget {
  final UserEntity user;

  const PendingApprovalScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 60,
                color: AppColors.black,
              ),
              const SizedBox(height: 18),
              Text(context.t('waiting_approval'), style: AppTextStyles.title1),
              const SizedBox(height: 8),
              Text(
                user.role == UserRole.driver
                    ? context.t('driver_approval_body')
                    : user.role == UserRole.store
                    ? context.t('store_approval_body')
                    : context.t('client_approval_body'),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: context.t('refresh_status'),
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthRefreshRequested()),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthSignOutRequested()),
                child: Text(context.t('sign_out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
