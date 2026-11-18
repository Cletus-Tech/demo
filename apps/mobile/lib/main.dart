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
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _account;

  @override
  void initState() {
    super.initState();
    _account = _loadAccount();
  }

  Future<Map<String, dynamic>> _loadAccount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser!;
    final profile = await client
        .from('profiles')
        .select('full_name,email')
        .eq('id', user.id)
        .single();
    final roles = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id);
    final role = roles.isEmpty
        ? 'external learner'
        : (roles.first['role'] as String).replaceAll('_', ' ');
    return {
      'name': profile['full_name'] ?? 'Learner',
      'email': profile['email'] ?? user.email ?? '',
      'role': role,
    };
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _openNotifications() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const NotificationsPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'My learning', 'Analytics', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex] == 'Home'
              ? 'Young Learners Tutorial'
              : titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(account: _account, onOpenLearning: () => setState(() => _selectedIndex = 1)),
          const _LearningTab(),
          const _AnalyticsTab(),
          _ProfileTab(account: _account, onRetry: () => setState(() => _account = _loadAccount()), onSignOut: _signOut),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.paleGold,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.line),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('Centre updates',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.ink)),
        SizedBox(height: 7),
        Text('Important notices and learning reminders will appear here.',
          style: TextStyle(color: AppColors.muted, height: 1.45)),
        SizedBox(height: 22),
        _InfoNotice(
          message: 'You have no notifications yet. When the centre publishes announcements or sends learning reminders to your account, they will appear here.',
        ),
      ],
    ),
  );
}

class _HomeTab extends StatelessWidget {
  final Future<Map<String, dynamic>> account;
  final VoidCallback onOpenLearning;
  const _HomeTab({required this.account, required this.onOpenLearning});

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: account,
    builder: (context, snapshot) {
      final name = snapshot.data?['name'] ?? 'Learner';
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEARNER PORTAL',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                    fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 8),
                Text('Welcome, $name',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
                const SizedBox(height: 5),
                const Text('Every Child Can Learn.',
                  style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: AppColors.brown,
                    borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your learning journey starts here',
                        style: TextStyle(color: Colors.white, fontSize: 21,
                          fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('Your classes, subjects, learning materials and progress will appear here as the centre activates them.',
                        style: TextStyle(color: Color(0xFFE7DED6), height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YOUR LEARNING',
                      style: TextStyle(fontSize: 11, letterSpacing: 1.1,
                        fontWeight: FontWeight.w800, color: AppColors.muted)),
                    TextButton(onPressed: onOpenLearning,
                      child: const Text('View all')),
                  ],
                ),
                const SizedBox(height: 4),
                const _FeatureRow(icon: Icons.menu_book_outlined,
                  title: 'Subjects and lessons',
                  detail: 'Your enrolled subjects and lesson materials.'),
                const SizedBox(height: 10),
                const _FeatureRow(icon: Icons.assignment_outlined,
                  title: 'Assignments and assessments',
                  detail: 'Tasks, practice and assessments from your tutors.'),
                const SizedBox(height: 10),
                const _FeatureRow(icon: Icons.query_stats_outlined,
                  title: 'Learning progress',
                  detail: 'Track learning activity and published results.'),
                const SizedBox(height: 26),
                const Center(child: Text('YOUNG LEARNERS TUTORIAL CENTRE',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.1,
                    color: AppColors.muted, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LearningTab extends StatelessWidget {
  const _LearningTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Keep building your knowledge',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
          color: AppColors.ink)),
      const SizedBox(height: 7),
      const Text('Your enrolled learning activities will be organised here.',
        style: TextStyle(color: AppColors.muted, height: 1.45)),
      const SizedBox(height: 22),
      const _FeatureRow(icon: Icons.menu_book_outlined,
        title: 'Subjects and lessons',
        detail: 'Subjects, lesson schedules and learning materials.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.assignment_outlined,
        title: 'Assignments',
        detail: 'Homework and tasks assigned by your tutors.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.quiz_outlined,
        title: 'Assessments',
        detail: 'Practice exercises, tests and assessment history.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.query_stats_outlined,
        title: 'My progress',
        detail: 'Learning activity and results published by the centre.'),
      const SizedBox(height: 18),
      const _InfoNotice(
        message: 'These sections are being connected to the centre’s class and lesson records. They will show your actual learning data when it is made available to your account.',
      ),
    ],
  );
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Your learning at a glance',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
          color: AppColors.ink)),
      const SizedBox(height: 7),
      const Text('A clear view of learning activity and academic progress.',
        style: TextStyle(color: AppColors.muted, height: 1.45)),
      const SizedBox(height: 22),
      const _FeatureRow(icon: Icons.menu_book_outlined,
        title: 'Lessons completed',
        detail: 'Completed lesson totals will appear here.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.assignment_turned_in_outlined,
        title: 'Assignments',
        detail: 'Submitted and outstanding assignments.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.assessment_outlined,
        title: 'Assessment performance',
        detail: 'Scores and published assessment results.'),
      const SizedBox(height: 10),
      const _FeatureRow(icon: Icons.trending_up_rounded,
        title: 'Progress over time',
        detail: 'Your academic progress across learning periods.'),
      const SizedBox(height: 18),
      const _InfoNotice(
        message: 'Analytics will populate from your actual lessons, submissions and published results. No progress figures are shown until the centre records that activity.',
      ),
    ],
  );
}

class _ProfileTab extends StatelessWidget {
  final Future<Map<String, dynamic>> account;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  const _ProfileTab({
    required this.account,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: account,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: AppColors.brown));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Your profile could not be loaded.',
              style: TextStyle(color: AppColors.ink)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ));
      }
      final data = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.paleGold,
                child: Text(
                  (data['name'] as String).trim().isEmpty
                      ? 'L'
                      : (data['name'] as String).trim()[0].toUpperCase(),
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700,
                    color: AppColors.brown),
                ),
              ),
              const SizedBox(height: 12),
              Text(data['name'] as String,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(data['role'] as String,
                style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 26),
          const Text('ACCOUNT DETAILS',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1,
              fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 10),
          Card(child: ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.brown),
            title: const Text('Email address'),
            subtitle: Text(data['email'] as String),
          )),
          const SizedBox(height: 9),
          Card(child: ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: AppColors.brown),
            title: const Text('Account type'),
            subtitle: Text(data['role'] as String),
          )),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brown,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.line),
            ),
          ),
        ],
      );
    },
  );
}

class _InfoNotice extends StatelessWidget {
  final String message;
  const _InfoNotice({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.paleGold,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.brown),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.ink, height: 1.45))),
      ],
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _FeatureRow({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(width: 42, height: 42,
        decoration: BoxDecoration(color: AppColors.paleGold,
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.brown)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700,
        color: AppColors.ink)),
      subtitle: Text(detail, style: const TextStyle(color: AppColors.muted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    ),
  );
}
