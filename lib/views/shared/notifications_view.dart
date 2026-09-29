import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/notifications_cubit.dart';
import 'package:tabala/models/notification_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// Everything the academy has told this account, newest first.
///
/// Opened from the bell in the home header. Every role uses the same screen
/// because the endpoint is scoped to whoever is signed in.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsView()),
      );

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NotificationsCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(
          title: Text('notifications'.tr()),
          actions: [
            BlocBuilder<NotificationsCubit, AsyncState<NotificationsPage>>(
              builder: (context, state) => (state.data?.unread ?? 0) == 0
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: _cubit.markAllRead,
                      child: Text('mark_all_read'.tr()),
                    ),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, AsyncState<NotificationsPage>>(
          builder: (context, state) {
            final page = state.data;

            if (page == null) {
              return AsyncStateView(
                isLoading: state.isBusy || !state.hasError,
                errorMessage: state.error,
                onRetry: _cubit.load,
                child: const SizedBox(),
              );
            }

            if (page.items.isEmpty) {
              return Center(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'no_notifications'.tr(),
                  message: 'no_notifications_desc'.tr(),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.goldInk,
              backgroundColor: AppColors.surfacecolor,
              onRefresh: () => _cubit.load(refresh: true),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: page.items.length,
                itemBuilder: (_, i) => _NotificationCard(
                  item: page.items[i],
                  onTap: () => _cubit.markRead(page.items[i].id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  /// The icon carries the kind, so a glance down the list separates an
  /// expiring subscription from an approved leave without reading.
  (IconData, Color) get _mark => switch (item.kind) {
        'leave' => (Icons.beach_access_rounded, AppColors.goldInk),
        'invoice' => (Icons.receipt_long_rounded, AppColors.greencolor),
        'enrollment' => (Icons.ac_unit_rounded, AppColors.goldInk),
        'enrollment_expiring' => (Icons.alarm_rounded, AppColors.goldInk),
        'enrollment_expired' => (Icons.event_busy_rounded, AppColors.redcolor),
        'announcement' => (Icons.campaign_rounded, AppColors.greencolor),
        _ => (Icons.info_rounded, AppColors.greycolor),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = _mark;

    return InkWell(
      onTap: item.read ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClubCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: AppStyles.bold14Black)),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.goldInk,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.body, style: AppStyles.regular12Grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
