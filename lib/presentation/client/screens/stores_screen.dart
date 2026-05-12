import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/services/admob_config.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/models/user_model.dart';
import '../../shared/widgets/admob_banner.dart';
import '../../shared/widgets/shared_widgets.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.t('back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.popOrGo('/client/home'),
        ),
        title: Text(context.t('stores')),
      ),
      body: Column(
        children: [
          const AdMobBanner(placement: AdMobPlacement.stores),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'store')
                  .where('isApproved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final stores =
                    snap.data!.docs.map(UserModel.fromFirestore).toList()
                      ..sort((a, b) => a.fullName.compareTo(b.fullName));
                if (stores.isEmpty) {
                  return EmptyState(
                    icon: Icons.storefront_outlined,
                    title: context.t('no_stores'),
                    subtitle: context.t('no_stores_body'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final store = stores[index];
                    return InkWell(
                      onTap: () =>
                          context.push('/client/store-profile', extra: store),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.accentLight,
                              backgroundImage: store.profilePhotoBase64 == null
                                  ? null
                                  : MemoryImage(
                                      base64Decode(store.profilePhotoBase64!),
                                    ),
                              child: store.profilePhotoBase64 == null
                                  ? const Icon(Icons.storefront_outlined)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.fullName,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.t(store.storeType?.name ?? 'store'),
                                    style: AppTextStyles.caption.copyWith(
                                      color:
                                          AppColors.textSecondary(context),
                                    ),
                                  ),
                                  if (store.phoneNumber.isNotEmpty)
                                    Text(
                                      store.phoneNumber,
                                      style: AppTextStyles.caption.copyWith(
                                        color:
                                            AppColors.textSecondary(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
