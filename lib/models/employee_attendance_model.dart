import 'package:tabala/models/json_utils.dart';

class EmployeeAttendanceData {
  /// Null until the employee has clocked in today.
  final EmployeeAttendanceRow? today;
  final List<EmployeeAttendanceRow> history;
  final int daysThisMonth;
  final Geofence? fence;

  const EmployeeAttendanceData({
    this.today,
    this.history = const [],
    this.daysThisMonth = 0,
    this.fence,
  });

  bool get checkedInToday => today != null;

  factory EmployeeAttendanceData.fromJson(
    Map<String, dynamic> today,
    Map<String, dynamic> history,
  ) {
    final t = today['attendance'];
    return EmployeeAttendanceData(
      today: t is Map<String, dynamic> ? EmployeeAttendanceRow.fromJson(t) : null,
      fence: today['geofence'] is Map<String, dynamic>
          ? Geofence.fromJson(today['geofence'] as Map<String, dynamic>)
          : null,
      history: J.list(history['attendances'], EmployeeAttendanceRow.fromJson),
      daysThisMonth: J.asInt(history['days_this_month']),
    );
  }
}

class EmployeeAttendanceRow {
  final int id;
  final String date;
  final String checkedInAt;
  final int distanceMeters;

  const EmployeeAttendanceRow({
    required this.id,
    required this.date,
    required this.checkedInAt,
    required this.distanceMeters,
  });

  factory EmployeeAttendanceRow.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendanceRow(
        id: J.asInt(json['id']),
        date: J.asString(json['date']),
        checkedInAt: J.asString(json['checked_in_at']),
        distanceMeters: J.asInt(json['distance_meters']),
      );
}

class Geofence {
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const Geofence({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
        latitude: J.asDouble(json['latitude']),
        longitude: J.asDouble(json['longitude']),
        radiusMeters: J.asInt(json['radius_meters']),
      );
}
