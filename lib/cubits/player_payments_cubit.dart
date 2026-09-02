import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/payment_model.dart';
import 'async_state.dart';

class PaymentsPage {
  final List<PaymentModel> payments;
  final PageMeta meta;

  const PaymentsPage({this.payments = const [], this.meta = const PageMeta()});

  double get totalPaid => payments
      .where((p) => p.isSuccess)
      .fold<double>(0, (acc, p) => acc + p.amount);

  int get pendingCount => payments.where((p) => p.isPending).length;

  PaymentsPage append(PaymentsPage next) =>
      PaymentsPage(payments: [...payments, ...next.payments], meta: next.meta);
}

/// The player's own payment history, `/player/payments`, paginated 15 at a
/// time. This endpoint existed on the backend from the start but the app had
/// no screen for it, so members could complete a checkout and then never see
/// a receipt again.
class PlayerPaymentsCubit extends Cubit<AsyncState<PaymentsPage>> {
  PlayerPaymentsCubit() : super(const AsyncState.idle());

  bool _isFetchingMore = false;

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      emit(AsyncState.ready(await _fetch(page: 1)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Pulls the next page and appends it. Guarded against the double-fire a
  /// scroll listener will otherwise produce near the bottom of the list.
  Future<void> loadMore() async {
    final current = state.data;
    if (current == null || !current.meta.hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    try {
      final next = await _fetch(page: current.meta.nextPage);
      emit(AsyncState.ready(current.append(next)));
    } on ApiException {
      // A failed "load more" leaves the existing page intact on purpose -
      // there is nothing useful to say beyond the rows already on screen.
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<PaymentsPage> _fetch({required int page}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.playerPayments,
      query: {'page': page, 'per_page': 15},
    );

    return PaymentsPage(
      payments: J.list(response['payments'], PaymentModel.fromJson),
      meta: PageMeta.fromJson(
        response['meta'] is Map ? Map<String, dynamic>.from(response['meta'] as Map) : null,
      ),
    );
  }

  /// A single payment's detail. Used by the receipt sheet.
  Future<PaymentModel?> fetchOne(int paymentId) async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerPayment(paymentId));
      return PaymentModel.fromJson(Map<String, dynamic>.from(response['payment'] as Map));
    } on ApiException {
      return null;
    }
  }
}
