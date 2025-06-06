import 'package:flutter/material.dart';
import 'tela_registro.dart';
import '../home_page.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

class TelaLogin extends StatelessWidget {
  const TelaLogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),

                // App logo placeholder
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

                // App title
                Text(
                  'Trip Nick',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: ColorAliases.primaryDefault,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Descubra, explore e compartilhe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: UIColors.textDisabled,
                  ),
                ),

                const SizedBox(height: 48),

                // Login form
                _buildLoginForm(context),

                const SizedBox(height: 24),

                // Create account link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Não tem uma conta? ',
                            style: TextStyle(color: UIColors.textBody),
                          ),
                          TextSpan(
                            text: 'Criar conta',
                            style: TextStyle(
                              color: UIColors.textAction,
                              fontWeight: FontWeight.w600,
                            ),
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
        // Username/Email field
        TextField(
          decoration: const InputDecoration(
            labelText: 'E-mail ou usuário',
            hintText: 'Digite seu e-mail ou nome de usuário',
            prefixIcon: Icon(Icons.person_outline),
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Password field
        TextField(
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            hintText: 'Digite sua senha',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: Icon(Icons.visibility_off_outlined),
          ),
        ),

        const SizedBox(height: 8),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Implement forgot password
            },
            child: Text(
              'Esqueceu a senha?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: UIColors.textAction,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => const HomePage()
                ),
              );
            },
            child: const Text('Entrar'),
          ),
        ),

        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 16),

        // Social login buttons
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement Google login
            },
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