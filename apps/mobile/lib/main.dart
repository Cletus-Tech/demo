import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
              if (permissions.contains('students.manage')) ...[
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
                  title: const Text('Academic management'),
                  subtitle: const Text('Create and manage classes, subjects and lessons'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminAcademicPage()),
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
                const _InfoNotice(message: 'Finance management access is active. Fee and payment management tools are being added next.'),
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
  @override
  void initState() { super.initState(); _rows = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final data = await Supabase.instance.client.from('students')
      .select('id,admission_number,level,status,user_id,profiles(full_name,email)')
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
  Future<void> _add() async {
    final admission = TextEditingController();
    final level = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add student record'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: admission, decoration: const InputDecoration(labelText: 'Admission number')),
        const SizedBox(height: 10),
        TextField(controller: level, decoration: const InputDecoration(labelText: 'Class / level')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
      ],
    ));
    if (ok == true && admission.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('students').insert({
          'admission_number': admission.text.trim(),
          'level': level.text.trim().isEmpty ? null : level.text.trim(),
        });
        setState(() => _rows = _load());
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create student: $e')));
      }
    }
    admission.dispose(); level.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student records')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add, backgroundColor: AppColors.brown, foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add_alt_1), label: const Text('Add student')),
    body: RefreshIndicator(onRefresh: () async => setState(() => _rows = _load()),
      child: FutureBuilder<List<Map<String, dynamic>>>(future: _rows, builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return ListView(padding: const EdgeInsets.all(20), children: const [
          _InfoNotice(message: 'Student records could not be loaded. Check that student-management permission has been assigned.'),
        ]);
        final rows = s.data ?? [];
        if (rows.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: const [
          _InfoNotice(message: 'No student records yet. Use Add student to create the first centre record.'),
        ]);
        return ListView.separated(padding: const EdgeInsets.fromLTRB(16,16,16,90), itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = rows[i];
            final p = r['profiles'] as Map<String, dynamic>?;
            return Card(child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => _StudentRecordDetailPage(student: r),
              )),
              title: Text(p?['full_name'] as String? ?? 'Account not linked'),
              subtitle: Text('Admission: ' + (r['admission_number'] ?? 'Not assigned').toString() +
                '  •  Level: ' + (r['level'] ?? 'Not set').toString() +
                '  •  Status: ' + (r['status'] ?? '').toString()),
              trailing: const Icon(Icons.chevron_right_rounded),
            ));
          });
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
      _safeRows(() => db.from('attendance_records').select('id,status,attended_at,note').eq('student_id', id).order('attended_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assignment_submissions').select('id,status,score,submitted_at,assignments(title)').eq('student_id', id).order('submitted_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assessment_attempts').select('id,score,submitted_at,assessments(title)').eq('student_id', id).order('started_at', ascending: false).limit(20)),
      _safeRows(() => db.from('results').select('id,score,grade,published_at,tutor_comment,subjects(name)').eq('student_id', id).order('created_at', ascending: false).limit(20)),
      _safeRows(() => db.from('invoices').select('id,description,amount,currency,status,due_at').eq('student_id', id).order('created_at', ascending: false).limit(20)),
    ]);
    return {
      'enrolments': values[0], 'attendance': values[1],
      'submissions': values[2], 'assessments': values[3],
      'results': values[4], 'invoices': values[5],
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
                  Text('Admission: ${student['admission_number'] ?? 'Not assigned'}'),
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
                (r) => _date(r['attended_at']) + (r['note'] == null ? '' : ' • ${r['note']}')),
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
              _section('School fees', data['invoices'] ?? [],
                'No fee invoices recorded.',
                (r) => (r['description'] ?? 'Invoice').toString(),
                (r) => '${r['currency'] ?? 'NGN'} ${r['amount']} • ${r['status']}'),
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
  late Future<List<Map<String, dynamic>>> _classes, _subjects, _lessons, _sessions;
  bool _busy = false;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); _reload(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
  void _reload() {
    final db = Supabase.instance.client;
    _classes = db.from('classes').select('id,name,level,capacity,status').order('name');
    _subjects = db.from('subjects').select('id,name,code,description,status').order('name');
    _lessons = db.from('lessons').select('id,title,description,content,class_id,subject_id,is_published,classes(name),subjects(name)').order('created_at', ascending: false);
    _sessions = db.from('academic_sessions').select('id,name,starts_on,ends_on,is_current').order('starts_on', ascending: false);
  }
  Future<void> _refresh() async { setState(_reload); await Future.wait([_classes,_subjects,_lessons,_sessions]); }
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
  Future<void> _editSession([Map<String,dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString() ?? '');
    final starts = TextEditingController(text: row?['starts_on']?.toString() ?? '');
    final ends = TextEditingController(text: row?['ends_on']?.toString() ?? '');
    bool current = row?['is_current'] == true;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
      title: Text(row == null ? 'Create academic session' : 'Edit academic session'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Session name (e.g. 2026/2027)')),
        TextField(controller: starts, decoration: const InputDecoration(labelText: 'Start date (YYYY-MM-DD)')),
        TextField(controller: ends, decoration: const InputDecoration(labelText: 'End date (YYYY-MM-DD)')),
        CheckboxListTile(value: current, contentPadding: EdgeInsets.zero, title: const Text('Set as current session'),
          onChanged: (v) => refreshDialog(() => current = v ?? false)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save session'))],
    )));
    final startDate = DateTime.tryParse(starts.text.trim());
    final endDate = DateTime.tryParse(ends.text.trim());
    if (ok == true) {
      if (name.text.trim().isEmpty || startDate == null || endDate == null || !endDate.isAfter(startDate)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a session name and valid dates. The end date must be after the start date.')));
      } else {
        try {
          final db = Supabase.instance.client;
          if (current) await db.from('academic_sessions').update({'is_current': false}).neq('id', row?['id'] ?? '00000000-0000-0000-0000-000000000000');
          final values = {'name': name.text.trim(), 'starts_on': starts.text.trim(),
            'ends_on': ends.text.trim(), 'is_current': current};
          if (row == null) { await db.from('academic_sessions').insert(values); }
          else { await db.from('academic_sessions').update(values).eq('id', row['id']); }
          await _refresh();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save session: ' + e.toString())));
        }
      }
    }
    name.dispose(); starts.dispose(); ends.dispose();
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
  Widget _err(Object? e)=>Padding(padding:const EdgeInsets.all(16),child:_InfoNotice(message:'Could not load this section. Check access or connection, then retry. ' + e.toString()));
  Widget _sessionsTab()=>FutureBuilder<List<Map<String,dynamic>>>(future:_sessions,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return _err(s.error); final rows=s.data ?? [];
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Academic sessions',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink))),
        FilledButton.icon(onPressed:_busy?null:()=>_editSession(),icon:const Icon(Icons.add),label:const Text('Add session'))]),
      const Padding(padding:EdgeInsets.only(top:8,bottom:12),child:Text('Create a session before enrolling students. Only one session should be current at a time.',style:TextStyle(color:AppColors.muted))),
      if(rows.isEmpty)const _InfoNotice(message:'No academic session has been created yet. Add the centre current session to enable enrolment.'),
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['name'].toString()),
        subtitle:Text(r['starts_on'].toString() + ' to ' + r['ends_on'].toString() + ' • ' + (r['is_current']==true?'Current':'Not current')),
        trailing:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>_editSession(r))))),
    ]);
  });
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
    appBar:AppBar(title:const Text('Academic management'),bottom:TabBar(controller:_tabs,tabs:const[
      Tab(text:'Classes'),Tab(text:'Subjects'),Tab(text:'Lessons'),Tab(text:'Sessions'),
    ])),
    body:RefreshIndicator(onRefresh:_refresh,child:TabBarView(controller:_tabs,children:[
      _classesTab(),_subjectsTab(),_lessonsTab(),_sessionsTab(),
    ])),
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
  final bool owner;
  final bool admin;
  const LearnerHomePage({super.key, this.owner = false, this.admin = false});
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
            onOpenCentre: () => _openCentrePortal(),
          ),
          _LearningTab(owner: widget.owner, admin: widget.admin),
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
  final VoidCallback onOpenCentre;
  const _HomeTab({
    required this.account,
    required this.onOpenLearning,
    required this.owner,
    required this.admin,
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
                Text(owner ? 'OWNER DASHBOARD' : admin ? 'CENTRE DASHBOARD' : 'LEARNER PORTAL',
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

class _LearningTab extends StatefulWidget {
  final bool owner;
  final bool admin;
  const _LearningTab({this.owner = false, this.admin = false});
  @override
  State<_LearningTab> createState() => _LearningTabState();
}
class _LearningTabState extends State<_LearningTab> {
  late Future<List<Map<String, dynamic>>> _lessons;
  @override
  void initState() { super.initState(); _lessons = _loadLessons(); }
  Future<List<Map<String, dynamic>>> _loadLessons() async {
    final db = Supabase.instance.client;
    var query = db.from('lessons')
      .select('id,title,description,content,scheduled_at,duration_minutes,subjects(name),classes(name)')
      .eq('is_published', true);
    // Owners and authorised administrators can inspect the centre's published
    // catalogue. Learners only receive lessons for their active enrolments.
    if (!widget.owner && !widget.admin) {
      final enrolments = await db.from('enrolments')
        .select('class_id').eq('status', 'active');
      final classIds = enrolments.map((row) => row['class_id'].toString()).toSet().toList();
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
      const Text('My learning', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 7),
      const Text('Open a lesson to read its notes and learning materials.', style: TextStyle(color: AppColors.muted, height: 1.45)),
      const SizedBox(height: 20),
      Card(
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
      client.from('assignment_submissions').select('id').eq('student_id', studentId),
      client.from('assessment_attempts').select('id').eq('student_id', studentId),
      client.from('results').select('id').eq('student_id', studentId).not('published_at', 'is', null),
    ]);
    return {
      'linked': true,
      'enrolments': values[0].length,
      'submissions': values[1].length,
      'attempts': values[2].length,
      'results': values[3].length,
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
        const Text('Choose an examination pathway to view its official website. Practice tests and mock examinations will be organised by the learner’s class and eligible examination.',
          style: TextStyle(color: AppColors.muted, height: 1.5)),
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
        const _InfoNotice(message: 'Examination-body logos are loaded as site icons from their official website domains. They are not recreated or presented as partnership badges. Young Learners Tutorial is an independent preparation platform, not an examination-body registration or certification portal.'),
      ],
    ),
  );
}
