import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/entities/order_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../order/bloc/order_bloc.dart';
import '../../shared/widgets/app_menu_button.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'restaurant_products_section.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final Set<String> _selectedOrderIds = {};
  bool _showOrders = false;

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        leading: _showOrders
            ? IconButton(
                tooltip: context.t('back'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _showOrders = false;
                  _selectedOrderIds.clear();
                }),
              )
            : null,
        title: Text(
          !_showOrders
              ? context.t('restaurant_products')
              : _selectedOrderIds.isEmpty
                  ? context.t('my_orders')
                  : '${_selectedOrderIds.length}',
        ),
        actions: [
          if (_showOrders) ...[
            if (_selectedOrderIds.isNotEmpty) ...[
              IconButton(
                tooltip: context.t('delete_selected'),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _hideSelectedOrders(user.uid),
              ),
              IconButton(
                tooltip: context.t('cancel'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_selectedOrderIds.clear),
              ),
            ],
          ] else ...[
            IconButton(
              tooltip: context.t('my_orders'),
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () {
                context.read<OrderBloc>().add(OrderWatchClientOrders(user.uid));
                setState(() => _showOrders = true);
              },
            ),
            IconButton(
              tooltip: context.t('stores'),
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.push('/client/stores'),
            ),
            IconButton(
              tooltip: context.t('open_dashboard'),
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => context.push('/client/dashboard'),
            ),
          ],
          AppMenuButton(user: user),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/client/drivers'),
        icon: const Icon(Icons.local_shipping_outlined),
        label: Text(context.t('choose_driver')),
      ),
      body: Column(
        children: [
          _ClientActiveTripBanner(clientId: user.uid),
          Expanded(
            child: _showOrders
                ? BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrdersLoaded) {
                        if (state.orders.isEmpty) {
                          return EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: context.t('no_orders_yet'),
                            subtitle: context.t('create_first_order'),
                          );
                        }
                        final deletableIds = state.orders
                            .where(_canHide)
                            .map((order) => order.orderId)
                            .toList();
                        return Column(
                          children: [
                            if (deletableIds.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => setState(() {
                                        _selectedOrderIds
                                          ..clear()
                                          ..addAll(deletableIds);
                                      }),
                                      icon:
                                          const Icon(Icons.select_all_rounded),
                                      label: Text(context.t('select_all')),
                                    ),
                                    const Spacer(),
                                    if (_selectedOrderIds.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () =>
                                            _hideSelectedOrders(user.uid),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        label:
                                            Text(context.t('delete_selected')),
                                      ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                itemCount: state.orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, index) {
                                  final order = state.orders[index];
                                  return _OrderTile(
                                    order: order,
                                    selected: _selectedOrderIds.contains(
                                      order.orderId,
                                    ),
                                    selectionMode: _selectedOrderIds.isNotEmpty,
                                    onSelect: _canHide(order)
                                        ? () => _toggleSelection(order.orderId)
                                        : null,
                                    onDelete: _canHide(order)
                                        ? () =>
                                            _hideOrder(order.orderId, user.uid)
                                        : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                : const RestaurantProductsSection(),
          ),
        ],
      ),
    );
  }

  bool _canHide(OrderEntity order) =>
      order.status == OrderStatus.delivered ||
      order.status == OrderStatus.rejected;

  void _toggleSelection(String orderId) {
    setState(() {
      if (!_selectedOrderIds.add(orderId)) {
        _selectedOrderIds.remove(orderId);
      }
    });
  }

  Future<void> _hideOrder(String orderId, String clientId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'hiddenByClientIds': FieldValue.arrayUnion([clientId]),
      'hiddenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _hideSelectedOrders(String clientId) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final orderId in _selectedOrderIds) {
      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(orderId),
        {
          'hiddenByClientIds': FieldValue.arrayUnion([clientId]),
          'hiddenAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
    if (mounted) setState(_selectedOrderIds.clear);
  }
}

class _ClientActiveTripBanner extends StatelessWidget {
  final String clientId;

  const _ClientActiveTripBanner({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: ['accepted', 'inProgress', 'delivered'])
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final order = OrderModel.fromFirestore(snap.data!.docs.first);
        if (order.status == OrderStatus.delivered &&
            order.clientRating != null) {
          return const SizedBox.shrink();
        }
        if (order.driverId == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final driver = await context.read<OrderBloc>().getUser(
                    order.driverId!,
                  );
              if (driver == null || !context.mounted) return;
              context.go(
                '/active-trip',
                extra: {'order': order, 'otherParty': driver},
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppColors.accent.withOpacity(0.14)
                    : AppColors.accentLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${context.t('return_active_trip')}: ${order.dropoffAddress}',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderEntity order;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;

  const _OrderTile({
    required this.order,
    required this.selected,
    required this.selectionMode,
    this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return InkWell(
      onTap: selectionMode && onSelect != null
          ? onSelect
          : () => context.go('/client/order/${order.orderId}'),
      onLongPress: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border(context),
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Hero(
                tag: 'order-icon-${order.orderId}',
                child: Icon(Icons.inventory_2_outlined, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.dropoffAddress,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(
              label: context.statusText(order.status.value),
              color: color,
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: context.t('delete'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.storePending => AppColors.warning,
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
