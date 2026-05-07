import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/validators.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/widgets/shared_widgets.dart';

class RestaurantProductsSection extends StatelessWidget {
  const RestaurantProductsSection({super.key});

  static const deliveryFee = 100.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('menu_items')
          .where('isAvailable', isEqualTo: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: context.t('no_menu_items'),
            subtitle: context.t('store_menu_empty'),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final products = snap.data!.docs;
        if (products.isEmpty) {
          return EmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: context.t('no_menu_items'),
            subtitle: context.t('store_menu_empty'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (_, index) => _ProductCard(doc: products[index]),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _ProductCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final image = data['imageBase64'] as String?;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final name = data['name'] as String? ?? '';
    final restaurant = data['storeName'] as String? ?? context.t('restaurant');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 92,
            width: double.infinity,
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
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${price.toStringAsFixed(0)} DA',
                  style: AppTextStyles.captionMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showRestaurantOrderSheet(context, doc),
                    child: Text(context.t('order_now')),
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

Future<void> _showRestaurantOrderSheet(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> productDoc,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface(context),
    builder: (_) => AppSettingsScope(
      controller: context.settings,
      child: _RestaurantOrderSheet(productDoc: productDoc),
    ),
  );
}

class _RestaurantOrderSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> productDoc;

  const _RestaurantOrderSheet({required this.productDoc});

  @override
  State<_RestaurantOrderSheet> createState() => _RestaurantOrderSheetState();
}

class _RestaurantOrderSheetState extends State<_RestaurantOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _address = TextEditingController();
  int _quantity = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _name = TextEditingController(text: user.fullName);
    _phone = TextEditingController(text: user.phoneNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productDoc.data();
    final name = data['name'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final productsTotal = price * _quantity;
    final total = productsTotal + RestaurantProductsSection.deliveryFee;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.title2),
                const SizedBox(height: 4),
                Text(
                  '${context.t('delivery_fee')}: ${RestaurantProductsSection.deliveryFee.toStringAsFixed(0)} DA',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _name,
                  hint: context.t('full_name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.t('field_required')
                      : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _phone,
                  hint: context.t('contact_phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => Validators.phone(value) == null
                      ? null
                      : context.t('algerian_phone_error'),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _address,
                  hint: context.t('delivery_address_hint'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return context.t('field_required');
                    if (text.length < 6) return context.t('address_too_short');
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(context.t('quantity'),
                        style: AppTextStyles.bodyMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _TotalRow(
                        label: context.t('products_total'),
                        value: productsTotal,
                      ),
                      const SizedBox(height: 6),
                      _TotalRow(
                        label: context.t('delivery_fee'),
                        value: RestaurantProductsSection.deliveryFee,
                      ),
                      const Divider(height: 18),
                      _TotalRow(
                        label: context.t('total'),
                        value: total,
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: context.t('send_store_order'),
                  isLoading: _loading,
                  onPressed: () => _submit(productsTotal: productsTotal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit({required double productsTotal}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final product = widget.productDoc.data();
      final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
      final productRef = widget.productDoc.reference;
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      final price = (product['price'] as num?)?.toDouble() ?? 0;
      final total = productsTotal + RestaurantProductsSection.deliveryFee;
      final storeId =
          product['storeId'] as String? ?? productRef.parent.parent?.id;
      if (storeId == null) return;

      final batch = FirebaseFirestore.instance.batch();
      batch.set(orderRef, {
        'clientId': user.uid,
        'clientName': _name.text.trim(),
        'clientPhone': _phone.text.trim(),
        'description': product['name'] as String? ?? '',
        'pickupLocation': const GeoPoint(0, 0),
        'pickupAddress': product['storeAddress'] as String? ?? '',
        'dropoffLocation': const GeoPoint(0, 0),
        'dropoffAddress': _address.text.trim(),
        'status': 'storePending',
        'sourceType': 'store',
        'storeId': storeId,
        'storeName': product['storeName'],
        'storePhone': product['storePhone'],
        'storeItemName': product['name'],
        'storeItemPrice': price,
        'quantity': _quantity,
        'deliveryFee': RestaurantProductsSection.deliveryFee,
        'productsTotal': productsTotal,
        'totalAmount': total,
        'bidCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(notificationRef, {
        'userId': storeId,
        'orderId': orderRef.id,
        'type': 'store_order',
        'title': 'New restaurant order',
        'body': '${_name.text.trim()} ordered ${product['name']}',
        'createdBy': user.uid,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('order_sent_to_restaurant'))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool strong;

  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = strong ? AppTextStyles.bodyMedium : AppTextStyles.body;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('${value.toStringAsFixed(0)} DA', style: style),
      ],
    );
  }
}
