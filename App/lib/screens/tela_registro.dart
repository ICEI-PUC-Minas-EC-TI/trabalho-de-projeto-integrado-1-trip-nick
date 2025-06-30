import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_page.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../services/user_sync_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _register() async {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (displayName.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    if (password != confirmPassword) {
      _showError('As senhas não coincidem');
      return;
    }

    if (password.length < 6) {
      _showError('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Update Firebase profile with display name
      await userCredential.user!.updateDisplayName(displayName);

      // Step 3: Sync user with your database
      final syncResult = await UserSyncService.syncFirebaseUser(
        userCredential.user!,
      );

      // For now, just navigate to home (remove this when implementing sync)
      // if (mounted) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const HomePage()),
      //   );
      // }

      if (syncResult.success) {
        // Step 4: Navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showError('Erro ao criar perfil: ${syncResult.error}');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'A senha é muito fraca.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este e-mail já está sendo usado por outra conta.';
          break;
        case 'invalid-email':
          errorMessage = 'E-mail inválido.';
          break;
        default:
          errorMessage = 'Erro ao criar conta: ${e.message}';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('Erro inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: UIColors.surfaceError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UIColors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Criar Conta',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Welcome text
                Text(
                  'Bem-vindo ao Trip Nick!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: ColorAliases.primaryDefault,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie sua conta para começar a descobrir e compartilhar lugares incríveis.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: UIColors.textDisabled),
                ),

                const SizedBox(height: 40),

                // Registration form
                _buildRegistrationForm(),

                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Criar Conta'),
                  ),
                ),

                const SizedBox(height: 24),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Já tem uma conta? ',
                            style: TextStyle(color: UIColors.textBody),
                          ),
                          TextSpan(
                            text: 'Fazer login',
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

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Display Name field
        TextField(
          controller: _displayNameController,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            labelText: 'Nome completo *',
            hintText: 'Digite seu nome completo',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

        // Email field
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            labelText: 'E-mail *',
            hintText: 'Digite seu e-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha *',
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),

        const SizedBox(height: 16),

        // Confirm Password field
        TextField(
          controller: _confirmPasswordController,
          enabled: !_isLoading,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar senha *',
            hintText: 'Digite sua senha novamente',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),

        const SizedBox(height: 16),

        // Required fields note
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: UIColors.textDisabled),
            const SizedBox(width: 8),
            Text(
              '* Campos obrigatórios',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: UIColors.textDisabled),
            ),
          ],
        ),
      ],
    );
  }
}
