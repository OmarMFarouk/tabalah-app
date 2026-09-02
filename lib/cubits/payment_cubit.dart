import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/payment_model.dart';
import 'package:tabala/models/payment_source_model.dart';

/// Drives checkout, which on this backend is a three-step dance that mirrors
/// a real gateway so the real one can be dropped in later without touching
/// the UI:
///
/// 1. `GET /player/payment-sources` - the methods the club accepts online.
///    This step was missing before, so the app hard-coded "card / wallet"
///    radio buttons that were never sent anywhere; the payment always fell
///    through to whichever source the backend had flagged as default.
/// 2. `POST /player/payments/initiate` with `membership_id` **and**
///    `payment_source_id` - creates a `pending_payment` enrollment and a
///    `pending` payment.
/// 3. `POST /player/payments/{id}/simulate` with `result: success|fail` -
///    stands in for the gateway's callback.
///
/// A free membership short-circuits: the backend auto-succeeds it inside
/// step 2 and returns an already-successful payment, so the UI must check
/// the returned status rather than assuming it still needs step 3.
class CheckoutState extends Equatable {
  final List<PaymentSourceModel> sources;
  final int? selectedSourceId;
  final PaymentModel? payment;
  final bool isLoadingSources;
  final bool isProcessing;
  final String? error;
  final CheckoutStage stage;

  const CheckoutState({
    this.sources = const [],
    this.selectedSourceId,
    this.payment,
    this.isLoadingSources = false,
    this.isProcessing = false,
    this.error,
    this.stage = CheckoutStage.summary,
  });

  PaymentSourceModel? get selectedSource {
    if (sources.isEmpty) return null;
    return sources.firstWhere(
      (s) => s.id == selectedSourceId,
      orElse: () => sources.first,
    );
  }

  CheckoutState copyWith({
    List<PaymentSourceModel>? sources,
    int? selectedSourceId,
    PaymentModel? payment,
    bool? isLoadingSources,
    bool? isProcessing,
    String? error,
    CheckoutStage? stage,
    bool clearError = false,
  }) {
    return CheckoutState(
      sources: sources ?? this.sources,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
      payment: payment ?? this.payment,
      isLoadingSources: isLoadingSources ?? this.isLoadingSources,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      stage: stage ?? this.stage,
    );
  }

  @override
  List<Object?> get props =>
      [sources, selectedSourceId, payment, isLoadingSources, isProcessing, error, stage];
}

enum CheckoutStage { summary, gateway, succeeded, failed }

class PaymentCubit extends Cubit<CheckoutState> {
  PaymentCubit() : super(const CheckoutState());

  /// Loads the club's online payment methods and pre-selects the club's
  /// default (or the first one, if none is flagged).
  Future<void> loadSources() async {
    emit(state.copyWith(isLoadingSources: true, clearError: true));

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerPaymentSources);
      final sources = J.list(response['payment_sources'], PaymentSourceModel.fromJson)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final preferred = sources.where((s) => s.isDefault).toList();
      emit(state.copyWith(
        sources: sources,
        selectedSourceId: preferred.isNotEmpty
            ? preferred.first.id
            : (sources.isNotEmpty ? sources.first.id : null),
        isLoadingSources: false,
      ));
    } on ApiException catch (e) {
      // A missing method list should not block a free membership, so this
      // surfaces as a soft error and checkout stays usable.
      emit(state.copyWith(isLoadingSources: false, error: e.message));
    }
  }

  void selectSource(int sourceId) {
    emit(state.copyWith(selectedSourceId: sourceId, clearError: true));
  }

  Future<void> initiate(int membershipId) async {
    emit(state.copyWith(isProcessing: true, clearError: true));

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.playerPaymentsInitiate,
        data: {
          'membership_id': membershipId,
          // Optional server-side: omitting it falls back to the club's
          // configured default. Sent whenever the member actually picked.
          if (state.selectedSourceId != null) 'payment_source_id': state.selectedSourceId,
        },
      );

      final payment = PaymentModel.fromJson(
        Map<String, dynamic>.from(response['payment'] as Map),
      );

      emit(state.copyWith(
        payment: payment,
        isProcessing: false,
        stage: _stageFor(payment),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.message));
    }
  }

  Future<void> simulate({required bool success}) async {
    final payment = state.payment;
    if (payment == null) return;

    emit(state.copyWith(isProcessing: true, clearError: true));

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.playerPaymentSimulate(payment.id),
        data: {'result': success ? 'success' : 'fail'},
      );

      final updated = PaymentModel.fromJson(
        Map<String, dynamic>.from(response['payment'] as Map),
      );

      emit(state.copyWith(
        payment: updated,
        isProcessing: false,
        stage: updated.isSuccess ? CheckoutStage.succeeded : CheckoutStage.failed,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.message));
    }
  }

  static CheckoutStage _stageFor(PaymentModel payment) {
    if (payment.isSuccess) return CheckoutStage.succeeded;
    if (payment.isFailed) return CheckoutStage.failed;
    return CheckoutStage.gateway;
  }
}
