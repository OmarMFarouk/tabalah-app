import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/session_rating_model.dart';

class RatingSubmission {
  final bool isSubmitting;
  final SessionRatingModel? result;
  final String? error;

  const RatingSubmission({this.isSubmitting = false, this.result, this.error});
}

/// `POST /player/session-ratings` - a player rates the trainer of a session
/// they attended.
///
/// Server-side rules worth mirroring in the UI so the member is not
/// surprised by a 422:
/// * they must have an attendance row with status `present` for that
///   session - "I was there" is not enough, the trainer or their own QR
///   check-in must have recorded it;
/// * `note` is **required**, not optional, and capped at 1000 characters;
/// * `rating` is numeric 0–5 and may be fractional (4.5 is valid);
/// * submitting twice updates the existing row rather than erroring, because
///   the backend uses `updateOrCreate` keyed on session + rater.
class SessionRatingCubit extends Cubit<RatingSubmission> {
  SessionRatingCubit() : super(const RatingSubmission());

  Future<bool> submit({
    required int sessionId,
    required int trainerUserId,
    required double rating,
    required String note,
  }) async {
    emit(const RatingSubmission(isSubmitting: true));

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.playerSessionRatings,
        data: {
          'session_id': sessionId,
          'trainer_user_id': trainerUserId,
          'rating': rating,
          'note': note,
        },
      );

      emit(RatingSubmission(
        result: SessionRatingModel.fromJson(
          Map<String, dynamic>.from(response['session_rating'] as Map),
        ),
      ));
      return true;
    } on ApiException catch (e) {
      emit(RatingSubmission(error: e.message));
      return false;
    }
  }

  /// Resolves a trainer's **user** id from their display name.
  ///
  /// This exists because of a genuine gap in the player-facing API: rating
  /// requires `trainer_user_id`, but nothing a player can call returns it.
  /// `HomepageTrainerResource` exposes `trainer_id` (the trainers-table key)
  /// and the membership detail endpoint exposes only a name and avatar.
  ///
  /// `GET /user?q=` is open to any signed-in role and searches on name, so
  /// it can bridge the gap - but only unambiguously. If the search returns
  /// anything other than exactly one trainer, this returns null and the UI
  /// refuses to submit rather than risk attaching the rating to the wrong
  /// person. The clean fix is server-side: add `trainer_user_id` to
  /// MembershipDetailCont's payload.
  Future<int?> lookupTrainerId(String name) async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.users,
        query: {'q': name},
      );

      final matches = (response['users'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((u) => u['user_role'] == 'trainer')
          .toList();

      if (matches.length != 1) return null;
      return matches.first['user_id'] is int
          ? matches.first['user_id'] as int
          : int.tryParse('${matches.first['user_id']}');
    } on ApiException {
      return null;
    }
  }
}
