import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/user_model.dart';
import 'async_state.dart';

/// The player's profile screen.
///
/// Note there are two profile surfaces on the backend and they edit
/// different columns:
///
/// * `PUT /player/profile` (this cubit's [update]) accepts name, avatar,
///   height, weight and emergency_contact only.
/// * `PUT /profile` (the shared one, [updateAccount]) is the *only* place
///   that can change email, phone or password - and changing the password
///   requires proving the current one, because a signed-in device left
///   unattended should not be enough to lock the real owner out.
class PlayerProfileCubit extends Cubit<AsyncState<UserModel>> {
  PlayerProfileCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      final response = await ApiClient.instance.get(ApiEndpoints.playerProfile);
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Returns null on success, or the server's message. The previous user is
  /// kept on screen throughout so the form never flashes empty.
  Future<String?> update({
    String? name,
    num? height,
    num? weight,
    String? emergencyContact,
  }) async {
    final previous = state.data;
    emit(state.toRefreshing());

    try {
      final response = await ApiClient.instance.put(
        ApiEndpoints.playerProfile,
        data: {
          if (name != null && name.isNotEmpty) 'name': name,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (emergencyContact != null) 'emergency_contact': emergencyContact,
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

  /// Account-level fields via the shared `/profile` endpoint.
  Future<String?> updateAccount({
    String? email,
    String? phone,
    String? password,
    String? currentPassword,
  }) async {
    final previous = state.data;

    try {
      final response = await ApiClient.instance.put(
        ApiEndpoints.profile,
        data: {
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (password != null && password.isNotEmpty) ...{
            'password': password,
            'current_password': currentPassword ?? '',
          },
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

  /// Points the avatar at an external image URL. The same endpoint also
  /// accepts a multipart upload; this variant covers the common case
  /// without pulling an image picker into the dependency list.
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
      final response = await ApiClient.instance.delete(ApiEndpoints.profileAvatar);
      emit(AsyncState.ready(
        UserModel.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
