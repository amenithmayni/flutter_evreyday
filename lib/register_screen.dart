import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('http://localhost:8080/api/users/register');
    final body = jsonEncode({
      "nom": _nomController.text.trim(),
      "prenom": _prenomController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = jsonDecode(response.body);
      final message = data['message'] ?? "Inscription réussie !";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),

                const Icon(Icons.person_add, size: 80, color: Colors.teal),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    text: "Every",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: "day", style: TextStyle(color: Colors.teal)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: "Nom",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Veuillez entrer votre nom' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: "Prénom",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Veuillez entrer votre prénom' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Email non valide';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: "Numéro de téléphone",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer votre numéro';
                    if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) return 'Numéro non valide';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirmer mot de passe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez confirmer le mot de passe';
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIGN UP", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Log In", style: TextStyle(color: Colors.teal)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
