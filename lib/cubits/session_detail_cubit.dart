import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/membership_session_model.dart';

class SessionDetailState extends Equatable {
  final MembershipSessionModel? session;
  final List<SessionPlayerModel> players;

  /// Fetched lazily - the QR endpoint is a separate call and the token is
  /// only needed when the trainer actually opens the display sheet.
  final String? qrToken;

  final bool isLoading;
  final bool isMarking;
  final String? error;

  const SessionDetailState({
    this.session,
    this.players = const [],
    this.qrToken,
    this.isLoading = false,
    this.isMarking = false,
    this.error,
  });

  bool get hasData => session != null;

  int get markedCount => players.where((p) => p.isMarked).length;

  int get presentCount =>
      players.where((p) => p.attendanceStatus == 'present').length;

  SessionDetailState copyWith({
    MembershipSessionModel? session,
    List<SessionPlayerModel>? players,
    String? qrToken,
    bool? isLoading,
    bool? isMarking,
    String? error,
    bool clearError = false,
  }) {
    return SessionDetailState(
      session: session ?? this.session,
      players: players ?? this.players,
      qrToken: qrToken ?? this.qrToken,
      isLoading: isLoading ?? this.isLoading,
      isMarking: isMarking ?? this.isMarking,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [session, players, qrToken, isLoading, isMarking, error];
}

/// One trainer session: its roster with per-player attendance status,
/// manual and QR-scan marking, and the session's own display QR.
class SessionDetailCubit extends Cubit<SessionDetailState> {
  SessionDetailCubit() : super(const SessionDetailState());

  int? _sessionId;

  Future<void> load(int sessionId, {bool refresh = false}) async {
    _sessionId = sessionId;
    emit(state.copyWith(isLoading: !refresh, clearError: true));

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.trainerSession(sessionId));

      emit(state.copyWith(
        session: MembershipSessionModel.fromJson(
          Map<String, dynamic>.from(response['session'] as Map),
        ),
        players: J.list(response['players'], SessionPlayerModel.fromJson),
        isLoading: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    }
  }

  /// Marks one player.
  ///
  /// The backend keys on (user, membership, session, **today's date**) via
  /// `updateOrCreate`, using `now()->toDateString()` rather than the
  /// session's own date. Marking a past session therefore writes a row
  /// dated today, not dated to the session - worth knowing before building
  /// any backfill flow on top of this.
  Future<String?> mark({
    required int userId,
    required String status,
    String? note,
  }) async {
    final session = state.session;
    if (session == null || _sessionId == null) return null;

    // Optimistic: flip the chip immediately, the request follows.
    emit(state.copyWith(
      isMarking: true,
      players: state.players
          .map((p) => p.userId == userId
              ? SessionPlayerModel(
                  userId: p.userId,
                  name: p.name,
                  attendanceStatus: status,
                  attendanceId: p.attendanceId,
                )
              : p)
          .toList(),
      clearError: true,
    ));

    try {
      await ApiClient.instance.post(
        ApiEndpoints.trainerAttendances,
        data: {
          'user_id': userId,
          'membership_id': session.membershipId,
          'session_id': _sessionId,
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      await load(_sessionId!, refresh: true);
      emit(state.copyWith(isMarking: false));
      return null;
    } on ApiException catch (e) {
      await load(_sessionId!, refresh: true);
      emit(state.copyWith(isMarking: false, error: e.message));
      return e.message;
    }
  }

  /// Scans a player's personal identity QR against this session. The token
  /// is a UUID from `players.qr_token`; the backend rejects anything else
  /// with a 422 before it even looks it up.
  Future<String?> scanPlayerQr(String playerQrToken, {String? status, String? note}) async {
    if (_sessionId == null) return 'No session loaded.';

    try {
      await ApiClient.instance.post(
        ApiEndpoints.trainerAttendancesScan,
        data: {
          'session_id': _sessionId,
          'player_qr_token': playerQrToken,
          if (status != null) 'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      await load(_sessionId!, refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The token the trainer projects for players to scan themselves in.
  Future<String?> loadQr() async {
    if (_sessionId == null) return null;

    try {
      final response =
          await ApiClient.instance.get(ApiEndpoints.trainerSessionQr(_sessionId!));
      final token = J.asStringOrNull(response['qr_token']);
      if (token != null) emit(state.copyWith(qrToken: token));
      return token;
    } on ApiException {
      return null;
    }
  }

  /// Rotates the token, e.g. once it has been shared beyond the room.
  Future<String?> regenerateQr() async {
    if (_sessionId == null) return null;

    try {
      final response = await ApiClient.instance
          .post(ApiEndpoints.trainerSessionQrRegenerate(_sessionId!));
      final token = J.asStringOrNull(response['qr_token']);
      if (token != null) emit(state.copyWith(qrToken: token));
      return token;
    } on ApiException {
      return null;
    }
  }
}
