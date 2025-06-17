import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'tela_registro.dart';
import '../home_page.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({Key? key}) : super(key: key);

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _emailUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _signInWithEmailPassword() async {
    String input = _emailUsernameController.text.trim();
    String password = _passwordController.text.trim();

    try {
      String email = input;
      // Checar se o usuário digitou um nome de usuário (simplesmente detectar se não é um email válido)
      if (!email.contains('@')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Digite um e-mail válido.',
        );
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // usuário cancelou

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
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
      backgroundColor: UIColors.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: ColorAliases.primaryDefault,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    size: 60,
                    color: UIColors.iconOnAction,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Trip Nick',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: ColorAliases.primaryDefault,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubra, explore e compartilhe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: UIColors.textDisabled,
                      ),
                ),
                const SizedBox(height: 48),
                _buildLoginForm(context),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => RegisterScreen(),
                      ));
                    },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(text: 'Não tem uma conta? ', style: TextStyle(color: UIColors.textBody)),
                          TextSpan(
                            text: 'Criar conta',
                            style: TextStyle(color: UIColors.textAction, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailUsernameController,
          decoration: const InputDecoration(
            labelText: 'E-mail ou usuário',
            hintText: 'Digite seu e-mail ou nome de usuário',
            prefixIcon: Icon(Icons.person_outline),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            hintText: 'Digite sua senha',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: Icon(Icons.visibility_off_outlined),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Esqueceu a senha?', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UIColors.textAction)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _signInWithEmailPassword,
            child: const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('ou', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Continuar com Google'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: UIColors.borderPrimary),
              foregroundColor: UIColors.textBody,
            ),
          ),
        ),
      ],
    );
  }
}

