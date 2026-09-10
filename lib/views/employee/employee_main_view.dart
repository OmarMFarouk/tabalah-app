import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/home_header.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/employee_attendance_cubit.dart';
import 'package:tabala/models/employee_attendance_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';

/// The employee portal.
///
/// One job, one screen: clock in. Everything else here is the record of
/// having done so, which is what makes the button trustworthy - an employee
/// can see exactly what was filed under their name.
///
/// No bottom navigation: a second tab would imply there is somewhere else to
/// go. Add one when there is.
class EmployeeMainView extends StatefulWidget {
  const EmployeeMainView({super.key});

  @override
  State<EmployeeMainView> createState() => _EmployeeMainViewState();
}

class _EmployeeMainViewState extends State<EmployeeMainView> {
  late final EmployeeAttendanceCubit _cubit;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _cubit = EmployeeAttendanceCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _describe(LocationBlock b) => switch (b) {
        LocationBlock.serviceOff => 'gps_off'.tr(),
        LocationBlock.denied => 'gps_denied'.tr(),
        LocationBlock.deniedForever => 'gps_denied_forever'.tr(),
        LocationBlock.timeout => 'gps_timeout'.tr(),
      };

  Future<void> _checkIn() async {
    setState(() => _submitting = true);
    final error = await _cubit.checkIn(describe: _describe);
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'attendance_recorded'.tr()),
        backgroundColor:
            error != null ? AppColors.redcolor : AppColors.primarycolor,
        // Only a permanently denied permission needs Settings; every other
        // failure is fixed by the user where they stand.
        action: error == _describe(LocationBlock.deniedForever)
            ? SnackBarAction(
                label: 'open_settings'.tr(),
                textColor: Colors.white,
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<EmployeeAttendanceCubit,
              AsyncState<EmployeeAttendanceData>>(
            builder: (context, state) => RefreshIndicator(
              color: AppColors.goldInk,
              backgroundColor: AppColors.surfacecolor,
              onRefresh: () => _cubit.load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  HomeHeader(
                      role: 'employee', name: user?.name, photoUrl: user?.photo),
                  const SizedBox(height: 12),
                  if (state.isBusy)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: AsyncStateView(isLoading: true, child: SizedBox()),
                    )
                  else if (state.hasError && !state.hasData)
                    AsyncStateView(
                      isLoading: false,
                      errorMessage: state.error,
                      onRetry: _cubit.load,
                      child: const SizedBox(),
                    )
                  else if (state.hasData)
                    ..._content(state.data!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(EmployeeAttendanceData data) {
    final done = data.checkedInToday;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ClubCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.location_on_rounded,
                size: 52,
                color: done ? AppColors.primarycolor : AppColors.goldInk,
              ),
              const SizedBox(height: 14),
              Text(
                done ? 'attendance_done_today'.tr() : 'attendance_not_yet'.tr(),
                textAlign: TextAlign.center,
                style: AppStyles.bold18Black,
              ),
              const SizedBox(height: 6),
              Text(
                done
                    ? 'attendance_done_at'.tr(args: [
                        AppDate.time(data.today!.checkedInAt, fallback: '')
                      ])
                    : 'attendance_gps_hint'.tr(),
                textAlign: TextAlign.center,
                style: AppStyles.regular14Grey,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  // Disabled once done: one per day is enforced by a unique
                  // index, so offering the button again only earns a refusal.
                  onPressed: (done || _submitting) ? null : _checkIn,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(
                    _submitting
                        ? 'locating'.tr()
                        : (done
                            ? 'attendance_recorded'.tr()
                            : 'record_attendance'.tr()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarycolor,
                    foregroundColor: AppColors.clubGreenDeep,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: .25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SectionHeader(
        title: 'my_performance'.tr(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClubGradientPanel(
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'days_this_month'.tr(),
                  value: '${data.daysThisMonth}',
                  icon: Icons.event_available_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'total_days'.tr(),
                  value: '${data.history.length}',
                  icon: Icons.history_rounded,
                  onDark: true,
                ),
              ),
            ],
          ),
        ),
      ),
      SectionHeader(
        title: 'attendance_history'.tr(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: data.history.isEmpty
            ? ClubCard(
                child: EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'no_attendance_yet'.tr(),
                  message: 'no_attendance_yet_desc'.tr(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            : Column(
                children: data.history
                    .take(30)
                    .map((r) => ClubCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 20, color: AppColors.primarycolor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppDate.friendlyDate(r.date),
                                  style: AppStyles.medium14Black,
                                ),
                              ),
                              Text(
                                AppDate.time(r.checkedInAt, fallback: ''),
                                style: AppStyles.regular14Grey,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
      ),
    ];
  }
}
