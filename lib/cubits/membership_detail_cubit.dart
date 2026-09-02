import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/membership_detail_model.dart';
import 'async_state.dart';

/// One membership's detail plus this player's enrollment status and the
/// next ten sessions.
class MembershipDetailCubit extends Cubit<AsyncState<MembershipDetail>> {
  MembershipDetailCubit() : super(const AsyncState.idle());

  int? _membershipId;

  Future<void> load(int membershipId, {bool refresh = false}) async {
    _membershipId = membershipId;
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response =
          await ApiClient.instance.get(ApiEndpoints.playerMembership(membershipId));

      emit(AsyncState.ready(MembershipDetail.fromJson(
        membership: Map<String, dynamic>.from(response['membership'] as Map),
        upcoming: response['upcoming_sessions'],
      )));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<void> reload() async {
    if (_membershipId != null) await load(_membershipId!, refresh: true);
  }
}
