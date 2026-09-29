import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/leave_model.dart';

import 'async_state.dart';

/// The signed-in account's own leave: the balance, the history, and the
/// form that adds to both.
///
/// Deliberately not paged. Nobody has enough leave requests in a year for a
/// second page to be worth the scroll listener.
class LeavesCubit extends Cubit<AsyncState<LeavesPage>> {
  LeavesCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      emit(AsyncState.ready(await _fetch()));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<LeavesPage> _fetch() async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.myLeaves,
      query: {'per_page': 50},
    );

    return LeavesPage(
      balance: LeaveBalance.fromJson(J.asMap(response['balance'])),
      items: J.list(response['leaves'], LeaveRequest.fromJson),
      types: {
        for (final entry in J.asMap(response['types']).entries)
          entry.key: '${entry.value}',
      },
    );
  }

  /// Raises a request. Returns the server's message on failure so the sheet
  /// can show it inline instead of replacing the whole screen with an error.
  Future<String?> request({
    required String type,
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.myLeaves, data: {
        'type': type,
        'start_date': _date(start),
        'end_date': _date(end),
        if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim(),
      });
      await load(refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Withdraw one that has not been decided yet.
  Future<String?> withdraw(int id) async {
    try {
      await ApiClient.instance.delete(ApiEndpoints.myLeave(id));
      await load(refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
