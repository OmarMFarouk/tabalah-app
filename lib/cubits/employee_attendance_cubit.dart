import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/models/employee_attendance_model.dart';

/// Why a clock-in could not be attempted, before the server is even asked.
///
/// Each of these needs a different sentence and a different button, so they
/// are distinct values rather than one "location failed" string.
enum LocationBlock { serviceOff, denied, deniedForever, timeout }

class EmployeeAttendanceCubit extends Cubit<AsyncState<EmployeeAttendanceData>> {
  EmployeeAttendanceCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      final today = await ApiClient.instance.get(ApiEndpoints.employeeAttendanceToday);
      final history = await ApiClient.instance.get(ApiEndpoints.employeeAttendances);
      emit(AsyncState.ready(EmployeeAttendanceData.fromJson(today, history)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// Read the device position, refusing anything the fence cannot trust.
  ///
  /// GPS is mandatory here by design: the whole feature is a claim about
  /// where someone physically was. Returns the block reason so the UI can
  /// offer the right remedy - open settings, or just try again.
  Future<(Position?, LocationBlock?)> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (null, LocationBlock.serviceOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return (null, LocationBlock.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return (null, LocationBlock.denied);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // High accuracy on purpose: the fence is tens of metres wide, and
          // a coarse fix would put honest staff outside it.
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (pos, null);
    } catch (_) {
      // Indoors with no fix is the common case, and it is recoverable by
      // walking to a window - so it is a timeout, not a permission problem.
      return (null, LocationBlock.timeout);
    }
  }

  /// Returns null on success, otherwise a message for the user.
  ///
  /// The fence is re-checked on the server, which is the authority; the
  /// client only avoids a pointless round trip when it already knows the
  /// position is outside.
  Future<String?> checkIn({required String Function(LocationBlock) describe}) async {
    final (pos, block) = await _position();
    if (block != null) return describe(block);

    try {
      await ApiClient.instance.post(
        ApiEndpoints.employeeCheckIn,
        data: {
          'latitude': pos!.latitude,
          'longitude': pos.longitude,
          'accuracy': pos.accuracy,
        },
      );
      await load(refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
