import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/cubits/payment_cubit.dart';
import 'package:tabala/models/payment_source_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_money.dart';

/// Checkout, mirroring the backend's three-step simulated gateway so a real
/// processor can replace it without touching this screen.
///
/// The important change from the original: the payment methods are now
/// **fetched** from `/player/payment-sources` and the chosen one is sent as
/// `payment_source_id`. Before, the screen showed two hardcoded radio
/// buttons ("card" / "wallet") whose value was stored in local state and
/// never transmitted, so every payment silently used whichever source the
/// club had flagged as default.
class CheckoutView extends StatefulWidget {
  final int membershipId;
  final String membershipName;
  final double price;

  const CheckoutView({
    super.key,
    required this.membershipId,
    required this.membershipName,
    required this.price,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late final PaymentCubit _cubit;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _cubit = PaymentCubit();

    // A free membership never reaches a gateway - the backend auto-succeeds
    // it inside `initiate` - so there is no reason to ask for a method.
    if (widget.price > 0) _cubit.loadSources();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('checkout'.tr())),
        body: BlocConsumer<PaymentCubit, CheckoutState>(
          listener: (context, state) {
            if (state.stage == CheckoutStage.succeeded && !_resultShown) {
              _resultShown = true;
              _showResultSheet(success: true);
            } else if (state.stage == CheckoutStage.failed && !_resultShown) {
              _resultShown = true;
              _showResultSheet(success: false);
            }
          },
          builder: (context, state) {
            if (state.stage == CheckoutStage.gateway) {
              return _gatewayScreen(state);
            }
            return _summary(state);
          },
        ),
      ),
    );
  }

  // ── Step 1: order summary + method picker ─────────────────────────────

  Widget _summary(CheckoutState state) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              ClubGradientPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('order_summary'.tr(), style: AppStyles.bold11Gold),
                    const SizedBox(height: 12),
                    Text(
                      widget.membershipName,
                      style: AppStyles.bold18Black.copyWith(color: PanelInk.strong(context)),
                    ),
                    const SizedBox(height: 18),
                    Divider(color: PanelInk.line(context), height: 1),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'total'.tr(),
                            style: AppStyles.regular14Grey.copyWith(color: PanelInk.muted(context)),
                          ),
                        ),
                        Text(
                          AppMoney.format(widget.price),
                          style: AppStyles.bold28Black.copyWith(color: PanelInk.strong(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.price > 0) ...[
                SectionHeader(title: 'payment_method'.tr()),
                if (state.isLoadingSources)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AsyncStateView(isLoading: true, child: SizedBox()),
                  )
                else if (state.sources.isEmpty)
                  ClubCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.orangecolor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'no_payment_methods'.tr(),
                            style: AppStyles.regular14Grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...state.sources.map(
                    (source) => _methodTile(
                      source,
                      selected: source.id == state.selectedSourceId,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              ClubCard(
                color: AppColors.lightOrange,
                border: Border.all(color: AppColors.orangecolor.withValues(alpha: .3)),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, size: 18, color: AppColors.orangecolor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'simulated_gateway_notice'.tr(),
                        style: AppStyles.regular12Grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: AppStyles.regular14Red,
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CustomElevatedButton(
              gold: true,
              isBusy: state.isProcessing,
              text: widget.price <= 0 ? 'join_for_free'.tr() : 'pay_now'.tr(),
              onPressed: () => _cubit.initiate(widget.membershipId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _methodTile(PaymentSourceModel source, {required bool selected}) {
    return ClubCard(
      onTap: () => _cubit.selectSource(source.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      border: Border.all(
        color: selected ? AppColors.goldInk : AppColors.borderColor,
        width: selected ? 1.6 : 1,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: selected ? .16 : .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(source.code), size: 20, color: AppColors.goldInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.name, style: AppStyles.bold14Black),
                if (source.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    source.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.regular12Grey,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.goldInk : AppColors.greycolor,
            size: 22,
          ),
        ],
      ),
    );
  }

  /// Best-effort icon from the source's stable `code`. Matching on the code
  /// rather than the display name means a club renaming "Mada Card" to
  /// "بطاقة مدى" does not silently lose the icon.
  IconData _iconFor(String code) {
    final key = code.toLowerCase();
    if (key.contains('apple')) return Icons.apple_rounded;
    if (key.contains('mada') || key.contains('card') || key.contains('visa')) {
      return Icons.credit_card_rounded;
    }
    if (key.contains('stc') || key.contains('wallet')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (key.contains('transfer') || key.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    return Icons.payments_rounded;
  }

  // ── Step 2: the stand-in gateway ──────────────────────────────────────

  Widget _gatewayScreen(CheckoutState state) {
    final payment = state.payment!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .14),
              border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
            ),
            child: Icon(Icons.lock_rounded, size: 32, color: AppColors.goldInk),
          ),
          const SizedBox(height: 18),
          Text(
            'simulated_gateway_title'.tr(),
            style: AppStyles.bold20Black,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${'reference'.tr()}: ${payment.shortReference}',
            style: AppStyles.regular12Grey,
          ),
          const SizedBox(height: 18),
          Text(
            AppMoney.amount(payment.amount, currency: payment.currency),
            style: AppStyles.bold32Gold,
          ),
          const SizedBox(height: 6),
          Text(payment.methodLabel, style: AppStyles.medium14Grey),
          const SizedBox(height: 30),
          Text(
            'simulated_gateway_prompt'.tr(),
            textAlign: TextAlign.center,
            style: AppStyles.regular14Grey,
          ),
          const SizedBox(height: 22),
          CustomElevatedButton(
            gold: true,
            isBusy: state.isProcessing,
            text: 'simulate_success'.tr(),
            onPressed: () => _cubit.simulate(success: true),
          ),
          const SizedBox(height: 12),
          CustomElevatedButton(
            text: 'simulate_failure'.tr(),
            bgColor: AppColors.surfacecolor,
            borderColor: AppColors.redcolor,
            textStyle: AppStyles.bold14Red,
            onPressed: state.isProcessing ? null : () => _cubit.simulate(success: false),
          ),
        ],
      ),
    );
  }

  // ── Step 3: outcome ───────────────────────────────────────────────────

  void _showResultSheet({required bool success}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (success ? AppColors.greencolor : AppColors.redcolor)
                    .withValues(alpha: .14),
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: success ? AppColors.greencolor : AppColors.redcolor,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              success ? 'payment_success_title'.tr() : 'payment_failed_title'.tr(),
              style: AppStyles.bold20Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              success ? 'payment_success_desc'.tr() : 'payment_failed_desc'.tr(),
              style: AppStyles.regular14Grey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            CustomElevatedButton(
              gold: success,
              text: 'done'.tr(),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pop(success);
              },
            ),
          ],
        ),
      ),
    );
  }
}
