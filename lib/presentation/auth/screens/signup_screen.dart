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
              onPressed: () => context.go('/login'),
            ),
          ),
          body: SafeArea(
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
                    SegmentedButton<UserRole>(
                      segments: [
                        ButtonSegment(
                          value: UserRole.client,
                          label: Text(context.t('client')),
                          icon: Icon(Icons.person_outline_rounded),
                        ),
                        ButtonSegment(
                          value: UserRole.driver,
                          label: Text(context.t('driver')),
                          icon: Icon(Icons.local_shipping_outlined),
                        ),
                        ButtonSegment(
                          value: UserRole.store,
                          label: Text(context.t('restaurant')),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (set) =>
                          setState(() => _role = set.first),
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
                          border: Border.all(color: AppColors.border(context)),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.photo_camera_outlined),
                                    const SizedBox(height: 8),
                                    Text(context.t('upload_vehicle_photo')),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_outlined),
                            const SizedBox(width: 10),
                            Text(context.t('restaurant')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _storeAddress,
                        hint: context.t('store_address'),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) return context.t('field_required');
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                        if (_role == UserRole.driver && _vehiclePhoto == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.t('vehicle_photo_required'),
                              ),
                            ),
                          );
                          return;
                        }
                        if (_role == UserRole.store && _storePhoto == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.t('store_photo_required')),
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
                                storeType:
                                    _role == UserRole.store ? _storeType : null,
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
