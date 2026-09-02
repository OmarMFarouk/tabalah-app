import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/enrollments_cubit.dart';
import 'package:tabala/cubits/player_payments_cubit.dart';
import 'package:tabala/models/enrollment_model.dart';
import 'package:tabala/models/payment_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/app_money.dart';
import 'package:tabala/src/utils/status_ui.dart';

/// The member's wallet: receipts on one tab, subscriptions on the other.
///
/// Both endpoints behind this screen (`/player/payments` and
/// `/player/enrollments`) were already live; neither had a screen, so a
/// member had no record of what they had paid or which subscriptions were
/// still running.
class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final PlayerPaymentsCubit _payments;
  late final EnrollmentsCubit _enrollments;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _payments = PlayerPaymentsCubit()..load();
    _enrollments = EnrollmentsCubit()..load();

    // `/player/payments` is paginated at 15 per page, so the list has to ask
    // for more as the member scrolls rather than assuming one page is the
    // whole history.
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        _payments.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _tabs.dispose();
    _payments.close();
    _enrollments.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _payments),
        BlocProvider.value(value: _enrollments),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(
          title: Text('wallet'.tr()),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.goldInk,
            indicatorWeight: 2.5,
            labelColor: AppColors.textcolor,
            unselectedLabelColor: AppColors.subtextcolor,
            labelStyle: AppStyles.bold14Black,
            unselectedLabelStyle: AppStyles.medium14Grey,
            tabs: [
              Tab(text: 'payments'.tr()),
              Tab(text: 'my_subscriptions'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [_paymentsTab(), _enrollmentsTab()],
        ),
      ),
    );
  }

  // ── Payments ──────────────────────────────────────────────────────────

  Widget _paymentsTab() {
    return BlocBuilder<PlayerPaymentsCubit, AsyncState<PaymentsPage>>(
      builder: (context, state) {
        return AsyncStateView(
          isLoading: state.isBusy,
          errorMessage: state.hasData ? null : state.error,
          onRetry: _payments.load,
          isEmpty: state.hasData && state.data!.payments.isEmpty,
          emptyMessage: 'no_payments_yet'.tr(),
          child: state.hasData ? _paymentsList(state.data!) : const SizedBox(),
        );
      },
    );
  }

  Widget _paymentsList(PaymentsPage page) {
    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _payments.load(refresh: true),
      child: ListView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          ClubBottomNav.scrollPadding(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClubGradientPanel(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'total_paid'.tr(),
                    value: AppMoney.amount(page.totalPaid),
                    icon: Icons.account_balance_wallet_rounded,
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'receipts'.tr(),
                    value: '${page.meta.total}',
                    icon: Icons.receipt_long_rounded,
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'pending'.tr(),
                    value: '${page.pendingCount}',
                    icon: Icons.hourglass_bottom_rounded,
                    onDark: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...page.payments.map(_paymentCard),
          if (page.meta.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.goldInk,
                  strokeWidth: 2.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentCard(PaymentModel payment) {
    final tone = StatusUi.payment(payment.status);

    return ClubCard(
      onTap: () => _showReceipt(payment),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(StatusUi.paymentIcon(payment.status), size: 20, color: StatusUi.readable(context, tone)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.enrollment?.membershipName ?? 'payment'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bold14Black,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // paid_at is only set once the gateway settles, so a
                      // pending row falls back to when it was started.
                      AppDate.friendlyDateTime(payment.paidAt ?? payment.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.regular12Grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppMoney.amount(payment.amount, currency: payment.currency),
                    style: AppStyles.bold16Black,
                  ),
                  const SizedBox(height: 5),
                  StatusChip(label: StatusUi.label(payment.status), color: tone),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReceipt(PaymentModel payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Icon(
                StatusUi.paymentIcon(payment.status),
                size: 44,
                color: StatusUi.payment(payment.status),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                AppMoney.amount(payment.amount, currency: payment.currency),
                style: AppStyles.bold28Black,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: StatusChip(
                label: StatusUi.label(payment.status),
                color: StatusUi.payment(payment.status),
              ),
            ),
            const SizedBox(height: 24),
            _receiptRow('reference'.tr(), payment.shortReference),
            _receiptRow('payment_method'.tr(), payment.methodLabel),
            if (payment.enrollment?.membershipName != null)
              _receiptRow('membership'.tr(), payment.enrollment!.membershipName!),
            _receiptRow('date'.tr(), AppDate.dateTime(payment.paidAt ?? payment.createdAt)),
            if (payment.refundedAt != null)
              _receiptRow('refunded_on'.tr(), AppDate.dateTime(payment.refundedAt)),
            if (payment.recordedByName != null)
              _receiptRow('recorded_by'.tr(), payment.recordedByName!),
            if (payment.notes != null) _receiptRow('notes'.tr(), payment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.regular14Grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppStyles.medium14Black,
            ),
          ),
        ],
      ),
    );
  }

  // ── Enrollments ───────────────────────────────────────────────────────

  Widget _enrollmentsTab() {
    return BlocBuilder<EnrollmentsCubit, AsyncState<EnrollmentsData>>(
      builder: (context, state) {
        return AsyncStateView(
          isLoading: state.isBusy,
          errorMessage: state.hasData ? null : state.error,
          onRetry: _enrollments.load,
          isEmpty: state.hasData && state.data!.all.isEmpty,
          emptyMessage: 'no_subscriptions_yet'.tr(),
          child: state.hasData ? _enrollmentsList(state.data!) : const SizedBox(),
        );
      },
    );
  }

  Widget _enrollmentsList(EnrollmentsData data) {
    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _enrollments.load(refresh: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          ClubBottomNav.scrollPadding(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (data.active.isNotEmpty) ...[
            SectionHeader(title: 'active'.tr()),
            ...data.active.map(_enrollmentCard),
          ],
          if (data.pending.isNotEmpty) ...[
            SectionHeader(title: 'awaiting_payment'.tr()),
            ...data.pending.map(_enrollmentCard),
          ],
          if (data.past.isNotEmpty) ...[
            SectionHeader(title: 'past_subscriptions'.tr()),
            ...data.past.map(_enrollmentCard),
          ],
        ],
      ),
    );
  }

  Widget _enrollmentCard(EnrollmentModel enrollment) {
    final tone = StatusUi.enrollment(enrollment.status);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  enrollment.membershipName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold16Black,
                ),
              ),
              StatusChip(label: StatusUi.label(enrollment.status), color: tone),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dateBlock('starts'.tr(), AppDate.date(enrollment.startDate)),
              ),
              Container(width: 1, height: 34, color: AppColors.borderColor),
              Expanded(
                child: _dateBlock('ends'.tr(), AppDate.date(enrollment.endDate)),
              ),
            ],
          ),
          if (enrollment.isActive) ...[
            const SizedBox(height: 14),
            ProgressRow(
              label: 'days_left'.tr(args: ['${AppDate.daysLeft(enrollment.endDate)}']),
              trailing: AppDate.friendlyDate(enrollment.endDate),
              value: _remainingFraction(enrollment),
              color: AppColors.greencolor,
            ),
          ],
        ],
      ),
    );
  }

  /// How much of the subscription window is still ahead, as a 0..1 value.
  double _remainingFraction(EnrollmentModel enrollment) {
    final start = AppDate.parse(enrollment.startDate);
    final end = AppDate.parse(enrollment.endDate);
    if (start == null || end == null) return 0;

    final total = end.difference(start).inMinutes;
    if (total <= 0) return 0;

    final left = end.difference(DateTime.now()).inMinutes;
    return (left / total).clamp(0.0, 1.0);
  }

  Widget _dateBlock(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppStyles.regular12Grey),
        const SizedBox(height: 4),
        Text(value, style: AppStyles.medium14Black),
      ],
    );
  }
}
