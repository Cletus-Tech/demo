import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://lvpetmhhspuagbjojlks.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_M3WhhESOhd7QrrHQA9gsig_yAp607GB',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  runApp(const YoungLearnersApp());
}

abstract final class AppColors {
  static const ink = Color(0xFF29231F);
  static const brown = Color(0xFF4A3022);
  static const gold = Color(0xFFC99A3D);
  static const cream = Color(0xFFF7F5F1);
  static const muted = Color(0xFF746D66);
  static const line = Color(0xFFE9E4DC);
  static const paleGold = Color(0xFFF5EBD7);
}

class YoungLearnersApp extends StatelessWidget {
  const YoungLearnersApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brown,
      primary: AppColors.brown,
      secondary: AppColors.gold,
      surface: Colors.white,
    );
    return MaterialApp(
      title: 'Young Learners Tutorial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brown, width: 1.4),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Session? _session;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (mounted) setState(() => _session = event.session);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _session == null ? const SignInPage() : const LearnerHomePage();
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool _obscure = true;
  String? _message;
  bool _error = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_creating) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (response.session == null) {
          _error = false;
          _message = 'Account created. Check your email to confirm your address, then sign in.';
        } else {
          _error = false;
          _message = 'Your learner account has been created.';
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      _error = true;
      _message = e.message;
    } catch (_) {
      _error = true;
      _message = 'Unable to complete the request. Please check your connection and try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 52, height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brown,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 22),
                      const Text('YOUNG LEARNERS',
                        style: TextStyle(fontSize: 12, letterSpacing: 1.4,
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 5),
                      const Text('Every Child Can Learn.',
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Text(_creating ? 'Create your learner account.' : 'Sign in to continue learning.',
                        style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 24),
                      if (_creating) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                        ),
                        const SizedBox(height: 13),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email address'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 15),
                        Text(_message!, style: TextStyle(
                          color: _error ? Colors.red.shade700 : Colors.green.shade800,
                          height: 1.4,
                        )),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brown,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_busy ? 'Please wait...' : (_creating ? 'Create account' : 'Sign in')),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() {
                          _creating = !_creating; _message = null; _error = false;
                        }),
                        child: Text(_creating ? 'Already have an account? Sign in' : 'New here? Create an account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LearnerHomePage extends StatefulWidget {
  const LearnerHomePage({super.key});
  @override
  State<LearnerHomePage> createState() => _LearnerHomePageState();
}

class _LearnerHomePageState extends State<LearnerHomePage> {
  late Future<Map<String, dynamic>> _account;

  @override
  void initState() {
    super.initState();
    _account = _loadAccount();
  }

  Future<Map<String, dynamic>> _loadAccount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser!;
    final profile = await client.from('profiles').select('full_name,email').eq('id', user.id).single();
    final roles = await client.from('user_roles').select('role').eq('user_id', user.id);
    final role = roles.isEmpty ? 'learner' : (roles.first['role'] as String).replaceAll('_', ' ');
    return {'name': profile['full_name'] ?? 'Learner', 'role': role};
  }

  Future<void> _signOut() async => Supabase.instance.client.auth.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Young Learners Tutorial',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(tooltip: 'Sign out', onPressed: _signOut,
            icon: const Icon(Icons.logout_outlined)),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _account,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brown));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Your account is signed in, but its profile could not be loaded.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.ink)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => setState(() => _account = _loadAccount()),
                  child: const Text('Try again')),
                TextButton(onPressed: _signOut, child: const Text('Sign out')),
              ]),
            ));
          }
          final account = snapshot.data!;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('LEARNER PORTAL',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                      fontWeight: FontWeight.w800, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Text('Welcome, ${account['name']}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
                  const SizedBox(height: 6),
                  const Text('Every Child Can Learn.',
                    style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: AppColors.brown,
                      borderRadius: BorderRadius.circular(14)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your learning journey starts here',
                        style: TextStyle(color: Colors.white, fontSize: 21,
                          fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('Your classes, subjects, learning materials and progress will appear in this space as the centre activates them.',
                        style: TextStyle(color: Color(0xFFE7DED6), height: 1.5)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Card(child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.brown),
                    title: const Text('Account type', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(account['role'] as String),
                  )),
                  const SizedBox(height: 16),
                  const Text('LEARNING AREAS',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.1,
                      fontWeight: FontWeight.w800, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  const _FeatureRow(icon: Icons.menu_book_outlined, title: 'Subjects and lessons',
                    detail: 'Your enrolled subjects and lesson materials.'),
                  const SizedBox(height: 9),
                  const _FeatureRow(icon: Icons.assignment_outlined, title: 'Assignments and assessments',
                    detail: 'Tasks, practice and assessments from your tutors.'),
                  const SizedBox(height: 9),
                  const _FeatureRow(icon: Icons.query_stats_outlined, title: 'Learning progress',
                    detail: 'Track learning activity and published results.'),
                  const SizedBox(height: 28),
                  const Center(child: Text('YOUNG LEARNERS TUTORIAL CENTRE',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.1,
                      color: AppColors.muted, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _FeatureRow({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.paleGold,
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: AppColors.brown)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700,
        color: AppColors.ink)),
      subtitle: Text(detail, style: const TextStyle(color: AppColors.muted)),
    ),
  );
}
