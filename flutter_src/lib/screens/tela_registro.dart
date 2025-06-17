import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showError('As senhas não coincidem');
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      Navigator.pop(context); // Volta para o login após cadastro
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.green[700]),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: FundoOndulado(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CREATE ACCOUNT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildTextField(Icons.person, "Username", controller: _usernameController),
                  const SizedBox(height: 10),
                  _buildTextField(Icons.email, "E-mail", controller: _emailController),
                  const SizedBox(height: 10),
                  _buildTextField(Icons.lock, "Password", controller: _passwordController, obscureText: true),
                  const SizedBox(height: 10),
                  _buildTextField(Icons.lock, "Confirm Password", controller: _confirmPasswordController, obscureText: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    onPressed: _register,
                    child: Text('Sign In', style: TextStyle(color: Colors.green[700])),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hintText, {bool obscureText = false, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        prefixIcon: Icon(icon, color: Colors.green[700]),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class FundoOndulado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white.withOpacity(0.9);
    Path path = Path();

    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.1, size.width * 0.5, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.2, size.width, size.height * 0.1);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

    path.reset();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.9);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

