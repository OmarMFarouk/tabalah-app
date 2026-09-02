import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/enrollment_model.dart';
import 'package:tabala/models/json_utils.dart';
import 'async_state.dart';

class EnrollmentsData {
  final List<EnrollmentModel> all;

  const EnrollmentsData(this.all);

  List<EnrollmentModel> get active => all.where((e) => e.isActive).toList();

  List<EnrollmentModel> get pending => all.where((e) => e.isAwaitingPayment).toList();

  /// Everything that is neither live nor waiting on money: expired windows
  /// and cancelled checkouts.
  List<EnrollmentModel> get past =>
      all.where((e) => !e.isActive && !e.isAwaitingPayment).toList();
}

/// `/player/enrollments` - the player's full subscription history across all
/// four states. Enrollments themselves are created by the checkout flow, not
/// by this endpoint; it is read-only.
class EnrollmentsCubit extends Cubit<AsyncState<EnrollmentsData>> {
  EnrollmentsCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerEnrollments);
      emit(AsyncState.ready(
        EnrollmentsData(J.list(response['enrollments'], EnrollmentModel.fromJson)),
      ));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
