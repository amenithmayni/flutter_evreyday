import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'ajout_habit.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> habits = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  File? profileImage;

  // Calendar variables
  DateTime selectedDate = DateTime.now();
  DateTime displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchHabits();
  }

  Future<void> fetchHabits() async {
    try {
      final url = Uri.parse('http://localhost:8080/api/habits');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          habits = data.map((habit) {
            return {
              'id': habit['id'],
              'nom': habit['nom'] ?? '',
              'type': habit['type'] ?? '',
              'duration': habit['duree'] ?? 0,
              'completed': habit['completed'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur lors de la récupération des habits');
      }
    } catch (e) {
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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom')),
            TextField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Type')),
            TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                habits[index]['nom'] = nameController.text;
                habits[index]['type'] = typeController.text;
                habits[index]['duration'] =
                    int.tryParse(durationController.text) ?? habits[index]['duration'];
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

  // ---------------- Calendar ----------------
  List<DateTime> getWeekDays() {
    return List.generate(7, (index) => selectedDate.add(Duration(days: index)));
  }

  Widget buildCalendar() {
    final weekDays = getWeekDays();

    return Column(
      children: [
        // عرض الشهر والسنة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1, 1);
                    selectedDate = DateTime(displayedMonth.year, displayedMonth.month, 1);
                  });
                },
                icon: const Icon(Icons.arrow_back)),
            Text(
              DateFormat.MMM().format(displayedMonth).toUpperCase() +
                  ' ${displayedMonth.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 1);
                    selectedDate = DateTime(displayedMonth.year, displayedMonth.month, 1);
                  });
                },
                icon: const Icon(Icons.arrow_forward)),
          ],
        ),
        const SizedBox(height: 8),
        // عرض 7 أيام ابتداءً من اليوم الحالي
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isToday = DateTime.now().day == day.day &&
                  DateTime.now().month == day.month &&
                  DateTime.now().year == day.year;
              final isSelected = selectedDate.day == day.day &&
                  selectedDate.month == day.month &&
                  selectedDate.year == day.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = day;
                    displayedMonth = DateTime(day.year, day.month, 1);
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.teal
                        : isToday
                            ? Colors.teal.shade100
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E().format(day), // Mon, Tue...
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Colors.black
                                  : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Colors.black
                                  : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildCalendar(),
          const SizedBox(height: 12),
          ...habits.asMap().entries.map((entry) => _habitCard(entry.key, entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: pickProfileImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null
                  ? const Icon(Icons.person, color: Colors.white, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
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
            onChanged: (val) {
              setState(() {
                habit['completed'] = val!;
              });
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit['nom'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: habit['completed'] ? Colors.white : Colors.black,
                    decoration: habit['completed']
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  'Type: ${habit['type']}',
                  style: TextStyle(
                    color: habit['completed'] ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Duration: ${habit['duration']} min',
                  style: TextStyle(
                    color: habit['completed'] ? Colors.white : Colors.black,
                  ),
                ),
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
    final tabs = [_buildHome(), _buildProfile()];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.teal),
            const SizedBox(width: 10),
            Text(
              "Welcome, ${widget.userName}",
              style: const TextStyle(color: Colors.black, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications')));
            },
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: pickProfileImage,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null
                  ? const Icon(Icons.person, color: Colors.white, size: 22)
                  : null,
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
                  MaterialPageRoute(
                      builder: (_) =>
                          AjouterHabitPage(onHabitAdded: _onHabitAdded)),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
        ],
      ),
    );
  }
}
