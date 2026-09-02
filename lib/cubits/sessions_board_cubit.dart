import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/membership_session_model.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'async_state.dart';

/// The four kanban columns, in the order the backend returns them.
const kSessionColumns = ['scheduled', 'ongoing', 'completed', 'cancelled'];

class SessionsBoard {
  final Map<String, List<MembershipSessionModel>> columns;

  const SessionsBoard(this.columns);

  List<MembershipSessionModel> column(String status) => columns[status] ?? const [];

  int get total => columns.values.fold<int>(0, (acc, list) => acc + list.length);

  bool get isEmpty => total == 0;
}

/// Kanban board of the trainer's sessions grouped by status, plus
/// drag-to-move and slot rescheduling.
///
/// The board window defaults server-side to "last 7 days through next 30",
/// so a session outside that range simply will not appear - that is a
/// filter, not a bug, and the UI exposes it via [load]'s date bounds.
class SessionsBoardCubit extends Cubit<AsyncState<SessionsBoard>> {
  SessionsBoardCubit() : super(const AsyncState.idle());

  int? _membershipFilter;
  DateTime? _from;
  DateTime? _to;

  int? get membershipFilter => _membershipFilter;

  Future<void> load({
    int? membershipId,
    DateTime? from,
    DateTime? to,
    bool clearFilter = false,
    bool refresh = false,
  }) async {
    if (clearFilter) {
      _membershipFilter = null;
    } else if (membershipId != null) {
      _membershipFilter = membershipId;
    }
    if (from != null) _from = from;
    if (to != null) _to = to;

    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.trainerSessionsBoard,
        query: {
          if (_membershipFilter != null) 'membership_id': _membershipFilter,
          if (_from != null) 'from': AppDate.apiDate(_from!),
          if (_to != null) 'to': AppDate.apiDate(_to!),
        },
      );

      final board = J.asMap(response['board']);
      final columns = <String, List<MembershipSessionModel>>{
        for (final key in kSessionColumns)
          key: J.list(board[key], MembershipSessionModel.fromJson),
      };

      emit(AsyncState.ready(SessionsBoard(columns)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Moves a card to a new column and/or a new slot.
  ///
  /// Two things the backend is strict about, both of which return a 422:
  /// the verb must be **PATCH** (there is no PUT route for reschedule), and
  /// times must be `H:i` exactly - `18:00`, never `18:00:00` and never
  /// `6:00 PM`. AppDate.apiTime produces the right shape.
  ///
  /// The board is optimistically updated so the card lands under the
  /// user's finger immediately, then reconciled against the server.
  Future<String?> reschedule(
    MembershipSessionModel session, {
    String? status,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
  }) async {
    final snapshot = state.data;

    if (snapshot != null && status != null && status != session.status) {
      emit(AsyncState.ready(_moved(snapshot, session, status)));
    }

    try {
      await ApiClient.instance.patch(
        ApiEndpoints.trainerSessionReschedule(session.id),
        data: {
          if (status != null) 'status': status,
          if (sessionDate != null) 'session_date': AppDate.apiDate(sessionDate),
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
        },
      );

      await _fetch();
      return null;
    } on ApiException catch (e) {
      // Put the card back where it came from before surfacing the error.
      if (snapshot != null) emit(AsyncState.ready(snapshot));
      return e.message;
    }
  }

  /// Rebuilds the column map with one card moved, for the optimistic step.
  SessionsBoard _moved(
    SessionsBoard board,
    MembershipSessionModel session,
    String toStatus,
  ) {
    final next = <String, List<MembershipSessionModel>>{
      for (final key in kSessionColumns)
        key: board.column(key).where((s) => s.id != session.id).toList(),
    };
    next[toStatus] = [...next[toStatus] ?? const [], session];
    return SessionsBoard(next);
  }
}
