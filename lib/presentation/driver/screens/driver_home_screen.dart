import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/entities/order_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../order/bloc/order_bloc.dart';
import '../../shared/widgets/app_menu_button.dart';
import '../../shared/widgets/osm_map_widgets.dart';
import '../../shared/widgets/shared_widgets.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderWatchOpenOrders());
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text(context.t('jobs_near_you')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                user.rating.toStringAsFixed(1),
                style: AppTextStyles.captionMedium,
              ),
            ),
          ),
          AppMenuButton(user: user),
        ],
      ),
      body: Column(
        children: [
          _DriverActiveTripBanner(driverId: user.uid),
          Expanded(
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: context.t('no_jobs_available'),
                      subtitle: context.t('open_requests_appear'),
                    );
                  }
                  return Column(
                    children: [
                      _DriverStats(
                        driverId: user.uid,
                        availableJobs: state.orders.length,
                      ),
                      _JobsMap(orders: state.orders),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) =>
                              _JobTile(order: state.orders[index]),
                        ),
                      ),
                    ],
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStats extends StatelessWidget {
  final String driverId;
  final int availableJobs;

  const _DriverStats({
    required this.driverId,
    required this.availableJobs,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final active = docs.where((doc) {
          final status = doc.data()['status'] as String? ?? '';
          return status == 'accepted' || status == 'inProgress';
        }).length;
        final completed =
            docs.where((doc) => doc.data()['status'] == 'delivered').toList();
        final earned = completed.fold<double>(
          0,
          (sum, doc) =>
              sum +
              ((doc.data()['acceptedBidAmount'] as num?)?.toDouble() ?? 0),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('driver_dashboard'), style: AppTextStyles.title3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DriverStatCard(
                      label: context.t('available_jobs'),
                      value: '$availableJobs',
                      icon: Icons.work_outline_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DriverStatCard(
                      label: context.t('active_orders'),
                      value: '$active',
                      icon: Icons.navigation_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DriverStatCard(
                      label: context.t('completed_orders'),
                      value: '${completed.length}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DriverStatCard(
                      label: context.t('total_earned'),
                      value: '${earned.toStringAsFixed(0)} DA',
                      icon: Icons.payments_outlined,
                      color: AppColors.driverRole,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DriverStatCard({
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

class _DriverActiveTripBanner extends StatelessWidget {
  final String driverId;

  const _DriverActiveTripBanner({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'inProgress'])
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final order = OrderModel.fromFirestore(snap.data!.docs.first);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final client =
                  await context.read<OrderBloc>().getUser(order.clientId);
              if (client == null || !context.mounted) return;
              context.go('/active-trip', extra: {
                'order': order,
                'otherParty': client,
              });
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
                      '${context.t('active_trip')}: ${order.pickupAddress} -> ${order.dropoffAddress}',
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

class _JobTile extends StatelessWidget {
  final OrderEntity order;

  const _JobTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/driver/bid/${order.orderId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                Expanded(
                    child:
                        Text(order.description, style: AppTextStyles.title3)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 10),
            Text(context.t('pickup'), style: AppTextStyles.caption),
            Text(order.pickupAddress, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(context.t('dropoff'), style: AppTextStyles.caption),
            Text(order.dropoffAddress, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _JobsMap extends StatelessWidget {
  final List<OrderEntity> orders;

  const _JobsMap({required this.orders});

  @override
  Widget build(BuildContext context) {
    final first = orders.first;
    final center = LatLng(
      first.pickupLocation.latitude,
      first.pickupLocation.longitude,
    );
    final markers = <Marker>[];
    for (final order in orders.take(20)) {
      final pickup = LatLng(
        order.pickupLocation.latitude,
        order.pickupLocation.longitude,
      );
      final dropoff = LatLng(
        order.dropoffLocation.latitude,
        order.dropoffLocation.longitude,
      );
      markers
        ..add(osmPinMarker(
          point: pickup,
          color: AppColors.success,
          icon: Icons.trip_origin_rounded,
          label: 'Pickup',
        ))
        ..add(osmPinMarker(
          point: dropoff,
          color: AppColors.error,
          icon: Icons.location_on_rounded,
          label: 'Drop-off',
        ));
    }

    return SizedBox(
      height: 220,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          const OsmTiles(),
          PolylineLayer(
            polylines: [
              for (final order in orders.take(8))
                Polyline(
                  points: [
                    LatLng(
                      order.pickupLocation.latitude,
                      order.pickupLocation.longitude,
                    ),
                    LatLng(
                      order.dropoffLocation.latitude,
                      order.dropoffLocation.longitude,
                    ),
                  ],
                  color: AppColors.accent.withOpacity(0.55),
                  strokeWidth: 3,
                ),
            ],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
