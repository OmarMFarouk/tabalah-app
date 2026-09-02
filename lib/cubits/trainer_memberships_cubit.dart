import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/membership_model.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'async_state.dart';

/// The classes this trainer runs, `/trainer/memberships`. The list comes
/// back with schedules loaded and enrollments counted, so a card can show
/// both the weekly slots and how full the class is without a second call.
class TrainerMembershipsCubit extends Cubit<AsyncState<List<MembershipModel>>> {
  TrainerMembershipsCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.trainerMemberships);
      emit(AsyncState.ready(J.list(response['memberships'], MembershipModel.fromJson)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Materialises session rows from a membership's schedule between two
  /// dates. Both bounds are optional: the backend defaults `from` to today
  /// and `to` to today plus its own default window.
  ///
  /// Returns the number of sessions created, or null on failure. Generation
  /// is idempotent - the `unique_session` index on
  /// (membership, schedule, date) means re-running over the same window
  /// creates nothing rather than duplicating.
  Future<int?> generateSessions(
    int membershipId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.trainerGenerateSessions(membershipId),
        data: {
          if (from != null) 'from': AppDate.apiDate(from),
          if (to != null) 'to': AppDate.apiDate(to),
        },
      );

      await load(refresh: true);
      return J.asInt(response['created_count']);
    } on ApiException {
      return null;
    }
  }
}
