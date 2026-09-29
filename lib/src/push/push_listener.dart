import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/push/push_service.dart';
import 'package:tabala/views/shared/notifications_view.dart';

/// Shows a notification that arrives while the app is open.
///
/// Android does not draw a system notification for a message delivered to a
/// foregrounded app - it hands it to the app and expects it to decide. So
/// this wraps the whole tree and turns one into a banner the user can tap
/// to open the list. Tapping a *system* notification, which is what happens
/// when the app was in the background, goes through the same place.
class PushListener extends StatefulWidget {
  const PushListener({super.key, required this.child});

  final Widget child;

  @override
  State<PushListener> createState() => _PushListenerState();
}

class _PushListenerState extends State<PushListener> {
  final List<StreamSubscription<RemoteMessage>> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    _subscriptions.add(
      PushService.instance.foregroundMessages.listen(_showBanner),
    );
    _subscriptions.add(
      PushService.instance.openedFromNotification.listen((_) => _openList()),
    );

    // A notification that launched the app from cold. Deferred to after the
    // first frame so there is a navigator to push onto.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await PushService.instance.initialMessage() != null) _openList();
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _openList() {
    if (!mounted) return;
    NotificationsView.open(context);
  }

  void _showBanner(RemoteMessage message) {
    final notification = message.notification;
    if (!mounted || notification == null) return;

    // The app's own preference wins over a message that still arrived - the
    // switch is off, so nothing should appear.
    if (!PushService.instance.enabled) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.surfacecolor,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: AppColors.goldInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title ?? '',
                      style: TextStyle(
                        color: AppColors.textcolor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if ((notification.body ?? '').isNotEmpty)
                      Text(
                        notification.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.subtextcolor,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'open'.tr(),
            textColor: AppColors.goldInk,
            onPressed: _openList,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
