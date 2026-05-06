import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings.dart';
import '../../../domain/entities/user_entity.dart';

class AppMenuButton extends StatelessWidget {
  final UserEntity user;

  const AppMenuButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.t('menu'),
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => context.push('/settings'),
    );
  }
}
