import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/push/push_service.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// The notifications row in the preferences card.
///
/// Two things can be off and they are not the same thing: the app's own
/// preference, and the permission the operating system holds. A switch that
/// is on while Android is silently dropping every notification is the worst
/// of both, so the tile reports the OS state underneath and offers the way
/// to fix it - a second prompt if one is still allowed, and otherwise a jump
/// to the system settings page, because Android only asks twice.
class NotificationSettingTile extends StatefulWidget {
  const NotificationSettingTile({super.key});

  @override
  State<NotificationSettingTile> createState() => _NotificationSettingTileState();
}

class _NotificationSettingTileState extends State<NotificationSettingTile>
    with WidgetsBindingObserver {
  bool _enabled = PushService.instance.enabled;
  bool _osGranted = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // They may have just come back from the system settings page having
    // changed exactly the thing this tile reports.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await PushService.instance.osPermissionGranted();
    if (!mounted) return;
    setState(() {
      _osGranted = granted;
      _enabled = PushService.instance.enabled;
      _checked = true;
    });
  }

  Future<void> _toggle(bool value) async {
    await PushService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);

    // Turning the switch on is the natural moment to ask for a permission
    // that was never granted.
    if (value && !_osGranted) {
      await PushService.instance.requestOsPermission();
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWarning = _checked && _enabled && !_osGranted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              size: 20,
              color: AppColors.goldInk,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('notifications'.tr(), style: AppStyles.medium14Black),
            ),
            Switch(
              value: _enabled,
              activeColor: AppColors.primarycolor,
              onChanged: _toggle,
            ),
          ],
        ),
        if (showWarning)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 32, top: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'notifications_blocked'.tr(),
                    style: TextStyle(color: AppColors.redcolor, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final granted =
                        await PushService.instance.requestOsPermission();
                    if (!granted) await openAppSettingsPage();
                    await _refresh();
                  },
                  child: Text('enable'.tr(), style: AppStyles.bold12Gold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Opens this app's page in the system settings.
///
/// Uses Geolocator's helper rather than adding a dependency for it: the app
/// already carries Geolocator for staff clock-in, and the page it opens is
/// the app's own settings screen, not anything location-specific.
Future<void> openAppSettingsPage() async {
  try {
    await Geolocator.openAppSettings();
  } catch (_) {
    // Nothing useful to say if the platform refuses to open it.
  }
}
