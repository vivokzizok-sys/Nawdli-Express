import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/entities/order_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/widgets/app_menu_button.dart';
import '../../shared/widgets/shared_widgets.dart';

class StoreHomeScreen extends StatelessWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text(context.t('store_dashboard')),
        actions: [AppMenuButton(user: user)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemSheet(context, user.uid),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('add_menu_item')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _StoreHeader(userName: user.fullName, phone: user.phoneNumber),
          const SizedBox(height: 16),
          Text(context.t('menu_items'), style: AppTextStyles.title3),
          const SizedBox(height: 8),
          _MenuItemsList(storeId: user.uid),
          const SizedBox(height: 20),
          Text(context.t('store_orders'), style: AppTextStyles.title3),
          const SizedBox(height: 8),
          _StoreOrdersList(storeId: user.uid),
        ],
      ),
    );
  }

  Future<void> _showMenuItemSheet(BuildContext context, String storeId) async {
    final name = TextEditingController();
    final price = TextEditingController();
    final description = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t('add_menu_item'), style: AppTextStyles.title3),
              const SizedBox(height: 12),
              AppTextField(controller: name, hint: context.t('item_name')),
              const SizedBox(height: 10),
              AppTextField(
                controller: price,
                hint: context.t('item_price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: const Center(widthFactor: 1.4, child: Text('DA')),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: description,
                hint: context.t('description'),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: context.t('save_changes'),
                onPressed: () async {
                  final parsedPrice = double.tryParse(price.text.trim());
                  if (name.text.trim().isEmpty ||
                      parsedPrice == null ||
                      parsedPrice <= 0) {
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(storeId)
                      .collection('menu_items')
                      .add({
                    'name': name.text.trim(),
                    'price': parsedPrice,
                    'description': description.text.trim(),
                    'isAvailable': true,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
    name.dispose();
    price.dispose();
    description.dispose();
  }
}

class _StoreHeader extends StatelessWidget {
  final String userName;
  final String phone;

  const _StoreHeader({required this.userName, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: AppTextStyles.title3),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemsList extends StatelessWidget {
  final String storeId;

  const _MenuItemsList({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(storeId)
          .collection('menu_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snap.data!.docs.isEmpty) {
          return EmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: context.t('no_menu_items'),
            subtitle: context.t('add_first_menu_item'),
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] as String? ?? '',
                            style: AppTextStyles.bodyMedium,
                          ),
                          if ((data['description'] as String? ?? '').isNotEmpty)
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
                    IconButton(
                      tooltip: context.t('delete'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StoreOrdersList extends StatelessWidget {
  final String storeId;

  const _StoreOrdersList({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snap.data!.docs.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.t('no_orders'),
            subtitle: context.t('store_orders_empty'),
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final order = OrderModel.fromFirestore(doc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StoreOrderTile(order: order),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StoreOrderTile extends StatelessWidget {
  final OrderEntity order;

  const _StoreOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  order.storeItemName ?? order.description,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              StatusChip(
                label: context.statusText(order.status.value),
                color: _statusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${context.t('client')}: ${order.clientName}'),
          Text('${context.t('phone')}: ${order.clientPhone}'),
          Text('${context.t('delivery_address')}: ${order.dropoffAddress}'),
          if (order.driverId != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(order.driverId)
                  .get(),
              builder: (context, snap) {
                final driver = snap.data?.data();
                if (driver == null) return const SizedBox.shrink();
                final driverName =
                    driver['fullName'] as String? ?? context.t('driver');
                final driverPhone = driver['phoneNumber'] as String? ?? '';
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.t('driver')}: $driverName - $driverPhone',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('call_driver'),
                      icon: const Icon(Icons.call_rounded),
                      onPressed: driverPhone.isEmpty
                          ? null
                          : () {
                              final normalized = driverPhone.replaceAll(
                                RegExp(r'[\s\-.]'),
                                '',
                              );
                              launchUrl(Uri(scheme: 'tel', path: normalized));
                            },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.requested => AppColors.info,
        OrderStatus.priced => AppColors.warning,
        OrderStatus.rejected => AppColors.error,
        OrderStatus.open => AppColors.info,
        OrderStatus.bidding => AppColors.warning,
        OrderStatus.accepted => AppColors.accent,
        OrderStatus.inProgress => AppColors.success,
        OrderStatus.delivered => AppColors.grey400,
        OrderStatus.cancelled => AppColors.error,
      };
}
