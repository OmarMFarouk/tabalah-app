import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/attendance_cubit.dart';
import 'package:tabala/models/player_attendance_model.dart';
import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/player/scan_session_qr_view.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  late final AttendanceCubit _cubit;
  String? _membershipFilter;

  @override
  void initState() {
    super.initState();
    _cubit = AttendanceCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final checkedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ScanSessionQrView()),
    );

    if (checkedIn == true && mounted) {
      _cubit.load(refresh: true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('checked_in_successfully'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('attendance'.tr())),
        body: BlocBuilder<AttendanceCubit, AsyncState<AttendanceData>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _cubit.load,
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
        // Checking in is the member's own act; a parent watching the
        // register has nothing to press here.
        floatingActionButton: AppScope.isGuardian
            ? null
            : FloatingActionButton.extended(
                onPressed: _openScanner,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.clubGreenDeep,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  'scan_to_check_in'.tr(),
                  style: AppStyles.bold14Black.copyWith(
                    color: AppColors.clubGreenDeep,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _content(AttendanceData data) {
    final rows = data.forMembership(_membershipFilter);

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(refresh: true),
      // The history is paged now, so the rest of it arrives as the member
      // scrolls rather than all of it before the screen can be drawn. The
      // ring above stays a statement about their whole record — the server
      // counts that separately from the rows.
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 400) {
            _cubit.loadMore();
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            // Extra on top of the usual clearance: this screen also
            // carries a floating check-in button above the nav bar.
            ClubBottomNav.scrollPadding(
              context,
              extra: AppScope.isGuardian ? 28 : 84,
            ),
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ClubGradientPanel(
              child: Column(
                children: [
                  _ring(data.rate),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'present'.tr(),
                          value: '${data.presentCount}',
                          onDark: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'late'.tr(),
                          value: '${data.lateCount}',
                          onDark: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'absent'.tr(),
                          value: '${data.absentCount}',
                          onDark: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'excused'.tr(),
                          value: '${data.excusedCount}',
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // The memberships this endpoint returns carry no id - only a name
            // and sport - so the filter necessarily matches on name.
            if (data.memberships.length > 1) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(
                      'all_memberships'.tr(),
                      _membershipFilter == null,
                      () => setState(() => _membershipFilter = null),
                    ),
                    ...data.memberships.map(
                      (m) => _filterChip(
                        m.name,
                        _membershipFilter == m.name,
                        () => setState(() => _membershipFilter = m.name),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SectionHeader(title: 'attendance_history'.tr()),
            if (rows.isEmpty)
              ClubCard(
                child: EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'no_attendance_yet'.tr(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            else
              ...rows.map(_attendanceCard),
            if (data.meta.hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double value) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: PanelInk.line(context),
              valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: AppStyles.bold32Black.copyWith(
                  color: PanelInk.strong(context),
                ),
              ),
              Text(
                'attendance_rate'.tr(),
                style: AppStyles.regular12Grey.copyWith(
                  color: PanelInk.muted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarycolor : AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primarycolor : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: selected ? AppStyles.medium12White : AppStyles.medium12Grey,
        ),
      ),
    );
  }

  Widget _attendanceCard(PlayerAttendanceModel a) {
    final tone = StatusUi.attendance(a.status);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              StatusUi.attendanceIcon(a.status),
              color: StatusUi.readable(context, tone),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.membershipName.isEmpty ? a.sportName : a.membershipName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold14Black,
                ),
                const SizedBox(height: 3),
                Text(
                  // The `date` column is a TIMESTAMP, so this carries a
                  // time as well as a day - worth showing, since it is when
                  // the member actually checked in.
                  AppDate.friendlyDateTime(a.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.regular12Grey,
                ),
              ],
            ),
          ),
          StatusChip(label: StatusUi.label(a.status), color: tone),
        ],
      ),
    );
  }
}
