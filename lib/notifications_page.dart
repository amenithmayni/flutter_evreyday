import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String body;
  final bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    this.isRead = false,
  });
}

class NotificationsPage extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationsPage({Key? key, required this.notifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return ListTile(
            leading: Icon(Icons.notifications),
            title: Text(notif.title),
            subtitle: Text(notif.body),
            tileColor: notif.isRead ? Colors.white : Colors.grey[200],
          );
        },
      ),
    );
  }
}
