import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/settings/app_settings.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/widgets/shared_widgets.dart';

class StoreProfileScreen extends StatelessWidget {
  final UserEntity store;

  const StoreProfileScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.t('back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.popOrGo('/client/stores'),
        ),
        title: Text(context.t('store_profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StoreHero(store: store),
          const SizedBox(height: 18),
          PrimaryButton(
            label: context.t('call_store'),
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _call(context),
          ),
          const SizedBox(height: 20),
          Text(context.t('menu_items'), style: AppTextStyles.title3),
          const SizedBox(height: 8),
          _PublicMenu(store: store),
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    final client = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    await FirebaseFirestore.instance.collection('store_call_logs').add({
      'storeId': store.uid,
      'storeName': store.fullName,
      'storePhone': store.phoneNumber,
      'clientId': client.uid,
      'clientName': client.fullName,
      'clientPhone': client.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final normalized = store.phoneNumber.replaceAll(RegExp(r'[\s\-.]'), '');
    await launchUrl(Uri(scheme: 'tel', path: normalized));
  }
}

class _StoreHero extends StatelessWidget {
  final UserEntity store;

  const _StoreHero({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.accentLight,
                backgroundImage: store.profilePhotoBase64 == null
                    ? null
                    : MemoryImage(base64Decode(store.profilePhotoBase64!)),
                child: store.profilePhotoBase64 == null
                    ? const Icon(Icons.storefront_outlined)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.fullName, style: AppTextStyles.title2),
                    const SizedBox(height: 4),
                    Text(
                      context.t(store.storeType?.name ?? 'store'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (store.phoneNumber.isNotEmpty)
                      Text(
                        store.phoneNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((store.storeAddress ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              store.storeAddress!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicMenu extends StatelessWidget {
  final UserEntity store;

  const _PublicMenu({required this.store});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(store.uid)
          .collection('menu_items')
          .where('isAvailable', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: context.t('no_menu_items'),
            subtitle: context.t('store_menu_empty'),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final image = data['imageBase64'] as String?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => context.push(
                  '/client/store-order',
                  extra: {
                    'store': store,
                    'itemId': doc.id,
                    'item': data,
                  },
                ),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: image == null || image.isEmpty
                              ? Container(
                                  color: AppColors.surfaceAlt(context),
                                  child: const Icon(Icons.fastfood_outlined),
                                )
                              : Image.memory(
                                  base64Decode(image),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceAlt(context),
                                    child:
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] as String? ?? '',
                              style: AppTextStyles.bodyMedium,
                            ),
                            if ((data['description'] as String? ?? '')
                                .isNotEmpty)
                              Text(
                                data['description'] as String,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${price.toStringAsFixed(0)} DA',
                        style: AppTextStyles.captionMedium,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
