import 'package:equatable/equatable.dart';

import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// App just started - deciding whether a stored session is still valid.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  /// True when a parent signed in with a player's code.
  ///
  /// The `user` is the *player* either way - a guardian token authenticates
  /// as the player it watches - so this flag is the only thing that tells
  /// the two apart, and it decides which shell AuthGate builds.
  final bool isGuardian;

  const AuthAuthenticated(this.user, {this.isGuardian = false});

  @override
  List<Object?> get props => [user, isGuardian];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Registration succeeded, but the account is not usable yet: the backend
/// issues an emailed code and withholds the token until it is entered. The
/// UI routes to the verification screen, carrying the address the code went
/// to so the user never retypes it.
class AuthRegistrationSuccess extends AuthState {
  final String email;

  const AuthRegistrationSuccess(this.email);
}

/// A correct password for an address that was never verified. Carries the
/// email so the login screen can send the user straight to the code screen
/// rather than showing a dead-end error.
class AuthNeedsVerification extends AuthState {
  final String email;
  final String message;

  const AuthNeedsVerification(this.email, this.message);
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
