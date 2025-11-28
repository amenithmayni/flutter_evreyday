import 'dart:io';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // تأكد إنو هذا المسار صحيح

class MyProfileScreen extends StatelessWidget {
  final String username;
  final String email;
  final File? profileImage;
  final List<String> completedHabits;

  const MyProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.profileImage,
    required this.completedHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PHOTO DE PROFIL
            CircleAvatar(
              radius: 60,
              backgroundImage:
                  profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),

            const SizedBox(height: 20),

            Text(username,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),

            const SizedBox(height: 5),

            Text(email, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            const Text(
              "Completed Habits",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            completedHabits.isEmpty
                ? const Text("No completed habits yet.")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedHabits.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.teal.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green),
                          title: Text(completedHabits[index]),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
