import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/player_home_model.dart';
import 'async_state.dart';

/// Player's home dashboard - active memberships (with attendance rate and
/// days left), today's sessions, and their trainers - all from the single
/// `/player/homepage` endpoint.
class PlayerHomeCubit extends Cubit<AsyncState<PlayerHomeData>> {
  PlayerHomeCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerHomepage);

      // The controller nests everything under `homepage`; fall back to the
      // envelope itself so the cubit still works if that wrapper is ever
      // flattened server-side.
      final payload = response['homepage'] is Map
          ? Map<String, dynamic>.from(response['homepage'] as Map)
          : response;

      emit(AsyncState.ready(PlayerHomeData.fromJson(payload)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
