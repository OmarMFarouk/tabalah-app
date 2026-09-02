import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/trainer_home_model.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'async_state.dart';

/// The trainer's day view. `/trainer/homepage` takes an optional `date`
/// query param and defaults to today, which is what the horizontal day
/// strip on the home screen drives.
class TrainerHomeCubit extends Cubit<AsyncState<TrainerHomeData>> {
  TrainerHomeCubit() : super(const AsyncState.idle());

  DateTime _selectedDay = DateTime.now();

  DateTime get selectedDay => _selectedDay;

  Future<void> load({DateTime? day, bool refresh = false}) async {
    if (day != null) _selectedDay = day;
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.trainerHomepage,
        // Always send an explicit date rather than relying on the server's
        // "today". The server's today is UTC-derived; the trainer's today is
        // Riyadh's. Around midnight those disagree.
        query: {'date': AppDate.apiDate(_selectedDay)},
      );

      emit(AsyncState.ready(TrainerHomeData.fromJson(response)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<void> selectDay(DateTime day) => load(day: day);
}
