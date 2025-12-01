import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String body;

  NotificationItem({required this.title, required this.body});
}

class NotificationsPage extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationsPage({Key? key, required this.notifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
          ? const Center(child: Text("Aucune notification"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notification_important, color: Colors.teal),
                  title: Text(notif.title),
                  subtitle: Text(notif.body),
                );
              },
            ),
    );
  }
}
