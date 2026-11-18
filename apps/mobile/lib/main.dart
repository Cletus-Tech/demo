import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_access.dart';
import 'package:url_launcher/url_launcher.dart';

// Keep release and web clients aligned with the active Supabase project.
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
      _session == null ? const SignInPage() : const RoleRouter();
}


class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});
  @override
  State<RoleRouter> createState() => _RoleRouterState();
}
class _RoleRouterState extends State<RoleRouter> {
  late Future<List<String>> _roles;
  @override
  void initState() { super.initState(); _roles = _load(); }
  Future<List<String>> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final rows = await Supabase.instance.client.from('user_roles')
        .select('role').eq('user_id', user.id);
    return List<Map<String, dynamic>>.from(rows)
        .map((e) => e['role'] as String).toList();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: _roles,
    builder: (context, s) {
      if (s.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brown)));
      }
      if (s.hasError) {
        return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Account permissions could not be checked.'),
          TextButton(onPressed: () => setState(() => _roles = _load()), child: const Text('Retry')),
          TextButton(onPressed: () => Supabase.instance.client.auth.signOut(), child: const Text('Sign out')),
        ])));
      }
      final roles = s.data ?? [];
      // Every authenticated account enters the same connected app shell.
      // Owner/admin tools are role-aware destinations inside the main dashboard,
      // not a replacement for the learner-facing home experience.
      return LearnerHomePage(
        owner: roles.contains('super_admin'),
        admin: roles.contains('admin') || roles.contains('super_admin'),
        tutor: roles.contains('tutor'),
        parent: Supabase.instance.client.auth.currentUser?.userMetadata?['account_type'] == 'parent',
      );
    },
  );
}

class AdminPortalPage extends StatefulWidget {
  final bool owner;
  const AdminPortalPage({super.key, required this.owner});
  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}
class _AdminPortalPageState extends State<AdminPortalPage> {
  late Future<Map<String, int>> _stats;
  late Future<Set<String>> _access;
  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
    _access = widget.owner
        ? Future<Set<String>>.value({
            'students.manage','academics.manage','staff.manage',
            'communications.send','finance.manage','reports.view',
          })
        : _loadPermissions();
  }
  Future<Set<String>> _loadPermissions() async {
    final data = await Supabase.instance.client.rpc('current_admin_permissions');
    return Set<String>.from(data as List);
  }
  Future<Map<String, int>> _loadStats() async {
    const tables = {'Students':'students','Tutors':'tutors','Classes':'classes','Lessons':'lessons','Announcements':'announcements'};
    final result = <String, int>{};
    for (final e in tables.entries) {
      try {
        final rows = await Supabase.instance.client.from(e.value).select('id');
        result[e.key] = rows.length;
      } catch (_) { result[e.key] = -1; }
    }
    return result;
  }
  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.owner ? 'Owner Portal' : 'Admin Portal'),
      actions: [IconButton(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout_rounded))],
    ),
    body: RefreshIndicator(
      onRefresh: () async => setState(() => _stats = _loadStats()),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.owner ? 'Centre control' : 'Centre administration',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text(widget.owner ? 'Oversee centre operations and control administrator access.' : 'Manage centre records and communications assigned to your account.',
          style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, int>>(future: _stats, builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final data = s.data ?? {};
          return GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
            childAspectRatio: 1.8, crossAxisSpacing: 10, mainAxisSpacing: 10,
            children: data.entries.map((e) => Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value < 0 ? '—' : e.value.toString(), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.brown)),
                Text(e.key, style: const TextStyle(color: AppColors.muted)),
              ]),
            ))).toList(),
          );
        }),
        const SizedBox(height: 22),
        const Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
        const SizedBox(height: 8),
        FutureBuilder<Set<String>>(
          future: _access,
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (accessSnapshot.hasError) {
              return const _InfoNotice(
                message: 'Your administrator permissions could not be verified. Sign out and sign in again, or contact the owner.',
              );
            }
            final permissions = accessSnapshot.data ?? <String>{};
            return Column(children: [
              if (permissions.contains('finance.manage') || permissions.contains('students.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.account_balance_outlined, color: AppColors.brown),
                  title: const Text('Learning access & payments'),
                  subtitle: const Text('Manage programme fees, bank details and payment approvals'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(OwnerLearningAccessPage(
                    owner: widget.owner,
                    canManageFinance: widget.owner || permissions.contains('finance.manage'),
                  )),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('students.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.brown),
                  title: const Text('Registered accounts'),
                  subtitle: const Text('View every student, parent and staff account'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminAccountsPage()),
                )),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: const Icon(Icons.family_restroom_outlined, color: AppColors.brown),
                  title: const Text('Parent link requests'),
                  subtitle: const Text('Verify parent accounts before linking children'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const GuardianPortalPage(admin: true)),
                )),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: const Icon(Icons.people_alt_outlined, color: AppColors.brown),
                  title: const Text('Student records'),
                  subtitle: const Text('View and manage student records and progress'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminStudentsPage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('communications.send')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: AppColors.brown),
                  title: const Text('Centre communications'),
                  subtitle: const Text('Publish general messages and notify linked students'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminCommunicationsPage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('academics.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: AppColors.brown),
                  title: const Text('Learning setup'),
                  subtitle: const Text('Manage learning levels, subjects, lessons and assessments'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminAcademicPage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('students.manage') && !permissions.contains('academics.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.fact_check_outlined, color: AppColors.brown),
                  title: const Text('Class attendance'),
                  subtitle: const Text('Take attendance and review class registers'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminAttendancePage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('staff.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.badge_outlined, color: AppColors.brown),
                  title: const Text('Tutor and staff management'),
                  subtitle: const Text('Link staff accounts and assign tutors to classes and subjects'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminStaffPage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('finance.manage'))
                const _InfoNotice(message: 'Finance permissions are active. Use Learning access & payments to manage bank details and verify learner payments.'),
              if (permissions.contains('reports.view'))
                const _InfoNotice(message: 'Reports access is active. Detailed centre reporting is being added next.'),
              if (permissions.isEmpty && !widget.owner)
                const _InfoNotice(message: 'Your account has administrator status but no management permissions have been assigned. Ask the owner to configure your access.'),
            ]);
          },
        ),
        if (widget.owner) ...[
          const SizedBox(height: 8),
          Card(child: ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.brown),
            title: const Text('Administrator access'),
            subtitle: const Text('Authorise accounts and configure permissions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _open(const OwnerAdminManagementPage()),
          )),
        ],
        const SizedBox(height: 16),
        const _InfoNotice(message: 'Dashboard figures are loaded from live database records. A dash means the current account does not have permission to read that section.'),
      ]),
    ),
  );
}

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});
  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}
class _AdminStudentsPageState extends State<AdminStudentsPage> {
  late Future<List<Map<String, dynamic>>> _rows;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() { super.initState(); _rows = _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final data = await Supabase.instance.client.from('students')
      .select('id,level,status,user_id,profiles(full_name,email)')
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student records')),
    body: RefreshIndicator(onRefresh: () async => setState(() => _rows = _load()),
      child: FutureBuilder<List<Map<String, dynamic>>>(future: _rows, builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return ListView(padding: const EdgeInsets.all(20), children: const [
          _InfoNotice(message: 'Student records could not be loaded. Check that student-management permission has been assigned.'),
        ]);
        final rows = s.data ?? [];
        final query = _searchController.text.trim().toLowerCase();
        final filtered = rows.where((r) {
          final p = r['profiles'] as Map<String, dynamic>?;
          final searchable = [
            p?['full_name'], p?['email'], r['level'],
          ].whereType<Object>().join(' ').toLowerCase();
          return query.isEmpty || searchable.contains(query);
        }).toList();
        if (rows.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: const [
          _InfoNotice(message: 'No learner accounts have been registered yet. New student sign-ups will appear here automatically.'),
        ]);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16,16,16,90),
          children: [
            Text('${rows.length} registered student${rows.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, email or class',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty ? null : IconButton(
                  onPressed: () { _searchController.clear(); setState(() {}); },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const _InfoNotice(message: 'No student matches this search.')
            else
              ...filtered.map((r) {
                final p = r['profiles'] as Map<String, dynamic>?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(child: ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => _StudentRecordDetailPage(student: r),
                    )),
                    title: Text(p?['full_name'] as String? ?? 'Account not linked'),
                    subtitle: Text([
                      p?['email'] ?? 'No email',
                      'Level: ' + (r['level'] ?? 'Not set').toString(),
                      'Status: ' + (r['status'] ?? '').toString(),
                    ].join(' • ')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  )),
                );
              }),
          ],
        );
      }),
    ),
  );
}

class _StudentRecordDetailPage extends StatefulWidget {
  final Map<String, dynamic> student;
  const _StudentRecordDetailPage({required this.student});
  @override
  State<_StudentRecordDetailPage> createState() => _StudentRecordDetailPageState();
}

class _StudentRecordDetailPageState extends State<_StudentRecordDetailPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _records;
  @override
  void initState() { super.initState(); _records = _load(); }

  Future<List<Map<String, dynamic>>> _safeRows(
      Future<dynamic> Function() request) async {
    return List<Map<String, dynamic>>.from(await request());
  }

  Future<Map<String, List<Map<String, dynamic>>>> _load() async {
    final db = Supabase.instance.client;
    final id = widget.student['id'];
    final values = await Future.wait([
      _safeRows(() => db.from('enrolments').select('id,status,classes(name,level)').eq('student_id', id)),
      _safeRows(() => db.from('attendance_records').select('id,status,attended_at,attendance_date,note').eq('student_id', id).order('attended_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assignment_submissions').select('id,status,score,submitted_at,assignments(title)').eq('student_id', id).order('submitted_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assessment_attempts').select('id,score,submitted_at,assessments(title)').eq('student_id', id).order('started_at', ascending: false).limit(20)),
      _safeRows(() => db.from('results').select('id,score,grade,published_at,tutor_comment,subjects(name)').eq('student_id', id).order('created_at', ascending: false).limit(20)),
      _safeRows(() => db.from('invoices').select('id,description,amount,currency,status,due_at').eq('student_id', id).order('created_at', ascending: false).limit(20)),
      _safeRows(() => db.from('payments').select('id,amount,status,paid_at,provider_reference,invoices!inner(description,student_id)').eq('invoices.student_id', id).order('paid_at', ascending: false).limit(20)),
    ]);
    return {
      'enrolments': values[0], 'attendance': values[1],
      'submissions': values[2], 'assessments': values[3],
      'results': values[4], 'invoices': values[5], 'payments': values[6],
    };
  }

  Future<void> _enrolStudent() async {
    final db = Supabase.instance.client;
    try {
      final session = await db.from('academic_sessions')
        .select('id,name').eq('is_current', true).maybeSingle();
      if (session == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set a current academic session in Academic management first.')));
        return;
      }
      final classes = await db.from('classes')
        .select('id,name,level').eq('status', 'active').order('name');
      if (classes.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create an active class before enrolling students.')));
        return;
      }
      String? classId = classes.first['id'].toString();
      final selected = await showDialog<String>(context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
          title: Text('Enrol in ' + session['name'].toString()),
          content: DropdownButtonFormField<String>(
            value: classId,
            decoration: const InputDecoration(labelText: 'Choose class'),
            items: classes.map<DropdownMenuItem<String>>((row) =>
              DropdownMenuItem<String>(value: row['id'].toString(),
                child: Text(row['name'].toString() +
                  (row['level'] == null ? '' : ' • ' + row['level'].toString())))).toList(),
            onChanged: (value) => refreshDialog(() => classId = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, classId), child: const Text('Enrol student')),
          ],
        )));
      if (selected == null) return;
      final existing = await db.from('enrolments').select('id')
        .eq('student_id', widget.student['id'])
        .eq('session_id', session['id']).eq('status', 'active');
      if ((existing as List).isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This student already has an active enrolment for the current session.')));
        return;
      }
      await db.from('enrolments').insert({
        'student_id': widget.student['id'],
        'class_id': selected,
        'session_id': session['id'],
        'status': 'active',
      });
      if (mounted) {
        setState(() => _records = _load());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student enrolled successfully. Their published class lessons will now appear in Learning.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enrol student: ' + e.toString())));
    }
  }

  Widget _section(String title, List<Map<String, dynamic>> rows,
      String empty, String Function(Map<String, dynamic>) primary,
      String Function(Map<String, dynamic>) secondary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(empty, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            )
          else
            ...rows.map((row) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(primary(row), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(secondary(row)),
            )),
        ]),
      ),
    );
  }

  String _date(dynamic value) {
    if (value == null) return 'Date not recorded';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final profile = student['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Unlinked student record';
    return Scaffold(
      appBar: AppBar(title: const Text('Student profile'), actions: [
        IconButton(tooltip: 'Enrol student', onPressed: _enrolStudent,
          icon: const Icon(Icons.person_add_alt_1_rounded)),
      ]),
      body: RefreshIndicator(
        onRefresh: () async { final next = _load(); setState(() => _records = next); await next; },
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _records,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator(color: AppColors.brown));
            if (snapshot.hasError)
              return ListView(children: const [ _InfoNotice(message: 'Student progress could not be loaded. Pull down to retry.') ]);
            final data = snapshot.data ?? {};
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text(profile?['email'] as String? ?? 'No learner account linked',
                    style: const TextStyle(color: AppColors.muted)),
                  const Divider(height: 22),
                  Text('Level: ${student['level'] ?? 'Not set'}'),
                  Text('Status: ${student['status'] ?? 'Unknown'}'),
                  Text('Account: ${student['user_id'] == null ? 'Not linked' : 'Linked'}'),
                ]),
              )),
              const SizedBox(height: 8),
              _section('Class enrolments', data['enrolments'] ?? [],
                'No enrolments recorded.',
                (r) => (r['classes']?['name'] ?? 'Class').toString(),
                (r) => 'Status: ${r['status'] ?? 'Not set'}'),
              _section('Attendance history', data['attendance'] ?? [],
                'No attendance records available.',
                (r) => (r['status'] ?? 'Attendance').toString(),
                (r) => _date(r['attendance_date'] ?? r['attended_at']) + (r['note'] == null ? '' : ' • ${r['note']}')),
              _section('Assignments', data['submissions'] ?? [],
                'No assignment submissions recorded.',
                (r) => (r['assignments']?['title'] ?? 'Assignment').toString(),
                (r) => 'Status: ${r['status'] ?? '—'} • Score: ${r['score'] ?? 'Not graded'}'),
              _section('Assessment attempts', data['assessments'] ?? [],
                'No assessment attempts recorded.',
                (r) => (r['assessments']?['title'] ?? 'Assessment').toString(),
                (r) => 'Score: ${r['score'] ?? 'Pending'} • ${_date(r['submitted_at'])}'),
              _section('Published results', data['results'] ?? [],
                'No results have been published.',
                (r) => (r['subjects']?['name'] ?? 'Subject').toString(),
                (r) => 'Score: ${r['score']} • Grade: ${r['grade'] ?? '—'} • ${_date(r['published_at'])}'),
              _section('School fee invoices', data['invoices'] ?? [],
                'No fee invoices recorded.',
                (r) => (r['description'] ?? 'Invoice').toString(),
                (r) => '${r['currency'] ?? 'NGN'} ${r['amount']} • ${r['status']} • Due: ${_date(r['due_at'])}'),
              _section('Payment history', data['payments'] ?? [],
                'No payment transactions recorded.',
                (r) => (r['invoices']?['description'] ?? 'Fee payment').toString(),
                (r) => 'Amount: ${r['amount']} • Status: ${r['status']} • Paid: ${_date(r['paid_at'])}' +
                  (r['provider_reference'] == null ? '' : ' • Ref: ${r['provider_reference']}')),
            ]);
          },
        ),
      ),
    );
  }
}


class AdminAcademicPage extends StatefulWidget {
  const AdminAcademicPage({super.key});
  @override
  State<AdminAcademicPage> createState() => _AdminAcademicPageState();
}
class _AdminAcademicPageState extends State<AdminAcademicPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<Map<String, dynamic>>> _classes, _subjects, _lessons, _assessments;
  bool _busy = false;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 6, vsync: this); _reload(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
  void _reload() {
    final db = Supabase.instance.client;
    _classes = db.from('classes').select('id,name,level,capacity,status').order('name');
    _subjects = db.from('subjects').select('id,name,code,description,status').order('name');
    _lessons = db.from('lessons').select('id,title,description,content,class_id,subject_id,is_published,classes(name),subjects(name)').order('created_at', ascending: false);
    _assessments = db.from('assessments').select('id,title,assessment_type,class_id,subject_id,duration_minutes,total_marks,is_published,starts_at,classes(name),subjects(name),questions(id)').order('created_at', ascending: false);
  }
  Future<void> _refresh() async { setState(_reload); await Future.wait([_classes,_subjects,_lessons,_assessments]); }
  Future<void> _save(String table, Map<String,dynamic> values, {String? id}) async {
    setState(() => _busy = true);
    try {
      final db = Supabase.instance.client.from(table);
      if (id == null) { await db.insert(values); } else { await db.update(values).eq('id',id); }
      if (mounted) { await _refresh(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved.'))); }
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: ' + e.toString())));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _editClass([Map<String,dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString() ?? '');
    final level = TextEditingController(text: row?['level']?.toString() ?? '');
    final capacity = TextEditingController(text: row?['capacity']?.toString() ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(row == null ? 'Create class' : 'Edit class'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller:name,decoration:const InputDecoration(labelText:'Class name')),
        TextField(controller:level,decoration:const InputDecoration(labelText:'Level / year')),
        TextField(controller:capacity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Capacity (optional)')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))],
    ));
    if(ok==true && name.text.trim().isNotEmpty) await _save('classes',{
      'name':name.text.trim(),'level':level.text.trim().isEmpty?null:level.text.trim(),
      'capacity':int.tryParse(capacity.text.trim()),'status':row?['status'] ?? 'active',
    },id:row?['id']?.toString());
    name.dispose(); level.dispose(); capacity.dispose();
  }
  Future<void> _editSubject([Map<String,dynamic>? row]) async {
    final name=TextEditingController(text:row?['name']?.toString() ?? '');
    final code=TextEditingController(text:row?['code']?.toString() ?? '');
    final desc=TextEditingController(text:row?['description']?.toString() ?? '');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(row==null?'Create subject':'Edit subject'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Subject name')),
        TextField(controller:code,decoration:const InputDecoration(labelText:'Subject code')),
        TextField(controller:desc,minLines:2,maxLines:3,decoration:const InputDecoration(labelText:'Description')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))],
    ));
    if(ok==true && name.text.trim().isNotEmpty) await _save('subjects',{
      'name':name.text.trim(),'code':code.text.trim().isEmpty?null:code.text.trim(),
      'description':desc.text.trim().isEmpty?null:desc.text.trim(),'status':row?['status'] ?? 'active',
    },id:row?['id']?.toString());
    name.dispose(); code.dispose(); desc.dispose();
  }
  Future<void> _editLesson([Map<String,dynamic>? row]) async {
    final title=TextEditingController(text:row?['title']?.toString() ?? '');
    final desc=TextEditingController(text:row?['description']?.toString() ?? '');
    final content=TextEditingController(text:row?['content']?.toString() ?? '');
    try {
      final classes=await _classes; final subjects=await _subjects;
      if(classes.isEmpty || subjects.isEmpty) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Create a class and a subject before adding lessons.')));
        return;
      }
      String? classId=row?['class_id']?.toString() ?? classes.first['id'].toString();
      String? subjectId=row?['subject_id']?.toString() ?? subjects.first['id'].toString();
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refreshDialog)=>AlertDialog(
        title:Text(row==null?'Create lesson':'Edit lesson'),
        content:SizedBox(width:430,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
          DropdownButtonFormField<String>(value:classId,decoration:const InputDecoration(labelText:'Class'),
            items:classes.map((c)=>DropdownMenuItem<String>(value:c['id'].toString(),child:Text(c['name'].toString()))).toList(),
            onChanged:(v)=>refreshDialog(()=>classId=v)),
          DropdownButtonFormField<String>(value:subjectId,decoration:const InputDecoration(labelText:'Subject'),
            items:subjects.map((v)=>DropdownMenuItem<String>(value:v['id'].toString(),child:Text(v['name'].toString()))).toList(),
            onChanged:(v)=>refreshDialog(()=>subjectId=v)),
          TextField(controller:desc,minLines:2,maxLines:3,decoration:const InputDecoration(labelText:'Short description')),
          TextField(controller:content,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'Lesson content')),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save lesson'))],
      )));
      if(ok==true && title.text.trim().isNotEmpty && classId!=null && subjectId!=null) await _save('lessons',{
        'title':title.text.trim(),'class_id':classId,'subject_id':subjectId,
        'description':desc.text.trim().isEmpty?null:desc.text.trim(),
        'content':content.text.trim().isEmpty?null:content.text.trim(),
        'is_published':row?['is_published'] ?? false,
      },id:row?['id']?.toString());
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Lesson form could not load: ' + e.toString())));
    } finally { title.dispose(); desc.dispose(); content.dispose(); }
  }

  Future<void> _createAssessment() async {
    final title = TextEditingController();
    final duration = TextEditingController(text: '30');
    try {
      final classes = await _classes; final subjects = await _subjects;
      if (classes.isEmpty || subjects.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a class and subject before creating an assessment.')));
        return;
      }
      String? classId = classes.first['id'].toString();
      String? subjectId = subjects.first['id'].toString();
      String type = 'Practice';
      final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
        title: const Text('Create assessment'),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Assessment title')),
          DropdownButtonFormField<String>(value: classId, decoration: const InputDecoration(labelText: 'Class'),
            items: classes.map((c) => DropdownMenuItem<String>(value: c['id'].toString(), child: Text(c['name'].toString()))).toList(),
            onChanged: (v) => refreshDialog(() => classId = v)),
          DropdownButtonFormField<String>(value: subjectId, decoration: const InputDecoration(labelText: 'Subject'),
            items: subjects.map((v) => DropdownMenuItem<String>(value: v['id'].toString(), child: Text(v['name'].toString()))).toList(),
            onChanged: (v) => refreshDialog(() => subjectId = v)),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Assessment type'),
            items: ['Practice','Mock examination','Class test','Revision'].map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: (v) => refreshDialog(() => type = v ?? 'Practice')),
          TextField(controller: duration, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Time limit in minutes (0 = untimed)')),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create'))],
      )));
      if (ok == true && title.text.trim().isNotEmpty && classId != null && subjectId != null) {
        final mins = int.tryParse(duration.text.trim()) ?? -1;
        if (mins < 0) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid time limit.')));
          return;
        }
        final created = await Supabase.instance.client.from('assessments').insert({
          'title': title.text.trim(), 'class_id': classId, 'subject_id': subjectId,
          'assessment_type': type, 'duration_minutes': mins == 0 ? null : mins,
          'total_marks': 0, 'is_published': false,
        }).select('id,title,assessment_type,class_id,subject_id,duration_minutes,total_marks,is_published').single();
        await _refresh();
        if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AdminAssessmentQuestionsPage(assessment: Map<String,dynamic>.from(created))));
        if (mounted) await _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assessment could not be created: ' + e.toString())));
    } finally { title.dispose(); duration.dispose(); }
  }

  Future<void> _toggleAssessment(Map<String,dynamic> row) async {
    final id = row['id'].toString();
    if (row['is_published'] == true) {
      await _save('assessments', {'is_published': false}, id: id);
      return;
    }
    try {
      final qs = await Supabase.instance.client.from('questions').select('marks').eq('assessment_id', id);
      if (qs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question before publishing.')));
        return;
      }
      final total = qs.fold<num>(0, (sum, q) => sum + ((q['marks'] as num?) ?? 0));
      await _save('assessments', {'total_marks': total, 'is_published': true}, id: id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assessment could not be published: ' + e.toString())));
    }
  }

  Widget _assessmentsTab() => FutureBuilder<List<Map<String,dynamic>>>(future: _assessments, builder: (context,s) {
    if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (s.hasError) return _err(s.error);
    final rows = s.data ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Expanded(child: Text('Assessments and CBT', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink))),
        FilledButton.icon(onPressed: _busy ? null : _createAssessment, icon: const Icon(Icons.add), label: const Text('Create')),
      ]),
      const Padding(padding: EdgeInsets.only(top: 8,bottom: 12),
        child: Text('Create a test, add its questions and answer key, then publish it to the selected class.', style: TextStyle(color: AppColors.muted))),
      if (rows.isEmpty) const _InfoNotice(message: 'No assessments have been created. Add a practice test or mock examination to begin.'),
      ...rows.map((r) {
        final q = r['questions'];
        final count = q is List ? q.length : 0;
        return Card(child: ListTile(
          title: Text(r['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text((r['classes']?['name'] ?? 'Class').toString() + ' • ' +
            (r['subjects']?['name'] ?? 'Subject').toString() + ' • ' +
            r['assessment_type'].toString() + ' • ' + count.toString() + ' questions • ' +
            (r['is_published'] == true ? 'Published' : 'Draft')),
          trailing: PopupMenuButton<String>(onSelected: (v) async {
            if (v == 'questions') {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => AdminAssessmentQuestionsPage(assessment: r)));
              if (mounted) await _refresh();
            }
            if (v == 'publish') await _toggleAssessment(r);
          }, itemBuilder: (_) => [
            const PopupMenuItem(value: 'questions', child: Text('Manage questions')),
            PopupMenuItem(value: 'publish', child: Text(r['is_published'] == true ? 'Unpublish' : 'Publish')),
          ]),
        ));
      }),
    ]);
  });

  Widget _err(Object? e)=>Padding(padding:const EdgeInsets.all(16),child:_InfoNotice(message:'Could not load this section. Check access or connection, then retry. ' + e.toString()));
  Widget _classesTab()=>FutureBuilder<List<Map<String,dynamic>>>(future:_classes,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return _err(s.error); final rows=s.data ?? [];
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Classes',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink))),
        FilledButton.icon(onPressed:_busy?null:()=>_editClass(),icon:const Icon(Icons.add),label:const Text('Add class'))]),
      if(rows.isEmpty)const _InfoNotice(message:'No classes yet. Add the centre’s first class.'),
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['name'].toString()),
        subtitle:Text((r['level'] ?? 'Level not set').toString() + ' • Capacity: ' + (r['capacity'] ?? 'Not set').toString() + ' • ' + r['status'].toString()),
        trailing:PopupMenuButton<String>(onSelected:(v){
          if(v=='edit')_editClass(r); if(v=='off')_save('classes',{'status':'inactive'},id:r['id'].toString());
          if(v=='on')_save('classes',{'status':'active'},id:r['id'].toString());
        },itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Edit')),
          if(r['status']=='active')const PopupMenuItem(value:'off',child:Text('Deactivate')),
          if(r['status']!='active')const PopupMenuItem(value:'on',child:Text('Activate'))])))),
    ]);
  });
  Widget _subjectsTab()=>FutureBuilder<List<Map<String,dynamic>>>(future:_subjects,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return _err(s.error); final rows=s.data ?? [];
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Subjects',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink))),
        FilledButton.icon(onPressed:_busy?null:()=>_editSubject(),icon:const Icon(Icons.add),label:const Text('Add subject'))]),
      if(rows.isEmpty)const _InfoNotice(message:'No subjects yet. Add the subjects taught at the centre.'),
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['name'].toString()),
        subtitle:Text((r['code'] ?? 'No code').toString() + ' • ' + r['status'].toString()),
        trailing:PopupMenuButton<String>(onSelected:(v){
          if(v=='edit')_editSubject(r); if(v=='off')_save('subjects',{'status':'inactive'},id:r['id'].toString());
          if(v=='on')_save('subjects',{'status':'active'},id:r['id'].toString());
        },itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Edit')),
          if(r['status']=='active')const PopupMenuItem(value:'off',child:Text('Deactivate')),
          if(r['status']!='active')const PopupMenuItem(value:'on',child:Text('Activate'))])))),
    ]);
  });
  Widget _lessonsTab()=>FutureBuilder<List<Map<String,dynamic>>>(future:_lessons,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return _err(s.error); final rows=s.data ?? [];
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Lessons',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink))),
        FilledButton.icon(onPressed:_busy?null:()=>_editLesson(),icon:const Icon(Icons.add),label:const Text('Add lesson'))]),
      if(rows.isEmpty)const _InfoNotice(message:'No lessons yet. Create classes and subjects, then add lessons.'),
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['title'].toString()),
        subtitle:Text((r['classes']?['name'] ?? 'Class').toString() + ' • ' + (r['subjects']?['name'] ?? 'Subject').toString() + ' • ' + (r['is_published']==true?'Published':'Draft')),
        trailing:PopupMenuButton<String>(onSelected:(v){
          if(v=='edit')_editLesson(r);
          if(v=='publish'||v=='draft')_save('lessons',{'is_published':v=='publish'},id:r['id'].toString());
        },itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Edit')),
          if(r['is_published']==true)const PopupMenuItem(value:'draft',child:Text('Move to draft')),
          if(r['is_published']!=true)const PopupMenuItem(value:'publish',child:Text('Publish'))])))),
    ]);
  });
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Learning setup'),bottom:TabBar(isScrollable:true,controller:_tabs,tabs:const[
      Tab(text:'Classes'),Tab(text:'Subjects'),Tab(text:'Lessons'),Tab(text:'Assessments'),Tab(text:'Assignments'),Tab(text:'Attendance'),
    ])),
    body:RefreshIndicator(onRefresh:_refresh,child:TabBarView(controller:_tabs,children:[
      _classesTab(),_subjectsTab(),_lessonsTab(),_assessmentsTab(),const AdminAssignmentsPanel(),const AdminAttendancePage(),
    ])),
  );
}





class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});
  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  late Future<List<Map<String, dynamic>>> _records;
  @override
  void initState() { super.initState(); _records = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client.from('attendance_records')
      .select('id,status,attendance_date,attended_at,note,classes(name)')
      .order('attendance_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _records = next); await next; }
  String _date(dynamic value) {
    if (value == null) return 'Date not recorded';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed.day.toString().padLeft(2, '0') + '/' +
      parsed.month.toString().padLeft(2, '0') + '/' + parsed.year.toString();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My attendance')),
    body: RefreshIndicator(color: AppColors.brown, onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(future: _records, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
        if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(20), children: const [
          _InfoNotice(message: 'Your attendance history could not be loaded. Pull down to retry.')]);
        final rows = snapshot.data ?? [];
        final present = rows.where((r) => r['status'] == 'present').length;
        final late = rows.where((r) => r['status'] == 'late').length;
        final absent = rows.where((r) => r['status'] == 'absent').length;
        final excused = rows.where((r) => r['status'] == 'excused').length;
        final denominator = present + late + absent;
        final rate = denominator == 0 ? null : (present + late) * 100 / denominator;
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Your attendance record', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('Attendance recorded by your centre for your enrolled classes.', style: TextStyle(color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ATTENDANCE RATE', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(rate == null ? '—' : rate.toStringAsFixed(1) + '%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.brown)),
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 8, children: [
              Text('Present: ' + present.toString()),
              Text('Late: ' + late.toString()),
              Text('Absent: ' + absent.toString()),
              Text('Excused: ' + excused.toString()),
            ]),
          ]))),
          const SizedBox(height: 18),
          const Text('ATTENDANCE HISTORY', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 8),
          if (rows.isEmpty) const _InfoNotice(message: 'No attendance has been recorded for your account yet. Your register will appear here after your tutor marks it.'),
          ...rows.map((r) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text((r['classes']?['name'] ?? 'Class').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(_date(r['attendance_date'] ?? r['attended_at']) + (r['note'] == null ? '' : ' • ' + r['note'].toString())),
            trailing: Text((r['status'] ?? '').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brown)),
          ))),
        ]);
      })),
  );
}

class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({super.key});
  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  late Future<Map<String, dynamic>> _options;
  Future<List<Map<String, dynamic>>>? _roster;
  String? _classId;
  String? _sessionId;
  DateTime _date = DateTime.now();
  final Map<String, String> _statuses = {};
  final Map<String, TextEditingController> _notes = {};
  bool _saving = false;

  String get _dateKey => _date.year.toString().padLeft(4, '0') + '-' +
      _date.month.toString().padLeft(2, '0') + '-' +
      _date.day.toString().padLeft(2, '0');

  @override
  void initState() { super.initState(); _options = _loadOptions(); }

  Future<Map<String, dynamic>> _loadOptions() async {
    final db = Supabase.instance.client;
    final classData = await db.rpc('attendance_available_classes');
    final classes = List<Map<String, dynamic>>.from(classData as List);
    if (mounted) {
      setState(() {
        _classId = classes.isEmpty ? null : classes.first['id'].toString();
        _sessionId = null;
        if (_classId != null) _roster = _loadRoster();
      });
    }
    return {'classes': classes};
  }

  Future<List<Map<String, dynamic>>> _loadRoster() async {
    if (_classId == null) return [];
    final result = await Supabase.instance.client.rpc('class_attendance_roster', params: {
      'p_class_id': _classId, 'p_session_id': _sessionId, 'p_attendance_date': _dateKey,
    });
    final rows = List<Map<String, dynamic>>.from(result as List);
    for (final row in rows) {
      final id = row['student_id'].toString();
      _statuses[id] = row['status']?.toString() ?? 'unmarked';
      _notes.putIfAbsent(id, () => TextEditingController(text: row['note']?.toString() ?? ''));
    }
    return rows;
  }

  void _reloadRoster() {
    _statuses.clear();
    for (final controller in _notes.values) { controller.dispose(); }
    _notes.clear();
    setState(() => _roster = _loadRoster());
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2035), helpText: 'Choose attendance date');
    if (chosen != null) { setState(() => _date = chosen); _reloadRoster(); }
  }

  Future<void> _save() async {
    final rows = await (_roster ?? Future.value(<Map<String, dynamic>>[]));
    final marks = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = row['student_id'].toString();
      final status = _statuses[id] ?? 'unmarked';
      if (status != 'unmarked') {
        marks.add({'student_id': id, 'status': status, 'note': _notes[id]?.text.trim()});
      }
    }
    if (marks.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mark at least one learner before saving.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await Supabase.instance.client.rpc('save_class_attendance', params: {
        'p_class_id': _classId, 'p_session_id': _sessionId,
        'p_attendance_date': _dateKey, 'p_marks': marks,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance saved for ' + result['saved'].toString() + ' learner(s).')));
        _reloadRoster();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance could not be saved: ' + e.toString())));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  void dispose() {
    for (final controller in _notes.values) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _options,
    builder: (context, options) {
      if (options.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: AppColors.brown));
      }
      if (options.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20),
        child: _InfoNotice(message: 'Attendance setup could not be loaded: ' + options.error.toString())));
      final classes = List<Map<String, dynamic>>.from(options.data?['classes'] ?? []);
      if (classes.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Class attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 12),
        const _InfoNotice(message: 'No active classes are available to this account. If you are a tutor, ask the centre to assign you to a class. Otherwise, create an active class.'),
      ]);
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Class attendance register', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 5),
            const Text('Select the class and date. Mark each approved learner, then save the register.',
              style: TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _classId, decoration: const InputDecoration(labelText: 'Class'),
              items: classes.map((r) => DropdownMenuItem<String>(value: r['id'].toString(),
                child: Text(r['name'].toString() + (r['level'] == null ? '' : ' • ' + r['level'].toString())))).toList(),
              onChanged: (v) { _classId = v; _reloadRoster(); }),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today_outlined), label: Text(_dateKey))),
              const SizedBox(width: 9),
              FilledButton.icon(onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving' : 'Save register')),
            ]),
          ])),
        const Divider(height: 1, color: AppColors.line),
        Expanded(child: _roster == null ? const Center(child: Text('Choose a class.'))
          : FutureBuilder<List<Map<String, dynamic>>>(future: _roster, builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
            if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(18), children: [
              _InfoNotice(message: 'The register could not be loaded. ' + snapshot.error.toString())]);
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return ListView(padding: const EdgeInsets.all(18), children: const [
              _InfoNotice(message: 'No learners with approved learning access are assigned to this class yet.')]);
            final marked = rows.where((r) => (_statuses[r['student_id'].toString()] ?? 'unmarked') != 'unmarked').length;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
              Row(children: [
                Expanded(child: Text(rows.length.toString() + ' enrolled learner(s)', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink))),
                Text(marked.toString() + ' marked', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              ...rows.map((row) {
                final id = row['student_id'].toString();
                return Card(margin: const EdgeInsets.only(bottom: 9),
                  child: Padding(padding: const EdgeInsets.all(13), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((row['full_name'] ?? 'Learner').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(value: _statuses[id] ?? 'unmarked',
                        decoration: const InputDecoration(labelText: 'Attendance status'),
                        items: [
                          if (row['attendance_id'] == null)
                            const DropdownMenuItem(value: 'unmarked', child: Text('Not marked')),
                          const DropdownMenuItem(value: 'present', child: Text('Present')),
                          const DropdownMenuItem(value: 'absent', child: Text('Absent')),
                          const DropdownMenuItem(value: 'late', child: Text('Late')),
                          const DropdownMenuItem(value: 'excused', child: Text('Excused')),
                        ],
                        onChanged: (v) => setState(() => _statuses[id] = v ?? 'unmarked')),
                      const SizedBox(height: 7),
                      TextField(controller: _notes[id], decoration: const InputDecoration(labelText: 'Note (optional)')),
                    ])));
              }),
            ]);
          })),
      ]);
    },
  );
}

class AdminAssignmentsPanel extends StatefulWidget {
  const AdminAssignmentsPanel({super.key});
  @override
  State<AdminAssignmentsPanel> createState()=>_AdminAssignmentsPanelState();
}
class _AdminAssignmentsPanelState extends State<AdminAssignmentsPanel>{
  late Future<List<Map<String,dynamic>>> _items;
  bool _busy=false;
  @override
  void initState(){super.initState();_items=_load();}
  Future<List<Map<String,dynamic>>> _load() async{
    final rows=await Supabase.instance.client.from('assignments')
      .select('id,title,instructions,due_at,max_score,published_at,classes(name),subjects(name),assignment_submissions(id)')
      .order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _refresh() async{final next=_load();setState(()=>_items=next);await next;}
  Future<void> _create() async{
    final title=TextEditingController();final instructions=TextEditingController();
    final due=TextEditingController();final max=TextEditingController(text:'10');
    try{
      final db=Supabase.instance.client;
      final classes=await db.from('classes').select('id,name').eq('status','active').order('name');
      final subjects=await db.from('subjects').select('id,name').eq('status','active').order('name');
      if(classes.isEmpty||subjects.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Create an active class and subject first.')));return;}
      String? classId=classes.first['id'].toString();String? subjectId=subjects.first['id'].toString();
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refreshDialog)=>AlertDialog(
        title:const Text('Create assignment'),
        content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextField(controller:title,decoration:const InputDecoration(labelText:'Assignment title')),
          DropdownButtonFormField<String>(value:classId,decoration:const InputDecoration(labelText:'Class'),
            items:classes.map((r)=>DropdownMenuItem<String>(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),onChanged:(v)=>refreshDialog(()=>classId=v)),
          DropdownButtonFormField<String>(value:subjectId,decoration:const InputDecoration(labelText:'Subject'),
            items:subjects.map((r)=>DropdownMenuItem<String>(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),onChanged:(v)=>refreshDialog(()=>subjectId=v)),
          TextField(controller:instructions,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Instructions')),
          TextField(controller:due,decoration:const InputDecoration(labelText:'Due date/time (optional, e.g. 2026-12-01 16:00)')),
          TextField(controller:max,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Maximum marks (optional)')),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Create draft'))],
      )));
      if(ok!=true)return;
      final dueText=due.text.trim();
      DateTime? dueDate;
      if(dueText.isNotEmpty)dueDate=DateTime.tryParse(dueText);
      final maxScore=max.text.trim().isEmpty?null:num.tryParse(max.text.trim());
      if(title.text.trim().isEmpty||classId==null||subjectId==null||
        (dueText.isNotEmpty&&dueDate==null)||(max.text.trim().isNotEmpty&&(maxScore==null||maxScore<=0))){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check the title, due date and maximum marks.')));return;
      }
      await db.from('assignments').insert({
        'title':title.text.trim(),'class_id':classId,'subject_id':subjectId,
        'instructions':instructions.text.trim().isEmpty?null:instructions.text.trim(),
        'due_at':dueDate?.toUtc().toIso8601String(),'max_score':maxScore,
      });
      await _refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Assignment could not be created: '+e.toString())));}
    finally{title.dispose();instructions.dispose();due.dispose();max.dispose();}
  }
  Future<void> _togglePublish(Map<String,dynamic> row) async{
    setState(()=>_busy=true);
    try{
      final published=row['published_at']!=null;
      await Supabase.instance.client.from('assignments').update({
        'published_at':published?null:DateTime.now().toUtc().toIso8601String(),
      }).eq('id',row['id']);
      await _refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update assignment: '+e.toString())));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,
    child:FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
      if(s.hasError)return ListView(padding:const EdgeInsets.all(18),children:[_InfoNotice(message:'Assignments could not be loaded: '+s.error.toString())]);
      final rows=s.data??[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        Row(children:[const Expanded(child:Text('Homework and marking',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:AppColors.ink))),
          FilledButton.icon(onPressed:_busy?null:_create,icon:const Icon(Icons.add),label:const Text('Create'))]),
        const Padding(padding:EdgeInsets.only(top:8,bottom:12),child:Text('Create a class assignment, publish it to enrolled learners, then review and mark their submissions.',style:TextStyle(color:AppColors.muted,height:1.4))),
        if(rows.isEmpty)const _InfoNotice(message:'No assignments created yet. Create the first homework task for a class.'),
        ...rows.map((r){
          final sub=r['assignment_submissions'];final count=sub is List?sub.length:0;
          final published=r['published_at']!=null;
          return Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
            title:Text(r['title']?.toString()??'Assignment',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
            subtitle:Text((r['classes']?['name']??'Class').toString()+' • '+(r['subjects']?['name']??'Subject').toString()+' • '+count.toString()+' submissions • '+(published?'Published':'Draft')),
            trailing:PopupMenuButton<String>(onSelected:(v)async{
              if(v=='submissions')await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>AdminAssignmentSubmissionsPage(assignment:r)));
              if(v=='publish'||v=='draft')await _togglePublish(r);
              if(mounted)await _refresh();
            },itemBuilder:(_)=>[
              const PopupMenuItem(value:'submissions',child:Text('View submissions / mark')),
              PopupMenuItem(value:published?'draft':'publish',child:Text(published?'Unpublish':'Publish to class')),
            ]),
          ));
        }),
      ]);
    }));
}

class AdminAssignmentSubmissionsPage extends StatefulWidget{
  final Map<String,dynamic> assignment;
  const AdminAssignmentSubmissionsPage({super.key,required this.assignment});
  @override
  State<AdminAssignmentSubmissionsPage> createState()=>_AdminAssignmentSubmissionsPageState();
}
class _AdminAssignmentSubmissionsPageState extends State<AdminAssignmentSubmissionsPage>{
  late Future<List<Map<String,dynamic>>> _items;
  bool _busy=false;
  @override
  void initState(){super.initState();_items=_load();}
  Future<List<Map<String,dynamic>>> _load()async{
    final rows=await Supabase.instance.client.from('assignment_submissions')
      .select('id,status,answer_text,score,tutor_feedback,submitted_at,graded_at,students(profiles(full_name))')
      .eq('assignment_id',widget.assignment['id']).order('submitted_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _refresh()async{final next=_load();setState(()=>_items=next);await next;}
  Future<void> _mark(Map<String,dynamic> row)async{
    final score=TextEditingController(text:row['score']?.toString()??'');
    final feedback=TextEditingController(text:row['tutor_feedback']?.toString()??'');
    final max=(widget.assignment['max_score'] as num?);
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Mark assignment'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:score,keyboardType:const TextInputType.numberWithOptions(decimal:true),
          decoration:InputDecoration(labelText:max==null?'Score':'Score (maximum '+max.toString()+' marks)')),
        TextField(controller:feedback,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Tutor feedback')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save mark'))],
    ));
    final value=num.tryParse(score.text.trim());
    if(ok==true){
      if(value==null||value<0||(max!=null&&value>max)){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid score within the maximum marks.')));
      }else{
        setState(()=>_busy=true);
        try{
          await Supabase.instance.client.from('assignment_submissions').update({
            'score':value,'tutor_feedback':feedback.text.trim().isEmpty?null:feedback.text.trim(),
            'status':'graded','graded_at':DateTime.now().toUtc().toIso8601String(),
          }).eq('id',row['id']);
          await _refresh();
        }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save mark: '+e.toString())));}
        finally{if(mounted)setState(()=>_busy=false);}
      }
    }
    score.dispose();feedback.dispose();
  }
  Future<void> _return(Map<String,dynamic> row)async{
    try{
      await Supabase.instance.client.from('assignment_submissions').update({
        'status':'returned','score':null,'graded_at':null,
        'tutor_feedback':'Please review the feedback and resubmit your work.',
      }).eq('id',row['id']);
      await _refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not return submission: '+e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Assignment submissions')),
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,child:FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
      if(s.hasError)return ListView(padding:const EdgeInsets.all(18),children:[_InfoNotice(message:'Submissions could not be loaded: '+s.error.toString())]);
      final rows=s.data??[];
      if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(18),children:const [_InfoNotice(message:'No learners have submitted this assignment yet.')]);
      return ListView(padding:const EdgeInsets.all(16),children:[
        Text(widget.assignment['title']?.toString()??'Assignment',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink)),
        const SizedBox(height:12),
        ...rows.map((r){
          final student=r['students'] is Map?Map<String,dynamic>.from(r['students'] as Map):<String,dynamic>{};
          final profile=student['profiles'] is Map?Map<String,dynamic>.from(student['profiles'] as Map):<String,dynamic>{};
          return Card(margin:const EdgeInsets.only(bottom:10),child:ExpansionTile(
            title:Text(profile['full_name']?.toString()??'Learner submission',style:const TextStyle(fontWeight:FontWeight.w700)),
            subtitle:Text((r['status']??'submitted').toString()+' • '+(r['submitted_at']?.toString()??'Date unavailable')),
            children:[
              Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Align(alignment:Alignment.centerLeft,child:Text('LEARNER ANSWER',style:TextStyle(fontSize:11,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.muted))),
                const SizedBox(height:7),
                SelectableText(r['answer_text']?.toString()??'No answer text supplied.',style:const TextStyle(height:1.5,color:AppColors.ink)),
                if(r['score']!=null)Padding(padding:const EdgeInsets.only(top:9),child:Text('Current score: '+r['score'].toString(),style:const TextStyle(fontWeight:FontWeight.w700))),
                if(r['tutor_feedback']!=null)Padding(padding:const EdgeInsets.only(top:6),child:Text('Feedback: '+r['tutor_feedback'].toString())),
                const SizedBox(height:12),
                Wrap(spacing:8,children:[
                  FilledButton.icon(onPressed:_busy?null:()=>_mark(r),icon:const Icon(Icons.grading_outlined),label:const Text('Mark')),
                  OutlinedButton.icon(onPressed:_busy?null:()=>_return(r),icon:const Icon(Icons.assignment_return_outlined),label:const Text('Return for correction')),
                ]),
              ])),
            ],
          ));
        }),
      ]);
    })));
}

class AdminAssessmentQuestionsPage extends StatefulWidget {
  final Map<String,dynamic> assessment;
  const AdminAssessmentQuestionsPage({super.key, required this.assessment});
  @override
  State<AdminAssessmentQuestionsPage> createState() => _AdminAssessmentQuestionsPageState();
}
class _AdminAssessmentQuestionsPageState extends State<AdminAssessmentQuestionsPage> {
  late Future<List<Map<String,dynamic>>> _questions;
  bool _busy = false;
  @override
  void initState() { super.initState(); _questions = _load(); }
  Future<List<Map<String,dynamic>>> _load() async {
    final rows = await Supabase.instance.client.from('questions').select('id,question_text,options,correct_answer,marks,position')
      .eq('assessment_id', widget.assessment['id']).order('position');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _questions = next); await next; }
  Future<void> _addQuestion() async {
    final question = TextEditingController();
    final a = TextEditingController(); final b = TextEditingController();
    final c = TextEditingController(); final d = TextEditingController();
    final marks = TextEditingController(text: '1');
    final explanation = TextEditingController();
    String correct = 'A';
    try {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,refreshDialog) => AlertDialog(
        title: const Text('Add multiple-choice question'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: question, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Question')),
          TextField(controller: a, decoration: const InputDecoration(labelText: 'Option A')),
          TextField(controller: b, decoration: const InputDecoration(labelText: 'Option B')),
          TextField(controller: c, decoration: const InputDecoration(labelText: 'Option C')),
          TextField(controller: d, decoration: const InputDecoration(labelText: 'Option D')),
          DropdownButtonFormField<String>(value: correct, decoration: const InputDecoration(labelText: 'Correct answer'),
            items: ['A','B','C','D'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => refreshDialog(() => correct = v ?? 'A')),
          TextField(controller: marks, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Marks')),
          TextField(controller: explanation, minLines: 2, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Explanation (optional)', alignLabelWithHint: true)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Save question'))],
      )));
      if (ok == true) {
        final opts = {'A':a.text.trim(),'B':b.text.trim(),'C':c.text.trim(),'D':d.text.trim()};
        final markValue = num.tryParse(marks.text.trim());
        if (question.text.trim().isEmpty || opts.values.any((v) => v.isEmpty) || markValue == null || markValue <= 0) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the question, all four options and a positive mark value.')));
          return;
        }
        setState(() => _busy = true);
        await Supabase.instance.client.from('questions').insert({
          'assessment_id': widget.assessment['id'], 'question_text': question.text.trim(),
          'options': opts, 'correct_answer': correct, 'marks': markValue,
          'explanation': explanation.text.trim().isEmpty ? null : explanation.text.trim(),
          'position': (await _load()).length + 1,
        });
        await _refresh();
        final all = await Supabase.instance.client.from('questions').select('marks').eq('assessment_id', widget.assessment['id']);
        final total = all.fold<num>(0, (sum,q) => sum + ((q['marks'] as num?) ?? 0));
        await Supabase.instance.client.from('assessments').update({'total_marks':total,'is_published':false}).eq('id',widget.assessment['id']);
        if (mounted) setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) { setState(() => _busy = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Question could not be saved: ' + e.toString()))); }
    } finally { question.dispose(); a.dispose(); b.dispose(); c.dispose(); d.dispose(); marks.dispose(); explanation.dispose(); }
  }
  Future<void> _deleteQuestion(Map<String,dynamic> q) async {
    try {
      await Supabase.instance.client.from('questions').delete().eq('id',q['id']);
      final all = await Supabase.instance.client.from('questions').select('marks').eq('assessment_id',widget.assessment['id']);
      final total = all.fold<num>(0,(sum,v)=>sum+((v['marks'] as num?)??0));
      await Supabase.instance.client.from('assessments').update({'total_marks':total,'is_published':false}).eq('id',widget.assessment['id']);
      await _refresh();
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Question could not be removed: '+e.toString()))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage questions')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _addQuestion,
      backgroundColor: AppColors.brown, foregroundColor: Colors.white,
      icon: const Icon(Icons.add), label: const Text('Add question')),
    body: RefreshIndicator(color: AppColors.brown,onRefresh:_refresh,
      child: FutureBuilder<List<Map<String,dynamic>>>(future:_questions,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Questions could not be loaded: '+s.error.toString())]);
        final rows=s.data??[];
        return ListView(padding:const EdgeInsets.fromLTRB(16,16,16,90),children:[
          Text(widget.assessment['title']?.toString()??'Assessment',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:6),
          Text(rows.length.toString()+' questions • Add an answer key for each item. Adding or removing questions returns the assessment to draft.',style:const TextStyle(color:AppColors.muted)),
          const SizedBox(height:14),
          if(rows.isEmpty)const _InfoNotice(message:'No questions yet. Add the first multiple-choice question.'),
          ...rows.map((q){
            final options=q['options'] is Map ? Map<String,dynamic>.from(q['options'] as Map) : <String,dynamic>{};
            return Card(child:ListTile(
              title:Text(q['question_text'].toString(),maxLines:3,overflow:TextOverflow.ellipsis),
              subtitle:Text('A. '+(options['A']??'').toString()+'   B. '+(options['B']??'').toString()+'\nCorrect answer: '+(q['correct_answer']??'').toString()+' • '+q['marks'].toString()+' mark(s)'),
              trailing:IconButton(icon:const Icon(Icons.delete_outline,color:AppColors.muted),onPressed:()=>_deleteQuestion(q)),
            ));
          }),
        ]);
      })),
  );
}

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});
  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  late Future<List<Map<String, dynamic>>> _tutors;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tutors = _loadTutors();
  }

  Future<List<Map<String, dynamic>>> _loadTutors() async {
    final rows = await Supabase.instance.client.from('tutors')
      .select('id,user_id,staff_number,qualification,status,profiles(full_name,email)')
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _addTutor() async {
    final db = Supabase.instance.client;
    try {
      final profiles = await db.from('profiles')
        .select('id,full_name,email').eq('status', 'active').order('full_name');
      final tutors = await db.from('tutors').select('user_id');
      final linked = (tutors as List).map((r) => r['user_id'].toString()).toSet();
      final available = List<Map<String, dynamic>>.from(profiles)
        .where((p) => !linked.contains(p['id'].toString())).toList();
      if (available.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unlinked active accounts found. The staff member must create an account first.')));
        return;
      }
      final staffNo = TextEditingController();
      final qualification = TextEditingController();
      String? userId = available.first['id'].toString();
      final ok = await showDialog<bool>(context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
          title: const Text('Add tutor'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: userId,
              decoration: const InputDecoration(labelText: 'Existing account'),
              items: available.map<DropdownMenuItem<String>>((p) =>
                DropdownMenuItem<String>(value: p['id'].toString(),
                  child: Text((p['full_name'] ?? 'Unnamed').toString() +
                    (p['email'] == null ? '' : ' • ' + p['email'].toString())))).toList(),
              onChanged: (v) => refreshDialog(() => userId = v),
            ),
            TextField(controller: staffNo, decoration: const InputDecoration(labelText: 'Staff number (optional)')),
            TextField(controller: qualification, decoration: const InputDecoration(labelText: 'Qualification (optional)')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add tutor')),
          ],
        )));
      if (ok == true && userId != null) {
        await db.from('tutors').insert({
          'user_id': userId,
          'staff_number': staffNo.text.trim().isEmpty ? null : staffNo.text.trim(),
          'qualification': qualification.text.trim().isEmpty ? null : qualification.text.trim(),
          'status': 'active',
        });
        if (mounted) setState(() => _tutors = _loadTutors());
      }
      staffNo.dispose();
      qualification.dispose();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add tutor: ' + e.toString())));
    }
  }

  Future<void> _assign(Map<String, dynamic> tutor) async {
    final db = Supabase.instance.client;
    try {
      final results = await Future.wait([
        db.from('classes').select('id,name').eq('status', 'active').order('name'),
        db.from('subjects').select('id,name').eq('status', 'active').order('name'),
      ]);
      final classes = List<Map<String, dynamic>>.from(results[0]);
      final subjects = List<Map<String, dynamic>>.from(results[1]);
      if (classes.isEmpty || subjects.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create an active class and subject before assigning a tutor.')));
        return;
      }
      String? classId = classes.first['id'].toString();
      String? subjectId = subjects.first['id'].toString();
      final ok = await showDialog<bool>(context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
          title: const Text('Assign tutor'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: classId, decoration: const InputDecoration(labelText: 'Class'),
              items: classes.map<DropdownMenuItem<String>>((r) =>
                DropdownMenuItem(value: r['id'].toString(), child: Text(r['name'].toString()))).toList(),
              onChanged: (v) => refreshDialog(() => classId = v),
            ),
            DropdownButtonFormField<String>(
              value: subjectId, decoration: const InputDecoration(labelText: 'Subject'),
              items: subjects.map<DropdownMenuItem<String>>((r) =>
                DropdownMenuItem(value: r['id'].toString(), child: Text(r['name'].toString()))).toList(),
              onChanged: (v) => refreshDialog(() => subjectId = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
          ],
        )));
      if (ok == true && classId != null && subjectId != null) {
        await db.from('class_tutors').upsert({
          'tutor_id': tutor['id'], 'class_id': classId, 'subject_id': subjectId,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutor assigned to the selected class and subject.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not assign tutor: ' + e.toString())));
    }
  }

  Future<void> _setStatus(Map<String, dynamic> tutor, String status) async {
    try {
      await Supabase.instance.client.from('tutors').update({'status': status}).eq('id', tutor['id']);
      if (mounted) setState(() => _tutors = _loadTutors());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update tutor: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tutor and staff management')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _addTutor,
      backgroundColor: AppColors.brown, foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add_alt_1), label: const Text('Add tutor')),
    body: RefreshIndicator(
      onRefresh: () async => setState(() => _tutors = _loadTutors()),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tutors,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator(color: AppColors.brown));
          if (snapshot.hasError)
            return ListView(padding: const EdgeInsets.all(20), children: [
              _InfoNotice(message: 'Tutor records could not be loaded: ' + snapshot.error.toString()),
            ]);
          final rows = snapshot.data ?? [];
          if (rows.isEmpty)
            return ListView(padding: const EdgeInsets.all(20), children: const [
              _InfoNotice(message: 'No tutors have been linked yet. Add a tutor using an existing registered account.'),
            ]);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = rows[index];
              final profile = row['profiles'] as Map<String, dynamic>?;
              return Card(child: ListTile(
                title: Text((profile?['full_name'] ?? 'Staff account').toString()),
                subtitle: Text((profile?['email'] ?? 'No email') .toString() +
                  ' • ' + (row['qualification'] ?? 'Qualification not set').toString() +
                  ' • ' + row['status'].toString()),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'assign') _assign(row);
                    if (v == 'off') _setStatus(row, 'inactive');
                    if (v == 'on') _setStatus(row, 'active');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'assign', child: Text('Assign to class and subject')),
                    if (row['status'] == 'active') const PopupMenuItem(value: 'off', child: Text('Deactivate')),
                    if (row['status'] != 'active') const PopupMenuItem(value: 'on', child: Text('Activate')),
                  ],
                ),
              ));
            },
          );
        },
      ),
    ),
  );
}

class AdminCommunicationsPage extends StatefulWidget {
  const AdminCommunicationsPage({super.key});
  @override
  State<AdminCommunicationsPage> createState() => _AdminCommunicationsPageState();
}
class _AdminCommunicationsPageState extends State<AdminCommunicationsPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _notify = true;
  bool _busy = false;
  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }
  Future<void> _publish() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title and message.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final sent = await Supabase.instance.client.rpc('publish_centre_announcement', params: {
        '_title': _title.text.trim(),
        '_body': _body.text.trim(),
        '_notify_students': _notify,
      });
      _title.clear();
      _body.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement published. Personal notifications sent to ' + sent.toString() + ' linked student account(s).')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message could not be published: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Centre communications')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Send a centre-wide message', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 8),
      const Text('Publish a general announcement and optionally send a personal notification to every linked student account.',
        style: TextStyle(color: AppColors.muted, height: 1.45)),
      const SizedBox(height: 18),
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Message title')),
      const SizedBox(height: 12),
      TextField(controller: _body, minLines: 5, maxLines: 9, decoration: const InputDecoration(labelText: 'Message')),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: _notify, onChanged: _busy ? null : (v) => setState(() => _notify = v),
        title: const Text('Also notify linked student accounts')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _busy ? null : _publish, icon: const Icon(Icons.send_rounded),
        label: Text(_busy ? 'Publishing...' : 'Publish message'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.brown, padding: const EdgeInsets.symmetric(vertical: 15))),
    ]),
  );
}

class OwnerAdminManagementPage extends StatefulWidget {
  const OwnerAdminManagementPage({super.key});
  @override
  State<OwnerAdminManagementPage> createState() => _OwnerAdminManagementPageState();
}
class _OwnerAdminManagementPageState extends State<OwnerAdminManagementPage> {
  final _email = TextEditingController();
  final Set<String> _permissions = {};
  bool _busy = false;
  late Future<List<Map<String, dynamic>>> _admins;
  static const labels = {
    'students.manage':'Manage students and learner records',
    'academics.manage':'Manage classes, subjects, lessons and assessments',
    'staff.manage':'Manage tutors and staff',
    'communications.send':'Publish announcements and send notifications',
    'finance.manage':'Manage invoices and payments',
    'reports.view':'View audit and centre reports',
  };
  @override
  void initState() { super.initState(); _admins = _load(); }
  @override
  void dispose() { _email.dispose(); super.dispose(); }
  Future<List<Map<String,dynamic>>> _load() async {
    final data = await Supabase.instance.client.rpc('owner_list_admins');
    return List<Map<String,dynamic>>.from(data);
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _admins = next); await next; }
  Future<void> _grant() async {
    final email = _email.text.trim();
    if (!email.contains('@')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an existing account email.'))); return; }
    setState(() => _busy = true);
    try {
      final db = Supabase.instance.client;
      await db.rpc('owner_grant_admin', params: {'_email':email});
      await db.rpc('owner_set_admin_permissions', params: {'_email':email,'_permissions':_permissions.toList()});
      _email.clear(); _permissions.clear(); await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrator access granted and permissions saved.')));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not grant access: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _revoke(String email) async {
    setState(() => _busy = true);
    try { await Supabase.instance.client.rpc('owner_revoke_admin', params: {'_email':email}); await _refresh(); }
    catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not revoke access: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _configure(Map<String, dynamic> admin) async {
    final email = admin['email'] as String? ?? '';
    final selected = List<String>.from(admin['permissions'] ?? []).toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('Configure administrator'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: labels.entries.map((entry) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(entry.key),
                  title: Text(entry.value),
                  onChanged: (value) => refreshDialog(() {
                    if (value == true) { selected.add(entry.key); }
                    else { selected.remove(entry.key); }
                  }),
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, selected), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('owner_set_admin_permissions', params: {
        '_email': email,
        '_permissions': result.toList(),
      });
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update permissions: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administrator access')),
    body: RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Authorise an administrator', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 6),
      const Text('Only the owner can grant or revoke administrator access. The account must already be registered.',
        style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 16),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Registered account email')),
      const SizedBox(height: 12),
      const Text('Assign permissions', style: TextStyle(fontWeight: FontWeight.w700)),
      ...labels.entries.map((e) => CheckboxListTile(contentPadding: EdgeInsets.zero,
        value: _permissions.contains(e.key), title: Text(e.value),
        onChanged: _busy ? null : (v) => setState(() { if(v == true) {_permissions.add(e.key);} else {_permissions.remove(e.key);} }))),
      FilledButton(onPressed: _busy ? null : _grant, style: FilledButton.styleFrom(backgroundColor: AppColors.brown),
        child: Text(_busy ? 'Saving...' : 'Grant administrator access')),
      const SizedBox(height: 26),
      const Text('CURRENT ADMINISTRATORS', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
      const SizedBox(height: 10),
      FutureBuilder<List<Map<String,dynamic>>>(future: _admins, builder: (context,s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return const _InfoNotice(message: 'Administrator list is available only to the authorised owner account.');
        final rows = s.data ?? [];
        if (rows.isEmpty) return const _InfoNotice(message: 'No administrators have been authorised yet.');
        return Column(children: rows.map((a) {
          final email = a['email'] as String? ?? '';
          final permissions = List<String>.from(a['permissions'] ?? []);
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(a['full_name'] as String? ?? email),
            subtitle: Text(email + '\n' + (permissions.isEmpty ? 'No permissions assigned' : permissions.map((p) => labels[p] ?? p).join(' • '))),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (action) {
                if (action == 'configure') _configure(a);
                if (action == 'revoke') _revoke(email);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'configure', child: Text('Configure permissions')),
                PopupMenuItem(value: 'revoke', child: Text('Revoke access')),
              ],
            ),
          ));
        }).toList());
      }),
    ])),
  );
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
  String _accountType = 'student';
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
          data: {'full_name': _name.text.trim(), 'account_type': _accountType},
        );
        if (response.session == null) {
          _error = false;
          _message = 'Account created. Check your email to confirm your address, then sign in.';
        } else {
          _error = false;
          _message = _accountType == 'parent'
              ? 'Your parent account has been created.'
              : 'Your learner account has been created.';
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
                      Text(_creating ? 'Create your account.' : 'Sign in to continue learning.',
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
                        DropdownButtonFormField<String>(
                          value: _accountType,
                          decoration: const InputDecoration(labelText: 'I am registering as'),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text('Student')),
                            DropdownMenuItem(value: 'parent', child: Text('Parent / guardian')),
                          ],
                          onChanged: _busy ? null : (v) => setState(() => _accountType = v ?? 'student'),
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
  final bool owner;
  final bool admin;
  final bool tutor;
  final bool parent;
  const LearnerHomePage({super.key, this.owner = false, this.admin = false, this.tutor = false, this.parent = false});
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
    final role = widget.parent
        ? 'parent / guardian'
        : roles.isEmpty
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

  void _openCentrePortal() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AdminPortalPage(owner: widget.owner),
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
          _HomeTab(
            account: _account,
            onOpenLearning: () => setState(() => _selectedIndex = 1),
            owner: widget.owner,
            admin: widget.admin,
            tutor: widget.tutor,
            parent: widget.parent,
            onOpenCentre: () => _openCentrePortal(),
          ),
          _LearningTab(owner: widget.owner, admin: widget.admin, tutor: widget.tutor),
          _AnalyticsTab(owner: widget.owner, admin: widget.admin),
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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _items = _loadItems();
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    final client = Supabase.instance.client;
    final notifications = await client
        .from('notifications')
        .select('id,title,body,read_at,created_at')
        .order('created_at', ascending: false);
    final announcements = await client
        .from('announcements')
        .select('id,title,body,published_at,created_at')
        .not('published_at', 'is', null)
        .lte('published_at', DateTime.now().toUtc().toIso8601String())
        .order('published_at', ascending: false);
    final items = <Map<String, dynamic>>[
      ...List<Map<String, dynamic>>.from(notifications).map((item) => {
        ...item,
        'kind': 'notification',
        'sort_at': item['created_at'],
      }),
      ...List<Map<String, dynamic>>.from(announcements).map((item) => {
        ...item,
        'kind': 'announcement',
        'sort_at': item['published_at'],
      }),
    ];
    items.sort((a, b) => DateTime.parse(b['sort_at'] as String)
        .compareTo(DateTime.parse(a['sort_at'] as String)));
    return items;
  }

  Future<void> _refresh() async {
    final next = _loadItems();
    setState(() => _items = next);
    await next;
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['kind'] != 'notification' || item['read_at'] != null) return;
    await Supabase.instance.client.from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', item['id']);
    await _refresh();
  }

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
    body: RefreshIndicator(
      color: AppColors.brown,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Centre updates',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.ink)),
          const SizedBox(height: 7),
          const Text('Announcements and personal learning reminders.',
            style: TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brown)),
                );
              }
              if (snapshot.hasError) {
                return const _InfoNotice(
                  message: 'Updates could not be loaded. Pull down to try again.',
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const _InfoNotice(
                  message: 'You have no notifications yet. Centre announcements and reminders sent to your account will appear here.',
                );
              }
              return Column(
                children: items.map((item) {
                  final isAnnouncement = item['kind'] == 'announcement';
                  final isUnread = !isAnnouncement && item['read_at'] == null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _markRead(item),
                      leading: Icon(
                        isAnnouncement ? Icons.campaign_outlined : Icons.notifications_none_rounded,
                        color: AppColors.brown,
                      ),
                      title: Text(item['title'] ?? 'Update',
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.ink,
                        )),
                      subtitle: item['body'] == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(item['body'],
                                style: const TextStyle(color: AppColors.muted, height: 1.4)),
                            ),
                      trailing: isUnread
                          ? const Icon(Icons.circle, size: 9, color: AppColors.gold)
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _HomeTab extends StatelessWidget {
  final Future<Map<String, dynamic>> account;
  final VoidCallback onOpenLearning;
  final bool owner;
  final bool admin;
  final bool tutor;
  final bool parent;
  final VoidCallback onOpenCentre;
  const _HomeTab({
    required this.account,
    required this.onOpenLearning,
    required this.owner,
    required this.admin,
    required this.tutor,
    required this.parent,
    required this.onOpenCentre,
  });

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
                Text(owner ? 'OWNER DASHBOARD' : admin ? 'CENTRE DASHBOARD' : tutor ? 'TUTOR PORTAL' : parent ? 'PARENT PORTAL' : 'LEARNER PORTAL',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parent ? 'Stay connected to your child’s learning' : 'Your learning journey starts here',
                        style: TextStyle(color: Colors.white, fontSize: 21,
                          fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text(parent
                        ? 'Link your child’s learner account to follow assignments, results and attendance from one place.'
                        : 'Your classes, subjects, learning materials and progress will appear here as the centre activates them.',
                        style: TextStyle(color: Color(0xFFE7DED6), height: 1.5)),
                    ],
                  ),
                ),
                if (owner) ...[
                  const SizedBox(height: 20),
                  const _CentreOverview(),
                ],
                if (admin) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.paleGold,
                        child: Icon(Icons.admin_panel_settings_outlined, color: AppColors.brown),
                      ),
                      title: Text(owner ? 'Owner centre' : 'Administration centre',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                      subtitle: Text(owner
                        ? 'Manage the centre, administrators, academic setup and operations.'
                        : 'Open the management tools assigned to your account.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: onOpenCentre,
                    ),
                  ),
                ],
                if (!owner && !admin && !tutor) ...[
                  Card(child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(backgroundColor: AppColors.paleGold,
                      child: Icon(Icons.family_restroom_outlined, color: AppColors.brown)),
                    title: const Text('Parent / guardian dashboard',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    subtitle: const Text('Link your account to your child’s learning profile'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const GuardianPortalPage())),
                  )),
                ],
                if (!parent) ...[
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

                ],
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

class _CentreOverview extends StatefulWidget {
  const _CentreOverview();

  @override
  State<_CentreOverview> createState() => _CentreOverviewState();
}

class _CentreOverviewState extends State<_CentreOverview> {
  late Future<Map<String, int>> _overview;

  @override
  void initState() {
    super.initState();
    _overview = _loadOverview();
  }

  Future<Map<String, int>> _loadOverview() async {
    final client = Supabase.instance.client;
    final results = await Future.wait([
      client.from('students').select('id'),
      client.from('classes').select('id'),
      client.from('subjects').select('id'),
      client.from('tutors').select('id'),
      client.from('lessons').select('id'),
    ]);
    return {
      'students': results[0].length,
      'classes': results[1].length,
      'subjects': results[2].length,
      'tutors': results[3].length,
      'lessons': results[4].length,
    };
  }

  Future<void> _refresh() async {
    final next = _loadOverview();
    setState(() => _overview = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CENTRE OVERVIEW',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1,
              fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 6),
          const Text('Live records from your centre',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.ink)),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, int>>(
            future: _overview,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator(
                    color: AppColors.brown)),
                );
              }
              if (snapshot.hasError) {
                return const _InfoNotice(
                  message: 'Centre figures could not be loaded with the current account permissions. Refresh or check the owner access settings.',
                );
              }
              final data = snapshot.data!;
              final entries = <MapEntry<String, String>>[
                MapEntry('Students', data['students'].toString()),
                MapEntry('Classes', data['classes'].toString()),
                MapEntry('Subjects', data['subjects'].toString()),
                MapEntry('Tutors', data['tutors'].toString()),
                MapEntry('Lessons', data['lessons'].toString()),
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: entries.map((entry) => Container(
                  width: 112,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.paleGold,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.value,
                        style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w800, color: AppColors.brown)),
                      const SizedBox(height: 3),
                      Text(entry.key,
                        style: const TextStyle(fontSize: 12,
                          color: AppColors.ink)),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh figures'),
            ),
          ),
        ],
      ),
    ),
  );
}



class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});
  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  late Future<List<Map<String, dynamic>>> _accounts;
  String _search = '';

  @override
  void initState() { super.initState(); _accounts = _load(); }

  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await Supabase.instance.client.rpc('admin_registered_accounts');
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<void> _refresh() async {
    final next = _load();
    setState(() => _accounts = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registered accounts')),
    body: RefreshIndicator(
      color: AppColors.brown,
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brown));
          }
          if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(20), children: [
            _InfoNotice(message: 'Registered accounts could not be loaded: ${snapshot.error}')
          ]);
          final all = snapshot.data ?? [];
          final q = _search.trim().toLowerCase();
          final rows = all.where((r) =>
            q.isEmpty ||
            (r['full_name'] ?? '').toString().toLowerCase().contains(q) ||
            (r['email'] ?? '').toString().toLowerCase().contains(q)
          ).toList();
          return ListView(padding: const EdgeInsets.all(18), children: [
            const Text('Every registered user', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 5),
            Text('${all.length} account(s) • Includes users who have not requested classroom access',
              style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search name or email'),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty) const _InfoNotice(message: 'No matching accounts were found.'),
            ...rows.map((r) {
              final roles = r['roles'] is List
                ? List<Map<String, dynamic>>.from(r['roles'] as List)
                : <Map<String, dynamic>>[];
              final roleNames = roles.map((v) => v['role'].toString().replaceAll('_',' ')).join(', ');
              final rawStudent = r['student'];
              final student = rawStudent is Map
                ? Map<String, dynamic>.from(rawStudent)
                : <String, dynamic>{};
              final isStaff = roles.any((v) => ['admin','super_admin','tutor'].contains(v['role']));
              final accountType = isStaff ? 'Staff account'
                : r['account_type'] == 'parent' ? 'Parent / guardian'
                : 'Student account';
              final created = DateTime.tryParse(r['created_at']?.toString() ?? '');
              final createdLabel = created == null ? 'Date unavailable'
                : '${created.toLocal().day.toString().padLeft(2,'0')}/${created.toLocal().month.toString().padLeft(2,'0')}/${created.toLocal().year}';
              return Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.paleGold,
                    child: Icon(r['account_type'] == 'parent' ? Icons.family_restroom_outlined : Icons.person_outline_rounded, color: AppColors.brown),
                  ),
                  title: Text((r['full_name'] ?? 'Unnamed account').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  subtitle: Text(
                    '${r['email'] ?? 'No email'}\n$accountType • Created $createdLabel'
                    '${student.isEmpty ? '' : '\nLevel: ${student['level'] ?? 'Not set'}'}'
                    '${roleNames.isEmpty ? '' : '\nAccess: $roleNames'}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          ]);
        },
      ),
    ),
  );
}


class GuardianChildDetailsPage extends StatefulWidget {
  final String studentId;
  final String childName;
  const GuardianChildDetailsPage({super.key, required this.studentId, required this.childName});
  @override
  State<GuardianChildDetailsPage> createState() => _GuardianChildDetailsPageState();
}

class _GuardianChildDetailsPageState extends State<GuardianChildDetailsPage> {
  late Future<Map<String, dynamic>> _details;
  @override
  void initState() { super.initState(); _details = _load(); }

  Future<Map<String, dynamic>> _load() async {
    final raw = await Supabase.instance.client.rpc('guardian_child_details', params: {
      'p_student_id': widget.studentId,
    });
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _details = next);
    await next;
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return 'Date unavailable';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2,'0')}/${local.month.toString().padLeft(2,'0')}/${local.year}';
  }

  Widget _section(String title, List<Map<String, dynamic>> rows, String empty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (rows.isEmpty) Text(empty, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((r['title'] ?? r['subject'] ?? r['status'] ?? 'Record').toString(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(
                title == 'Assignments'
                  ? '${r['subject'] ?? 'Subject'} • ${r['status'] ?? 'Not submitted'} • ${r['score'] == null ? 'Not marked' : '${r['score']}/${r['max_score'] ?? '?'}'}'
                  : title == 'Results'
                    ? 'Score: ${r['score'] ?? '-'} • Grade: ${r['grade'] ?? 'Not graded'} • ${_date(r['published_at'])}'
                    : '${r['status'] ?? ''} • ${_date(r['date'])}',
                style: const TextStyle(color: AppColors.muted, height: 1.4)),
              if (r['feedback'] != null && r['feedback'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Tutor feedback: ${r['feedback']}', style: const TextStyle(height: 1.4))),
              if (r['comment'] != null && r['comment'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Tutor comment: ${r['comment']}', style: const TextStyle(height: 1.4))),
              if (r['note'] != null && r['note'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Note: ${r['note']}', style: const TextStyle(height: 1.4))),
              const Divider(height: 14, color: AppColors.line),
            ]),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.childName)),
    body: RefreshIndicator(
      color: AppColors.brown,
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
          if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(20), children: [
            _InfoNotice(message: 'Learner progress could not be loaded: ${snapshot.error}')
          ]);
          final data = snapshot.data!;
          final assignments = List<Map<String, dynamic>>.from(data['assignments'] ?? []);
          final results = List<Map<String, dynamic>>.from(data['results'] ?? []);
          final attendance = List<Map<String, dynamic>>.from(data['attendance'] ?? []);
          final child = Map<String, dynamic>.from(data['child'] ?? {});
          return ListView(padding: const EdgeInsets.all(18), children: [
            Text((child['name'] ?? widget.childName).toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text((child['level'] ?? 'Level not set').toString(), style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            _section('Assignments', assignments, 'No assignments have been published for this learner yet.'),
            _section('Results', results, 'No results have been published yet.'),
            _section('Attendance', attendance, 'No attendance records have been added yet.'),
          ]);
        },
      ),
    ),
  );
}

class GuardianPortalPage extends StatefulWidget {
  final bool admin;
  const GuardianPortalPage({super.key, this.admin = false});
  @override
  State<GuardianPortalPage> createState() => _GuardianPortalPageState();
}

class _GuardianPortalPageState extends State<GuardianPortalPage> {
  late Future<dynamic> _data;
  final TextEditingController _email = TextEditingController();
  String _relationship = 'Parent';
  bool _busy = false;

  @override
  void initState() { super.initState(); _data = _load(); }

  Future<dynamic> _load() async {
    final db = Supabase.instance.client;
    final raw = await db.rpc(widget.admin ? 'admin_guardian_link_requests' : 'guardian_portal_summary');
    if (widget.admin) return List<Map<String, dynamic>>.from(raw as List);
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await Supabase.instance.client.rpc('request_guardian_link', params: {
        'p_student_email': _email.text.trim(),
        'p_relationship': _relationship,
      });
      _email.clear();
      await _refresh();
      final message = result is Map && result['message'] != null
        ? result['message'].toString()
        : 'Your request has been sent for centre verification.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request could not be submitted: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _review(Map<String, dynamic> row, String decision) async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('review_guardian_link_request', params: {
        'p_request_id': row['id'],
        'p_decision': decision,
        'p_admin_note': decision == 'approved' ? null : 'Please confirm the learner email and contact the centre if needed.',
      });
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision == 'approved' ? 'Parent account linked.' : 'Request rejected.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request could not be reviewed: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.admin ? 'Parent link requests' : 'Parent / guardian')),
    body: RefreshIndicator(
      color: AppColors.brown,
      onRefresh: _refresh,
      child: FutureBuilder<dynamic>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brown));
          }
          if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(20), children: [
            _InfoNotice(message: 'Parent information could not be loaded: ${snapshot.error}')
          ]);
          if (widget.admin) {
            final rows = List<Map<String, dynamic>>.from(snapshot.data ?? []);
            if (rows.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: const [
              Text('Parent verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              SizedBox(height: 10),
              _InfoNotice(message: 'There are no parent link requests waiting for review.')
            ]);
            return ListView(padding: const EdgeInsets.all(18), children: [
              const Text('Verify parent and learner accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              const Text('Confirm that the parent is authorised to view the learner account before approving the link.', style: TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 14),
              ...rows.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((r['guardian_name'] ?? 'Parent account').toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text((r['guardian_email'] ?? '').toString(), style: const TextStyle(color: AppColors.muted)),
                    const Divider(height: 20),
                    Text('Learner email: ${r['requested_email'] ?? ''}'),
                    Text('Learner account: ${r['student_name'] ?? 'Not found yet'}'),
                    Text('Relationship: ${r['relationship'] ?? 'Parent'}'),
                    if (r['student_id'] == null)
                      const Padding(padding: EdgeInsets.only(top: 7), child: Text('No matching active learner account was found. Do not approve until the email is corrected.', style: TextStyle(color: Colors.red, height: 1.35))),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: _busy ? null : () => _review(r, 'rejected'),
                        child: const Text('Reject'))),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton(
                        onPressed: _busy || r['student_id'] == null ? null : () => _review(r, 'approved'),
                        child: const Text('Approve link'))),
                    ]),
                  ]),
                ),
              )),
            ]);
          }

          final data = Map<String, dynamic>.from(snapshot.data as Map);
          final children = List<Map<String, dynamic>>.from(data['children'] ?? []);
          final requests = List<Map<String, dynamic>>.from(data['requests'] ?? []);
          return ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Your children’s learning', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Link your account to a learner account to follow learning progress. The centre will verify every request before sharing information.', style: TextStyle(color: AppColors.muted, height: 1.45)),
            const SizedBox(height: 18),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Request a child link', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              const Text('Enter the email address the learner uses to sign in to Young Learners Tutorial.', style: TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 10),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Learner account email')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(labelText: 'Your relationship to the learner'),
                items: const ['Parent','Mother','Father','Guardian','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: _busy ? null : (v) => setState(() => _relationship = v ?? 'Parent'),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Submitting...' : 'Send link request'))),
            ]))),
            const SizedBox(height: 18),
            const Text('Linked children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            if (children.isEmpty) const _InfoNotice(message: 'No child accounts have been linked yet. Once the centre approves your request, linked learners will appear here.'),
            ...children.map((c) => Card(child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.paleGold, child: Icon(Icons.school_outlined, color: AppColors.brown)),
              title: Text((c['name'] ?? 'Learner').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              isThreeLine: true,
              subtitle: Text(
                '${c['level'] ?? 'Level not set'} • ${c['relationship'] ?? 'Parent'}'
                '\nAttendance: ${c['attendance_rate'] == null ? 'No records yet' : '${c['attendance_rate']}%'}'
                '\nAssignments submitted: ${c['assignments_submitted'] ?? 0}'
                '${c['latest_result'] == null ? '' : '\nLatest result: ${c['latest_result']} in ${c['latest_subject'] ?? 'a subject'}'}',
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => GuardianChildDetailsPage(
                  studentId: c['student_id'].toString(),
                  childName: (c['name'] ?? 'Learner').toString(),
                ),
              )),
            ))),
            const SizedBox(height: 18),
            const Text('Your requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            if (requests.isEmpty) const _InfoNotice(message: 'You have not submitted a parent link request yet.'),
            ...requests.map((r) => Card(child: ListTile(
              title: Text((r['requested_email'] ?? '').toString()),
              subtitle: Text('${r['relationship'] ?? 'Parent'} • ${r['status'] ?? 'pending'}${r['admin_note'] == null ? '' : ' • ${r['admin_note']}'}'),
              trailing: Icon(
                r['status'] == 'approved' ? Icons.check_circle_outline : r['status'] == 'rejected' ? Icons.info_outline : Icons.hourglass_top_rounded,
                color: r['status'] == 'approved' ? Colors.green : AppColors.gold),
            ))),
          ]);
        },
      ),
    ),
  );
}

class _LearningTab extends StatefulWidget {
  final bool owner;
  final bool admin;
  final bool tutor;
  const _LearningTab({this.owner = false, this.admin = false, this.tutor = false});
  @override
  State<_LearningTab> createState() => _LearningTabState();
}
class _LearningTabState extends State<_LearningTab> {
  late Future<List<Map<String, dynamic>>> _lessons;
  @override
  void initState() { super.initState(); _lessons = _loadLessons(); }
  Future<List<Map<String, dynamic>>> _loadLessons() async {
    if (widget.tutor) return [];
    final db = Supabase.instance.client;
    var query = db.from('lessons')
      .select('id,title,description,content,scheduled_at,duration_minutes,subjects(name),classes(name)')
      .eq('is_published', true);
    // Owners and authorised administrators can inspect the centre's published
    // catalogue. Learners only receive lessons for their active enrolments.
    if (!widget.owner && !widget.admin) {
      final approvedRequests = await db.from('learning_access_requests')
        .select('learning_programmes(class_id)').eq('status', 'approved');
      final classIds = approvedRequests.map((row) {
        final programme = row['learning_programmes'] as Map<String, dynamic>?;
        return programme?['class_id']?.toString();
      }).whereType<String>().toSet().toList();
      if (classIds.isEmpty) return [];
      query = query.inFilter('class_id', classIds);
    }
    final rows = await query.order('scheduled_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
  Future<void> _refresh() async { final next = _loadLessons(); setState(() => _lessons = next); await next; }
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.brown, onRefresh: _refresh,
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.tutor ? 'Tutor workspace' : 'My learning', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 7),
      Text(widget.tutor ? 'Take attendance for the classes assigned to you.' : 'Open a lesson to read its notes and learning materials.', style: const TextStyle(color: AppColors.muted, height: 1.45)),
      const SizedBox(height: 20),
      if (widget.tutor) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.fact_check_outlined, color: AppColors.brown)),
          title: const Text('Class attendance', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('Take and update the register for your assigned classes'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Class attendance')), body: const AdminAttendancePage()))),
        ),
      ),
      if (widget.tutor) const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.school_outlined, color: AppColors.brown)),
          title: const Text('Learning programmes', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('Choose a class programme, view fees and request classroom access'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LearningAccessPage())),
        ),
      ),
      if (!widget.owner && !widget.admin && !widget.tutor) const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.event_available_outlined, color: AppColors.brown)),
          title: const Text('My attendance', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('View your attendance history and attendance rate'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StudentAttendancePage())),
        ),
      ),
      if (!widget.owner && !widget.admin && !widget.tutor) const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.assignment_outlined, color: AppColors.brown)),
          title: const Text('My assignments', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('View homework, submit your answers and read tutor feedback'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StudentAssignmentsPage())),
        ),
      ),
      if (!widget.owner && !widget.admin && !widget.tutor) const SizedBox(height: 10),
      if (!widget.tutor) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.assured_workload_outlined, color: AppColors.brown),
          ),
          title: const Text('Nigerian Examination Preparation', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('WAEC, NECO, JAMB, NABTEB, NBAIS and entrance examinations'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ExamPreparationPage())),
        ),
      ),
      const SizedBox(height: 18),
      FutureBuilder<List<Map<String, dynamic>>>(future: _lessons, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator(color: AppColors.brown)));
        if (snapshot.hasError) return const _InfoNotice(message: 'Lessons could not be loaded. Check your connection and pull down to try again.');
        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) return const _InfoNotice(message: 'There are no published lessons available yet. New lessons will appear here when your tutorial centre publishes them.');
        return Column(children: lessons.map((lesson) {
          final subject = lesson['subjects']; final classInfo = lesson['classes'];
          final meta = [if (subject is Map && subject['name'] != null) subject['name'], if (classInfo is Map && classInfo['name'] != null) classInfo['name']].join(' • ');
          return Padding(padding: const EdgeInsets.only(bottom: 11), child: Card(child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.menu_book_rounded, color: AppColors.brown)),
            title: Text(lesson['title'] ?? 'Lesson', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text([if (meta.isNotEmpty) meta, if (lesson['duration_minutes'] != null) '${lesson["duration_minutes"]} min'].join('  •  '), style: const TextStyle(color: AppColors.muted))),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonDetailPage(lesson: lesson))),
          )));
        }).toList());
      }),
    ]),
  );
}
class LessonDetailPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const LessonDetailPage({super.key, required this.lesson});
  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}
class _LessonDetailPageState extends State<LessonDetailPage> {
  late Future<List<Map<String, dynamic>>> _materials;
  @override
  void initState() {
    super.initState();
    _materials = Supabase.instance.client.from('learning_materials').select('id,title,material_type,storage_path,external_url')
      .eq('lesson_id', widget.lesson['id']).then((rows) => List<Map<String, dynamic>>.from(rows));
  }
  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(appBar: AppBar(title: const Text('Lesson details')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(lesson['title'] ?? 'Lesson', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 9),
      if (lesson['description'] != null) Text(lesson['description'], style: const TextStyle(color: AppColors.muted, height: 1.5)),
      const SizedBox(height: 22),
      const Text('LESSON NOTES', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(17), child: SelectableText((lesson['content'] as String?)?.trim().isNotEmpty == true ? lesson['content'] as String : 'Your tutor has not added lesson notes yet.', style: const TextStyle(height: 1.65, color: AppColors.ink)))),
      const SizedBox(height: 22),
      const Text('LEARNING MATERIALS', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
      const SizedBox(height: 10),
      FutureBuilder<List<Map<String, dynamic>>>(future: _materials, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
        if (snapshot.hasError) return const _InfoNotice(message: 'Learning materials could not be loaded.');
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const _InfoNotice(message: 'No extra materials have been added to this lesson yet.');
        return Column(children: items.map((item) => Card(child: ListTile(
          leading: const Icon(Icons.attach_file_rounded, color: AppColors.brown),
          title: Text(item['title'] ?? 'Learning material'),
          subtitle: Text(item['material_type'] ?? 'Learning resource'),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () {
            final url = item['external_url'];
            if (url is String && url.startsWith('https://')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This resource does not have an external link yet.')));
            }
          },
        ))).toList());
      }),
    ]));
  }
}
class _AnalyticsTab extends StatefulWidget {
  final bool owner;
  final bool admin;
  const _AnalyticsTab({this.owner = false, this.admin = false});
  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  late Future<Map<String, dynamic>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final student = await client.from('students')
        .select('id').eq('user_id', userId).maybeSingle();
    if (student == null) return {'linked': false};
    final studentId = student['id'];
    final values = await Future.wait([
      client.from('enrolments').select('id').eq('student_id', studentId),
      client.from('assignment_submissions').select('id,status,score,assignments(max_score)').eq('student_id', studentId),
      client.from('assessment_attempts').select('id').eq('student_id', studentId),
      client.from('results').select('id').eq('student_id', studentId).not('published_at', 'is', null),
      client.from('attendance_records').select('id,status').eq('student_id', studentId),
    ]);
    final submissions = List<Map<String,dynamic>>.from(values[1]);
    final graded = submissions.where((r) => r['status'] == 'graded' && r['score'] is num).toList();
    final percentages = graded.map((r) {
      final assignment = r['assignments'];
      final maxScore = assignment is Map ? assignment['max_score'] : null;
      final score = r['score'] as num;
      return maxScore is num && maxScore > 0 ? (score / maxScore) * 100 : null;
    }).whereType<num>().toList();
    final average = percentages.isEmpty ? null :
      percentages.reduce((a,b) => a+b) / percentages.length;
    final attendance = List<Map<String,dynamic>>.from(values[4]);
    final attendanceDays = attendance.where((r) => r['status'] != 'excused').length;
    final attendedDays = attendance.where((r) => r['status'] == 'present' || r['status'] == 'late').length;
    final attendanceRate = attendanceDays == 0 ? null : attendedDays * 100 / attendanceDays;
    return {
      'linked': true,
      'enrolments': values[0].length,
      'submissions': submissions.length,
      'graded': graded.length,
      'assignment_average': average,
      'attempts': values[2].length,
      'results': values[3].length,
      'attendance_days': attendance.length,
      'attendance_rate': attendanceRate,
    };
  }

  Future<void> _refresh() async {
    final next = _loadStats();
    setState(() => _stats = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.owner) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Centre analytics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.ink)),
          SizedBox(height: 7),
          Text('Live totals from the centre records. Detailed reports will build on these connected records.',
            style: TextStyle(color: AppColors.muted, height: 1.45)),
          SizedBox(height: 18),
          _CentreOverview(),
        ],
      );
    }
    return RefreshIndicator(
    color: AppColors.brown,
    onRefresh: _refresh,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Your learning at a glance',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.ink)),
        const SizedBox(height: 7),
        const Text('A clear view of your recorded learning activity and academic progress.',
          style: TextStyle(color: AppColors.muted, height: 1.45)),
        const SizedBox(height: 20),
        FutureBuilder<Map<String, dynamic>>(
          future: _stats,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.brown)),
              );
            }
            if (snapshot.hasError) {
              return const _InfoNotice(
                message: 'Your learning statistics could not be loaded. Pull down to try again.',
              );
            }
            final stats = snapshot.data!;
            if (stats['linked'] != true) {
              return const _InfoNotice(
                message: 'Your learner profile has not yet been linked to a student record by the centre. Your analytics will appear after the centre completes your enrolment.',
              );
            }
            return Column(
              children: [
                _FeatureRow(
                  icon: Icons.class_outlined,
                  title: 'Active enrolments',
                  detail: stats['enrolments'].toString() + ' recorded class enrolments',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Assignments submitted',
                  detail: stats['submissions'].toString() + ' submissions recorded',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: Icons.grading_outlined,
                  title: 'Assignments marked',
                  detail: stats['graded'].toString() + ' graded' +
                    (stats['assignment_average'] == null ? '' :
                      ' • average ' + (stats['assignment_average'] as num).toStringAsFixed(1) + '%'),
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: Icons.event_available_outlined,
                  title: 'Attendance rate',
                  detail: stats['attendance_rate'] == null
                    ? stats['attendance_days'].toString() + ' recorded attendance entries'
                    : (stats['attendance_rate'] as num).toStringAsFixed(1) + '% across ' + stats['attendance_days'].toString() + ' recorded days',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: Icons.assessment_outlined,
                  title: 'Assessment attempts',
                  detail: stats['attempts'].toString() + ' attempts recorded',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: Icons.trending_up_rounded,
                  title: 'Published results',
                  detail: stats['results'].toString() + ' results available to you',
                ),
                const SizedBox(height: 18),
                const _InfoNotice(
                  message: 'These figures come from your actual learner records. Lesson completion is not yet tracked separately, so it is not included as a completed-lesson figure.',
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
  }
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



class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});
  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}
class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  late Future<List<Map<String,dynamic>>> _items;
  @override
  void initState(){super.initState();_items=_load();}
  Future<List<Map<String,dynamic>>> _load() async {
    final raw=await Supabase.instance.client.rpc('student_assignments');
    if(raw is! List)return [];
    return raw.map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<void> _refresh() async {final next=_load();setState(()=>_items=next);await next;}
  String _date(dynamic raw){
    final d=DateTime.tryParse(raw?.toString()??'');
    if(d==null)return 'No due date';
    final local=d.toLocal();
    return 'Due '+local.day.toString().padLeft(2,'0')+'/'+local.month.toString().padLeft(2,'0')+'/'+local.year.toString();
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('My assignments')),
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,
      child:FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Assignments could not be loaded. '+s.error.toString())]);
        final rows=s.data??[];
        if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(20),children:const [
          _InfoNotice(message:'No assignments have been published for your active class yet. New homework will appear here when your tutor publishes it.')
        ]);
        return ListView(padding:const EdgeInsets.all(18),children:[
          const Text('Homework and class tasks',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:6),
          const Text('Open an assignment to read the instructions and submit your work.',style:TextStyle(color:AppColors.muted)),
          const SizedBox(height:14),
          ...rows.map((r){
            final status=(r['submission_status']??'not submitted').toString();
            final done=status=='graded';
            final isOverdue=r['due_at']!=null&&DateTime.tryParse(r['due_at'].toString())?.isBefore(DateTime.now().toUtc())==true&&status!='submitted'&&status!='graded';
            return Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
              contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:9),
              leading:Container(width:43,height:43,decoration:BoxDecoration(color:AppColors.paleGold,borderRadius:BorderRadius.circular(11)),
                child:const Icon(Icons.assignment_outlined,color:AppColors.brown)),
              title:Text(r['title']?.toString()??'Assignment',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
              subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Text(
                (r['subject_name']??'Subject').toString()+' • '+_date(r['due_at'])+'\n'+
                (done?'Graded • '+(r['score']??'—').toString()+' marks':status=='submitted'?'Submitted • Awaiting marking':status=='returned'?'Returned for correction' :isOverdue?'Overdue • Not submitted':'Not submitted'),
                style:const TextStyle(color:AppColors.muted,height:1.45))),
              trailing:const Icon(Icons.chevron_right_rounded,color:AppColors.brown),
              onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>StudentAssignmentDetailPage(assignment:r))).then((_)=>_refresh()),
            ));
          }),
        ]);
      })),
  );
}

class StudentAssignmentDetailPage extends StatefulWidget {
  final Map<String,dynamic> assignment;
  const StudentAssignmentDetailPage({super.key,required this.assignment});
  @override
  State<StudentAssignmentDetailPage> createState()=>_StudentAssignmentDetailPageState();
}
class _StudentAssignmentDetailPageState extends State<StudentAssignmentDetailPage>{
  late final TextEditingController _answer;
  bool _busy=false;
  @override
  void initState(){super.initState();_answer=TextEditingController(text:widget.assignment['answer_text']?.toString()??'');}
  @override
  void dispose(){_answer.dispose();super.dispose();}
  Future<void> _submit() async{
    if(_answer.text.trim().length<2){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Write your answer before submitting.')));return;
    }
    setState(()=>_busy=true);
    try{
      await Supabase.instance.client.rpc('submit_student_assignment',params:{
        'p_assignment_id':widget.assignment['id'],'p_answer_text':_answer.text.trim(),
      });
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your assignment has been submitted.')));Navigator.of(context).pop();}
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Submission failed: '+e.toString())));
    }finally{if(mounted)setState(()=>_busy=false);}
  }
  String _due(){
    final d=DateTime.tryParse(widget.assignment['due_at']?.toString()??'');
    if(d==null)return 'No due date';
    final x=d.toLocal();return x.day.toString().padLeft(2,'0')+'/'+x.month.toString().padLeft(2,'0')+'/'+x.year.toString();
  }
  @override
  Widget build(BuildContext context){
    final a=widget.assignment;
    final status=(a['submission_status']??'').toString();
    final canSubmit=status.isEmpty||status=='draft'||status=='returned';
    return Scaffold(appBar:AppBar(title:const Text('Assignment details')),
      body:ListView(padding:const EdgeInsets.all(20),children:[
        Text(a['title']?.toString()??'Assignment',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:AppColors.ink)),
        const SizedBox(height:8),
        Text((a['subject_name']??'Subject').toString()+' • '+(a['class_name']??'Class').toString(),style:const TextStyle(color:AppColors.muted)),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:[
          Chip(label:Text(_due())),
          if(a['max_score']!=null)Chip(label:Text('Maximum '+a['max_score'].toString()+' marks')),
          if(status.isNotEmpty)Chip(label:Text(status.toUpperCase())),
        ]),
        const SizedBox(height:18),
        const Text('INSTRUCTIONS',style:TextStyle(fontSize:11,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:8),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(a['instructions']?.toString().trim().isNotEmpty==true?a['instructions'].toString():'Your tutor has not added extra instructions.',style:const TextStyle(height:1.55,color:AppColors.ink)))),
        const SizedBox(height:20),
        if(canSubmit)...[
          const Text('YOUR ANSWER',style:TextStyle(fontSize:11,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.muted)),
          const SizedBox(height:8),
          TextField(controller:_answer,minLines:7,maxLines:14,maxLength:30000,
            decoration:const InputDecoration(hintText:'Type your assignment answer here...',alignLabelWithHint:true,border:OutlineInputBorder())),
          const SizedBox(height:10),
          FilledButton.icon(onPressed:_busy?null:_submit,icon:const Icon(Icons.send_rounded),
            style:FilledButton.styleFrom(backgroundColor:AppColors.brown,padding:const EdgeInsets.symmetric(vertical:14)),
            label:Text(_busy?'Submitting...':'Submit assignment')),
          if(status=='returned')const Padding(padding:EdgeInsets.only(top:10),child:_InfoNotice(message:'Your tutor returned this work for correction. Update your answer and submit it again.')),
        ]else...[
          const _InfoNotice(message:'Your work has been submitted and is awaiting tutor marking, or has already been graded. You cannot change it unless your tutor returns it for correction.'),
          if(a['answer_text']!=null)Card(child:Padding(padding:const EdgeInsets.all(15),child:SelectableText(a['answer_text'].toString(),style:const TextStyle(height:1.5,color:AppColors.ink)))),
          if(a['score']!=null)Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Score: '+a['score'].toString()+(a['max_score']==null?'':' / '+a['max_score'].toString()),style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
            if(a['tutor_feedback']!=null&&a['tutor_feedback'].toString().isNotEmpty)...[
              const SizedBox(height:8),const Text('Tutor feedback',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.brown)),
              const SizedBox(height:5),Text(a['tutor_feedback'].toString(),style:const TextStyle(height:1.5)),
            ],
          ]))),
        ],
      ]));
  }
}

class StudentAssessmentsPage extends StatefulWidget {
  const StudentAssessmentsPage({super.key});
  @override
  State<StudentAssessmentsPage> createState() => _StudentAssessmentsPageState();
}
class _StudentAssessmentsPageState extends State<StudentAssessmentsPage> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() { super.initState(); _items = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await Supabase.instance.client.rpc('student_available_assessments');
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _items = next); await next; }
  Future<void> _openHistory() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StudentAssessmentHistoryPage()));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Practice and mock tests'),
      actions: [IconButton(tooltip: 'My results', onPressed: _openHistory, icon: const Icon(Icons.history_rounded))]),
    body: RefreshIndicator(color: AppColors.brown, onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(future: _items, builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
        if (snap.hasError) return ListView(padding: const EdgeInsets.all(22), children: const [_InfoNotice(message: 'Practice tests could not be loaded. Check your connection and try again.')]);
        final items = snap.data ?? [];
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Available for your class', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('Only tests published for your active class enrolment appear here.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: _openHistory, icon: const Icon(Icons.history_rounded), label: const Text('View my previous results')),
          const SizedBox(height: 14),
          if (items.isEmpty) const _InfoNotice(message: 'There are no published practice tests for your current class yet. Your tutor will publish eligible tests here when they are ready.'),
          ...items.map((item) {
            final count = (item['question_count'] as num?)?.toInt() ?? 0;
            final duration = (item['duration_minutes'] as num?)?.toInt();
            return Padding(padding: const EdgeInsets.only(bottom: 11), child: Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(item['title']?.toString() ?? 'Practice test', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(
                (item['subject_name']?.toString() ?? 'Subject') + ' • ' +
                (item['class_name']?.toString() ?? 'Class') + ' • ' +
                count.toString() + ' questions' +
                ((duration != null && duration > 0) ? ' • ' + duration.toString() + ' minutes' : ''),
                style: const TextStyle(color: AppColors.muted))),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17, color: AppColors.brown),
              onTap: count == 0 ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => StudentAssessmentRunnerPage(assessment: item))),
            )));
          }),
        ]);
      })),
  );
}

class StudentAssessmentHistoryPage extends StatefulWidget {
  const StudentAssessmentHistoryPage({super.key});
  @override
  State<StudentAssessmentHistoryPage> createState() => _StudentAssessmentHistoryPageState();
}
class _StudentAssessmentHistoryPageState extends State<StudentAssessmentHistoryPage> {
  late Future<List<Map<String,dynamic>>> _history;
  @override
  void initState() { super.initState(); _history = _load(); }
  Future<List<Map<String,dynamic>>> _load() async {
    final raw = await Supabase.instance.client.rpc('student_assessment_history');
    if (raw is! List) return [];
    return raw.map((e) => Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _history = next); await next; }
  String _date(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return 'Date unavailable';
    final d = parsed.toLocal();
    return d.day.toString().padLeft(2,'0') + '/' + d.month.toString().padLeft(2,'0') + '/' + d.year.toString();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My assessment results')),
    body: RefreshIndicator(color: AppColors.brown,onRefresh:_refresh,
      child: FutureBuilder<List<Map<String,dynamic>>>(future:_history,builder:(context,snap){
        if(snap.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(snap.hasError)return ListView(padding:const EdgeInsets.all(22),children:[_InfoNotice(message:'Your result history could not be loaded. '+snap.error.toString())]);
        final rows=snap.data??[];
        if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(22),children:const [
          _InfoNotice(message:'You have not submitted any assessments yet. Completed tests will appear here with their scores and dates.')
        ]);
        return ListView(padding:const EdgeInsets.all(18),children:[
          const Text('Your completed tests',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:6),
          const Text('Scores are saved against your learner account.',style:TextStyle(color:AppColors.muted)),
          const SizedBox(height:14),
          ...rows.map((r){
            final pct=(r['percentage'] as num?)?.toDouble();
            final score=(r['score'] as num?)??0;
            final total=(r['total_marks'] as num?)??0;
            final passed=pct!=null&&pct>=50;
            return Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:Padding(
              padding:const EdgeInsets.all(15),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Container(width:48,height:48,decoration:BoxDecoration(color:AppColors.paleGold,borderRadius:BorderRadius.circular(12)),
                  child:Icon(Icons.assignment_turned_in_outlined,color:AppColors.brown)),
                const SizedBox(width:13),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(r['assessment_title']?.toString()??'Assessment',style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
                  const SizedBox(height:4),
                  Text((r['subject_name']??'Subject').toString()+' • '+(r['class_name']??'Class').toString()+' • '+(r['assessment_type']??'Test').toString(),
                    style:const TextStyle(color:AppColors.muted,fontSize:12)),
                  const SizedBox(height:7),
                  Text(_date(r['submitted_at']),style:const TextStyle(color:AppColors.muted,fontSize:12)),
                  const SizedBox(height:6),
                  Text(score.toString()+' / '+total.toString()+' marks',
                    style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
                ])),
                const SizedBox(width:8),
                Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                  Text(pct==null?'—':pct.toStringAsFixed(1)+'%',
                    style:TextStyle(fontWeight:FontWeight.w800,fontSize:18,color:passed?Colors.green.shade700:AppColors.brown)),
                  Text(passed?'Good progress':'Keep practising',style:const TextStyle(fontSize:10,color:AppColors.muted)),
                ]),
              ]),
            )));
          }),
        ]);
      })),
  );
}

class StudentAssessmentRunnerPage extends StatefulWidget {
  final Map<String, dynamic> assessment;
  const StudentAssessmentRunnerPage({super.key, required this.assessment});
  @override
  State<StudentAssessmentRunnerPage> createState() => _StudentAssessmentRunnerPageState();
}
class _StudentAssessmentRunnerPageState extends State<StudentAssessmentRunnerPage> {
  late Future<List<Map<String, dynamic>>> _questions;
  final Map<String, dynamic> _answers = {};
  Timer? _timer;
  int _remaining = 0;
  bool _submitting = false;
  String? _loadError;
  String? _attemptId;
  @override
  void initState() {
    super.initState();
    _questions = _loadQuestions();
  }
  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    try {
      final started = await Supabase.instance.client.rpc('start_student_assessment',
        params: {'p_assessment_id': widget.assessment['id']});
      final startData = Map<String, dynamic>.from(started as Map);
      _attemptId = startData['attempt_id']?.toString();
      final mins = (startData['duration_minutes'] as num?)?.toInt() ?? 0;
      _remaining = (startData['remaining_seconds'] as num?)?.toInt() ?? (mins > 0 ? mins * 60 : 0);
      final raw = await Supabase.instance.client.rpc('student_assessment_questions',
        params: {'p_attempt_id': _attemptId});
      if (raw is! List) return [];
      final rows = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (rows.isNotEmpty && _remaining > 0) _startTimer();
      return rows;
    } catch (e) { _loadError = e.toString(); rethrow; }
  }
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _submitting) { timer.cancel(); return; }
      if (_remaining <= 1) {
        setState(() => _remaining = 0); timer.cancel(); _submit(autoSubmit: true);
      } else { setState(() => _remaining--); }
    });
  }
  List<Map<String, dynamic>> _options(Map<String, dynamic> q) {
    final raw = q['options'];
    if (raw is List) return raw.map((v) {
      if (v is Map) {
        final value = v['value'] ?? v['key'] ?? v['label'] ?? '';
        return {'value': value, 'label': (v['label'] ?? v['text'] ?? value).toString()};
      }
      return {'value': v, 'label': v.toString()};
    }).toList();
    if (raw is Map) return raw.entries.map((e) {
      final v = e.value;
      return {'value': e.key, 'label': (v is Map ? (v['label'] ?? v['text'] ?? e.key) : v).toString()};
    }).toList();
    return [];
  }
  Future<void> _submit({bool autoSubmit = false}) async {
    if (_submitting) return;
    if (!autoSubmit) {
      final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        title: const Text('Submit your answers?'),
        content: Text('You have answered ' + _answers.length.toString() + ' question(s). Unanswered questions will be marked incorrect.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Continue test')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Submit test')),
        ]));
      if (ok != true || !mounted) return;
    }
    setState(() => _submitting = true); _timer?.cancel();
    try {
      final raw = await Supabase.instance.client.rpc('submit_student_assessment',
        params: {'p_attempt_id': _attemptId, 'p_answers': _answers});
      final result = Map<String, dynamic>.from(raw as Map);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => StudentAssessmentResultPage(assessment: widget.assessment, result: result, autoSubmitted: autoSubmit)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your test could not be submitted: ' + e.toString())));
    }
  }
  String get _clock => (_remaining ~/ 60).toString().padLeft(2, '0') + ':' + (_remaining % 60).toString().padLeft(2, '0');
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.assessment['title']?.toString() ?? 'Assessment'),
      actions: [_remaining > 0 ? Padding(padding: const EdgeInsets.only(right: 16),
        child: Center(child: Text(_clock, style: TextStyle(fontWeight: FontWeight.w800,
          color: _remaining <= 60 ? Colors.red.shade700 : AppColors.brown)))) : const SizedBox.shrink()]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _questions, builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.brown));
      if (snap.hasError) return Padding(padding: const EdgeInsets.all(22), child: _InfoNotice(message: 'This assessment is unavailable. ' + (_loadError ?? '')));
      final qs = snap.data ?? [];
      if (qs.isEmpty) return const Padding(padding: EdgeInsets.all(22), child: _InfoNotice(message: 'This assessment does not contain questions yet.'));
      return Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), children: [
          Text(qs.length.toString() + ' questions • ' + (widget.assessment['subject_name']?.toString() ?? ''),
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...List.generate(qs.length, (index) {
            final q = qs[index]; final id = q['id'].toString(); final options = _options(q);
            return Padding(padding: const EdgeInsets.only(bottom: 14), child: Card(child: Padding(
              padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('QUESTION ' + (index + 1).toString(), style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.gold)),
                const SizedBox(height: 9),
                Text(q['question_text']?.toString() ?? '', style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink)),
                if (options.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('No answer options configured for this question.', style: TextStyle(color: AppColors.muted))),
                ...options.map((o) => RadioListTile<dynamic>(
                  contentPadding: EdgeInsets.zero, dense: true, activeColor: AppColors.brown,
                  value: o['value'], groupValue: _answers[id],
                  onChanged: _submitting ? null : (v) => setState(() => _answers[id] = v),
                  title: Text(o['label'].toString(), style: const TextStyle(color: AppColors.ink)),
                )),
              ]))));
          }),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: SizedBox(width: double.infinity, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brown, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _submitting ? null : () => _submit(),
            child: Text(_submitting ? 'Submitting…' : 'Submit assessment'),
          )))),
      ]);
    }),
  );
}

class StudentAssessmentResultPage extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> result;
  final bool autoSubmitted;
  const StudentAssessmentResultPage({super.key, required this.assessment, required this.result, required this.autoSubmitted});
  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as num?) ?? 0;
    final total = (result['total_marks'] as num?) ?? 0;
    final percent = (result['percentage'] as num?) ?? 0;
    final review = result['review'] is List
      ? (result['review'] as List).map((e) => Map<String,dynamic>.from(e as Map)).toList()
      : <Map<String,dynamic>>[];
    return Scaffold(appBar: AppBar(title: const Text('Assessment result'), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const SizedBox(height: 24),
        const Icon(Icons.assignment_turned_in_outlined, size: 58, color: AppColors.gold),
        const SizedBox(height: 16),
        Text(autoSubmitted ? 'Time is up' : 'Assessment submitted', textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(assessment['title']?.toString() ?? 'Practice test', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 26),
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          Text(percent.toStringAsFixed(1) + '%', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.brown)),
          const SizedBox(height: 5),
          Text(score.toString() + ' / ' + total.toString() + ' marks', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text((result['answered'] ?? 0).toString() + ' of ' + (result['question_count'] ?? 0).toString() + ' questions answered', style: const TextStyle(color: AppColors.muted)),
        ]))),
        const SizedBox(height: 18),
        const _InfoNotice(message: 'Your score has been saved to your assessment history. Your tutor or school may review and publish formal results separately.'),
        if (review.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('Answer review',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:10),
          ...review.asMap().entries.map((entry) {
            final index=entry.key;
            final q=entry.value;
            final opts=q['options'] is Map ? Map<String,dynamic>.from(q['options'] as Map) : <String,dynamic>{};
            final selected=q['selected_answer']?.toString()??'Not answered';
            final correct=q['correct_answer']?.toString()??'Not set';
            final selectedLabel=opts[selected]?.toString()??selected;
            final correctLabel=opts[correct]?.toString()??correct;
            final isCorrect=q['is_correct']==true;
            final explanation=q['explanation']?.toString()??'';
            return Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:Padding(
              padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Icon(isCorrect?Icons.check_circle_outline:Icons.highlight_off,
                    color:isCorrect?Colors.green.shade700:Colors.red.shade700,size:20),
                  const SizedBox(width:8),
                  Text('Question '+(index+1).toString(),
                    style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
                  const Spacer(),
                  Text((q['marks']??0).toString()+' mark(s)',style:const TextStyle(fontSize:12,color:AppColors.muted)),
                ]),
                const SizedBox(height:9),
                Text(q['question_text']?.toString()??'',style:const TextStyle(fontWeight:FontWeight.w600,color:AppColors.ink)),
                const SizedBox(height:9),
                Text('Your answer: '+selectedLabel,style:TextStyle(color:isCorrect?Colors.green.shade700:Colors.red.shade700)),
                Text('Correct answer: '+correctLabel,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
                if(explanation.trim().isNotEmpty)...[
                  const SizedBox(height:8),
                  Text('Explanation: '+explanation,style:const TextStyle(color:AppColors.muted,height:1.4)),
                ],
              ]),
            )));
          }),
        ],
        const SizedBox(height: 22),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.brown, padding: const EdgeInsets.symmetric(vertical: 15)),
          onPressed: () => Navigator.of(context).pop(), child: const Text('Back to practice tests')),
      ]));
  }
}

class ExamPreparationPage extends StatelessWidget {
  const ExamPreparationPage({super.key});

  static const bodies = <Map<String, String>>[
    {
      'name': 'WAEC',
      'full': 'West African Examinations Council',
      'exam': 'WASSCE School • WASSCE Private • GCE',
      'url': 'https://waecnigeria.org/',
      'logo': 'https://waecinternational.org/timetable/images/logo.png',
      'domain': 'waecnigeria.org',
      'stage': 'SS3 and eligible private candidates',
      'note': 'WASSCE school candidates are generally in SS3. Private-candidate routes are for eligible candidates outside the school-candidate route.',
    },
    {
      'name': 'NECO',
      'full': 'National Examinations Council',
      'exam': 'SSCE Internal • SSCE External • BECE • NCEE • NGE',
      'url': 'https://neco.gov.ng/',
      'logo': 'https://d1jcea4y7xhp7l.cloudfront.net/2021/01/neco-timetable-novdec-e1457601333710.jpg',
      'domain': 'neco.gov.ng',
      'stage': 'Primary 6 • JSS3 • SS3',
      'note': 'NCEE is for pupils completing Primary 6; BECE is for eligible JSS3 candidates; SSCE is the senior secondary certificate route.',
    },
    {
      'name': 'JAMB',
      'full': 'Joint Admissions and Matriculation Board',
      'exam': 'UTME • Direct Entry',
      'url': 'https://www.jamb.gov.ng/',
      'logo': 'https://www.jamb.gov.ng/assets/layouts/layout3/img/banner.png',
      'domain': 'jamb.gov.ng',
      'stage': 'SS3 and post-secondary eligible candidates',
      'note': 'UTME and Direct Entry are tertiary-admission pathways. JAMB does not conduct GCE; WAEC and NECO offer external/private-candidate routes.',
    },
    {
      'name': 'NABTEB',
      'full': 'National Business and Technical Examinations Board',
      'exam': 'NBC • NTC • ANBC • ANTC',
      'url': 'https://nabteb.gov.ng/',
      'logo': 'https://jambhub.com/wp-content/uploads/2022/02/National-Business-and-Technical-Examinations-Board-Nabteb.jpg',
      'domain': 'nabteb.gov.ng',
      'stage': 'Senior secondary and technical/vocational candidates',
      'note': 'National business, technical, advanced and modular trade certificate pathways.',
    },
    {
      'name': 'NBAIS',
      'full': 'National Board for Arabic and Islamic Studies',
      'exam': 'SAISSCE • Tahfeez and related pathways',
      'url': 'https://nbais.gov.ng/',
      'logo': 'https://wazobianet.com/static/landing/assets/images/parters/nbais.jpg',
      'domain': 'nbais.gov.ng',
      'stage': 'Learners in recognised Arabic and Islamic studies pathways',
      'note': 'SAISSCE, Tahfeez and related Arabic and Islamic studies certification pathways.',
    },
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open $url');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Examination Preparation')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Prepare with recognised Nigerian examination bodies',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text('Choose an examination pathway for official information, or open the practice centre to take tests published for your current class.',
          style: TextStyle(color: AppColors.muted, height: 1.5)),
        const SizedBox(height: 18),
        Card(child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(width: 46, height: 46,
            decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.quiz_outlined, color: AppColors.brown)),
          title: const Text('Practice tests and mock examinations',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          subtitle: const Text('Take timed tests published for your class and review your score.'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const StudentAssessmentsPage())),
        )),
        const SizedBox(height: 18),
        ...bodies.map((body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    body['logo']!,
                    width: 52, height: 52,
                    fit: body['name'] == 'JAMB' ? BoxFit.cover : BoxFit.contain,
                    alignment: body['name'] == 'JAMB' ? Alignment.centerRight : Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52, height: 52, alignment: Alignment.center,
                      color: AppColors.paleGold,
                      child: Text(body['name']!.substring(0, 1),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brown)),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(body['name']!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(body['full']!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Text(body['exam']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brown)),
                  const SizedBox(height: 5),
                  Text('Recommended stage: ${body['stage']!}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brown)),
                  const SizedBox(height: 5),
                  Text(body['note']!, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      try { await _open(body['url']!); }
                      catch (_) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The official website could not be opened. Please try again.')));
                      }
                    },
                    child: Text('Visit official website  ↗',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ])),
              ]),
            ),
          ),
        )),
        const _InfoNotice(message: 'Examination-body emblems are displayed for identification and are not partnership badges. Young Learners Tutorial is an independent preparation platform, not an examination-body registration or certification portal.'),
      ],
    ),
  );
}
