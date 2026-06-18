import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calculator.dart';
import 'models.dart';
import 'sample_data.dart';
import 'supabase_config.dart';
import 'supabase_repository.dart';
import 'update_checker.dart';

const _brandLogoSvg = 'assets/brand/logo-banca.svg';

class SistemaRgtApp extends StatelessWidget {
  const SistemaRgtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema RGT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF245B57),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        fontFamily: 'Arial',
      ),
      home: const AuthGate(child: RgtHomePage()),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    _user = Supabase.instance.client.auth.currentUser;
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (mounted) {
        setState(() => _user = state.session?.user);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || _user != null) {
      return widget.child;
    }

    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isCreatingAccount = false;
  var _isSubmitting = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isCreatingAccount = !_isCreatingAccount;
      _error = null;
      _successMessage = null;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível autenticar no Supabase.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signUp() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cpfController.text.trim().isEmpty ||
        password.isEmpty ||
        confirmation.isEmpty) {
      setState(() => _error = 'Preencha todos os campos do cadastro.');
      return;
    }

    if (password != confirmation) {
      setState(() => _error = 'A senha e a confirmação de senha não conferem.');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: password,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'cpf': _cpfController.text.trim(),
        },
      );

      setState(() {
        _successMessage =
            'Cadastro criado. Confirme seu e-mail para liberar o acesso.';
        _isCreatingAccount = false;
        _confirmPasswordController.clear();
      });
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível criar a conta no Supabase.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Acesso RGT RH',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Entre com o usuário autorizado para registrar lançamentos com auditoria.',
                      style: TextStyle(color: Color(0xFF5E6762)),
                    ),
                    const SizedBox(height: 20),
                    if (_isCreatingAccount) ...[
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Nome',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'E-mail',
                      ),
                    ),
                    if (_isCreatingAccount) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Telefone',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'CPF',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Senha',
                      ),
                      onSubmitted: (_) {
                        if (!_isSubmitting && !_isCreatingAccount) {
                          unawaited(_signIn());
                        }
                      },
                    ),
                    if (_isCreatingAccount) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Confirmar senha',
                        ),
                        onSubmitted: (_) {
                          if (!_isSubmitting) {
                            unawaited(_signUp());
                          }
                        },
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF9A1D24)),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _successMessage!,
                        style: const TextStyle(color: Color(0xFF245B57)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : (_isCreatingAccount ? _signUp : _signIn),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isCreatingAccount
                                  ? Icons.person_add_alt_1_outlined
                                  : Icons.login_outlined,
                            ),
                      label:
                          Text(_isCreatingAccount ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isSubmitting ? null : _toggleMode,
                      child: Text(
                        _isCreatingAccount
                            ? 'Já tenho conta'
                            : 'Não tenho conta de login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    required this.update,
    required this.onDownload,
    super.key,
  });

  final UpdateInfo update;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.system_update_alt_outlined),
      title: const Text('Atualização disponível'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versão instalada: ${update.currentVersion}\n'
            'Nova versão: ${update.latestVersion}',
          ),
          if (update.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(update.notes),
          ],
          if (update.mandatory) ...[
            const SizedBox(height: 12),
            const Text(
              'Esta atualização é obrigatória para continuar usando a versão mais recente do sistema.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
      actions: [
        if (!update.mandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
        FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Baixar atualização'),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isSavingProfile = false;
  var _isSendingReset = false;
  var _isChangingEmail = false;
  var _isChangingPassword = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrateFromUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  User? get _user {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }
    return Supabase.instance.client.auth.currentUser;
  }

  void _hydrateFromUser() {
    final user = _user;
    final metadata = user?.userMetadata ?? {};
    _nameController.text = metadata['name']?.toString() ?? '';
    _phoneController.text = metadata['phone']?.toString() ?? '';
    _cpfController.text = metadata['cpf']?.toString() ?? '';
    _emailController.text = user?.email ?? '';
  }

  void _setMessage(String message) {
    setState(() {
      _message = message;
      _error = null;
    });
  }

  void _setError(String message) {
    setState(() {
      _error = message;
      _message = null;
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSavingProfile = true;
      _message = null;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'cpf': _cpfController.text.trim(),
          },
        ),
      );
      _setMessage('Perfil atualizado com sucesso.');
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível atualizar o perfil.');
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      _setError('Não há e-mail vinculado a esta conta.');
      return;
    }

    setState(() {
      _isSendingReset = true;
      _message = null;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _setMessage('Enviamos um e-mail com instruções para redefinir a senha.');
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível enviar o e-mail de redefinição.');
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Future<void> _changeEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      _setError('Informe o novo e-mail.');
      return;
    }
    if (newEmail == _user?.email) {
      _setError('Informe um e-mail diferente do atual.');
      return;
    }

    final nonce = await _requestReauthentication(
      'Confirmar troca de e-mail',
      'Enviaremos um código para o e-mail atual antes de solicitar a confirmação do novo e-mail.',
    );
    if (nonce == null) {
      return;
    }

    setState(() {
      _isChangingEmail = true;
      _message = null;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail, nonce: nonce),
      );
      _setMessage('Enviamos a confirmação para o novo e-mail informado.');
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível solicitar a troca de e-mail.');
    } finally {
      if (mounted) {
        setState(() => _isChangingEmail = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (password.length < 6) {
      _setError('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (password != confirmation) {
      _setError('A nova senha e a confirmação não conferem.');
      return;
    }

    final nonce = await _requestReauthentication(
      'Confirmar alteração de senha',
      'Enviaremos um código para confirmar sua identidade antes de alterar a senha.',
    );
    if (nonce == null) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _message = null;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password, nonce: nonce),
      );
      _passwordController.clear();
      _confirmPasswordController.clear();
      _setMessage('Senha alterada com sucesso.');
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível alterar a senha.');
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<String?> _requestReauthentication(String title, String subtitle) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ReauthenticationDialog(title: title, subtitle: subtitle);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          PageTitle(
            title: 'Perfil',
            subtitle: 'Entre no Supabase para gerenciar sua conta.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageTitle(
          title: 'Perfil',
          subtitle: user.email ?? 'Conta autenticada',
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            SectionPanel(
              title: 'Dados da conta',
              child: Column(
                children: [
                  ProfileTextField(
                    controller: _nameController,
                    label: 'Nome',
                    icon: Icons.edit_outlined,
                  ),
                  ProfileTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    icon: Icons.edit_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  ProfileTextField(
                    controller: _cpfController,
                    label: 'CPF',
                    icon: Icons.edit_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isSavingProfile ? null : _saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar perfil'),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'E-mail e confirmação',
              child: Column(
                children: [
                  ProfileTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    icon: Icons.alternate_email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isChangingEmail ? null : _changeEmail,
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Alterar e-mail'),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Senha',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSendingReset ? null : _sendPasswordReset,
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('Enviar e-mail para redefinir senha'),
                  ),
                  const SizedBox(height: 12),
                  ProfileTextField(
                    controller: _passwordController,
                    label: 'Nova senha',
                    icon: Icons.edit_outlined,
                    obscureText: true,
                  ),
                  ProfileTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar nova senha',
                    icon: Icons.edit_outlined,
                    obscureText: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Alterar com reautenticação'),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Segurança',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SecurityStatusRow(
                    icon: Icons.mail_lock_outlined,
                    title: 'Confirmação de e-mail',
                    subtitle: user.emailConfirmedAt == null
                        ? 'E-mail ainda não confirmado.'
                        : 'E-mail confirmado.',
                  ),
                  const SizedBox(height: 12),
                  SecurityStatusRow(
                    icon: Icons.history_outlined,
                    title: 'Último acesso',
                    subtitle: user.lastSignInAt ?? 'Sem registro disponível.',
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: const TextStyle(color: Color(0xFF245B57)),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF9A1D24)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          suffixIcon: Icon(icon),
        ),
      ),
    );
  }
}

class SecurityStatusRow extends StatelessWidget {
  const SecurityStatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF245B57)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF5E6762))),
            ],
          ),
        ),
      ],
    );
  }
}

class ReauthenticationDialog extends StatefulWidget {
  const ReauthenticationDialog({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  State<ReauthenticationDialog> createState() => _ReauthenticationDialogState();
}

class _ReauthenticationDialogState extends State<ReauthenticationDialog> {
  final _codeController = TextEditingController();
  var _isSending = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_sendCode());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.reauthenticate();
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível enviar o código.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _confirm() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Informe o código recebido.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.subtitle),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Código de reautenticação',
            ),
            onSubmitted: (_) => _confirm(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF9A1D24))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton.icon(
          onPressed: _isSending ? null : _sendCode,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('Reenviar código'),
        ),
        FilledButton.icon(
          onPressed: _isSending ? null : _confirm,
          icon: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_outlined),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.actorEmail,
    required this.occurredAt,
  });

  final String tableName;
  final String recordId;
  final String action;
  final String actorEmail;
  final DateTime occurredAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      tableName: json['table_name']?.toString() ?? '',
      recordId: json['record_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      actorEmail: json['actor_email']?.toString() ?? 'Usuário não informado',
      occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
    );
  }
}

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late Future<List<AuditLogEntry>> _entriesFuture = _fetchEntries();

  Future<List<AuditLogEntry>> _fetchEntries() async {
    if (!SupabaseConfig.isConfigured ||
        Supabase.instance.client.auth.currentUser == null) {
      return const [];
    }

    final rows = await Supabase.instance.client
        .from('audit_log')
        .select('table_name, record_id, action, actor_email, occurred_at')
        .order('occurred_at', ascending: false)
        .limit(100);

    return rows.map<AuditLogEntry>((row) {
      return AuditLogEntry.fromJson(row);
    }).toList();
  }

  void _refresh() {
    setState(() => _entriesFuture = _fetchEntries());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Expanded(
              child: PageTitle(
                title: 'Auditoria',
                subtitle:
                    'Histórico de lançamentos, alterações e responsáveis.',
              ),
            ),
            IconButton(
              tooltip: 'Atualizar auditoria',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AuditLogEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const SectionPanel(
                title: 'Eventos recentes',
                child: Text('Não foi possível carregar a auditoria.'),
              );
            }

            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return const SectionPanel(
                title: 'Eventos recentes',
                child: Text(
                  'Nenhum evento de auditoria encontrado para esta sessão.',
                ),
              );
            }

            return SectionPanel(
              title: 'Eventos recentes',
              child: Column(
                children: [
                  for (final entry in entries) AuditLogTile(entry: entry),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class AuditLogTile extends StatelessWidget {
  const AuditLogTile({required this.entry, super.key});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final actionColor = switch (entry.action) {
      'INSERT' => const Color(0xFF245B57),
      'UPDATE' => const Color(0xFF856404),
      'DELETE' => const Color(0xFF9A1D24),
      _ => const Color(0xFF5E6762),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_history_outlined, color: actionColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_actionLabel(entry.action)} em ${_tableLabel(entry.tableName)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('Responsável: ${entry.actorEmail}'),
                Text('Registro: ${entry.recordId}'),
                Text('Data e hora: ${_formatDateTime(entry.occurredAt)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String action) {
    return switch (action) {
      'INSERT' => 'Lançamento',
      'UPDATE' => 'Alteração',
      'DELETE' => 'Exclusão',
      _ => action,
    };
  }

  String _tableLabel(String tableName) {
    return switch (tableName) {
      'collaborators' => 'colaboradores',
      'unit_assignments' => 'histórico de banca',
      'monthly_statements' => 'demonstrativo mensal',
      'absence_entries' => 'faltas',
      'negative_cash_entries' => 'caixa negativo',
      'cash_closings' => 'fechamento de caixa',
      'units' => 'bancas',
      _ => tableName,
    };
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class RgtHomePage extends StatefulWidget {
  const RgtHomePage({super.key});

  @override
  State<RgtHomePage> createState() => _RgtHomePageState();
}

class _RgtHomePageState extends State<RgtHomePage> {
  final _calculator = const RgtCalculator();
  final _updateChecker = const UpdateChecker();
  SupabaseRepository? _repository;
  var _selectedIndex = 0;
  late List<Employee> _employees = [...sampleEmployees];
  late Employee _selectedEmployee = _employees.first;
  late Unit _selectedUnit =
      _effectiveUnitFor(_selectedEmployee, DateTime.now());
  Unit? _dashboardUnitFilter;
  final List<UnitAssignment> _unitAssignments = [];
  late final List<CashClosingEntry> _cashClosings = [
    ...sampleCashClosings,
  ];
  late MonthlyStatement _statement = _statementFor(_selectedEmployee);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdates());
    });

    if (SupabaseConfig.isConfigured) {
      _repository = SupabaseRepository();
      if (_repository!.canPersist) {
        unawaited(_loadRemoteData());
      }
    }
  }

  Future<void> _checkForUpdates() async {
    final update = await _updateChecker.check();
    if (!mounted || update == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !update.mandatory,
      builder: (context) {
        return UpdateAvailableDialog(
          update: update,
          onDownload: () async {
            await _updateChecker.openDownload(update);
            if (context.mounted && !update.mandatory) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _loadRemoteData() async {
    final repository = _repository;
    if (repository == null || !repository.canPersist) {
      return;
    }

    try {
      final snapshot = await repository.fetchSnapshot();
      final selectedEmployee = snapshot.employees.isEmpty
          ? _selectedEmployee
          : snapshot.employees.first;
      final statement = await repository.fetchStatement(
        _employeeWithEffectiveUnitFrom(
          selectedEmployee,
          DateTime.now(),
          snapshot.unitAssignments,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (snapshot.employees.isNotEmpty) {
          _employees = snapshot.employees;
          _selectedEmployee = selectedEmployee;
          _selectedUnit = _effectiveUnitForFrom(
              selectedEmployee, DateTime.now(), snapshot.unitAssignments);
        }
        _unitAssignments
          ..clear()
          ..addAll(snapshot.unitAssignments);
        _cashClosings
          ..clear()
          ..addAll(snapshot.cashClosings);
        _statement = statement;
      });
    } catch (_) {}
  }

  Employee _employeeWithEffectiveUnit(Employee employee, DateTime date) {
    return employee.copyWith(unit: _effectiveUnitFor(employee, date));
  }

  Employee _employeeWithEffectiveUnitFrom(
    Employee employee,
    DateTime date,
    List<UnitAssignment> assignments,
  ) {
    return employee.copyWith(
      unit: _effectiveUnitForFrom(employee, date, assignments),
    );
  }

  Unit _effectiveUnitFor(Employee employee, DateTime date) {
    return _effectiveUnitForFrom(employee, date, _unitAssignments);
  }

  Unit _effectiveUnitForFrom(
    Employee employee,
    DateTime date,
    List<UnitAssignment> assignmentsSource,
  ) {
    final normalized = DateTime(date.year, date.month, date.day);
    final assignments = assignmentsSource.where((assignment) {
      return assignment.employeeId == employee.id &&
          _sameDay(assignment.date, normalized);
    }).toList();

    if (assignments.isEmpty) {
      return employee.unit;
    }

    assignments.sort((a, b) => a.id.compareTo(b.id));
    return assignments.last.unit;
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Employee> get _effectiveEmployeesToday {
    final today = DateTime.now();
    return _employees.map((employee) {
      return _employeeWithEffectiveUnit(employee, today);
    }).toList();
  }

  MonthlyStatement _statementFor(Employee employee) {
    return sampleStatement(
        _employeeWithEffectiveUnit(employee, DateTime.now()));
  }

  Employee _currentEmployeeById(String id) {
    return _employees.firstWhere((employee) => employee.id == id);
  }

  void _selectEmployee(Employee employee) {
    final currentEmployee = _currentEmployeeById(employee.id);
    setState(() {
      _selectedEmployee = currentEmployee;
      _selectedUnit = _effectiveUnitFor(currentEmployee, DateTime.now());
      _statement = _statementFor(currentEmployee);
      _selectedIndex = 2;
    });
    unawaited(_loadStatement(currentEmployee));
    _showTabFeedback(
      'Demonstrativo mensal aberto para ${currentEmployee.name}.',
    );
  }

  Future<void> _loadStatement(Employee employee) async {
    final repository = _repository;
    if (repository == null || !repository.canPersist) {
      return;
    }

    try {
      final effectiveEmployee =
          _employeeWithEffectiveUnit(employee, DateTime.now());
      final statement = await repository.fetchStatement(effectiveEmployee);
      if (mounted && _selectedEmployee.id == employee.id) {
        setState(() => _statement = statement);
      }
    } catch (_) {
      return;
    }
  }

  void _selectUnit(Unit unit) {
    if (unit == Unit.geral) {
      setState(() => _selectedUnit = Unit.geral);
      return;
    }

    final employeesInUnit = _effectiveEmployeesToday.where((employee) {
      return employee.unit == unit;
    }).toList();

    if (employeesInUnit.isEmpty) {
      return;
    }

    final employee = employeesInUnit.first;
    final currentEmployee = _currentEmployeeById(employee.id);
    setState(() {
      _selectedUnit = unit;
      _selectedEmployee = currentEmployee;
      _statement = _statementFor(currentEmployee);
    });
  }

  void _addCashClosing(CashClosingEntry entry) {
    setState(() {
      _cashClosings.insert(0, entry);
    });
    unawaited(_persist((repository) => repository.addCashClosing(entry)));
  }

  void _updateEmployee(Employee updatedEmployee) {
    setState(() {
      _employees = _employees.map((employee) {
        return employee.id == updatedEmployee.id ? updatedEmployee : employee;
      }).toList();
      if (_selectedEmployee.id == updatedEmployee.id) {
        _selectedEmployee = updatedEmployee;
        _selectedUnit = _effectiveUnitFor(updatedEmployee, DateTime.now());
        _statement = _statement.copyWith(
          employee: _employeeWithEffectiveUnit(updatedEmployee, DateTime.now()),
        );
      }
    });
    unawaited(
        _persist((repository) => repository.saveEmployee(updatedEmployee)));
  }

  void _addUnitAssignment(UnitAssignment assignment) {
    setState(() {
      _unitAssignments.insert(0, assignment);
      if (_selectedEmployee.id == assignment.employeeId) {
        _selectedUnit = _effectiveUnitFor(_selectedEmployee, DateTime.now());
        _statement = _statement.copyWith(
          employee:
              _employeeWithEffectiveUnit(_selectedEmployee, DateTime.now()),
        );
      }
    });
    unawaited(
      _persist((repository) => repository.addUnitAssignment(assignment)),
    );
  }

  void _changeStatement(MonthlyStatement statement) {
    setState(() => _statement = statement);
    unawaited(_persist((repository) => repository.saveStatement(statement)));
  }

  Future<void> _persist(
    Future<void> Function(SupabaseRepository repository) operation,
  ) async {
    final repository = _repository;
    if (repository == null || !repository.canPersist) {
      return;
    }

    try {
      await operation(repository);
    } catch (_) {
      return;
    }
  }

  void _setSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showTabFeedback(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    });
  }

  Future<void> _openReportOptions() async {
    final options = await showDialog<ReportOptions>(
      context: context,
      builder: (context) {
        return ReportOptionsDialog(
          employees: _effectiveEmployeesToday,
          selectedEmployee: _selectedEmployee,
          selectedUnit: _selectedUnit,
        );
      },
    );

    if (!mounted || options == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return ReportPreviewDialog(
          options: options,
          selectedEmployee: _employeeWithEffectiveUnit(
            _selectedEmployee,
            DateTime.now(),
          ),
          selectedStatement: _statement,
          cashClosings: _cashClosings,
          statementForEmployee: _statementForReport,
        );
      },
    );
  }

  String reportMessage(ReportOptions options) {
    final parts = <String>[];

    if (options.includeFinancialStatement) {
      parts.add('demonstrativo mensal');
    }
    if (options.includeGeneralCashClosing) {
      parts.add('fechamento de caixa geral');
    }
    if (options.includeEmployeeCashClosing) {
      parts.add(
        'fechamento por ${_collaboratorCountLabel(options.selectedEmployees.length)}',
      );
    }

    return 'Relatório preparado: ${parts.join(', ')}.';
  }

  String _collaboratorCountLabel(int count) {
    return count == 1 ? '1 colaborador' : '$count colaboradores';
  }

  MonthlyStatement _statementForReport(Employee employee) {
    if (employee.id == _selectedEmployee.id) {
      return _statement.copyWith(employee: employee);
    }

    return sampleStatement(employee);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final effectiveEmployees = _effectiveEmployeesToday;
    final summary = _calculator.calculate(
      _statement,
      cashClosings: _cashClosings,
      restrictCashClosingsToStatementUnit: false,
    );

    final pages = [
      DashboardPage(
        employees: effectiveEmployees,
        cashClosings: _cashClosings,
        selectedUnitFilter: _dashboardUnitFilter,
        onUnitFilterChanged: (unit) {
          setState(() => _dashboardUnitFilter = unit);
        },
      ),
      EmployeesPage(
        employees: _employees,
        unitAssignments: _unitAssignments,
        selectedUnit: _selectedUnit,
        selectedEmployee: _selectedEmployee,
        effectiveUnitForDate: _effectiveUnitFor,
        onUnitSelected: _selectUnit,
        onEmployeeSelected: _selectEmployee,
        onEmployeeSaved: _updateEmployee,
        onUnitAssignmentAdded: _addUnitAssignment,
      ),
      StatementPage(
        statement: _statement,
        summary: summary,
        employees: effectiveEmployees,
        cashClosings: _cashClosings,
        selectedUnit: _selectedUnit,
        selectedEmployee: _employeeWithEffectiveUnit(
          _selectedEmployee,
          DateTime.now(),
        ),
        onChanged: _changeStatement,
        onEmployeeSelected: (employee) {
          final currentEmployee = _currentEmployeeById(employee.id);
          setState(() {
            _selectedEmployee = currentEmployee;
            _selectedUnit = _effectiveUnitFor(currentEmployee, DateTime.now());
            _statement = _statementFor(currentEmployee);
          });
          unawaited(_loadStatement(currentEmployee));
        },
        onUnitSelected: _selectUnit,
        effectiveUnitForDate: (employee, date) {
          return _effectiveUnitFor(_currentEmployeeById(employee.id), date);
        },
        onCashClosingAdded: _addCashClosing,
      ),
      const ProfilePage(),
      const AuditPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            RgtSideNav(
              selectedIndex: _selectedIndex,
              onChanged: _setSelectedIndex,
              onSignOut: SupabaseConfig.isConfigured
                  ? () => Supabase.instance.client.auth.signOut()
                  : null,
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  AppHeader(onReportRequested: _openReportOptions),
                  Expanded(
                    child: PageTransitionHost(
                      selectedIndex: _selectedIndex,
                      child: pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _setSelectedIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Painel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Equipe',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Mensal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.manage_history_outlined),
                  selectedIcon: Icon(Icons.manage_history),
                  label: 'Auditoria',
                ),
              ],
            ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.onReportRequested,
    super.key,
  });

  final VoidCallback onReportRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          const BrandMark(size: 42),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de RGT',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Demonstrativo mensal de entradas e saídas',
                  style: TextStyle(color: Color(0xFF5E6762)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Gerar relatório',
            onPressed: onReportRequested,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 42, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: SvgPicture.asset(
        _brandLogoSvg,
        fit: BoxFit.contain,
        semanticsLabel: 'Logo Banca',
      ),
    );
  }
}

class PageTransitionHost extends StatelessWidget {
  const PageTransitionHost({
    required this.selectedIndex,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: child,
      ),
    );
  }
}

class ReportOptionsDialog extends StatefulWidget {
  const ReportOptionsDialog({
    required this.employees,
    required this.selectedEmployee,
    required this.selectedUnit,
    super.key,
  });

  final List<Employee> employees;
  final Employee selectedEmployee;
  final Unit selectedUnit;

  @override
  State<ReportOptionsDialog> createState() => _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends State<ReportOptionsDialog> {
  var _includeFinancialStatement = true;
  var _includeGeneralCashClosing = true;
  var _includeEmployeeCashClosing = true;
  late final Set<String> _selectedEmployeeIds = {
    if (widget.selectedUnit != Unit.geral) widget.selectedEmployee.id,
  };

  bool get _hasSelection {
    return _includeFinancialStatement ||
        _includeGeneralCashClosing ||
        (_includeEmployeeCashClosing && _selectedEmployees.isNotEmpty);
  }

  List<Employee> get _employeeOptions {
    if (widget.selectedUnit == Unit.geral) {
      return widget.employees;
    }

    return widget.employees.where((employee) {
      return employee.unit == widget.selectedUnit;
    }).toList();
  }

  List<Employee> get _selectedEmployees {
    return _employeeOptions.where((employee) {
      return _selectedEmployeeIds.contains(employee.id);
    }).toList();
  }

  void _submit() {
    Navigator.of(context).pop(
      ReportOptions(
        includeFinancialStatement: _includeFinancialStatement,
        includeGeneralCashClosing: _includeGeneralCashClosing,
        includeEmployeeCashClosing: _includeEmployeeCashClosing,
        selectedEmployees: _selectedEmployees,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar relatório'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.selectedUnit == Unit.geral
                    ? 'Todos os colaboradores'
                    : '${widget.selectedUnit.label} - ${widget.selectedEmployee.name}',
                style: const TextStyle(color: Color(0xFF5E6762)),
              ),
              const SizedBox(height: 16),
              ReportCheckbox(
                title: 'Demonstrativo mensal',
                subtitle: 'Resumo financeiro do colaborador selecionado.',
                value: _includeFinancialStatement,
                onChanged: (value) {
                  setState(() => _includeFinancialStatement = value);
                },
              ),
              ReportCheckbox(
                title: 'Fechamento de caixa geral',
                subtitle: 'Consolidado mensal por todas as unidades.',
                value: _includeGeneralCashClosing,
                onChanged: (value) {
                  setState(() => _includeGeneralCashClosing = value);
                },
              ),
              ReportCheckbox(
                title: 'Fechamento de caixa por colaborador',
                subtitle: widget.selectedUnit == Unit.geral
                    ? 'Escolha os colaboradores que entrarão no relatório.'
                    : 'Lançamentos dos colaboradores selecionados.',
                value: _includeEmployeeCashClosing,
                onChanged: (value) {
                  setState(() => _includeEmployeeCashClosing = value);
                },
              ),
              if (_includeEmployeeCashClosing) ...[
                const SizedBox(height: 8),
                ReportEmployeeSelection(
                  employees: _employeeOptions,
                  selectedEmployeeIds: _selectedEmployeeIds,
                  onChanged: (employee, selected) {
                    setState(() {
                      if (selected) {
                        _selectedEmployeeIds.add(employee.id);
                      } else {
                        _selectedEmployeeIds.remove(employee.id);
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _hasSelection ? _submit : null,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Preparar relatório'),
        ),
      ],
    );
  }
}

class ReportCheckbox extends StatelessWidget {
  const ReportCheckbox({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class ReportEmployeeSelection extends StatelessWidget {
  const ReportEmployeeSelection({
    required this.employees,
    required this.selectedEmployeeIds,
    required this.onChanged,
    super.key,
  });

  final List<Employee> employees;
  final Set<String> selectedEmployeeIds;
  final void Function(Employee employee, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E5DF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final employee in employees)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(employee.name),
              subtitle: Text(employee.unit.label),
              value: selectedEmployeeIds.contains(employee.id),
              onChanged: (value) => onChanged(employee, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }
}

class ReportPreviewDialog extends StatelessWidget {
  const ReportPreviewDialog({
    required this.options,
    required this.selectedEmployee,
    required this.selectedStatement,
    required this.cashClosings,
    required this.statementForEmployee,
    super.key,
  });

  final ReportOptions options;
  final Employee selectedEmployee;
  final MonthlyStatement selectedStatement;
  final List<CashClosingEntry> cashClosings;
  final MonthlyStatement Function(Employee employee) statementForEmployee;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monthClosings = _entriesUntil(today);
    final generalClosing = CashClosingReportSummary.fromEntries(monthClosings);
    final statement = selectedStatement.copyWith(employee: selectedEmployee);
    final statementSummary = const RgtCalculator().calculate(
      statement,
      cashClosings: cashClosings,
      today: today,
      restrictCashClosingsToStatementUnit: false,
    );

    return AlertDialog(
      title: const Text('Relatório gerado'),
      content: SizedBox(
        width: 760,
        height: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gerado em ${_formatDateTime(today)}',
                style: const TextStyle(color: Color(0xFF5E6762)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fonte: dados carregados e calculados no sistema.',
                style: TextStyle(color: Color(0xFF5E6762)),
              ),
              const SizedBox(height: 16),
              if (options.includeFinancialStatement) ...[
                SectionPanel(
                  title: 'Demonstrativo mensal',
                  child: Column(
                    children: [
                      ReportInfoRow(
                        label: 'Colaborador',
                        value: selectedEmployee.name,
                      ),
                      ReportInfoRow(
                        label: 'Banca',
                        value: selectedEmployee.unit.label,
                      ),
                      ReportInfoRow(
                        label: 'Mês de referência',
                        value:
                            '${statement.referenceMonth.month.toString().padLeft(2, '0')}/${statement.referenceMonth.year}',
                      ),
                      const Divider(height: 24),
                      SummaryTable(summary: statementSummary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (options.includeGeneralCashClosing) ...[
                SectionPanel(
                  title: 'Fechamento de caixa geral',
                  child: Column(
                    children: [
                      SummaryRow(
                        label: 'Caixa positivo no mês',
                        value: generalClosing.positive,
                      ),
                      SummaryRow(
                        label: 'Caixa negativo no mês',
                        value: generalClosing.negative,
                      ),
                      SummaryRow(
                        label: 'Fechamento de caixa parcial',
                        value: generalClosing.balance,
                      ),
                      SummaryRow(
                        label: 'Descontar em folha',
                        value: generalClosing.payrollDeductions,
                      ),
                      const Divider(height: 24),
                      for (final unit in Unit.values.where((unit) {
                        return unit != Unit.geral &&
                            monthClosings.any((entry) => entry.unit == unit);
                      }))
                        ReportCashClosingBreakdownRow(
                          label: unit.label,
                          summary: CashClosingReportSummary.fromEntries(
                            monthClosings.where((entry) => entry.unit == unit),
                          ),
                        ),
                      if (monthClosings.isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Nenhum fechamento lançado no mês.'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (options.includeEmployeeCashClosing)
                SectionPanel(
                  title: 'Fechamento de caixa por colaborador',
                  child: options.selectedEmployees.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Nenhum colaborador selecionado.'),
                        )
                      : Column(
                          children: [
                            for (final employee in options.selectedEmployees)
                              ReportEmployeeClosingBlock(
                                employee: employee,
                                statement: statementForEmployee(employee),
                                entries: monthClosings.where((entry) {
                                  return entry.employee.id == employee.id;
                                }).toList(),
                              ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_outlined),
          label: const Text('Concluir'),
        ),
      ],
    );
  }

  List<CashClosingEntry> _entriesUntil(DateTime today) {
    return cashClosings.where((entry) {
      return entry.date.year == today.year &&
          entry.date.month == today.month &&
          !entry.date.isAfter(today);
    }).toList();
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} às $hour:$minute';
  }
}

class ReportEmployeeClosingBlock extends StatelessWidget {
  const ReportEmployeeClosingBlock({
    required this.employee,
    required this.statement,
    required this.entries,
    super.key,
  });

  final Employee employee;
  final MonthlyStatement statement;
  final List<CashClosingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final closing = CashClosingReportSummary.fromEntries(entries);
    final summary = const RgtCalculator().calculate(
      statement.copyWith(employee: employee),
      cashClosings: entries,
      today: DateTime.now(),
      restrictCashClosingsToStatementUnit: false,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Column(
        children: [
          ReportInfoRow(label: 'Colaborador', value: employee.name),
          ReportInfoRow(label: 'Banca', value: employee.unit.label),
          SummaryRow(label: 'Caixa positivo', value: closing.positive),
          SummaryRow(label: 'Caixa negativo', value: closing.negative),
          SummaryRow(label: 'Fechamento parcial', value: closing.balance),
          SummaryRow(
            label: 'Desconto em folha',
            value: closing.payrollDeductions,
          ),
          SummaryRow(
            label: 'Passivo calculado',
            value: summary.finalLiability,
            emphasized: true,
          ),
          if (entries.isNotEmpty) ...[
            const Divider(height: 20),
            for (final entry in entries)
              ReportInfoRow(
                label: formatDate(entry.date),
                value:
                    '${entry.type.label} - ${formatCurrency(entry.amount)} - ${entry.description}',
              ),
          ],
        ],
      ),
    );
  }
}

class ReportCashClosingBreakdownRow extends StatelessWidget {
  const ReportCashClosingBreakdownRow({
    required this.label,
    required this.summary,
    super.key,
  });

  final String label;
  final CashClosingReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Positivo ${formatCurrency(summary.positive)} · '
            'Negativo ${formatCurrency(summary.negative)} · '
            'Parcial ${formatCurrency(summary.balance)}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class ReportInfoRow extends StatelessWidget {
  const ReportInfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class CashClosingReportSummary {
  const CashClosingReportSummary({
    required this.positive,
    required this.negative,
    required this.payrollDeductions,
  });

  factory CashClosingReportSummary.fromEntries(
    Iterable<CashClosingEntry> entries,
  ) {
    var positive = 0.0;
    var negative = 0.0;
    var payrollDeductions = 0.0;

    for (final entry in entries) {
      if (entry.type == CashClosingType.positive) {
        positive += entry.amount;
      } else {
        negative += entry.amount;
        if (entry.deductFromPayroll) {
          payrollDeductions += entry.amount;
        }
      }
    }

    return CashClosingReportSummary(
      positive: positive,
      negative: negative,
      payrollDeductions: payrollDeductions,
    );
  }

  final double positive;
  final double negative;
  final double payrollDeductions;

  double get balance => positive - negative;
}

class RgtSideNav extends StatelessWidget {
  const RgtSideNav({
    required this.selectedIndex,
    required this.onChanged,
    this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF17201D),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              BrandMark(size: 36),
              SizedBox(width: 10),
              Text(
                'RGT RH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          NavButton(
            icon: Icons.bar_chart_outlined,
            label: 'Painel',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          NavButton(
            icon: Icons.groups_outlined,
            label: 'Colaboradores',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          NavButton(
            icon: Icons.receipt_long_outlined,
            label: 'Demonstrativo mensal',
            selected: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
          NavButton(
            icon: Icons.person_outline,
            label: 'Perfil',
            selected: selectedIndex == 3,
            onTap: () => onChanged(3),
          ),
          NavButton(
            icon: Icons.manage_history_outlined,
            label: 'Auditoria',
            selected: selectedIndex == 4,
            onTap: () => onChanged(4),
          ),
          const Spacer(),
          if (onSignOut != null) ...[
            TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_outlined, size: 18),
              label: const Text('Sair'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB7C3BD),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF245B57) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.employees,
    required this.cashClosings,
    required this.selectedUnitFilter,
    required this.onUnitFilterChanged,
    super.key,
  });

  final List<Employee> employees;
  final List<CashClosingEntry> cashClosings;
  final Unit? selectedUnitFilter;
  final ValueChanged<Unit?> onUnitFilterChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Employee? _selectedGlobalEmployee;
  final Map<Unit, Employee?> _selectedEmployeesByUnit = {};

  List<UnitDashboardSummary> get _unitSummaries {
    const calculator = RgtCalculator();
    final unitOptions = Unit.values.where((unit) => unit != Unit.geral);
    final units = widget.selectedUnitFilter == null
        ? unitOptions
        : [widget.selectedUnitFilter!];

    return units.map((unit) {
      final unitEmployees = widget.employees.where((employee) {
        return employee.unit == unit;
      }).toList();
      final selectedEmployee = _selectedEmployeesByUnit[unit];
      final effectiveEmployees = selectedEmployee == null
          ? unitEmployees
          : unitEmployees.where((employee) {
              return employee.id == selectedEmployee.id;
            }).toList();

      var revenues = 0.0;
      var expenses = 0.0;
      var finalLiability = 0.0;
      var partialCashClosing = 0.0;
      var payrollCashDiscount = 0.0;

      for (final employee in effectiveEmployees) {
        final summary = calculator.calculate(
          sampleStatement(employee),
          cashClosings: widget.cashClosings,
        );
        revenues += summary.revenues;
        expenses += summary.expenses;
        finalLiability += summary.finalLiability;
        partialCashClosing += summary.partialCashClosing;
        payrollCashDiscount += summary.payrollCashDiscount;
      }

      return UnitDashboardSummary(
        unit: unit,
        employees: unitEmployees,
        selectedEmployee: selectedEmployee,
        revenues: revenues,
        expenses: expenses,
        finalLiability: finalLiability,
        partialCashClosing: partialCashClosing,
        payrollCashDiscount: payrollCashDiscount,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summaries = _unitSummaries;
    final globalSummaries = _selectedGlobalEmployee == null
        ? summaries
        : summaries.where((summary) {
            return summary.unit == _selectedGlobalEmployee!.unit;
          }).map((summary) {
            final employee = _selectedGlobalEmployee!;
            final financialSummary = const RgtCalculator().calculate(
              sampleStatement(employee),
              cashClosings: widget.cashClosings,
            );

            return UnitDashboardSummary(
              unit: summary.unit,
              employees: summary.employees,
              selectedEmployee: employee,
              revenues: financialSummary.revenues,
              expenses: financialSummary.expenses,
              finalLiability: financialSummary.finalLiability,
              partialCashClosing: financialSummary.partialCashClosing,
              payrollCashDiscount: financialSummary.payrollCashDiscount,
            );
          }).toList();
    final totals = DashboardTotals.fromSummaries(globalSummaries);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardHeader(
          employees: widget.employees,
          selectedUnitFilter: widget.selectedUnitFilter,
          selectedEmployee: _selectedGlobalEmployee,
          onUnitFilterChanged: (unit) {
            if (_selectedGlobalEmployee != null &&
                unit != null &&
                _selectedGlobalEmployee!.unit != unit) {
              setState(() => _selectedGlobalEmployee = null);
            }
            widget.onUnitFilterChanged(unit);
          },
          onEmployeeFilterChanged: (employee) {
            setState(() => _selectedGlobalEmployee = employee);
          },
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            MetricCard(
              title: 'Passivo global',
              value: formatCurrency(totals.finalLiability),
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              title: 'Receitas globais',
              value: formatCurrency(totals.revenues),
              icon: Icons.trending_up,
            ),
            MetricCard(
              title: 'Despesas globais',
              value: formatCurrency(totals.expenses),
              icon: Icons.trending_down,
            ),
            MetricCard(
              title: 'Fechamento parcial',
              value: formatCurrency(totals.partialCashClosing),
              icon: Icons.point_of_sale_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionPanel(
          title: 'Bancas',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final summary in summaries)
                BancaMetricCard(
                  summary: summary,
                  onEmployeeChanged: (employee) {
                    setState(() {
                      _selectedEmployeesByUnit[summary.unit] = employee;
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.employees,
    required this.selectedUnitFilter,
    required this.selectedEmployee,
    required this.onUnitFilterChanged,
    required this.onEmployeeFilterChanged,
    super.key,
  });

  final List<Employee> employees;
  final Unit? selectedUnitFilter;
  final Employee? selectedEmployee;
  final ValueChanged<Unit?> onUnitFilterChanged;
  final ValueChanged<Employee?> onEmployeeFilterChanged;

  @override
  Widget build(BuildContext context) {
    const title = PageTitle(
      title: 'Painel global',
      subtitle: 'Visão consolidada por banca e métricas do mês.',
    );
    final filter = SizedBox(
      width: 280,
      child: DropdownButtonFormField<Unit?>(
        isExpanded: true,
        initialValue: selectedUnitFilter,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Filtro de banca',
        ),
        items: [
          const DropdownMenuItem<Unit?>(
            value: null,
            child: Text('Todos os colaboradores'),
          ),
          ...Unit.values.where((unit) => unit != Unit.geral).map(
                (unit) => DropdownMenuItem<Unit?>(
                  value: unit,
                  child: Text(unit.label),
                ),
              ),
        ],
        onChanged: onUnitFilterChanged,
      ),
    );
    final employeeOptions = selectedUnitFilter == null
        ? employees
        : employees.where((employee) {
            return employee.unit == selectedUnitFilter;
          }).toList();
    final employeeFilter = SizedBox(
      width: 280,
      child: DropdownButtonFormField<Employee?>(
        isExpanded: true,
        initialValue: employeeOptions.contains(selectedEmployee)
            ? selectedEmployee
            : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Filtro de colaborador',
        ),
        items: [
          const DropdownMenuItem<Employee?>(
            value: null,
            child: Text('Todos os colaboradores'),
          ),
          ...employeeOptions.map(
            (employee) => DropdownMenuItem<Employee?>(
              value: employee,
              child: Text(employee.name),
            ),
          ),
        ],
        onChanged: onEmployeeFilterChanged,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: filter),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: employeeFilter),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: title),
            const SizedBox(width: 16),
            filter,
            const SizedBox(width: 12),
            employeeFilter,
          ],
        );
      },
    );
  }
}

class UnitDashboardSummary {
  const UnitDashboardSummary({
    required this.unit,
    required this.employees,
    required this.selectedEmployee,
    required this.revenues,
    required this.expenses,
    required this.finalLiability,
    required this.partialCashClosing,
    required this.payrollCashDiscount,
  });

  final Unit unit;
  final List<Employee> employees;
  final Employee? selectedEmployee;
  final double revenues;
  final double expenses;
  final double finalLiability;
  final double partialCashClosing;
  final double payrollCashDiscount;
}

class DashboardTotals {
  const DashboardTotals({
    required this.revenues,
    required this.expenses,
    required this.finalLiability,
    required this.partialCashClosing,
  });

  factory DashboardTotals.fromSummaries(List<UnitDashboardSummary> summaries) {
    return DashboardTotals(
      revenues: summaries.fold(0, (total, item) => total + item.revenues),
      expenses: summaries.fold(0, (total, item) => total + item.expenses),
      finalLiability: summaries.fold(
        0,
        (total, item) => total + item.finalLiability,
      ),
      partialCashClosing: summaries.fold(
        0,
        (total, item) => total + item.partialCashClosing,
      ),
    );
  }

  final double revenues;
  final double expenses;
  final double finalLiability;
  final double partialCashClosing;
}

class BancaMetricCard extends StatelessWidget {
  const BancaMetricCard({
    required this.summary,
    required this.onEmployeeChanged,
    super.key,
  });

  final UnitDashboardSummary summary;
  final ValueChanged<Employee?> onEmployeeChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E5DF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.unit.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Employee?>(
              isExpanded: true,
              initialValue: summary.selectedEmployee,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Colaborador',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<Employee?>(
                  value: null,
                  child: Text('Todos da banca'),
                ),
                ...summary.employees.map(
                  (employee) => DropdownMenuItem<Employee?>(
                    value: employee,
                    child: Text(employee.name),
                  ),
                ),
              ],
              onChanged: onEmployeeChanged,
            ),
            const SizedBox(height: 14),
            SummaryRow(label: 'Receitas', value: summary.revenues),
            SummaryRow(label: 'Despesas', value: summary.expenses),
            SummaryRow(
              label: 'Fechamento parcial',
              value: summary.partialCashClosing,
            ),
            if (summary.payrollCashDiscount > 0)
              SummaryRow(
                label: 'Desconto em folha',
                value: summary.payrollCashDiscount,
              ),
            const Divider(height: 24),
            SummaryRow(
              label: 'Passivo da banca',
              value: summary.finalLiability,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({
    required this.employees,
    required this.unitAssignments,
    required this.selectedUnit,
    required this.selectedEmployee,
    required this.effectiveUnitForDate,
    required this.onUnitSelected,
    required this.onEmployeeSelected,
    required this.onEmployeeSaved,
    required this.onUnitAssignmentAdded,
    super.key,
  });

  final List<Employee> employees;
  final List<UnitAssignment> unitAssignments;
  final Unit selectedUnit;
  final Employee selectedEmployee;
  final Unit Function(Employee employee, DateTime date) effectiveUnitForDate;
  final ValueChanged<Unit> onUnitSelected;
  final ValueChanged<Employee> onEmployeeSelected;
  final ValueChanged<Employee> onEmployeeSaved;
  final ValueChanged<UnitAssignment> onUnitAssignmentAdded;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final filteredEmployees = selectedUnit == Unit.geral
        ? employees
        : employees.where((employee) {
            return effectiveUnitForDate(employee, today) == selectedUnit;
          }).toList();
    final filterLabel = selectedUnit == Unit.geral
        ? 'todos os colaboradores'
        : selectedUnit.label;
    final countLabel = filteredEmployees.length == 1
        ? '1 colaborador'
        : '${filteredEmployees.length} colaboradores';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageTitle(
          title: 'Colaboradores',
          subtitle: 'Base inicial para vincular demonstrativos por unidade.',
        ),
        const SizedBox(height: 16),
        SectionPanel(
          title: 'Filtros vinculados',
          child: ResponsiveGrid(
            children: [
              DropdownButtonFormField<Unit>(
                initialValue: selectedUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Unidade',
                ),
                items: Unit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (unit) {
                  if (unit != null) {
                    onUnitSelected(unit);
                  }
                },
              ),
              DropdownButtonFormField<Employee>(
                initialValue: filteredEmployees.contains(selectedEmployee)
                    ? selectedEmployee
                    : filteredEmployees.first,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Colaborador',
                ),
                items: filteredEmployees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee,
                        child: Text(employee.name),
                      ),
                    )
                    .toList(),
                onChanged: (employee) {
                  if (employee != null) {
                    onEmployeeSelected(employee);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EmployeeEditorPanel(
          employee: selectedEmployee,
          effectiveUnit: effectiveUnitForDate(selectedEmployee, today),
          assignments: unitAssignments.where((assignment) {
            return assignment.employeeId == selectedEmployee.id;
          }).toList(),
          onEmployeeSaved: onEmployeeSaved,
          onUnitAssignmentAdded: onUnitAssignmentAdded,
        ),
        const SizedBox(height: 16),
        Text(
          '$countLabel em $filterLabel',
          style: const TextStyle(
            color: Color(0xFF5E6762),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final employee in filteredEmployees)
          EmployeeRow(
            employee: employee,
            effectiveUnit: effectiveUnitForDate(employee, today),
            selected: employee.id == selectedEmployee.id,
            onTap: () => onEmployeeSelected(employee),
          ),
      ],
    );
  }
}

class EmployeeEditorPanel extends StatefulWidget {
  const EmployeeEditorPanel({
    required this.employee,
    required this.effectiveUnit,
    required this.assignments,
    required this.onEmployeeSaved,
    required this.onUnitAssignmentAdded,
    super.key,
  });

  final Employee employee;
  final Unit effectiveUnit;
  final List<UnitAssignment> assignments;
  final ValueChanged<Employee> onEmployeeSaved;
  final ValueChanged<UnitAssignment> onUnitAssignmentAdded;

  @override
  State<EmployeeEditorPanel> createState() => _EmployeeEditorPanelState();
}

class _EmployeeEditorPanelState extends State<EmployeeEditorPanel> {
  late final TextEditingController _nameController;
  late Unit _baseUnit;
  late Unit _temporaryUnit;
  var _assignmentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _baseUnit = widget.employee.unit;
    _temporaryUnit = widget.effectiveUnit;
  }

  @override
  void didUpdateWidget(EmployeeEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id != widget.employee.id) {
      _nameController.text = widget.employee.name;
      _baseUnit = widget.employee.unit;
      _temporaryUnit = widget.effectiveUnit;
      _assignmentDate = DateTime.now();
      return;
    }

    if (oldWidget.employee != widget.employee) {
      _nameController.text = widget.employee.name;
      _baseUnit = widget.employee.unit;
    }
    if (oldWidget.effectiveUnit != widget.effectiveUnit) {
      _temporaryUnit = widget.effectiveUnit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAssignmentDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _assignmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => _assignmentDate = selected);
    }
  }

  void _saveEmployee() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    widget.onEmployeeSaved(
      widget.employee.copyWith(name: name, unit: _baseUnit),
    );
  }

  void _launchTemporaryUnit() {
    widget.onUnitAssignmentAdded(
      UnitAssignment(
        id: 'unit-${DateTime.now().microsecondsSinceEpoch}',
        employeeId: widget.employee.id,
        date: DateTime(
          _assignmentDate.year,
          _assignmentDate.month,
          _assignmentDate.day,
        ),
        unit: _temporaryUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = [...widget.assignments]
      ..sort((a, b) => b.date.compareTo(a.date));

    return SectionPanel(
      title: 'Cadastro do colaborador',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nome do colaborador',
                ),
              ),
              DropdownButtonFormField<Unit>(
                initialValue: _baseUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Banca de cadastro',
                ),
                items: Unit.values
                    .where((unit) => unit != Unit.geral)
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (unit) {
                  if (unit != null) {
                    setState(() => _baseUnit = unit);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saveEmployee,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar cadastro'),
            ),
          ),
          const Divider(height: 28),
          Text(
            'Banca efetiva hoje: ${widget.effectiveUnit.label}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              DropdownButtonFormField<Unit>(
                initialValue: _temporaryUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Banca temporária',
                ),
                items: Unit.values
                    .where((unit) => unit != Unit.geral)
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (unit) {
                  if (unit != null) {
                    setState(() => _temporaryUnit = unit);
                  }
                },
              ),
              OutlinedButton.icon(
                onPressed: _pickAssignmentDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(formatDate(_assignmentDate)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _launchTemporaryUnit,
              icon: const Icon(Icons.sync_alt_outlined),
              label: const Text('Lançar banca temporária'),
            ),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text(
              'Nenhuma alteração temporária lançada.',
              style: TextStyle(color: Color(0xFF5E6762)),
            )
          else
            Column(
              children: [
                for (final assignment in history)
                  UnitAssignmentRow(assignment: assignment),
              ],
            ),
        ],
      ),
    );
  }
}

class UnitAssignmentRow extends StatelessWidget {
  const UnitAssignmentRow({required this.assignment, super.key});

  final UnitAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_outlined, color: Color(0xFF245B57)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatDate(assignment.date)} - ${assignment.unit.label}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeRow extends StatelessWidget {
  const EmployeeRow({
    required this.employee,
    required this.effectiveUnit,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Employee employee;
  final Unit effectiveUnit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFE3EFEB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF245B57),
                  foregroundColor: Colors.white,
                  child: Text(employee.name.characters.first),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('Banca atual: ${effectiveUnit.label}'),
                      if (employee.unit != effectiveUnit)
                        Text(
                          'Cadastro: ${employee.unit.label}',
                          style: const TextStyle(color: Color(0xFF5E6762)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(height: 4),
                    Text(
                      'Abrir mensal',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5E6762)),
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

class StatementPage extends StatelessWidget {
  const StatementPage({
    required this.statement,
    required this.summary,
    required this.employees,
    required this.cashClosings,
    required this.selectedUnit,
    required this.selectedEmployee,
    required this.onChanged,
    required this.onUnitSelected,
    required this.onEmployeeSelected,
    required this.effectiveUnitForDate,
    required this.onCashClosingAdded,
    super.key,
  });

  final MonthlyStatement statement;
  final FinancialSummary summary;
  final List<Employee> employees;
  final List<CashClosingEntry> cashClosings;
  final Unit selectedUnit;
  final Employee selectedEmployee;
  final ValueChanged<MonthlyStatement> onChanged;
  final ValueChanged<Unit> onUnitSelected;
  final ValueChanged<Employee> onEmployeeSelected;
  final Unit Function(Employee employee, DateTime date) effectiveUnitForDate;
  final ValueChanged<CashClosingEntry> onCashClosingAdded;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageTitle(
          title: 'Demonstrativo mensal',
          subtitle: statement.employee.name,
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            SectionPanel(
              title: 'Previsão e descontos',
              child: Column(
                children: [
                  MoneyField(
                    label: 'Previsão de lançamento',
                    value: statement.salaryForecast,
                    onChanged: (value) => onChanged(
                      statement.copyWith(salaryForecast: value),
                    ),
                  ),
                  MoneyField(
                    label: 'Vales',
                    value: statement.vouchers,
                    onChanged: (value) => onChanged(
                      statement.copyWith(vouchers: value),
                    ),
                  ),
                  AbsenceHistoryField(
                    absences: statement.absences,
                    onChanged: (absences) => onChanged(
                      statement.copyWith(absences: absences),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Assiduidade e receitas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NumberStepper(
                    label: 'Pontuação de assiduidade',
                    value: statement.attendanceScore,
                    onChanged: (value) => onChanged(
                      statement.copyWith(attendanceScore: value),
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<Incentive>(
                    initialValue: statement.incentive,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Pontuação de incentivo',
                    ),
                    items: Incentive.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(statement.copyWith(incentive: value));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ReadOnlyMoneyField(
                    label: 'Valor do incentivo',
                    value: statement.incentive.amount,
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Bonificação e caixa',
              child: Column(
                children: [
                  MoneyField(
                    label: 'Bonificação de balanço',
                    value: statement.balanceBonus,
                    onChanged: (value) => onChanged(
                      statement.copyWith(balanceBonus: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lançar bonificação em receita',
                    value: statement.launchBalanceBonusAsRevenue,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchBalanceBonusAsRevenue: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lançar caixa negativo como despesa',
                    value: statement.launchNegativeCashAsExpense,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchNegativeCashAsExpense: value),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Resumo financeiro',
              child: SummaryTable(summary: summary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CashClosingPage(
          employees: employees,
          entries: cashClosings,
          selectedUnit: selectedUnit,
          selectedEmployee: selectedEmployee,
          onUnitSelected: onUnitSelected,
          onEmployeeSelected: onEmployeeSelected,
          effectiveUnitForDate: effectiveUnitForDate,
          onEntryAdded: onCashClosingAdded,
          embedded: true,
        ),
      ],
    );
  }
}

class CashClosingPage extends StatefulWidget {
  const CashClosingPage({
    required this.employees,
    required this.entries,
    required this.selectedUnit,
    required this.selectedEmployee,
    required this.onUnitSelected,
    required this.onEmployeeSelected,
    required this.effectiveUnitForDate,
    required this.onEntryAdded,
    this.embedded = false,
    super.key,
  });

  final List<Employee> employees;
  final List<CashClosingEntry> entries;
  final Unit selectedUnit;
  final Employee selectedEmployee;
  final ValueChanged<Unit> onUnitSelected;
  final ValueChanged<Employee> onEmployeeSelected;
  final Unit Function(Employee employee, DateTime date) effectiveUnitForDate;
  final ValueChanged<CashClosingEntry> onEntryAdded;
  final bool embedded;

  @override
  State<CashClosingPage> createState() => _CashClosingPageState();
}

class _CashClosingPageState extends State<CashClosingPage> {
  final _descriptionController = TextEditingController();
  var _date = DateTime.now();
  var _type = CashClosingType.positive;
  var _amount = 0.0;
  var _deductFromPayroll = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<Employee> get _filteredEmployees {
    if (widget.selectedUnit == Unit.geral) {
      return widget.employees;
    }

    return widget.employees.where((employee) {
      return employee.unit == widget.selectedUnit;
    }).toList();
  }

  List<CashClosingEntry> get _visibleEntries {
    final now = DateTime.now();
    return widget.entries.where((entry) {
      final sameMonth =
          entry.date.year == now.year && entry.date.month == now.month;
      final untilToday = !entry.date.isAfter(now);
      if (widget.selectedUnit == Unit.geral) {
        return sameMonth && untilToday;
      }

      return sameMonth &&
          untilToday &&
          entry.unit == widget.selectedUnit &&
          entry.employee.id == widget.selectedEmployee.id;
    }).toList();
  }

  CashClosingSummary get _summary {
    if (widget.selectedUnit != Unit.geral) {
      return const RgtCalculator().calculateCashClosingSummary(
        widget.entries,
        unit: widget.selectedUnit,
        employee: widget.selectedEmployee,
      );
    }

    var positive = 0.0;
    var negative = 0.0;
    var payrollDeductions = 0.0;

    for (final entry in _visibleEntries) {
      if (entry.type == CashClosingType.positive) {
        positive += entry.amount;
      } else {
        negative += entry.amount;
        if (entry.deductFromPayroll) {
          payrollDeductions += entry.amount;
        }
      }
    }

    return CashClosingSummary(
      positive: positive,
      negative: negative,
      payrollDeductions: payrollDeductions,
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _submit() {
    if (_amount <= 0) {
      return;
    }

    final description = _descriptionController.text.trim();
    final entryEmployee = widget.selectedEmployee;
    final entryUnit = widget.effectiveUnitForDate(entryEmployee, _date);
    widget.onEntryAdded(
      CashClosingEntry(
        id: 'cx-${DateTime.now().microsecondsSinceEpoch}',
        date: _date,
        unit: entryUnit,
        employee: entryEmployee.copyWith(unit: entryUnit),
        type: _type,
        amount: _amount,
        description: description.isEmpty ? 'Fechamento de caixa' : description,
        deductFromPayroll:
            _type == CashClosingType.negative && _deductFromPayroll,
      ),
    );

    setState(() {
      _amount = 0;
      _descriptionController.clear();
      _deductFromPayroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final employees = _filteredEmployees;
    final entries = _visibleEntries;
    final summary = _summary;
    final isGlobalUnit = widget.selectedUnit == Unit.geral;
    final selectedEmployee = isGlobalUnit
        ? null
        : employees.contains(widget.selectedEmployee)
            ? widget.selectedEmployee
            : null;
    final canSubmit = _amount > 0 && selectedEmployee != null;

    final content = [
      const PageTitle(
        title: 'Fechamento de caixa',
        subtitle: 'Lançamentos por data, unidade e colaborador.',
      ),
      const SizedBox(height: 16),
      ResponsiveGrid(
        children: [
          MetricCard(
            title: 'Caixa positivo no mês',
            value: formatCurrency(summary.positive),
            icon: Icons.add_card_outlined,
          ),
          MetricCard(
            title: 'Caixa negativo no mês',
            value: formatCurrency(summary.negative),
            icon: Icons.credit_card_off_outlined,
          ),
          MetricCard(
            title: 'Saldo até hoje',
            value: formatCurrency(summary.balance),
            icon: Icons.account_balance_outlined,
          ),
          MetricCard(
            title: 'Descontar em folha',
            value: formatCurrency(summary.payrollDeductions),
            icon: Icons.payments_outlined,
          ),
        ],
      ),
      const SizedBox(height: 16),
      ResponsiveGrid(
        children: [
          SectionPanel(
            title: 'Novo lançamento',
            child: Column(
              children: [
                DropdownButtonFormField<Unit>(
                  initialValue: widget.selectedUnit,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Unidade',
                  ),
                  items: Unit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      widget.onUnitSelected(unit);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Employee?>(
                  initialValue: selectedEmployee,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Colaborador',
                  ),
                  items: [
                    if (isGlobalUnit)
                      const DropdownMenuItem<Employee?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                    ...employees.map(
                      (employee) => DropdownMenuItem<Employee?>(
                        value: employee,
                        child: Text(employee.name),
                      ),
                    ),
                  ],
                  onChanged: (employee) {
                    if (employee != null) {
                      widget.onEmployeeSelected(employee);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<CashClosingType>(
                  segments: const [
                    ButtonSegment(
                      value: CashClosingType.positive,
                      label: Text('Positivo'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment(
                      value: CashClosingType.negative,
                      label: Text('Negativo'),
                      icon: Icon(Icons.trending_down),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (values) {
                    setState(() {
                      _type = values.first;
                      if (_type == CashClosingType.positive) {
                        _deductFromPayroll = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Valor do caixa',
                  value: _amount,
                  onChanged: (value) => setState(() => _amount = value),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Descrição',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(formatDate(_date)),
                      ),
                    ),
                  ],
                ),
                if (_type == CashClosingType.negative)
                  SwitchRow(
                    label: 'Descontar de folha salarial',
                    value: _deductFromPayroll,
                    onChanged: (value) {
                      setState(() => _deductFromPayroll = value);
                    },
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lançar caixa'),
                  ),
                ),
              ],
            ),
          ),
          SectionPanel(
            title: 'Lançamentos do mês até hoje',
            child: entries.isEmpty
                ? const Text('Nenhum lançamento neste filtro.')
                : Column(
                    children: [
                      for (final entry in entries) CashClosingRow(entry: entry),
                    ],
                  ),
          ),
        ],
      ),
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: content,
    );
  }
}

class CashClosingRow extends StatelessWidget {
  const CashClosingRow({required this.entry, super.key});

  final CashClosingEntry entry;

  @override
  Widget build(BuildContext context) {
    final isNegative = entry.type == CashClosingType.negative;
    final color =
        isNegative ? const Color(0xFF8E2F2F) : const Color(0xFF245B57);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNegative ? Icons.remove_circle_outline : Icons.add_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('${formatDate(entry.date)} - ${entry.employee.name}'),
                if (entry.deductFromPayroll)
                  const Text(
                    'Descontar de folha salarial',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E2F2F)),
                  ),
              ],
            ),
          ),
          Text(
            formatCurrency(entry.amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF245B57)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF5E6762))),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionPanel extends StatelessWidget {
  const SectionPanel({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF5E6762))),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class MoneyField extends StatefulWidget {
  const MoneyField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.bottomPadding = 12,
    super.key,
  });

  final String label;
  final double value;
  final double bottomPadding;
  final ValueChanged<double> onChanged;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        double.tryParse(_controller.text.replaceAll(',', '.')) !=
            widget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: 'R\$ ',
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          final value = double.tryParse(text.replaceAll(',', '.'));
          if (value != null) {
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}

class ReadOnlyMoneyField extends StatelessWidget {
  const ReadOnlyMoneyField({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6F7F4),
      ),
      child: Text(
        formatCurrency(value),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class RevenueToggleField extends StatelessWidget {
  const RevenueToggleField({
    required this.label,
    required this.value,
    required this.enabledLabel,
    required this.enabled,
    required this.onChanged,
    required this.onEnabledChanged,
    super.key,
  });

  final String label;
  final double value;
  final String enabledLabel;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Column(
        children: [
          MoneyField(
            label: label,
            value: value,
            onChanged: onChanged,
            bottomPadding: 8,
          ),
          SwitchRow(
            label: enabledLabel,
            value: enabled,
            onChanged: onEnabledChanged,
          ),
        ],
      ),
    );
  }
}

class AbsenceHistoryField extends StatefulWidget {
  const AbsenceHistoryField({
    required this.absences,
    required this.onChanged,
    super.key,
  });

  final List<AbsenceEntry> absences;
  final ValueChanged<List<AbsenceEntry>> onChanged;

  @override
  State<AbsenceHistoryField> createState() => _AbsenceHistoryFieldState();
}

class _AbsenceHistoryFieldState extends State<AbsenceHistoryField> {
  late DateTime _selectedDate = _today();
  var _asExpense = true;

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    final normalized = DateTime(selected.year, selected.month, selected.day);
    setState(() => _selectedDate = normalized);
  }

  void _launchAbsence() {
    if (_selectedDateExists) {
      return;
    }

    final updated = [
      ...widget.absences,
      AbsenceEntry(date: _selectedDate, asExpense: _asExpense),
    ]..sort((a, b) => a.date.compareTo(b.date));
    widget.onChanged(updated);
  }

  bool get _selectedDateExists {
    return widget.absences.any((absence) {
      return _sameDate(absence.date, _selectedDate);
    });
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _removeAbsence(AbsenceEntry absence) {
    final updated = [...widget.absences]..remove(absence);
    widget.onChanged(updated);
  }

  void _toggleExpense(AbsenceEntry absence, bool asExpense) {
    final updated = widget.absences.map((item) {
      if (_sameDate(item.date, absence.date)) {
        return AbsenceEntry(date: item.date, asExpense: asExpense);
      }
      return item;
    }).toList();
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E5DF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.absences.length == 1
                      ? '1 falta registrada'
                      : '${widget.absences.length} faltas registradas',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _selectedDateExists ? null : _launchAbsence,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lançar falta'),
              ),
            ],
          ),
          SwitchRow(
            label: 'Lançar esta falta como despesa',
            value: _asExpense,
            onChanged: (value) => setState(() => _asExpense = value),
          ),
          const SizedBox(height: 12),
          if (widget.absences.isEmpty)
            const Text(
              'Nenhuma falta lançada.',
              style: TextStyle(color: Color(0xFF5E6762)),
            )
          else
            Column(
              children: [
                for (final absence in widget.absences)
                  AbsenceRow(
                    absence: absence,
                    onExpenseChanged: (value) {
                      _toggleExpense(absence, value);
                    },
                    onDelete: () => _removeAbsence(absence),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class AbsenceRow extends StatelessWidget {
  const AbsenceRow({
    required this.absence,
    required this.onExpenseChanged,
    required this.onDelete,
    super.key,
  });

  final AbsenceEntry absence;
  final ValueChanged<bool> onExpenseChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDate(absence.date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Text('Despesa'),
          Switch(
            value: absence.asExpense,
            onChanged: onExpenseChanged,
          ),
          IconButton(
            tooltip: 'Remover falta',
            onPressed: onDelete,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class SummaryTable extends StatelessWidget {
  const SummaryTable({required this.summary, super.key});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SummaryRow(label: 'Receitas', value: summary.revenues),
        SummaryRow(label: 'Despesas', value: summary.expenses),
        SummaryRow(
            label: 'Desconto por faltas', value: summary.absenceDiscount),
        SummaryRow(label: 'Caixa negativo', value: summary.negativeCash),
        SummaryRow(
          label: 'Fechamento de caixa parcial',
          value: summary.partialCashClosing,
        ),
        if (summary.payrollCashDiscount > 0)
          SummaryRow(
            label: 'Desconto em folha por caixa',
            value: summary.payrollCashDiscount,
          ),
        const Divider(height: 28),
        SummaryRow(
          label: 'Passivo circulante final',
          value: summary.finalLiability,
          emphasized: true,
        ),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatCurrency(value),
            style: TextStyle(
              fontSize: emphasized ? 18 : 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension MonthlyStatementCopy on MonthlyStatement {
  MonthlyStatement copyWith({
    Employee? employee,
    DateTime? referenceMonth,
    double? salaryForecast,
    double? vouchers,
    List<AbsenceEntry>? absences,
    int? attendanceScore,
    Incentive? incentive,
    double? balanceBonus,
    bool? launchBalanceBonusAsRevenue,
    List<CashEntry>? negativeCashEntries,
    bool? launchNegativeCashAsExpense,
  }) {
    return MonthlyStatement(
      employee: employee ?? this.employee,
      referenceMonth: referenceMonth ?? this.referenceMonth,
      salaryForecast: salaryForecast ?? this.salaryForecast,
      vouchers: vouchers ?? this.vouchers,
      absences: absences ?? this.absences,
      attendanceScore: attendanceScore ?? this.attendanceScore,
      incentive: incentive ?? this.incentive,
      balanceBonus: balanceBonus ?? this.balanceBonus,
      launchBalanceBonusAsRevenue:
          launchBalanceBonusAsRevenue ?? this.launchBalanceBonusAsRevenue,
      negativeCashEntries: negativeCashEntries ?? this.negativeCashEntries,
      launchNegativeCashAsExpense:
          launchNegativeCashAsExpense ?? this.launchNegativeCashAsExpense,
    );
  }
}
