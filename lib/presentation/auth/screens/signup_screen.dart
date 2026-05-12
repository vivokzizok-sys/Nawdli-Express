import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user_entity.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _wilaya = TextEditingController();
  final _commune = TextEditingController();
  final _password = TextEditingController();
  final _storeAddress = TextEditingController();
  UserRole _role = UserRole.client;
  VehicleType _vehicleType = VehicleType.bike;
  StoreType _storeType = StoreType.restaurant;
  bool _accountTypeChosen = false;
  File? _vehiclePhoto;
  File? _storePhoto;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _wilaya.dispose();
    _commune.dispose();
    _password.dispose();
    _storeAddress.dispose();
    super.dispose();
  }

  Future<void> _pickVehiclePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (picked != null) setState(() => _vehiclePhoto = File(picked.path));
  }

  Future<void> _pickStorePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (picked != null) setState(() => _storePhoto = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.page(context),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (_accountTypeChosen) {
                  setState(() => _accountTypeChosen = false);
                } else {
                  context.go('/login');
                }
              },
            ),
          ),
          body: !_accountTypeChosen
              ? _AccountTypePicker(
                  onSelected: (role, storeType) {
                    setState(() {
                      _role = role;
                      if (storeType != null) _storeType = storeType;
                      _accountTypeChosen = true;
                    });
                  },
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('create_account'),
                            style: AppTextStyles.title1,
                          ),
                          const SizedBox(height: 20),
                          _SelectedAccountTypeCard(
                            role: _role,
                            storeType:
                                _role == UserRole.store ? _storeType : null,
                            onChange: () =>
                                setState(() => _accountTypeChosen = false),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _name,
                            hint: context.t('full_name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? context.t('field_required')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _email,
                            hint: context.t('email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return context.t('field_required');
                              }
                              return RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(v.trim())
                                  ? null
                                  : context.t('valid_email');
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _phone,
                            hint: context.t('phone'),
                            keyboardType: TextInputType.phone,
                            validator: (v) => Validators.phone(v) == null
                                ? null
                                : context.t('algerian_phone_error'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _wilaya,
                                  hint: context.t('wilaya'),
                                  validator: (v) {
                                    final text = v?.trim() ?? '';
                                    if (text.isEmpty)
                                      return context.t('field_required');
                                    if (text.length < 3)
                                      return context.t('write_clear_value');
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppTextField(
                                  controller: _commune,
                                  hint: context.t('commune'),
                                  validator: (v) {
                                    final text = v?.trim() ?? '';
                                    if (text.isEmpty)
                                      return context.t('field_required');
                                    if (text.length < 3)
                                      return context.t('write_clear_value');
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _password,
                            hint: context.t('password'),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return context.t('field_required');
                              }
                              return v.length >= 6
                                  ? null
                                  : context.t('password_length');
                            },
                          ),
                          if (_role == UserRole.driver) ...[
                            const SizedBox(height: 18),
                            Text(
                              context.t('vehicle'),
                              style: AppTextStyles.captionMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border(context)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.two_wheeler_rounded,
                                    color: AppColors.driverRole,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.t('motorcycle'),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickVehiclePhoto,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                ),
                                child: _vehiclePhoto == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.photo_camera_outlined),
                                          const SizedBox(height: 8),
                                          Text(context
                                              .t('upload_vehicle_photo')),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          _vehiclePhoto!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          if (_role == UserRole.store) ...[
                            const SizedBox(height: 18),
                            AppTextField(
                              controller: _storeAddress,
                              hint: context.t('store_address'),
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                if (text.isEmpty)
                                  return context.t('field_required');
                                if (text.length < 6) {
                                  return context.t('address_too_short');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickStorePhoto,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                ),
                                child: _storePhoto == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(context.t('upload_store_photo')),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          _storePhoto!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: context.t('create_account'),
                            isLoading: loading,
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              if (_role == UserRole.driver &&
                                  _vehiclePhoto == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.t('vehicle_photo_required'),
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_role == UserRole.store &&
                                  _storePhoto == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(context.t('store_photo_required')),
                                  ),
                                );
                                return;
                              }
                              context.read<AuthBloc>().add(
                                    AuthSignUpRequested(
                                      email: _email.text,
                                      password: _password.text,
                                      fullName: _name.text,
                                      phoneNumber: _phone.text,
                                      wilaya: _wilaya.text,
                                      commune: _commune.text,
                                      role: _role,
                                      vehicleType: _role == UserRole.driver
                                          ? _vehicleType
                                          : null,
                                      vehiclePhoto: _role == UserRole.driver
                                          ? _vehiclePhoto
                                          : null,
                                      storeType: _role == UserRole.store
                                          ? _storeType
                                          : null,
                                      storeAddress: _role == UserRole.store
                                          ? _storeAddress.text
                                          : null,
                                      profilePhoto: _role == UserRole.store
                                          ? _storePhoto
                                          : null,
                                    ),
                                  );
                            },
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(context.t('already_have_account')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _AccountTypePicker extends StatelessWidget {
  final void Function(UserRole role, StoreType? storeType) onSelected;

  const _AccountTypePicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      _SignupOption(
        label: context.t('client'),
        icon: Icons.person_outline_rounded,
        color: AppColors.clientRole,
        onTap: () => onSelected(UserRole.client, null),
      ),
      _SignupOption(
        label: context.t('driver'),
        icon: Icons.two_wheeler_rounded,
        color: AppColors.driverRole,
        onTap: () => onSelected(UserRole.driver, null),
      ),
      _SignupOption(
        label: context.t('restaurant'),
        icon: Icons.restaurant_outlined,
        color: AppColors.accent,
        onTap: () => onSelected(UserRole.store, StoreType.restaurant),
      ),
      _SignupOption(
        label: context.t('grocery'),
        icon: Icons.local_grocery_store_outlined,
        color: AppColors.success,
        onTap: () => onSelected(UserRole.store, StoreType.grocery),
      ),
      _SignupOption(
        label: context.t('hardware'),
        icon: Icons.construction_outlined,
        color: AppColors.warning,
        onTap: () => onSelected(UserRole.store, StoreType.hardware),
      ),
      _SignupOption(
        label: context.t('produce'),
        icon: Icons.eco_outlined,
        color: AppColors.info,
        onTap: () => onSelected(UserRole.store, StoreType.produce),
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(context.t('choose_account_type'), style: AppTextStyles.title1),
          const SizedBox(height: 8),
          Text(
            context.t('choose_account_type_body'),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 22),
          for (final option in options) ...[
            _AccountTypeTile(option: option),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SignupOption {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SignupOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _AccountTypeTile extends StatelessWidget {
  final _SignupOption option;

  const _AccountTypeTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: option.color.withValues(alpha: 0.12),
              child: Icon(option.icon, color: option.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(option.label, style: AppTextStyles.bodyMedium),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SelectedAccountTypeCard extends StatelessWidget {
  final UserRole role;
  final StoreType? storeType;
  final VoidCallback onChange;

  const _SelectedAccountTypeCard({
    required this.role,
    required this.storeType,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final label = role == UserRole.store
        ? context.t(storeType?.name ?? 'store')
        : context.t(role.name);
    final icon = role == UserRole.store
        ? _storeTypeIcon(storeType ?? StoreType.restaurant)
        : Icons.person_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          TextButton(
            onPressed: onChange,
            child: Text(context.t('change')),
          ),
        ],
      ),
    );
  }
}

IconData _storeTypeIcon(StoreType type) => switch (type) {
      StoreType.restaurant => Icons.restaurant_outlined,
      StoreType.grocery => Icons.local_grocery_store_outlined,
      StoreType.hardware => Icons.construction_outlined,
      StoreType.produce => Icons.eco_outlined,
      StoreType.other => Icons.storefront_outlined,
    };
