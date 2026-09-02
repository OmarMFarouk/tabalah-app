import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/user_model.dart';
import 'async_state.dart';

/// `PUT /trainer/profile` accepts name, avatar and bio. Everything else
/// about a trainer - their sport, their status, their rating - is set by the
/// club in the admin panel and is read-only here.
class TrainerProfileCubit extends Cubit<AsyncState<UserModel>> {
  TrainerProfileCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.trainerProfile);
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<String?> update({String? name, String? bio}) async {
    final previous = state.data;

    try {
      final response = await ApiClient.instance.put(
        ApiEndpoints.trainerProfile,
        data: {
          if (name != null && name.isNotEmpty) 'name': name,
          if (bio != null) 'bio': bio,
        },
      );

      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
      return null;
    } on ApiException catch (e) {
      if (previous != null) emit(AsyncState.ready(previous));
      return e.message;
    }
  }

  /// Replaces the avatar with a picture from the device.
  ///
  /// The same endpoint behind [setAvatarUrl] — it takes either a multipart
  /// file or a URL — so the response shape and the state update are
  /// identical; only how the picture got there differs.
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final response = await ApiClient.instance.upload(
        ApiEndpoints.profileAvatar,
        filePath: filePath,
      );
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setAvatarUrl(String url) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.profileAvatar,
        data: {'avatar_url': url},
      );
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> removeAvatar() async {
    try {
      final response = await ApiClient.instance.delete(
        ApiEndpoints.profileAvatar,
      );
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
