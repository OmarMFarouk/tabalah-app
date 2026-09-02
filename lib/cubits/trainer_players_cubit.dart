import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/trainer_player_model.dart';
import 'async_state.dart';

/// One page of the trainer's players, plus where that page sits.
class TrainerPlayersPage {
  final List<TrainerPlayerSummary> players;
  final PageMeta meta;

  const TrainerPlayersPage({required this.players, required this.meta});

  TrainerPlayersPage append(TrainerPlayersPage next) => TrainerPlayersPage(
    players: [...players, ...next.players],
    meta: next.meta,
  );
}

/// Everyone enrolled across the signed-in trainer's memberships, a page at
/// a time.
///
/// This used to ask for the whole roster in one call. The endpoint answered
/// by loading every enrollment and running an attendance query per player,
/// so the cost of opening the screen grew with the size of the club — and
/// all of it was paid up front to render the first handful of rows.
class TrainerPlayersCubit extends Cubit<AsyncState<TrainerPlayersPage>> {
  TrainerPlayersCubit() : super(const AsyncState.idle());

  bool _isFetchingMore = false;

  String _query = '';
  bool _worstFirst = false;

  /// Searching and sorting re-query from page one rather than reordering
  /// what is loaded: with a paged list, filtering on the device would only
  /// ever search the rows already downloaded.
  Future<void> setQuery(String value) {
    _query = value.trim();
    return load(refresh: true);
  }

  Future<void> setWorstFirst(bool value) {
    _worstFirst = value;
    return load(refresh: true);
  }

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      emit(AsyncState.ready(await _fetch(page: 1)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Pulls the next page and appends it. Guarded against the double-fire a
  /// scroll listener produces near the bottom of the list.
  Future<void> loadMore() async {
    final current = state.data;
    if (current == null || !current.meta.hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    try {
      final next = await _fetch(page: current.meta.nextPage);
      emit(AsyncState.ready(current.append(next)));
    } on ApiException {
      // Leave what is already on screen alone — there is nothing useful to
      // say beyond the rows the trainer can already see.
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<TrainerPlayersPage> _fetch({required int page}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.trainerPlayers,
      query: {
        'page': page,
        'per_page': 15,
        if (_query.isNotEmpty) 'q': _query,
        if (_worstFirst) 'sort': 'attendance',
      },
    );

    return TrainerPlayersPage(
      players: J.list(response['players'], TrainerPlayerSummary.fromJson),
      meta: PageMeta.fromJson(
        response['meta'] is Map
            ? Map<String, dynamic>.from(response['meta'] as Map)
            : null,
      ),
    );
  }
}

/// One player's profile and attendance history, scoped to this trainer's
/// own memberships. The path segment is the **user** id, not the players
/// table id - `/trainer/players/{playerUserId}`.
class TrainerPlayerDetailCubit extends Cubit<AsyncState<TrainerPlayerDetail>> {
  TrainerPlayerDetailCubit() : super(const AsyncState.idle());

  Future<void> load(int userId, {bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.trainerPlayer(userId));
      emit(AsyncState.ready(TrainerPlayerDetail.fromJson(
        player: Map<String, dynamic>.from(response['player'] as Map),
        attendances: response['attendances'],
      )));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
