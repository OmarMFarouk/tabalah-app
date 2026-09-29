import 'package:flutter/material.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/src/colors/app_colors.dart';

import 'notifications_view.dart';

/// The bell in the home header, with the unread count on it.
///
/// It asks for the count when the header is built and again whenever the
/// app comes back to the foreground - there is no socket, and a timer
/// ticking behind a screen nobody is looking at would be a battery cost for
/// a number that can wait.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.notifications,
        query: {'per_page': 1},
      );
      if (!mounted) return;
      setState(() => _unread = J.asInt(response['unread_count']));
    } on ApiException {
      // A badge is not worth an error state; it simply stays as it was.
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await NotificationsView.open(context);
        await _load();
      },
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 18,
              color: AppColors.greycolor,
            ),
            if (_unread > 0)
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(
                    color: AppColors.redcolor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _unread > 9 ? '9+' : '$_unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
