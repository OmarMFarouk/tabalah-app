import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/notification_model.dart';

import 'async_state.dart';

/// Everything the academy has told this account: a subscription running
/// out, a leave decision, an invoice, an announcement.
class NotificationsCubit extends Cubit<AsyncState<NotificationsPage>> {
  NotificationsCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      emit(AsyncState.ready(await _fetch()));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<NotificationsPage> _fetch() async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.notifications,
      query: {'per_page': 30},
    );

    return NotificationsPage(
      items: J.list(response['notifications'], AppNotification.fromJson),
      unread: J.asInt(response['unread_count']),
    );
  }

  /// Marking one read is a local change too: the list redraws immediately
  /// rather than waiting for the round trip, and the reload settles it.
  Future<void> markRead(String id) async {
    final current = state.data;
    if (current != null) {
      emit(AsyncState.ready(current.withRead(id)));
    }

    try {
      await ApiClient.instance.post(ApiEndpoints.notificationRead(id));
    } on ApiException {
      // The optimistic change stands; the next load corrects it if it did
      // not actually take.
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.notificationsReadAll);
      await load(refresh: true);
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
