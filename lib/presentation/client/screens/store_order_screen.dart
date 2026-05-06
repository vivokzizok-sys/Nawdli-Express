import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../order/bloc/order_bloc.dart';
import '../../shared/widgets/shared_widgets.dart';

class StoreOrderScreen extends StatefulWidget {
  final UserEntity store;
  final Map<String, dynamic> item;

  const StoreOrderScreen({super.key, required this.store, required this.item});

  @override
  State<StoreOrderScreen> createState() => _StoreOrderScreenState();
}

class _StoreOrderScreenState extends State<StoreOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  String? _driverId;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.item['name'] as String? ?? '';
    final itemPrice = (widget.item['price'] as num?)?.toDouble() ?? 0;
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          context.go('/client/order/${state.order.orderId}');
        }
        if (state is OrderError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is OrderProcessing;
        return Scaffold(
          backgroundColor: AppColors.page(context),
          appBar: AppBar(
            leading: IconButton(
              tooltip: context.t('back'),
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.go('/client/store-profile', extra: widget.store),
            ),
            title: Text(context.t('store_order')),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _SelectedItemCard(
                  storeName: widget.store.fullName,
                  itemName: itemName,
                  itemPrice: itemPrice,
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('choose_driver'),
                  style: AppTextStyles.captionMedium,
                ),
                const SizedBox(height: 8),
                _DriverPicker(
                  selectedDriverId: _driverId,
                  onChanged: (value) => setState(() => _driverId = value),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _address,
                  hint: context.t('delivery_address_hint'),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return context.t('field_required');
                    if (text.length < 6) return context.t('address_too_short');
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone,
                  hint: context.t('contact_phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => Validators.phone(v) == null
                      ? null
                      : context.t('algerian_phone_error'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _notes,
                  hint: context.t('order_notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: context.t('send_store_order'),
                  isLoading: loading,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (_driverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.t('choose_driver_first')),
                        ),
                      );
                      return;
                    }
                    final user =
                        (context.read<AuthBloc>().state as AuthAuthenticated)
                            .user;
                    final description = [
                      itemName,
                      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
                    ].join(' - ');
                    context.read<OrderBloc>().add(
                      OrderCreateRequested(
                        OrderEntity(
                          orderId: '',
                          clientId: user.uid,
                          clientName: user.fullName,
                          clientPhone: _phone.text.trim(),
                          description: description,
                          pickupLocation: const LocationPoint(
                            latitude: 0,
                            longitude: 0,
                          ),
                          pickupAddress:
                              widget.store.storeAddress ??
                              widget.store.fullName,
                          dropoffLocation: const LocationPoint(
                            latitude: 0,
                            longitude: 0,
                          ),
                          dropoffAddress: _address.text.trim(),
                          status: OrderStatus.requested,
                          driverId: _driverId,
                          sourceType: 'store',
                          storeId: widget.store.uid,
                          storeName: widget.store.fullName,
                          storePhone: widget.store.phoneNumber,
                          storeItemName: itemName,
                          storeItemPrice: itemPrice,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  final String storeName;
  final String itemName;
  final double itemPrice;

  const _SelectedItemCard({
    required this.storeName,
    required this.itemName,
    required this.itemPrice,
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
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 3),
                Text(
                  storeName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${itemPrice.toStringAsFixed(0)} DA',
            style: AppTextStyles.captionMedium,
          ),
        ],
      ),
    );
  }
}

class _DriverPicker extends StatelessWidget {
  final String? selectedDriverId;
  final ValueChanged<String?> onChanged;

  const _DriverPicker({
    required this.selectedDriverId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isApproved', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        final drivers = snap.data!.docs.map(UserModel.fromFirestore).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        if (drivers.isEmpty) {
          return EmptyState(
            icon: Icons.local_shipping_outlined,
            title: context.t('no_drivers'),
            subtitle: context.t('no_drivers_body'),
          );
        }
        return DropdownButtonFormField<String>(
          value: selectedDriverId,
          decoration: InputDecoration(hintText: context.t('choose_driver')),
          items: drivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.uid,
                  child: Text(
                    '${driver.fullName} - ${driver.rating.toStringAsFixed(1)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          validator: (value) =>
              value == null ? context.t('choose_driver_first') : null,
          onChanged: onChanged,
        );
      },
    );
  }
}
