import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ajout_habit.dart'; // page ajout habit

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
                    int.tryParse(durationController.text) ??
                        habits[index]['duration'];
              });
              Navigator.pop(context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _onHabitAdded() { //RELOD APRES ADD
    fetchHabits();
    setState(() {
      _currentIndex = 0;
    });
  }

  Widget _buildHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(//JGRIDVIEW
        itemCount: habits.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3 / 2,
        ),
        itemBuilder: (context, index) {
          final habit = habits[index];
          return Card(
            color: habit['completed'] ? Colors.green.shade200 : Colors.white,
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit['nom'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: habit['completed']
                              ? TextDecoration.lineThrough //SUP NOM
                              : null,
                        ),
                      ),
                      Text('Type: ${habit['type']}'),
                      Text('Duration: ${habit['duration']} min'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Checkbox(
                        value: habit['completed'],
                        onChanged: (val) {
                          setState(() {
                            habit['completed'] = val!;
                          });
                        },
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => modifyHabit(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteHabit(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdd() => AjouterHabitPage(onHabitAdded: _onHabitAdded);//ADD

  Widget _buildProfile() => Center(//PROFILE 
        child: Text(
          'Profile de ${widget.userName}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tabs = [_buildHome(), _buildAdd(), _buildProfile()];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Welcome, ${widget.userName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [//NOTIFIVATION
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (val) => setState(() => _currentIndex = val),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
