import 'json_utils.dart';

/// One thing the academy told this account.
///
/// `kind` is what the server put in the payload's `type`, and is what the
/// list uses to pick an icon - not a closed enum, because a new kind of
/// notice should reach the app without a release.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String kind;
  final bool read;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.kind = 'app',
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: J.asString(json['id']),
        title: J.asString(json['title']),
        body: J.asString(json['body']),
        kind: J.asStringOrNull(json['kind']) ?? 'app',
        read: J.asBool(json['read']),
        createdAt: J.asStringOrNull(json['created_at']),
      );

  AppNotification asRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        kind: kind,
        read: true,
        createdAt: createdAt,
      );
}

class NotificationsPage {
  final List<AppNotification> items;
  final int unread;

  const NotificationsPage({this.items = const [], this.unread = 0});

  /// The same page with one entry marked read, for the optimistic update.
  NotificationsPage withRead(String id) => NotificationsPage(
        items: [
          for (final item in items) item.id == id ? item.asRead() : item,
        ],
        unread: items.any((i) => i.id == id && !i.read) ? unread - 1 : unread,
      );
}
