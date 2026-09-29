import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

/// Push notifications, and the device token that makes them possible.
///
/// ---------------------------------------------------------------------
/// Why the token is held here rather than posted once at sign-in
/// ---------------------------------------------------------------------
/// A token posted once goes stale in ways nothing tells the app about: a
/// reinstall, a restore onto a new handset, Firebase rotating it, the user
/// clearing app data. So the token is kept in memory and attached to every
/// API call as a header ([currentToken]); the server upserts whatever it
/// sees. That makes the registration self-healing - by the time anything
/// needs to push to this device, the most recent request has already told
/// the server where to find it.
///
/// Nothing here throws. A phone with Google Play Services missing, a
/// permission the user declined, an emulator without Firebase - all of them
/// end with [available] false and an app that works exactly as before,
/// minus the buzz.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// The key the app stores its own "do I want notifications" answer under.
  /// Separate from the OS permission: someone can grant the permission and
  /// still turn notifications off inside the app.
  static const _prefsKey = 'notifications_enabled';

  String? _token;
  bool _available = false;
  StreamSubscription<String>? _refreshes;

  /// The current FCM token, or null when push is not working on this device.
  String? get currentToken => _enabled ? _token : null;

  /// Whether Firebase started and a token was obtained.
  bool get available => _available;

  bool _enabled = true;

  /// The in-app preference. False means the app stops sending its token, so
  /// the server has nothing to push to - which is what "off" should mean.
  bool get enabled => _enabled;

  /// Called once from `main`, before the app runs.
  Future<void> init() async {
    // The stored preference decides whether the token is sent, but the token
    // is still fetched: turning notifications back on should not require a
    // restart.
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      _enabled = true;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Push: Firebase did not start - $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Ask, but do not insist. On Android 12 and below this is granted
      // without a prompt; on 13+ and on iOS it shows the system dialog.
      await FirebaseMessaging.instance.requestPermission();

      _token = await FirebaseMessaging.instance.getToken();
      _available = _token != null;

      // Firebase replaces a token without warning. Keeping the newest one in
      // memory is all that is needed, because every request carries it.
      _refreshes = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        _available = true;
      });
    } catch (e) {
      debugPrint('Push: messaging unavailable - $e');
    }
  }

  /// Whether the OS will actually deliver a notification right now. Used by
  /// the settings screen to explain a switch that is on but silent.
  Future<bool> osPermissionGranted() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Ask the OS again. Returns whether it ended up granted - on Android 13+
  /// a second refusal is final and the user has to go to system settings,
  /// which is what the settings screen then offers.
  Future<bool> requestOsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // The preference is a convenience; the in-memory flag already took.
    }
  }

  /// Messages that arrive while the app is open. Android does not display
  /// these itself, so the stream is handed to the UI to show in-app.
  Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  /// A notification the user tapped, which opened or resumed the app.
  Stream<RemoteMessage> get openedFromNotification =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification that launched a terminated app, if any.
  Future<RemoteMessage?> initialMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage();
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _refreshes?.cancel();
  }
}

/// Runs in its own isolate when a message arrives and the app is not in the
/// foreground. Android has already drawn the notification by this point -
/// this exists so the handler is registered, which is what stops Firebase
/// logging a warning on every delivery.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('Push: background message ${message.messageId}');
}
