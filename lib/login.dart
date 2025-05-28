import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'signup.dart';
import 'forgotpassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://192.168.214.226/librareadsmob/lib/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullNameController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/LibraReadsBG.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color(0xFF121921).withOpacity(0.7),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  const Text(
                    'LibraReads',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'AbhayaLibre',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(27),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Full Name',
                            style: TextStyle(
                              color: Color(0xFFA28D4F),
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: fullNameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              hintText: 'John Doe',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value != null && value.isNotEmpty
                                    ? null
                                    : 'Full name is required',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFFA28D4F),
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              hintText: '**********',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) =>
                                value != null && value.length >= 6
                                    ? null
                                    : 'Password must be at least 6 characters',
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                );
                              },
                              child: const Text(
                                'Forgot your password?',
                                style: TextStyle(
                                  color: Color(0xFFA28D4F),
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA28D4F),
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(
                        color: Color(0xFFA28D4F),
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
