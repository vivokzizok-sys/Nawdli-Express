import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../domain/entities/order_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../order/bloc/order_bloc.dart';
import '../../shared/widgets/app_menu_button.dart';
import '../../shared/widgets/shared_widgets.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    context.read<OrderBloc>().add(OrderWatchClientOrders(user.uid));
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text(context.t('my_orders')),
        actions: [
          AppMenuButton(user: user),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/client/create-order'),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('new_order')),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: context.t('no_orders_yet'),
                subtitle: context.t('create_first_order'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: state.orders.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                if (index == 0) return _ClientStats(orders: state.orders);
                return _OrderTile(order: state.orders[index - 1]);
              },
            );
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
  }
}

class _ClientStats extends StatelessWidget {
  final List<OrderEntity> orders;

  const _ClientStats({required this.orders});

  @override
  Widget build(BuildContext context) {
    final active = orders
        .where((o) =>
            o.status == OrderStatus.accepted ||
            o.status == OrderStatus.inProgress)
        .length;
    final completed =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final spent = orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + (o.acceptedBidAmount ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('client_dashboard'), style: AppTextStyles.title3),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.t('total_orders'),
                value: '${orders.length}',
                icon: Icons.receipt_long_outlined,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: context.t('active_orders'),
                value: '$active',
                icon: Icons.local_shipping_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.t('completed_orders'),
                value: '$completed',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: context.t('total_spent'),
                value: '${spent.toStringAsFixed(0)} DA',
                icon: Icons.payments_outlined,
                color: AppColors.driverRole,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.title3),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderEntity order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return InkWell(
      onTap: () => context.go('/client/order/${order.orderId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border.all(color: AppColors.border(context)),
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
                    '${order.pickupAddress} -> ${order.dropoffAddress}',
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
            StatusChip(label: order.status.value, color: color),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.open => AppColors.info,
        OrderStatus.bidding => AppColors.warning,
        OrderStatus.accepted => AppColors.accent,
        OrderStatus.inProgress => AppColors.success,
        OrderStatus.delivered => AppColors.grey400,
        OrderStatus.cancelled => AppColors.error,
      };
}
