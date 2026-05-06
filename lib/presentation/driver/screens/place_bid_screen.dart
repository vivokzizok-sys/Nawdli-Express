import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../order/bloc/order_bloc.dart';
import '../../shared/widgets/shared_widgets.dart';

class PlaceBidScreen extends StatefulWidget {
  final String orderId;

  const PlaceBidScreen({super.key, required this.orderId});

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is BidPlaced) context.go('/driver/home');
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is OrderProcessing;
        return Scaffold(
          appBar: AppBar(title: const Text('Place Bid')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _amount,
                      hint: 'Bid amount',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final base = Validators.required(value, label: 'Amount');
                        if (base != null) return base;
                        final amount = double.tryParse(value!);
                        return amount != null && amount > 0
                            ? null
                            : 'Enter a valid amount';
                      },
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Send Bid',
                      isLoading: loading,
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final driver = (context.read<AuthBloc>().state
                                as AuthAuthenticated)
                            .user;
                        context.read<OrderBloc>().add(OrderBidPlaceRequested(
                              orderId: widget.orderId,
                              driver: driver,
                              amount: double.parse(_amount.text),
                            ));
                      },
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
