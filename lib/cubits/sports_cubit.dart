import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/sport_page_model.dart';
import 'async_state.dart';

/// Every sport with its active memberships, each annotated with the
/// player's own `enrollment_status`.
class SportsCubit extends Cubit<AsyncState<List<SportWithPlans>>> {
  SportsCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerSports);
      final sports = (response['sports'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => SportWithPlans.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      emit(AsyncState.ready(sports));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
