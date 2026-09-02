import 'json_utils.dart';

/// Mirrors `App\Http\Resources\SessionRatingResource`.
///
/// Field names to get right, because they are easy to guess wrong:
/// there is a single free-text field called `note` (not `comment`), the
/// rating is a decimal (4.5 is valid, the column is `decimal(5,2)`), and
/// the two participant names come back as `rater_name` / `ratee_name`.
///
/// `user_id` on this resource is the person being rated (the trainer);
/// `rater_id` is the player who submitted it.
class SessionRatingModel {
  final int id;
  final int sessionId;
  final int userId;
  final String? rateeName;
  final int raterId;
  final String? raterName;
  final double rating;
  final String? note;
  final String? createdAt;

  const SessionRatingModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.raterId,
    required this.rating,
    this.rateeName,
    this.raterName,
    this.note,
    this.createdAt,
  });

  factory SessionRatingModel.fromJson(Map<String, dynamic> json) {
    return SessionRatingModel(
      id: J.asInt(json['id']),
      sessionId: J.asInt(json['session_id']),
      userId: J.asInt(json['user_id']),
      rateeName: J.asStringOrNull(json['ratee_name']),
      raterId: J.asInt(json['rater_id']),
      raterName: J.asStringOrNull(json['rater_name']),
      rating: J.asDouble(json['rating']),
      note: J.asStringOrNull(json['note']),
      createdAt: J.asStringOrNull(json['created_at']),
    );
  }
}
