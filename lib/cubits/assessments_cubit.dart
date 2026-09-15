import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/assessment_model.dart';
import 'package:tabala/models/json_utils.dart';

import 'async_state.dart';

/// The signed-in player's assessments — or, in a parent's session, those of
/// the player being watched: the endpoint follows the scope.
class AssessmentsCubit extends Cubit<AsyncState<AssessmentsPage>> {
  AssessmentsCubit() : super(const AsyncState.idle());

  bool _fetchingMore = false;

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      emit(AsyncState.ready(await _fetch(1)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Next page, appended. Guarded against the double-fire a scroll listener
  /// produces near the bottom of the list.
  Future<void> loadMore() async {
    final current = state.data;
    if (current == null || !current.meta.hasMore || _fetchingMore) return;

    _fetchingMore = true;
    try {
      emit(AsyncState.ready(current.append(await _fetch(current.meta.nextPage))));
    } on ApiException {
      // What is on screen stays; there is nothing more useful to show.
    } finally {
      _fetchingMore = false;
    }
  }

  Future<AssessmentsPage> _fetch(int page) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.playerAssessments,
      query: {'page': page, 'per_page': 15},
    );

    return AssessmentsPage(
      summary: AssessmentSummary.fromJson(J.asMap(response['summary'])),
      items: J.list(response['assessments'], AssessmentItem.fromJson),
      meta: PageMeta.fromJson(
        response['meta'] is Map ? Map<String, dynamic>.from(response['meta'] as Map) : null,
      ),
    );
  }
}
