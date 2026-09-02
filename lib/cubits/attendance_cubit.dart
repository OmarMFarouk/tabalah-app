import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/player_attendance_model.dart';
import 'async_state.dart';

/// What `/player/attendances` returns: the player's own attendance rows
/// plus the memberships they hold, so the screen can offer a per-membership
/// filter without a second request.
/// The tallies for the member's whole record, counted by the server.
///
/// Separate from the rows on purpose. The list is paged, so counting the
/// loaded rows would give a rate that changed every time the member
/// scrolled — a headline figure that moves as you look at it is worse than
/// no headline figure.
class AttendanceSummary {
  final int present;
  final int late;
  final int absent;
  final int excused;
  final int total;

  const AttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.excused = 0,
    this.total = 0,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceSummary();
    return AttendanceSummary(
      present: J.asInt(json['present']),
      late: J.asInt(json['late']),
      absent: J.asInt(json['absent']),
      excused: J.asInt(json['excused']),
      total: J.asInt(json['total']),
    );
  }
}

class AttendanceData {
  final List<PlayerAttendanceModel> attendances;
  final List<AttendanceMembershipRef> memberships;
  final AttendanceSummary summary;
  final PageMeta meta;

  const AttendanceData({
    this.attendances = const [],
    this.memberships = const [],
    this.summary = const AttendanceSummary(),
    this.meta = const PageMeta(),
  });

  AttendanceData append(AttendanceData next) => AttendanceData(
    attendances: [...attendances, ...next.attendances],
    memberships: next.memberships,
    summary: next.summary,
    meta: next.meta,
  );

  int get total => summary.total;
  int get presentCount => summary.present;
  int get lateCount => summary.late;
  int get absentCount => summary.absent;
  int get excusedCount => summary.excused;

  /// 0..1. Excused sessions are left out of the denominator entirely - the
  /// club excused them, so counting them against the member would be unfair.
  double get rate {
    final counted = total - excusedCount;
    if (counted <= 0) return 0;
    return (presentCount + lateCount) / counted;
  }

  /// Filters the rows currently loaded. The membership filter narrows what
  /// is on screen rather than re-querying, which is the same behaviour as
  /// before — the difference is that "on screen" is now a page rather than
  /// the entire history.
  List<PlayerAttendanceModel> forMembership(String? name) {
    if (name == null) return attendances;
    return attendances.where((a) => a.membershipName == name).toList();
  }
}

/// The membership stubs this endpoint returns alongside the rows. Note they
/// carry **no id** - just a name and sport - so filtering has to be by name.
class AttendanceMembershipRef {
  final String name;
  final String? sportName;

  const AttendanceMembershipRef({required this.name, this.sportName});

  factory AttendanceMembershipRef.fromJson(Map<String, dynamic> json) {
    return AttendanceMembershipRef(
      name: J.asString(json['name']),
      sportName: J.asStringOrNull(json['sport_name']),
    );
  }
}

/// The attendance history, a page at a time.
///
/// A member's record only ever grows, so fetching all of it to show the
/// most recent dozen got slower every session they attended.
class AttendanceCubit extends Cubit<AsyncState<AttendanceData>> {
  AttendanceCubit() : super(const AsyncState.idle());

  bool _isFetchingMore = false;
  String? _date;

  Future<void> load({String? date, bool refresh = false}) async {
    _date = date;
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      emit(AsyncState.ready(await _fetch(page: 1)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<void> loadMore() async {
    final current = state.data;
    if (current == null || !current.meta.hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    try {
      final next = await _fetch(page: current.meta.nextPage);
      emit(AsyncState.ready(current.append(next)));
    } on ApiException {
      // Keep the rows already on screen.
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<AttendanceData> _fetch({required int page}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.playerAttendances,
      query: {
        if (_date != null) 'date': _date,
        'page': page,
        'per_page': 15,
      },
    );

    return AttendanceData(
      attendances: J.list(
        response['attendances'],
        PlayerAttendanceModel.fromJson,
      ),
      // The filter list at the top of the screen, sent whole on every page
      // because a member belongs to a handful of memberships.
      memberships: J.list(
        response['memberships'],
        AttendanceMembershipRef.fromJson,
      ),
      summary: AttendanceSummary.fromJson(
        response['summary'] is Map
            ? Map<String, dynamic>.from(response['summary'] as Map)
            : null,
      ),
      meta: PageMeta.fromJson(
        response['meta'] is Map
            ? Map<String, dynamic>.from(response['meta'] as Map)
            : null,
      ),
    );
  }

  /// Scans the session QR the trainer is displaying to check in.
  ///
  /// Deliberately does not touch [state]: the scanner screen owns the
  /// success/failure feedback, and blanking the list behind it would be
  /// jarring. The list refreshes via [load] when the scanner pops.
  ///
  /// Returns null on success, or the server's message on failure - the
  /// backend distinguishes "QR not recognised" (404), "session closed"
  /// (422) and "you are not enrolled" (403), and all three are worth
  /// showing verbatim.
  Future<String?> checkIn(String qrToken) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.playerCheckIn,
        data: {'qr_token': qrToken},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
