import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:table_calendar/table_calendar.dart';

import 'ajout_habit.dart';
import 'MyProfile_Screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String email;

  const HomeScreen({super.key, required this.userName, this.email = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> habits = [];
  List<Map<String, String>> notifications = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  File? profileImage;
  int notifCount = 0;

  DateTime selectedDate = DateTime.now();
  DateTime lastResetDate = DateTime.now();
  int currentMonthIndex = DateTime.now().month - 1;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    fetchHabits();
  }

  void _initNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    flutterLocalNotificationsPlugin.initialize(settings,
        onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) {
        setState(() {
          notifications.add({
            'title': 'Habit Reminder',
            'body': details.payload!,
          });
          notifCount = notifications.length;
        });
      }
    });
  }

  void _showNotificationsPanel() {
    setState(() => notifCount = 0);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (notifications.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("Aucune notification")),
          );
        }
        return SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: const Icon(Icons.notification_important, color: Colors.teal),
                title: Text(notif['title'] ?? ''),
                subtitle: Text(notif['body'] ?? ''),
              );
            },
          ),
        );
      },
    );
  }

  void _resetCompletedDaily() {
    DateTime today = DateTime.now();
    if (today.day != lastResetDate.day ||
        today.month != lastResetDate.month ||
        today.year != lastResetDate.year) {
      for (var habit in habits) {
        habit['completed'] = false;
      }
      lastResetDate = today;
    }
  }

  void _scheduleDailyNotification(String habitName, String heure) {
    final parts = heure.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    flutterLocalNotificationsPlugin.zonedSchedule(
      habitName.hashCode,
      'Habit Reminder',
      '$habitName n\'est pas complété',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'habit_channel', 'Habit Notifications',
            importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _scheduleAllDailyNotifications() {
    for (var habit in habits) {
      if (!habit['completed']) {
        _scheduleDailyNotification(habit['nom'], habit['heure']);
      }
    }
  }

  Future<void> fetchHabits() async {
    try {
      final url = Uri.parse('http://localhost:8080/api/habits');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          habits = data.map((habit) {
            return {
              'id': habit['id'],
              'nom': habit['nom'] ?? '',
              'type': habit['type'] ?? '',
              'duration': habit['duree'] ?? 0,
              'heure': habit['heure'] ?? '',
              'completed': habit['completed'] ?? false,
            };
          }).toList();

          _resetCompletedDaily();
          _scheduleAllDailyNotifications();
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur lors de la récupération des habits');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void deleteHabit(int index) {
    setState(() {
      habits.removeAt(index);
    });
  }

  void modifyHabit(int index) async {
    final habit = habits[index];
    final TextEditingController nameController =
        TextEditingController(text: habit['nom']);
    final TextEditingController typeController =
        TextEditingController(text: habit['type']);
    final TextEditingController durationController =
        TextEditingController(text: habit['duration'].toString());
    final TextEditingController timeController =
        TextEditingController(text: habit['heure']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type')),
            TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration')),
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Heure HH:mm')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                habits[index]['nom'] = nameController.text;
                habits[index]['type'] = typeController.text;
                habits[index]['duration'] = int.tryParse(durationController.text) ?? habits[index]['duration'];
                habits[index]['heure'] = timeController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _onHabitAdded() {
    fetchHabits();
  }

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  // ------------------- Month Carousel -------------------
  Widget buildMonthCarousel() {
    return SizedBox(
      height: 50,
      child: PageView.builder(
        controller: PageController(initialPage: currentMonthIndex, viewportFraction: 0.4),
        itemCount: 12,
        onPageChanged: (index) {
          setState(() {
            currentMonthIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final month = DateTime(DateTime.now().year, index + 1);
          final isSelected = index == currentMonthIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                DateFormat.MMMM().format(month),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------- TableCalendar -------------------
  Widget buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDate,
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          selectedDate = selectedDay;
        });
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekendStyle: TextStyle(color: Colors.red),
        weekdayStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      headerVisible: false,
      enabledDayPredicate: (day) => day.month == currentMonthIndex + 1,
    );
  }

  Widget _buildHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildMonthCarousel(),
          const SizedBox(height: 12),
          buildCalendar(),
          const SizedBox(height: 12),
          ...habits.asMap().entries.map((entry) => _habitCard(entry.key, entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return MyProfileScreen(
      username: widget.userName,
      profileImage: profileImage,
      email: widget.email,
      completedHabits: habits
          .where((h) => h['completed'] == true)
          .map((h) => h['nom'] as String)
          .toList(),
    );
  }

  Widget _habitCard(int index, Map<String, dynamic> habit) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: habit['completed'] ? Colors.teal.shade100 : Colors.white,
        border: Border.all(color: Colors.teal, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Checkbox(
            value: habit['completed'],
            onChanged: (val) => setState(() => habit['completed'] = val!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit['nom'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: habit['completed'] ? Colors.white : Colors.black,
                      decoration: habit['completed'] ? TextDecoration.lineThrough : null,
                    )),
                Text('Type: ${habit['type']}', style: TextStyle(color: habit['completed'] ? Colors.white : Colors.black)),
                Text('Duration: ${habit['duration']} min', style: TextStyle(color: habit['completed'] ? Colors.white : Colors.black)),
                Text('Time: ${habit['heure']}', style: TextStyle(color: habit['completed'] ? Colors.white : Colors.black)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onSelected: (value) {
              if (value == 'Edit') modifyHabit(index);
              if (value == 'Delete') deleteHabit(index);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Edit', child: Text('Edit')),
              const PopupMenuItem(value: 'Delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_buildHome(), _buildProfile(), Container()]; // Chat placeholder

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Welcome, ${widget.userName}", style: const TextStyle(color: Colors.black, fontSize: 17)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: _showNotificationsPanel,
              ),
              if (notifCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$notifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: pickProfileImage,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null ? const Icon(Icons.person, color: Colors.white, size: 22) : null,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: tabs[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AjouterHabitPage(onHabitAdded: _onHabitAdded)),
                );
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (val) => setState(() => _currentIndex = val),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
        ],
      ),
    );
  }
}
