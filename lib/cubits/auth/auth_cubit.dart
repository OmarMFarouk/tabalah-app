import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/sec_prefs/app_sec_prefs.dart';
import '../../models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Called once from the app root: if a token is stored, verify it's still
  /// valid by hitting /user/me; otherwise the user lands on onboarding/login.
  Future<void> bootstrap() async {
    emit(const AuthLoading());

    final token = await AppSecPrefs.readToken();
    if (token == null || token.isEmpty) {
      AppScope.clearGuardian();
      emit(const AuthUnauthenticated());
      return;
    }

    // Restored before the first request goes out: it decides both which
    // endpoint verifies the session and which prefix every later call uses.
    AppScope.isGuardian = await AppSecPrefs.readIsGuardian();

    try {
      // `/user/me` is closed to guardian tokens by design, so a restored
      // parent session verifies itself against the portal's own endpoint.
      final response = await ApiClient.instance.get(
        AppScope.isGuardian ? ApiEndpoints.guardianMe : ApiEndpoints.me,
      );
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _currentUser = user;
      if (AppScope.isGuardian) AppScope.watchingPlayerName = user.name;
      emit(AuthAuthenticated(user, isGuardian: AppScope.isGuardian));
    } on ApiException {
      await AppSecPrefs.clear();
      AppScope.clearGuardian();
      emit(const AuthUnauthenticated());
    }
  }

  /// Parent-portal sign-in.
  ///
  /// No account, no password: the code *is* the credential, and what it
  /// buys is a read-only view of one player. The token that comes back is
  /// scoped server-side, so even if a write slipped through the UI it
  /// would be refused with a 403 rather than going through.
  Future<void> guardianLogin({required String code}) async {
    emit(const AuthLoading());

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.guardianLogin,
        data: {'code': code},
      );

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      await AppSecPrefs.saveSession(
        token: token,
        role: user.role,
        isGuardian: true,
      );

      // Set before the state is emitted: the screens that build off
      // AuthAuthenticated fire their first requests immediately, and those
      // have to go to `/guardian/*`.
      AppScope.isGuardian = true;
      AppScope.watchingPlayerName = user.name;

      _currentUser = user;
      emit(AuthAuthenticated(user, isGuardian: true));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      await AppSecPrefs.saveSession(token: token, role: user.role);
      // A credentialed login is never a guardian session; clearing here
      // matters because a parent and a player can share a device.
      AppScope.clearGuardian();
      _currentUser = user;
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      // The password was right but the address was never confirmed. That is
      // a step the user can finish, not a failure - send them to the code
      // screen instead of showing a dead end.
      if (e.isForbidden) {
        emit(AuthNeedsVerification(email, e.message));
        return;
      }

      emit(AuthFailure(e.message));
    }
  }

  /// Exchange the emailed code for a session. The backend returns the auth
  /// token here, so verifying logs the user straight in rather than bouncing
  /// them back to a password prompt they filled in moments ago.
  Future<String?> verifyEmail({required String email, required String code}) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      await AppSecPrefs.saveSession(token: token, role: user.role);
      AppScope.clearGuardian();
      _currentUser = user;
      emit(AuthAuthenticated(user));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Ask for a fresh code. The backend answers the same way for unknown
  /// addresses, so a null return here does not prove the account exists.
  Future<String?> resendVerification({required String email}) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> registerPlayer({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    num? height,
    num? weight,
    String? emergencyContact,
  }) async {
    emit(const AuthLoading());

    try {
      await ApiClient.instance.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (emergencyContact != null && emergencyContact.isNotEmpty)
            'emergency_contact': emergencyContact,
        },
      );

      emit(AuthRegistrationSuccess(email));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  /// Returns null on success, or an error message on failure. Kept separate
  /// from the AuthState machine (rather than emitting new states) since the
  /// dedicated Forgot/Reset Password screens manage their own local
  /// loading/success UI and shouldn't disturb whatever screen is
  /// listening to AuthState elsewhere (e.g. the login screen underneath).
  Future<String?> forgotPassword({required String email}) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    try {
      // A guardian token has no access to `/logout`; its own endpoint
      // deletes just that token and leaves the player's session alone.
      await ApiClient.instance.get(
        AppScope.isGuardian ? ApiEndpoints.guardianLogout : ApiEndpoints.logout,
      );
    } on ApiException {
      // Even if the network call fails, we still clear the local session.
    }

    await AppSecPrefs.clear();
    AppScope.clearGuardian();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  /// Wired to ApiClient.onUnauthorized so any 401 anywhere in the app drops
  /// the user back to the login flow.
  Future<void> forceLogout() async {
    await AppSecPrefs.clear();
    AppScope.clearGuardian();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }
}
