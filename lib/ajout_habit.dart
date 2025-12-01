import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AjouterHabitPage extends StatefulWidget {
  final VoidCallback onHabitAdded;
  const AjouterHabitPage({super.key, required this.onHabitAdded});

  @override
  State<AjouterHabitPage> createState() => _AjouterHabitPageState();
}

class _AjouterHabitPageState extends State<AjouterHabitPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  String name = '';
  String type = '';
  double duration = 30;
  TimeOfDay? time;

  final List<String> habitTypes = ['Health', 'Work', 'Leisure', 'Learning'];

  bool validateStep() {
    switch (_currentStep) {
      case 0:
        return name.isNotEmpty;
      case 1:
        return type.isNotEmpty;
      case 2:
        return duration > 0;
      case 3:
        return time != null;
      default:
        return true;
    }
  }

  Future<void> _submitHabit() async {
    if (!validateStep()) return;

    final url = Uri.parse('http://localhost:8080/api/habits');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': name.isNotEmpty ? name : '',
        'type': type.isNotEmpty ? type : '',
        'duree': '${duration.toInt()} min',
        'heure': time != null ? '${time!.hour}:${time!.minute}' : '',
        'completed': false, 
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit added successfully!')),
      );
      widget.onHabitAdded();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  Widget _buildStepContent() {
    String motivation = '';
    Widget content = const SizedBox();

    switch (_currentStep) {
      case 0:
        motivation = "Start your new habit with energy!";
        content = Card(
          color: Colors.teal.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (val) => setState(() => name = val),
            ),
          ),
        );
        break;
      case 1:
        motivation = "Choose the type that inspires you the most!";
        content = Wrap(
          spacing: 10,
          alignment: WrapAlignment.center,
          children: habitTypes.map((t) {
            final selected = t == type;
            return ChoiceChip(
              label: Text(t),
              selected: selected,
              selectedColor: Colors.teal,
              onSelected: (_) => setState(() => type = t),
            );
          }).toList(),
        );
        break;
      case 2:
        motivation = "Define the ideal duration for this habit!";
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Duration: ${duration.toInt()} min', style: const TextStyle(fontSize: 18)),
            Slider(
              min: 10,
              max: 120,
              divisions: 11,
              value: duration,
              label: '${duration.toInt()} min',
              onChanged: (val) => setState(() => duration = val),
            ),
          ],
        );
        break;
      case 3:
        motivation = "Choose the perfect time for your habi!";
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time != null ? 'Time: ${time!.format(context)}' : 'Select Time', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (selected != null) setState(() => time = selected);
              },
              child: const Text('Pick Time'),
            ),
          ],
        );
        break;
      case 4:
        motivation = "Here is the final summary of your habit";
        content = Card(
          color: Colors.teal.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${name.isNotEmpty ? name : ''}', style: const TextStyle(fontSize: 16)),
                Text('Type: ${type.isNotEmpty ? type : ''}', style: const TextStyle(fontSize: 16)),
                Text('Duration: ${duration.toInt()} min', style: const TextStyle(fontSize: 16)),
                Text('Time: ${time != null ? time!.format(context) : ''}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              motivation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Habit'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey.shade300,
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildStepContent()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Previous'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 4) {
                      if (validateStep()) setState(() => _currentStep++);
                    } else {
                      _submitHabit();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text(_currentStep < 4 ? 'Next' : 'Add'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
