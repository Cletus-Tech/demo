import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_access.dart';
import 'result_management.dart';
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

class AppThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  static const _key = 'young_learners_theme_mode';
  static Future<void> load() async { final p = await SharedPreferences.getInstance(); mode.value = p.getBool(_key) == true ? ThemeMode.dark : ThemeMode.light; }
  static Future<void> setDark(bool dark) async { mode.value = dark ? ThemeMode.dark : ThemeMode.light; final p = await SharedPreferences.getInstance(); await p.setBool(_key, dark); }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.load();
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

class YoungLearnersLogo extends StatelessWidget {
  final bool compact;
  const YoungLearnersLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brandText = dark ? const Color(0xFFFFE8B2) : AppColors.brown;
    Widget bookMark(double width, double height) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFFFFF7E7) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.gold, width: dark ? 1.6 : 1),
        boxShadow: dark ? [
          BoxShadow(color: AppColors.gold.withValues(alpha: .22), blurRadius: 12, spreadRadius: 1),
        ] : const [],
      ),
      child: SvgPicture.asset('assets/young_learners_logo.svg',
        width: width, height: height, fit: BoxFit.contain),
    );
    if (compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('YL', style: TextStyle(
            fontFamily: 'Georgia', fontSize: 23, height: .85,
            fontWeight: FontWeight.w900, letterSpacing: -2, color: brandText)),
          bookMark(38, 24),
        ]),
        const SizedBox(width: 6),
        Container(width: 2, height: 43, color: AppColors.gold),
        const SizedBox(width: 7),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUNG LEARNERS', style: TextStyle(
            fontSize: 11, height: 1, fontWeight: FontWeight.w900,
            letterSpacing: .1, color: brandText)),
          const SizedBox(height: 3),
          const _TutorialWordmark(compact: true),
        ]),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('YL', style: TextStyle(
            fontFamily: 'Georgia', fontSize: 37, height: .85,
            fontWeight: FontWeight.w900, letterSpacing: -3, color: brandText)),
          bookMark(62, 34),
        ]),
        const SizedBox(width: 10),
        Container(width: 2, height: 70, color: AppColors.gold),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUNG LEARNERS', maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 17, height: 1, fontWeight: FontWeight.w900,
              letterSpacing: .1, color: brandText)),
          const SizedBox(height: 5),
          const _TutorialWordmark(),
        ]),
      ]),
      const SizedBox(height: 5),
      Text('EVERY CHILD CAN LEARN',
        style: TextStyle(fontSize: 10, letterSpacing: 1.1,
          fontWeight: FontWeight.w700, color: brandText)),
    ]);
  }
}

class _TutorialWordmark extends StatelessWidget {
  final bool compact;
  const _TutorialWordmark({this.compact = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 9, vertical: compact ? 1 : 3),
    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
    child: Text('TUTORIAL', style: TextStyle(
      fontSize: compact ? 8 : 12, height: 1, fontWeight: FontWeight.w900,
      letterSpacing: compact ? .8 : 2, color: AppColors.brown)),
  );
}

class YoungLearnersApp extends StatelessWidget {
  const YoungLearnersApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: AppThemeController.mode,
    builder: (context, mode, _) {
      final lightScheme = ColorScheme.fromSeed(seedColor: AppColors.brown, primary: AppColors.brown, secondary: AppColors.gold, surface: Colors.white);
      final darkScheme = ColorScheme.fromSeed(seedColor: AppColors.gold, primary: const Color(0xFFE5C27A), secondary: AppColors.gold, surface: const Color(0xFF24211E), brightness: Brightness.dark);
      return MaterialApp(
        title: 'Young Learners Tutorial',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true, colorScheme: lightScheme,
          scaffoldBackgroundColor: AppColors.cream,
          appBarTheme: const AppBarTheme(backgroundColor: AppColors.cream, foregroundColor: AppColors.ink, elevation: 0),
          cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line))),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brown, width: 1.4))),
        ),
        darkTheme: ThemeData(
          useMaterial3: true, brightness: Brightness.dark, colorScheme: darkScheme,
          scaffoldBackgroundColor: const Color(0xFF171513),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF171513), foregroundColor: Color(0xFFF4EFE8), elevation: 0),
          cardTheme: CardThemeData(color: const Color(0xFF24211E), elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF3B342D)))),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF2B2723), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF494037))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF494037))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold, width: 1.4))),
        ),
        home: const AuthGate(),
      );
    },
  );
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
    final client = Supabase.instance.client;
    final rows = await client.from('user_roles')
        .select('role').eq('user_id', user.id);
    final roles = List<Map<String, dynamic>>.from(rows)
        .map((e) => e['role'] as String).toList();
    final profile = await client.from('profiles')
        .select('account_type').eq('id', user.id).maybeSingle();
    if (profile?['account_type'] == 'parent') {
      roles.add('parent_account');
    } else if (profile?['account_type'] == 'student' &&
        !roles.any((r) => ['super_admin', 'admin', 'tutor', 'staff'].contains(r))) {
      final student = await client.from('students')
          .select('id,level').eq('user_id', user.id).maybeSingle();
      if (student == null || (student['level'] as String? ?? '').trim().isEmpty) {
        roles.add('class_missing');
      }
    }
    return roles;
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
      if (roles.contains('class_missing')) {
        return StudentClassSetupPage(onComplete: () {
          if (mounted) setState(() => _roles = _load());
        });
      }
      // Every authenticated account enters the same connected app shell.
      // Owner/admin tools are role-aware destinations inside the main dashboard,
      // not a replacement for the learner-facing home experience.
      return LearnerHomePage(
        owner: roles.contains('super_admin'),
        admin: roles.contains('admin') || roles.contains('super_admin'),
        tutor: roles.contains('tutor'),
        staffMember: roles.contains('staff'),
        parent: roles.contains('parent_account'),
      );
    },
  );
}



class StudentClassSetupPage extends StatefulWidget {
  final VoidCallback onComplete;
  const StudentClassSetupPage({super.key, required this.onComplete});
  @override
  State<StudentClassSetupPage> createState() => _StudentClassSetupPageState();
}

class _StudentClassSetupPageState extends State<StudentClassSetupPage> {
  static const _levels = [
    'Primary 1', 'Primary 2', 'Primary 3', 'Primary 4', 'Primary 5', 'Primary 6',
    'JSS 1', 'JSS 2', 'JSS 3', 'SS 1', 'SS 2', 'SS 3',
  ];
  String? _level;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_level == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser!;
      final existing = await db.from('students')
          .select('id').eq('user_id', user.id).maybeSingle();
      if (existing == null) {
        await db.from('students').insert({'user_id': user.id, 'level': _level});
      } else {
        await db.from('students').update({'level': _level})
            .eq('id', existing['id']);
      }
      widget.onComplete();
    } catch (e) {
      if (mounted) setState(() => _error = 'Your class could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
        child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: YoungLearnersLogo()),
            const SizedBox(height: 24),
            const Text('Let’s set up your learning space',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Choose the class you are currently in. We’ll use this to organise your lessons, classroom, assignments and learning resources.',
              textAlign: TextAlign.center, style: TextStyle(height: 1.45)),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              value: _level,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select your current class'),
              items: _levels.map((level) => DropdownMenuItem(
                value: level, child: Text(level))).toList(),
              onChanged: _saving ? null : (value) => setState(() => _level = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving || _level == null ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Continue to my dashboard'),
            ),
            const SizedBox(height: 8),
            const Text('You can ask the centre administrator to correct your class if you select the wrong one.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.4)),
          ],
        ))),
      ),
    ))),
  );
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});
  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late Future<Map<String,dynamic>> _report;
  @override
  void initState() { super.initState(); _report = _load(); }
  Future<Map<String,dynamic>> _load() async {
    final raw = await Supabase.instance.client.rpc('admin_centre_reports');
    return Map<String,dynamic>.from(raw as Map);
  }
  Future<void> _refresh() async { final next = _load(); setState(() => _report = next); await next; }
  String _money(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '') ?? 0;
    return '₦' + n.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
  String _figure(dynamic value) {
    final raw = value?.toString() ?? '0';
    final parsed = num.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return raw;
    final parts = parsed.toString().split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 && parts[1] != '0' ? '$whole.${parts[1]}' : whole;
  }
  Widget _metric(String label, dynamic value, {String? hint}) => Builder(
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Expanded(child: Card(
        child: Padding(padding: const EdgeInsets.all(13), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_figure(value), style: TextStyle(
              fontSize: 23, fontWeight: FontWeight.w900, color: colors.primary,
              fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
            if (hint != null) Text(hint, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
          ],
        )),
      ));
    });
  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 11,
          letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.muted)),
        const SizedBox(height: 8), ...children,
      ],
    ));
  Widget _line(String label, dynamic value, {String? trailing}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.ink))),
      Text(trailing ?? (value?.toString() ?? '0'),
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Centre reports & analytics')),
    body: RefreshIndicator(color: AppColors.brown, onRefresh: _refresh,
      child: FutureBuilder<Map<String,dynamic>>(future: _report, builder: (context,s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: AppColors.brown));
        if (s.hasError) return ListView(padding: const EdgeInsets.all(20), children: [
          _InfoNotice(message: 'Centre reports could not be loaded: ${s.error}')
        ]);
        final data=s.data!;
        final overview=Map<String,dynamic>.from(data['overview'] as Map);
        final requests=Map<String,dynamic>.from(data['requests'] as Map);
        final finance=Map<String,dynamic>.from(data['finance'] as Map);
        final attendance=Map<String,dynamic>.from(data['attendance'] as Map);
        final assignments=Map<String,dynamic>.from(data['assignments'] as Map);
        final assessments=Map<String,dynamic>.from(data['assessments'] as Map);
        final classes=List<Map<String,dynamic>>.from(data['class_summary'] as List);
        final recent=List<Map<String,dynamic>>.from(data['recent_requests'] as List);
        return ListView(padding: const EdgeInsets.fromLTRB(16,16,16,32), children: [
          const Text('A live view of centre activity', style: TextStyle(
            fontSize: 23,fontWeight: FontWeight.w800,color: AppColors.ink)),
          const SizedBox(height: 5),
          const Text('Figures are calculated from saved records. Refresh to see the latest activity.',
            style: TextStyle(color: AppColors.muted)),
          _section('People & programmes', [
            Row(children:[
              _metric('Accounts',overview['registered_accounts']),
              _metric('Students',overview['student_accounts']),
            ]),
            Row(children:[
              _metric('Parents',overview['parent_accounts']),
              _metric('Active tutors',overview['active_tutors']),
            ]),
            Row(children:[
              _metric('Approved learners',overview['approved_learners']),
              _metric('Active programmes',overview['active_programmes']),
            ]),
          ]),
          _section('Learning access requests', [
            Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),child:Column(children:[
              _line('Awaiting payment',requests['awaiting_payment']),
              const Divider(height:1),
              _line('Payment submitted',requests['payment_submitted']),
              const Divider(height:1),
              _line('Approved',requests['approved']),
              const Divider(height:1),
              _line('Rejected / needs attention',requests['rejected']),
            ]))),
          ]),
          _section('Payment overview', [
            Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),child:Column(children:[
              _line('Awaiting payment verification',null,trailing:_money(finance['awaiting_verification'])),
              const Divider(height:1),
              _line('Verified payments',null,trailing:_money(finance['verified_payments'])),
              const Divider(height:1),
              _line('Approved programme value',null,trailing:_money(finance['approved_programme_value'])),
            ]))),
            const Padding(padding: EdgeInsets.only(top:5),child:Text(
              'Amounts awaiting verification are learner-submitted claims, not confirmed revenue.',
              style:TextStyle(fontSize:11,color:AppColors.muted))),
          ]),
          _section('Attendance', [
            Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),child:Column(children:[
              _line('Total attendance records',attendance['total_records']),
              const Divider(height:1),
              _line('Present',attendance['present']),
              const Divider(height:1),
              _line('Late',attendance['late']),
              const Divider(height:1),
              _line('Absent',attendance['absent']),
              const Divider(height:1),
              _line('Excused',attendance['excused']),
            ]))),
          ]),
          _section('Assignments & assessments', [
            Row(children:[
              _metric('Published assignments',assignments['published']),
              _metric('Submissions',assignments['submissions']),
            ]),
            Row(children:[
              _metric('Graded',assignments['graded']),
              _metric('Awaiting review',assignments['awaiting_review']),
            ]),
            Row(children:[
              _metric('Published tests',assessments['published']),
              _metric('Past-question sets',assessments['past_question_sets']),
            ]),
            Row(children:[
              _metric('Completed CBT attempts',assessments['completed_attempts']),
              _metric('Average CBT score',assessments['average_percentage']==null?'—':'${assessments['average_percentage']}%'),
            ]),
          ]),
          _section('Programme / class activity', [
            if(classes.isEmpty) const _InfoNotice(message:'No learning programmes have been configured yet.'),
            ...classes.map((c)=>Card(child:ListTile(
              title:Text((c['class_name']??'Class').toString(),
                style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
              subtitle:Text('${c['stage']??''} • ${c['level']??''} • ${c['active']==true?'Active':'Inactive'}'),
              trailing:Text('${c['approved_learners']??0} learners',
                style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.brown)),
            ))),
          ]),
          _section('Recent learning requests', [
            if(recent.isEmpty) const _InfoNotice(message:'No learning access requests have been submitted yet.'),
            ...recent.map((r)=>Card(child:ListTile(
              title:Text((r['learner_name']??'Learner').toString(),
                style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
              subtitle:Text('${r['programme_title']??'Programme'} • ${r['level']??''} • ${r['status']??''}'),
              trailing:Text(_money(r['amount_due']),
                style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.brown)),
            ))),
          ]),
        ]);
      }),
    ),
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
                Card(child: ListTile(
                  leading: const Icon(Icons.assessment_outlined, color: AppColors.brown),
                  title: const Text('Results & report cards'),
                  subtitle: const Text('Enter class scores, calculate grades and release student results'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminResultsPage()),
                )),
                const SizedBox(height: 8),
              ],
              if (permissions.contains('communications.send') && !permissions.contains('staff.manage')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.forum_outlined, color: AppColors.brown),
                  title: const Text('Staff Room'),
                  subtitle: const Text('Private staff conversations and coordinator announcements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const StaffRoomPage(canAnnounce: true)),
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
                Card(child: ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.brown),
                  title: const Text('Billboard appearance'),
                  subtitle: const Text('Change the design of an existing notice without editing its message'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminBillboardAppearancePage()),
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
                  leading: const Icon(Icons.forum_outlined, color: AppColors.brown),
                  title: const Text('Staff Room'),
                  subtitle: const Text('Private staff conversations and coordinator announcements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const StaffRoomPage(canAnnounce: true)),
                )),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: const Icon(Icons.fact_check_outlined, color: AppColors.brown),
                  title: const Text('Tutor Interview Centre'),
                  subtitle: const Text('Review applications, shortlist candidates and schedule interviews'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const TutorInterviewCentrePage(admin: true)),
                )),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: const Icon(Icons.groups_2_outlined, color: AppColors.brown),
                  title: const Text('Staff directory'),
                  subtitle: const Text('Add employees and manage staff-room access'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminEmployeePage()),
                )),
                const SizedBox(height: 8),
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
              if (permissions.contains('reports.view')) ...[
                Card(child: ListTile(
                  leading: const Icon(Icons.insights_outlined, color: AppColors.brown),
                  title: const Text('Centre reports & analytics'),
                  subtitle: const Text('Review learner access, payments, attendance, assignments and CBT activity'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(const AdminReportsPage()),
                )),
                const SizedBox(height: 8),
              ],
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
      .select('id,level,status,user_id,admission_number,created_at,profiles(full_name,email,phone)')
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
  Future<void> _exportExcelDirectory() async {
    try {
      final rows=await _load();
      final workbook=xls.Excel.createExcel();
      workbook.rename('Sheet1','Student Directory');
      final sheet=workbook['Student Directory'];
      sheet.appendRow([
        xls.TextCellValue('Student name'),xls.TextCellValue('Email'),xls.TextCellValue('Phone'),
        xls.TextCellValue('Class'),xls.TextCellValue('Admission number'),
        xls.TextCellValue('Account status'),xls.TextCellValue('Registered on'),
      ]);
      for(final row in rows) {
        final profile=row['profiles'] as Map<String,dynamic>?;
        sheet.appendRow([
          xls.TextCellValue((profile?['full_name']??'').toString()),
          xls.TextCellValue((profile?['email']??'').toString()),
          xls.TextCellValue((profile?['phone']??'').toString()),
          xls.TextCellValue((row['level']??'').toString()),
          xls.TextCellValue((row['admission_number']??'').toString()),
          xls.TextCellValue((row['status']??'').toString()),
          xls.TextCellValue((row['created_at']??'').toString()),
        ]);
      }
      final bytes=workbook.save();
      if(bytes==null)throw Exception('The Excel workbook could not be generated.');
      final saved=await FilePicker.platform.saveFile(
        dialogTitle:'Export Young Learners student directory',
        fileName:'young_learners_student_directory.xlsx',
        type:FileType.custom,allowedExtensions:['xlsx'],
        bytes:Uint8List.fromList(bytes),
      );
      if(saved!=null&&mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Excel student directory exported: ${rows.length} records.')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not export student directory: $e')));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student records'),actions:[
      IconButton(onPressed:_exportExcelDirectory,tooltip:'Export Excel-compatible spreadsheet',
        icon:const Icon(Icons.table_view_outlined)),
    ]),
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
            else ...[
              for (final level in const [
                'Primary 1','Primary 2','Primary 3','Primary 4','Primary 5','Primary 6',
                'JSS 1','JSS 2','JSS 3','SS 1','SS 2','SS 3','Not yet selected','Other',
              ])
                if (filtered.where((r) {
                  final value = (r['level'] ?? '').toString().trim();
                  final group = value.isEmpty ? 'Not yet selected' :
                      (const ['Primary 1','Primary 2','Primary 3','Primary 4','Primary 5','Primary 6',
                        'JSS 1','JSS 2','JSS 3','SS 1','SS 2','SS 3'].contains(value) ? value : 'Other');
                  return group == level;
                }).isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      initiallyExpanded: query.isNotEmpty,
                      leading: const Icon(Icons.school_outlined, color: AppColors.gold),
                      title: Text(level, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${filtered.where((r) {
                        final value = (r['level'] ?? '').toString().trim();
                        final group = value.isEmpty ? 'Not yet selected' :
                            (const ['Primary 1','Primary 2','Primary 3','Primary 4','Primary 5','Primary 6',
                              'JSS 1','JSS 2','JSS 3','SS 1','SS 2','SS 3'].contains(value) ? value : 'Other');
                        return group == level;
                      }).length} student(s)'),
                      children: filtered.where((r) {
                        final value = (r['level'] ?? '').toString().trim();
                        final group = value.isEmpty ? 'Not yet selected' :
                            (const ['Primary 1','Primary 2','Primary 3','Primary 4','Primary 5','Primary 6',
                              'JSS 1','JSS 2','JSS 3','SS 1','SS 2','SS 3'].contains(value) ? value : 'Other');
                        return group == level;
                      }).map((r) {
                        final p = r['profiles'] as Map<String, dynamic>?;
                        return ListTile(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => _StudentRecordDetailPage(student: r),
                          )),
                          title: Text(p?['full_name'] as String? ?? 'Account not linked'),
                          subtitle: Text('${p?['email'] ?? 'No email'} • ${r['status'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        );
                      }).toList(),
                    ),
                  ),
            ],
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
      _safeRows(() => db.from('learning_access_requests').select('id,programme_title,level,amount_due,status,payment_reference,created_at,reviewed_at,admin_note').eq('user_id', widget.student['user_id'])),
      _safeRows(() => db.from('attendance_records').select('id,status,attended_at,attendance_date,note').eq('student_id', id).order('attended_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assignment_submissions').select('id,status,score,submitted_at,assignments(title)').eq('student_id', id).order('submitted_at', ascending: false).limit(20)),
      _safeRows(() => db.from('assessment_attempts').select('id,score,submitted_at,assessments(title)').eq('student_id', id).order('started_at', ascending: false).limit(20)),
      _safeRows(() => db.from('results').select('id,score,grade,ca_score,exam_score,max_ca,max_exam,remark,published_at,tutor_comment,subjects(name),result_periods(title,academic_year)').eq('student_id', id).order('created_at', ascending: false).limit(40)),
      _safeRows(() => db.from('invoices').select('id,description,amount,currency,status,due_at').eq('student_id', id).order('created_at', ascending: false).limit(20)),
      _safeRows(() => db.from('payments').select('id,amount,status,paid_at,provider_reference,invoices!inner(description,student_id)').eq('invoices.student_id', id).order('paid_at', ascending: false).limit(20)),
    ]);
    return {
      'learning_access': values[0], 'attendance': values[1],
      'submissions': values[2], 'assessments': values[3],
      'results': values[4], 'invoices': values[5], 'payments': values[6],
    };
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
      appBar: AppBar(title: const Text('Student profile'),actions:[
        IconButton(tooltip:'Message this student',icon:const Icon(Icons.chat_bubble_outline),
          onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
            builder:(_)=>StudentDirectChatPage(studentId:student['id'].toString(),studentName:name,admin:true)))),
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
              _section('Learning access requests', data['learning_access'] ?? [],
                'No programme requests recorded.',
                (r) => (r['programme_title'] ?? 'Learning programme').toString(),
                (r) => '${r['level'] ?? 'Level not set'} • ₦${r['amount_due'] ?? '-'} • ${r['status'] ?? 'Not set'}'),
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
                (r) => '${r['result_periods']?['title'] ?? 'Result'} ${r['result_periods']?['academic_year'] ?? ''} • CA: ${r['ca_score'] ?? '—'}/${r['max_ca'] ?? '—'} • Exam: ${r['exam_score'] ?? '—'}/${r['max_exam'] ?? '—'} • Total: ${r['score']} • Grade: ${r['grade'] ?? '—'} • ${r['remark'] ?? ''} • ${_date(r['published_at'])}'),
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
int _schoolLevelRank(dynamic value) {
  final label = (value ?? '').toString().toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = RegExp(r'(PRIMARY|JSS|JS|SS)\s*(\d+)').firstMatch(label);
  if (match == null) return 999;
  final stage = match.group(1)!;
  final level = int.tryParse(match.group(2)!) ?? 99;
  final stageRank = stage == 'PRIMARY' ? 0 : (stage == 'JSS' || stage == 'JS') ? 1 : 2;
  return stageRank * 100 + level;
}

List<Map<String, dynamic>> _sortSchoolClasses(List<Map<String, dynamic>> rows) {
  final sorted = List<Map<String, dynamic>>.from(rows);
  sorted.sort((a, b) {
    final aRank = _schoolLevelRank(a['level'] ?? a['name']);
    final bRank = _schoolLevelRank(b['level'] ?? b['name']);
    if (aRank != bRank) return aRank.compareTo(bRank);
    return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
  });
  return sorted;
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
    _classes = db.from('classes').select('id,name,level,capacity,status').then((rows) => _sortSchoolClasses(List<Map<String, dynamic>>.from(rows)));
    _subjects = db.from('subjects').select('id,name,code,description,status').order('name');
    _lessons = db.from('lessons').select('id,title,description,content,live_class_url,class_id,subject_id,is_published,classes(name),subjects(name)').order('created_at', ascending: false);
    _assessments = db.from('assessments').select('id,title,assessment_type,class_id,subject_id,duration_minutes,total_marks,is_published,starts_at,is_past_question,exam_body,exam_year,exam_name,topic,classes(name),subjects(name),questions(id)').order('created_at', ascending: false);
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
    final liveUrl=TextEditingController(text:row?['live_class_url']?.toString() ?? '');
    final duration=TextEditingController(text:row?['duration_minutes']?.toString() ?? '60');
    DateTime? scheduledAt = DateTime.tryParse(row?['scheduled_at']?.toString() ?? '')?.toLocal();
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
          TextButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: ctx,
                initialDate: scheduledAt ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (date == null || !ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: scheduledAt == null ? TimeOfDay.fromDateTime(now) : TimeOfDay.fromDateTime(scheduledAt!),
              );
              if (time == null) return;
              refreshDialog(() => scheduledAt = DateTime(date.year,date.month,date.day,time.hour,time.minute));
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(scheduledAt == null ? 'Schedule live class (optional)' : 'Scheduled: ${scheduledAt!.day.toString().padLeft(2,'0')}/${scheduledAt!.month.toString().padLeft(2,'0')}/${scheduledAt!.year} ${TimeOfDay.fromDateTime(scheduledAt!).format(ctx)}'),
          ),
          TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Class duration in minutes')),
          TextField(controller:desc,minLines:2,maxLines:3,decoration:const InputDecoration(labelText:'Short description')),
          TextField(controller:content,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'Lesson content')),
          TextField(controller:liveUrl,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Live class link (optional)',hintText:'https://...')),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save lesson'))],
      )));
      if(ok==true && title.text.trim().isNotEmpty && classId!=null && subjectId!=null) {
        final meetingLink = liveUrl.text.trim();
        if (meetingLink.isNotEmpty && !meetingLink.startsWith('https://')) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a secure live-class link beginning with https://')));
        } else {
          await _save('lessons',{
            'title':title.text.trim(),'class_id':classId,'subject_id':subjectId,
            'description':desc.text.trim().isEmpty?null:desc.text.trim(),
            'content':content.text.trim().isEmpty?null:content.text.trim(),
            'live_class_url':meetingLink.isEmpty?null:meetingLink,
            'scheduled_at':scheduledAt?.toUtc().toIso8601String(),
            'duration_minutes':int.tryParse(duration.text.trim()),
            'is_published':row?['is_published'] ?? false,
          },id:row?['id']?.toString());
        }
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Lesson form could not load: ' + e.toString())));
    } finally { title.dispose(); desc.dispose(); content.dispose(); liveUrl.dispose(); duration.dispose(); }
  }

  Future<void> _createAssessment() async {
    final title = TextEditingController();
    final duration = TextEditingController(text: '30');
    final examYear = TextEditingController();
    final examName = TextEditingController();
    final topic = TextEditingController();
    final sourceNote = TextEditingController();
    String? examBody;
    bool isPastQuestion = false;
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
          const Divider(height: 22),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: isPastQuestion,
            title: const Text('Add to past-question bank'),
            subtitle: const Text('Use this for verified past questions or exam-style practice.'),
            onChanged: (v) => refreshDialog(() => isPastQuestion = v ?? false)),
          if (isPastQuestion) ...[
            DropdownButtonFormField<String>(value: examBody,
              decoration: const InputDecoration(labelText: 'Examination body'),
              items: ['WAEC','NECO','JAMB','NABTEB','NBAIS','NCEE','BECE']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => refreshDialog(() => examBody = v)),
            TextField(controller: examYear, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Exam year (optional)')),
            TextField(controller: examName,
              decoration: const InputDecoration(labelText: 'Exam type (e.g. WASSCE, UTME)')),
            TextField(controller: topic,
              decoration: const InputDecoration(labelText: 'Topic (optional)')),
            TextField(controller: sourceNote,
              decoration: const InputDecoration(labelText: 'Source / reference note (optional)')),
          ],
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create'))],
      )));
      if (ok == true && title.text.trim().isNotEmpty && classId != null && subjectId != null) {
        if (isPastQuestion && examBody == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose the examination body for this question set.')));
          return;
        }
        final mins = int.tryParse(duration.text.trim()) ?? -1;
        if (mins < 0) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid time limit.')));
          return;
        }
        final created = await Supabase.instance.client.from('assessments').insert({
          'title': title.text.trim(), 'class_id': classId, 'subject_id': subjectId,
          'assessment_type': type, 'duration_minutes': mins == 0 ? null : mins,
          'is_past_question': isPastQuestion,
          'exam_body': isPastQuestion ? examBody : null,
          'exam_year': isPastQuestion ? int.tryParse(examYear.text.trim()) : null,
          'exam_name': isPastQuestion && examName.text.trim().isNotEmpty ? examName.text.trim() : null,
          'topic': isPastQuestion && topic.text.trim().isNotEmpty ? topic.text.trim() : null,
          'source_note': isPastQuestion && sourceNote.text.trim().isNotEmpty ? sourceNote.text.trim() : null,
          'total_marks': 0, 'is_published': false,
        }).select('id,title,assessment_type,class_id,subject_id,duration_minutes,total_marks,is_published,is_past_question,exam_body,exam_year,exam_name,topic').single();
        await _refresh();
        if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AdminAssessmentQuestionsPage(assessment: Map<String,dynamic>.from(created))));
        if (mounted) await _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assessment could not be created: ' + e.toString())));
    } finally { title.dispose(); duration.dispose(); examYear.dispose(); examName.dispose(); topic.dispose(); sourceNote.dispose(); }
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
            (r['is_past_question'] == true ? ((r['exam_body'] ?? 'Past questions').toString() + (r['exam_year'] == null ? '' : ' ' + r['exam_year'].toString()) + ' • ') : '') +
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
      .select('id,title,instructions,due_at,max_score,published_at,tutor_id,classes(name),subjects(name),assignment_submissions(id)')
      .order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _refresh() async{final next=_load();setState(()=>_items=next);await next;}
  Future<void> _create() async{
    final title=TextEditingController();final instructions=TextEditingController();
    final due=TextEditingController();final max=TextEditingController(text:'10');
    try{
      final db=Supabase.instance.client;
      final setup=await Future.wait<dynamic>([
        db.from('classes').select('id,name').eq('status','active').order('name'),
        db.from('subjects').select('id,name').eq('status','active').order('name'),
        db.rpc('admin_class_tutor_options'),
      ]);
      final classes=List<Map<String,dynamic>>.from(setup[0] as List);
      final subjects=List<Map<String,dynamic>>.from(setup[1] as List);
      final tutorOptions=List<Map<String,dynamic>>.from((setup[2] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      if(classes.isEmpty||subjects.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Create an active class and subject first.')));return;}
      String? classId=classes.first['id'].toString();String? subjectId=subjects.first['id'].toString();
      String tutorId='';
      List<Map<String,dynamic>> eligibleTutors(String? c,String? sub)=>tutorOptions.where((t)=>t['class_id']==c&&t['subject_id']==sub).toList();
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refreshDialog)=>AlertDialog(
        title:const Text('Create assignment'),
        content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextField(controller:title,decoration:const InputDecoration(labelText:'Assignment title')),
          DropdownButtonFormField<String>(value:classId,decoration:const InputDecoration(labelText:'Class'),
            items:classes.map((r)=>DropdownMenuItem<String>(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),onChanged:(v)=>refreshDialog(() { classId=v; final options=eligibleTutors(classId,subjectId); tutorId=options.isEmpty?'':options.first['tutor_id'].toString(); })),
          DropdownButtonFormField<String>(value:subjectId,decoration:const InputDecoration(labelText:'Subject'),
            items:subjects.map((r)=>DropdownMenuItem<String>(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),onChanged:(v)=>refreshDialog(() { subjectId=v; final options=eligibleTutors(classId,subjectId); tutorId=options.isEmpty?'':options.first['tutor_id'].toString(); })),
          DropdownButtonFormField<String>(value:tutorId,decoration:const InputDecoration(labelText:'Assigned tutor (optional)'),
            items:[const DropdownMenuItem<String>(value:'',child:Text('No tutor assigned')),...eligibleTutors(classId,subjectId).map((t)=>DropdownMenuItem<String>(value:t['tutor_id'].toString(),child:Text(t['tutor_name'].toString())))],
            onChanged:(v)=>refreshDialog(()=>tutorId=v??'')),
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
        'tutor_id':tutorId.isEmpty?null:tutorId,
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
            subtitle:Text((r['classes']?['name']??'Class').toString()+' • '+(r['subjects']?['name']??'Subject').toString()+' • '+(r['tutor_id']==null?'No tutor assigned':'Tutor assigned')+' • '+count.toString()+' submissions • '+(published?'Published':'Draft')),
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

  Future<void> _bulkImport() async {
    final raw = TextEditingController();
    try {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Bulk import questions'),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Paste rows copied from Excel or Google Sheets. Use one question per row and separate each column with a TAB.'),
            const SizedBox(height: 8),
            const Text('Column order: Question | Option A | Option B | Option C | Option D | Correct answer (A-D) | Marks | Explanation (optional)',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            const SelectableText('What is 2 + 2?\t3\t4\t5\t6\tB\t1\tAdd two and two.',
              style: TextStyle(fontSize: 11, color: AppColors.brown)),
            const SizedBox(height: 10),
            TextField(controller: raw, minLines: 8, maxLines: 14,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Paste question rows here',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              )),
            const SizedBox(height: 6),
            const Text('You can import up to 500 questions at a time. Each row must contain four options and a valid answer key.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Validate and import')),
        ],
      ));
      if (ok != true) return;
      final lines = raw.text.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste at least one question row.')));
        return;
      }
      if (lines.length > 500) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import is limited to 500 questions at a time.')));
        return;
      }
      final existing = await _load();
      final imported = <Map<String,dynamic>>[];
      for (var i = 0; i < lines.length; i++) {
        final cells = lines[i].split('\t');
        if (cells.length < 7 || cells.length > 8) {
          throw FormatException('Line ${i + 1}: expected 7 or 8 TAB-separated columns.');
        }
        final question = cells[0].trim();
        final options = {
          'A': cells[1].trim(), 'B': cells[2].trim(),
          'C': cells[3].trim(), 'D': cells[4].trim(),
        };
        final correct = cells[5].trim().toUpperCase();
        final marks = num.tryParse(cells[6].trim());
        if (question.isEmpty || options.values.any((v) => v.isEmpty) ||
            !['A','B','C','D'].contains(correct) || marks == null || marks <= 0) {
          throw FormatException('Line ${i + 1}: check the question, four options, correct answer and positive marks.');
        }
        imported.add({
          'assessment_id': widget.assessment['id'],
          'question_text': question,
          'options': options,
          'correct_answer': correct,
          'marks': marks,
          'explanation': cells.length == 8 && cells[7].trim().isNotEmpty ? cells[7].trim() : null,
          'position': existing.length + i + 1,
        });
      }
      setState(() => _busy = true);
      await Supabase.instance.client.from('questions').insert(imported);
      final all = await Supabase.instance.client.from('questions')
        .select('marks').eq('assessment_id', widget.assessment['id']);
      final total = all.fold<num>(0, (sum, q) => sum + ((q['marks'] as num?) ?? 0));
      await Supabase.instance.client.from('assessments').update({
        'total_marks': total, 'is_published': false,
      }).eq('id', widget.assessment['id']);
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} questions imported. Assessment returned to draft.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk import could not be completed: $e')));
    } finally {
      raw.dispose();
      if (mounted) setState(() => _busy = false);
    }
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
    appBar: AppBar(title: const Text('Manage questions'), actions: [
      TextButton.icon(onPressed: _busy ? null : _bulkImport,
        icon: const Icon(Icons.playlist_add), label: const Text('Bulk import')),
    ]),
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

class AdminBillboardAppearancePage extends StatefulWidget{
  const AdminBillboardAppearancePage({super.key});
  @override State<AdminBillboardAppearancePage> createState()=>_AdminBillboardAppearancePageState();
}
class _AdminBillboardAppearancePageState extends State<AdminBillboardAppearancePage>{
  static const styles=<String,String>{
    'gold':'Warm gold','blue':'Ocean blue','green':'Forest green','rose':'Rose glow',
    'ocean':'Deep ocean','violet':'Violet light','teal':'Teal shine','sunset':'Sunset glow',
    'emerald':'Emerald glow','midnight':'Midnight','neon':'Neon night','aurora':'Aurora lights',
    'royal':'Royal purple','coral':'Coral light',
  };
  late Future<List<Map<String,dynamic>>> _items;
  String? _selected,_style;
  bool _saving=false;
  @override void initState(){super.initState();_items=_load();}
  Future<List<Map<String,dynamic>>> _load()async{
    final now=DateTime.now().toUtc().toIso8601String();
    final rows=await Supabase.instance.client.from('announcements')
      .select('id,title,body,banner_tone,published_at')
      .not('published_at','is',null).lte('published_at',now)
      .or('expires_at.is.null,expires_at.gt.$now').order('published_at',ascending:false);
    final list=List<Map<String,dynamic>>.from(rows);
    if(list.isNotEmpty){_selected??=list.first['id'].toString();final active=list.firstWhere((x)=>x['id'].toString()==_selected,orElse:()=>list.first);_style??=active['banner_tone'].toString();}
    return list;
  }
  Future<void> _save()async{
    if(_selected==null||_style==null)return;
    setState(()=>_saving=true);
    try{
      await Supabase.instance.client.from('announcements').update({'banner_tone':_style}).eq('id',_selected!);
      if(mounted){setState(()=>_items=_load());ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Billboard design changed. The headline and message were left untouched.')));}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Appearance could not be updated: $e')));}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Billboard appearance')),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Could not load notices: ${s.error}'));
      final rows=s.data??[];
      if(rows.isEmpty)return const Padding(padding:EdgeInsets.all(24),child:Text('There are no active billboard notices to style yet.'));
      final selected=rows.firstWhere((x)=>x['id'].toString()==_selected,orElse:()=>rows.first);
      return ListView(padding:const EdgeInsets.all(20),children:[
        const Text('Choose a notice',style:TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(value:_selected,isExpanded:true,decoration:const InputDecoration(labelText:'Existing billboard message'),
          items:rows.map((x)=>DropdownMenuItem(value:x['id'].toString(),child:Text(x['title'].toString(),overflow:TextOverflow.ellipsis))).toList(),
          onChanged:_saving?null:(v){setState((){_selected=v;final found=rows.firstWhere((x)=>x['id'].toString()==v,orElse:()=>rows.first);_style=found['banner_tone']?.toString()??'gold';});}),
        const SizedBox(height:18),
        const Text('Select a visual design',style:TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        Wrap(spacing:9,runSpacing:9,children:styles.entries.map((entry){
          final active=_style==entry.key;
          final palette=_preview(entry.key);
          return InkWell(borderRadius:BorderRadius.circular(12),onTap:_saving?null:()=>setState(()=>_style=entry.key),
            child:Container(width:145,padding:const EdgeInsets.all(10),decoration:BoxDecoration(
              gradient:LinearGradient(colors:palette),borderRadius:BorderRadius.circular(12),
              border:Border.all(color:active?AppColors.gold:Colors.white.withValues(alpha:.3),width:active?3:1),
              boxShadow:[BoxShadow(color:palette[1].withValues(alpha:.22),blurRadius:active?15:7)]),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Icon(Icons.auto_awesome,color:Colors.white,size:18),
                const SizedBox(height:16),Text(entry.value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
                if(active)const Text('SELECTED',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1)),
              ])));
        }).toList()),
        const SizedBox(height:18),
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(
          gradient:LinearGradient(colors:_preview(_style??'gold')),borderRadius:BorderRadius.circular(16),
          boxShadow:[BoxShadow(color:_preview(_style??'gold')[1].withValues(alpha:.3),blurRadius:22)]),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('CENTRE UPDATE',style:TextStyle(color:Colors.white70,fontSize:10,letterSpacing:1.4,fontWeight:FontWeight.w900)),
            const SizedBox(height:12),Text(selected['title'].toString(),style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
            const SizedBox(height:8),Text(selected['body'].toString(),maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,height:1.4)),
          ])),
        const SizedBox(height:10),
        const Text('This action changes only the selected notice’s visual style. Its title, message, audience, expiry and attachments remain unchanged.',style:TextStyle(color:AppColors.muted,height:1.4)),
        const SizedBox(height:16),FilledButton.icon(onPressed:_saving?null:_save,icon:const Icon(Icons.check_circle_outline),label:Text(_saving?'Saving...':'Apply design only')),
      ]);
    }));
  List<Color> _preview(String key){
    const palettes=<String,List<Color>>{
      'gold':[Color(0xFF67431F),Color(0xFFC99A3D),Color(0xFF211B18)],
      'blue':[Color(0xFF183E60),Color(0xFF247BA0),Color(0xFF102A43)],
      'green':[Color(0xFF24513D),Color(0xFF3C8D68),Color(0xFF102D22)],
      'rose':[Color(0xFF673B45),Color(0xFFB85C72),Color(0xFF321D2A)],
      'ocean':[Color(0xFF042A45),Color(0xFF0077B6),Color(0xFF00B4D8)],
      'violet':[Color(0xFF35155D),Color(0xFF7B2CBF),Color(0xFFC77DFF)],
      'teal':[Color(0xFF064E52),Color(0xFF0F9B8E),Color(0xFF5EEAD4)],
      'sunset':[Color(0xFF7F1D1D),Color(0xFFEA580C),Color(0xFFFBBF24)],
      'emerald':[Color(0xFF064E3B),Color(0xFF059669),Color(0xFF6EE7B7)],
      'midnight':[Color(0xFF111827),Color(0xFF334155),Color(0xFF64748B)],
      'neon':[Color(0xFF17113A),Color(0xFF4C1D95),Color(0xFFDB2777)],
      'aurora':[Color(0xFF082F49),Color(0xFF0F766E),Color(0xFF6D28D9)],
      'royal':[Color(0xFF312E81),Color(0xFF6D28D9),Color(0xFFBE185D)],
      'coral':[Color(0xFF7C2D12),Color(0xFFEA580C),Color(0xFFF97373)],
    };
    return palettes[key]??palettes['gold']!;
  }
}

class AdminCommunicationsPage extends StatefulWidget {
  const AdminCommunicationsPage({super.key});
  @override
  State<AdminCommunicationsPage> createState() => _AdminCommunicationsPageState();
}
class _AdminCommunicationsPageState extends State<AdminCommunicationsPage> {
  final _title=TextEditingController(), _body=TextEditingController();
  bool _notify=true, _busy=false;
  PlatformFile? _attachment;
  static const _fileTypes=['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','rtf','jpg','jpeg','png','webp','gif','mp4','webm','mov'];
  String _targetClassId='', _tone='gold';
  DateTime _expiresAt=DateTime.now().add(const Duration(days:7));
  late Future<List<Map<String,dynamic>>> _classes;
  @override
  void initState(){super.initState();_classes=_loadClasses();}
  @override
  void dispose(){_title.dispose();_body.dispose();super.dispose();}
  String _mime(PlatformFile f){final ext=f.extension?.toLowerCase()??'';return const {'pdf':'application/pdf','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','txt':'text/plain','csv':'text/csv','rtf':'application/rtf','jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','mp4':'video/mp4','webm':'video/webm','mov':'video/quicktime'}[ext]??'application/octet-stream';}
  Future<void> _chooseAttachment() async{final r=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:_fileTypes,withData:true);if(r!=null&&r.files.isNotEmpty&&mounted){final file=r.files.first;if(file.size>52428800){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Attachments must be 50 MB or smaller.')));return;}setState(()=>_attachment=file);}}
  Future<List<Map<String,dynamic>>> _loadClasses() async{
    final rows=await Supabase.instance.client.from('classes').select('id,name').eq('status','active').order('name');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _chooseExpiry() async{
    final picked=await showDatePicker(context:context,initialDate:_expiresAt,
      firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)),
      helpText:'When should this dashboard notice expire?');
    if(picked!=null&&mounted)setState(()=>_expiresAt=DateTime(picked.year,picked.month,picked.day,23,59,59));
  }
  Future<void> _publish() async{
    if(_title.text.trim().isEmpty||_body.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a title and message.')));return;
    }
    if(!_expiresAt.isAfter(DateTime.now())){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Choose an expiry date in the future.')));return;
    }
    setState(()=>_busy=true);
    String? attachmentPath;
    try{
      String? attachmentName,attachmentMime;int? attachmentSize;
      if(_attachment!=null){
        final file=_attachment!;
        final bytes=file.bytes;
        if(bytes==null)throw Exception('The selected file could not be read.');
        final uid=Supabase.instance.client.auth.currentUser!.id;
        attachmentName=file.name;attachmentMime=_mime(file);attachmentSize=file.size;
        final safe=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
        attachmentPath='announcements/$uid/${DateTime.now().microsecondsSinceEpoch}_$safe';
        await Supabase.instance.client.storage.from('platform-attachments')
          .uploadBinary(attachmentPath!,bytes,fileOptions:FileOptions(contentType:attachmentMime,upsert:false));
      }
      final sent=await Supabase.instance.client.rpc('publish_dashboard_announcement',params:{
        '_title':_title.text.trim(),'_body':_body.text.trim(),'_notify_students':_notify,
        '_expires_at':_expiresAt.toUtc().toIso8601String(),
        '_target_class_id':_targetClassId.isEmpty?null:_targetClassId,'_banner_tone':_tone,
        '_attachment_path':attachmentPath,'_attachment_name':attachmentName,
        '_attachment_mime_type':attachmentMime,'_attachment_size':attachmentSize,
      });
      _title.clear();_body.clear();
      if(mounted){
        setState(() {_expiresAt=DateTime.now().add(const Duration(days:7));_attachment=null;});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:Text('Dashboard update published. ${sent.toString()} student notification(s) sent.')));
      }
    }catch(e){
      if(attachmentPath!=null){try{await Supabase.instance.client.storage.from('platform-attachments').remove([attachmentPath]);}catch(_){}}
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Update could not be published: $e')));
    }finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Dashboard update board')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Publish a dashboard notice',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:AppColors.ink)),
      const SizedBox(height:8),
      const Text('This notice appears on the dashboard as a rotating billboard. Publish to the whole platform or target one class. When its expiry date passes, it automatically leaves the active board.',
        style:TextStyle(color:AppColors.muted,height:1.45)),
      const SizedBox(height:18),
      TextField(controller:_title,maxLength:90,decoration:const InputDecoration(labelText:'Headline')),
      const SizedBox(height:8),
      TextField(controller:_body,minLines:4,maxLines:8,maxLength:1200,
        decoration:const InputDecoration(labelText:'Announcement / learning instruction')),
      const SizedBox(height:12),
      FutureBuilder<List<Map<String,dynamic>>>(future:_classes,builder:(context,snapshot){
        final classes=snapshot.data??[];
        return DropdownButtonFormField<String>(
          value:_targetClassId,decoration:const InputDecoration(labelText:'Who should see this update?'),
          items:[const DropdownMenuItem(value:'',child:Text('Whole platform')),
            ...classes.map((c)=>DropdownMenuItem(value:c['id'].toString(),child:Text(c['name'].toString())))],
          onChanged:_busy?null:(v)=>setState(()=>_targetClassId=v??''));
      }),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(
        value:_tone,decoration:const InputDecoration(labelText:'Billboard appearance'),
        items:const [
          DropdownMenuItem(value:'gold',child:Text('Warm gold')),
          DropdownMenuItem(value:'blue',child:Text('Ocean blue')),
          DropdownMenuItem(value:'green',child:Text('Forest green')),
          DropdownMenuItem(value:'rose',child:Text('Rose glow')),
          DropdownMenuItem(value:'ocean',child:Text('Deep ocean')),
          DropdownMenuItem(value:'violet',child:Text('Violet light')),
          DropdownMenuItem(value:'teal',child:Text('Teal shine')),
          DropdownMenuItem(value:'sunset',child:Text('Sunset glow')),
          DropdownMenuItem(value:'emerald',child:Text('Emerald glow')),
          DropdownMenuItem(value:'midnight',child:Text('Midnight')),
          DropdownMenuItem(value:'neon',child:Text('Neon night')),
          DropdownMenuItem(value:'aurora',child:Text('Aurora lights')),
          DropdownMenuItem(value:'royal',child:Text('Royal purple')),
          DropdownMenuItem(value:'coral',child:Text('Coral light')),
        ],
        onChanged:_busy?null:(v)=>setState(()=>_tone=v??'gold')),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:_busy?null:_chooseAttachment,
        icon:const Icon(Icons.attach_file),
        label:Text(_attachment==null?'Attach a document or media file':_attachment!.name),
      ),
      if(_attachment!=null)Align(alignment:Alignment.centerLeft,child:TextButton.icon(
        onPressed:()=>setState(()=>_attachment=null),icon:const Icon(Icons.close),label:const Text('Remove attachment'))),
      const Text('Supported: PDF, Word, Excel, PowerPoint, text, images and videos. Maximum 50 MB.',
        style:TextStyle(fontSize:11,color:AppColors.muted)),
      const SizedBox(height:8),
      Card(child:ListTile(
        leading:const Icon(Icons.event_available_outlined,color:AppColors.brown),
        title:const Text('Automatic expiry'),
        subtitle:Text('Visible until ${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year}'),
        trailing:const Icon(Icons.calendar_month_outlined),onTap:_busy?null:_chooseExpiry)),
      SwitchListTile(contentPadding:EdgeInsets.zero,value:_notify,
        onChanged:_busy?null:(v)=>setState(()=>_notify=v),
        title:const Text('Also send a personal notification to affected students')),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:_busy?null:_publish,icon:const Icon(Icons.campaign_outlined),
        label:Text(_busy?'Publishing...':'Publish dashboard update'),
        style:FilledButton.styleFrom(backgroundColor:AppColors.brown,padding:const EdgeInsets.symmetric(vertical:15))),
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
                      const Center(child: YoungLearnersLogo()),
                      const SizedBox(height: 16),
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
  final bool staffMember;
  final bool parent;
  const LearnerHomePage({super.key, this.owner = false, this.admin = false, this.tutor = false, this.staffMember = false, this.parent = false});
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
        .select('full_name,email,phone,avatar_url,about_me,occupation,profile_class,interests,skills,aspirations')
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
      'phone': profile['phone'] ?? '',
      'avatar_url': profile['avatar_url'],
      'about_me': profile['about_me'] ?? '',
      'occupation': profile['occupation'] ?? '',
      'profile_class': profile['profile_class'] ?? '',
      'interests': profile['interests'] ?? '',
      'skills': profile['skills'] ?? '',
      'aspirations': profile['aspirations'] ?? '',
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
    final titles = widget.parent ? ['Home', 'Parent learning', 'Child progress', 'Profile'] : ['Home', 'My learning', 'Analytics', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: titles[_selectedIndex] == 'Home'
            ? const YoungLearnersLogo(compact: true)
            : Text(
                titles[_selectedIndex],
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
            staffMember: widget.staffMember,
            parent: widget.parent,
            onOpenCentre: () => _openCentrePortal(),
          ),
          _LearningTab(owner: widget.owner, admin: widget.admin, tutor: widget.tutor, parent: widget.parent),
          _AnalyticsTab(owner: widget.owner, admin: widget.admin, parent: widget.parent),
          _ProfileTab(account: _account, onRetry: () => setState(() => _account = _loadAccount()), onSignOut: _signOut),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 0,
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
    final now = DateTime.now().toUtc().toIso8601String();
    final announcements = await client
        .from('announcements')
        .select('id,title,body,published_at,expires_at,created_at')
        .not('published_at', 'is', null)
        .lte('published_at', now)
        .or('expires_at.is.null,expires_at.gt.$now')
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

class _DashboardAnnouncementBoard extends StatefulWidget {
  final String fallbackTitle, fallbackBody;
  final bool canManage;
  const _DashboardAnnouncementBoard({required this.fallbackTitle,required this.fallbackBody,required this.canManage});
  @override
  State<_DashboardAnnouncementBoard> createState()=>_DashboardAnnouncementBoardState();
}
class _DashboardAnnouncementBoardState extends State<_DashboardAnnouncementBoard>{
  List<Map<String,dynamic>> _items=[];
  int _index=0;
  bool _loading=true;
  Timer? _rotation;
  Timer? _expiryRefresh;
  Timer? _typingTimer;
  int _typedTitle=0;
  @override
  void initState(){
    super.initState();_load();
    _rotation=Timer.periodic(const Duration(seconds:8),(_){
      if(mounted&&_items.length>1){
        setState(()=>_index=(_index+1)%_items.length);
        _startTitleTyping();
      }
    });
    _expiryRefresh=Timer.periodic(const Duration(minutes:1),(_)=>_load());
  }
  void _startTitleTyping(){
    _typingTimer?.cancel();
    final item=_items.isEmpty?null:_items[_index.clamp(0,_items.length-1).toInt()];
    final title=(item?['title']??widget.fallbackTitle).toString();
    _typedTitle=0;
    if(!mounted)return;
    if(title.isEmpty){setState((){});return;}
    _typingTimer=Timer.periodic(const Duration(milliseconds:32),(timer){
      if(!mounted){timer.cancel();return;}
      if(_typedTitle>=title.length){timer.cancel();return;}
      setState(()=>_typedTitle=(_typedTitle+1).clamp(0,title.length));
    });
  }
  @override
  void dispose(){_rotation?.cancel();_expiryRefresh?.cancel();_typingTimer?.cancel();super.dispose();}
  Future<void> _openAttachment(Map<String,dynamic> item) async{
    try{
      final path=item['attachment_path']?.toString();
      if(path==null||path.isEmpty)throw Exception('No attachment is available.');
      final url=await Supabase.instance.client.storage.from('platform-attachments').createSignedUrl(path,3600);
      await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open attachment: $e')));}
  }
  Future<void> _load() async{
    try{
      final now=DateTime.now().toUtc().toIso8601String();
      final rows=await Supabase.instance.client.from('announcements')
        .select('id,title,body,published_at,expires_at,banner_tone,target_class_id,attachment_path,attachment_name,classes(name)')
        .not('published_at','is',null).lte('published_at',now)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('display_order',ascending:false).order('published_at',ascending:false).limit(10);
      if(mounted){
        final previousItem=_items.isNotEmpty?_items[_index.clamp(0,_items.length-1).toInt()]:null;
        final previousId=previousItem?['id'];
        final previousTitle=previousItem?['title'];
        final previousBody=previousItem?['body'];
        final nextItems=List<Map<String,dynamic>>.from(rows);
        final nextIndex=previousId==null?0:nextItems.indexWhere((row)=>row['id']==previousId);
        final safeIndex=nextIndex<0?0:nextIndex;
        final nextActive=nextItems.isEmpty?null:nextItems[safeIndex];
        final activeChanged=previousId!=nextActive?['id'] || previousTitle!=nextActive?['title'] || previousBody!=nextActive?['body'];
        setState((){_items=nextItems;_index=safeIndex;_loading=false;});
        if(activeChanged)_startTitleTyping();
      }
    }catch(_){if(mounted)setState(()=>_loading=false);}
  }
  List<Color> _toneColors(String value){
    switch(value){
      case 'blue':return const [Color(0xFF183E60),Color(0xFF247BA0),Color(0xFF102A43)];
      case 'green':return const [Color(0xFF24513D),Color(0xFF3C8D68),Color(0xFF102D22)];
      case 'rose':return const [Color(0xFF673B45),Color(0xFFB85C72),Color(0xFF321D2A)];
      case 'ocean':return const [Color(0xFF042A45),Color(0xFF0077B6),Color(0xFF00B4D8)];
      case 'violet':return const [Color(0xFF35155D),Color(0xFF7B2CBF),Color(0xFFC77DFF)];
      case 'teal':return const [Color(0xFF064E52),Color(0xFF0F9B8E),Color(0xFF5EEAD4)];
      case 'sunset':return const [Color(0xFF7F1D1D),Color(0xFFEA580C),Color(0xFFFBBF24)];
      case 'emerald':return const [Color(0xFF064E3B),Color(0xFF059669),Color(0xFF6EE7B7)];
      case 'midnight':return const [Color(0xFF111827),Color(0xFF334155),Color(0xFF64748B)];
      case 'neon':return const [Color(0xFF17113A),Color(0xFF4C1D95),Color(0xFFDB2777)];
      case 'aurora':return const [Color(0xFF082F49),Color(0xFF0F766E),Color(0xFF6D28D9)];
      case 'royal':return const [Color(0xFF312E81),Color(0xFF6D28D9),Color(0xFFBE185D)];
      case 'coral':return const [Color(0xFF7C2D12),Color(0xFFEA580C),Color(0xFFF97373)];
      default:return const [Color(0xFF67431F),Color(0xFFC99A3D),Color(0xFF211B18)];
    }
  }
  @override
  Widget build(BuildContext context){
    final item=_items.isEmpty?null:_items[_index.clamp(0,_items.length-1).toInt()];
    final palette=_toneColors((item?['banner_tone']??'gold').toString());
    final tone=palette.first;
    final title=(item?['title']??widget.fallbackTitle).toString();
    final body=(item?['body']??widget.fallbackBody).toString();
    final className=(item?['classes'] is Map?item!['classes']['name']:null)?.toString();
    return Container(
      width:double.infinity,constraints:const BoxConstraints(minHeight:205),padding:const EdgeInsets.all(22),
      decoration:BoxDecoration(
        gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:[palette[0],palette[1],palette[2]]),
        borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.gold.withValues(alpha:.65),width:1.2),
        boxShadow:[BoxShadow(color:palette[1].withValues(alpha:.34),blurRadius:24,spreadRadius:1,offset:const Offset(0,7))]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.campaign_rounded,color:Color(0xFFFFD98A),size:22),const SizedBox(width:8),
          Text(item==null?'LEARNING BOARD':'CENTRE UPDATE',
            style:const TextStyle(color:Color(0xFFFFD98A),fontSize:10,letterSpacing:1.5,fontWeight:FontWeight.w900)),
          const Spacer(),
          if(className!=null&&className.isNotEmpty)
            Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
              decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(20)),
              child:Text(className,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))
          else if(item!=null)
            Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
              decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(20)),
              child:const Text('ALL LEARNERS',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))),
        ]),
        const SizedBox(height:16),
        AnimatedSwitcher(duration:const Duration(milliseconds:550),
          transitionBuilder:(child,animation)=>SlideTransition(
            position:Tween<Offset>(begin:const Offset(.06,0),end:Offset.zero).animate(animation),
            child:FadeTransition(opacity:animation,child:child)),
          child:Column(key:ValueKey('${item?['id']??'welcome-board'}|$title|$body'),crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Expanded(child:Text(title.substring(0,_typedTitle.clamp(0,title.length).toInt()),maxLines:2,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:Colors.white,fontSize:22,height:1.16,fontWeight:FontWeight.w800))),
              if(_typedTitle<title.length)
                Container(width:2,height:23,margin:const EdgeInsets.only(left:3,top:2),
                  decoration:BoxDecoration(color:const Color(0xFFFFD98A),borderRadius:BorderRadius.circular(2))),
            ]),
            const SizedBox(height:9),
            Text(body,maxLines:4,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:Color(0xFFF0E8DE),fontSize:13,height:1.48)),
            if(item!=null && (item['attachment_path']??'').toString().isNotEmpty)
              Align(alignment:Alignment.centerLeft,child:TextButton.icon(
                onPressed:()=>_openAttachment(item),
                icon:const Icon(Icons.attach_file,size:15),
                label:Text((item['attachment_name']??'Open attachment').toString(),maxLines:1,overflow:TextOverflow.ellipsis),
                style:TextButton.styleFrom(foregroundColor:const Color(0xFFFFD98A)))),
          ])),
        const SizedBox(height:14),
        Row(children:[
          if(_items.length>1)
            Row(children:[
              IconButton(
                visualDensity:VisualDensity.compact,padding:EdgeInsets.zero,constraints:const BoxConstraints(minWidth:28,minHeight:28),
                onPressed:(){setState(()=>_index=(_index-1+_items.length)%_items.length);_startTitleTyping();},
                icon:const Icon(Icons.chevron_left_rounded,color:Colors.white,size:20)),
              ...List.generate(_items.length,(i)=>AnimatedContainer(
                duration:const Duration(milliseconds:350),curve:Curves.easeOutCubic,
                margin:const EdgeInsets.only(right:5),width:i==_index?20:6,height:6,
                decoration:BoxDecoration(color:i==_index?const Color(0xFFFFD98A):Colors.white.withValues(alpha:.42),
                  borderRadius:BorderRadius.circular(8)))),
              IconButton(
                visualDensity:VisualDensity.compact,padding:EdgeInsets.zero,constraints:const BoxConstraints(minWidth:28,minHeight:28),
                onPressed:(){setState(()=>_index=(_index+1)%_items.length);_startTitleTyping();},
                icon:const Icon(Icons.chevron_right_rounded,color:Colors.white,size:20)),
            ])
          else
            Text(item==null?'YOUR LEARNING SPACE':'YOUNG LEARNERS TUTORIAL',
              style:TextStyle(color:Colors.white.withValues(alpha:.72),fontSize:9,letterSpacing:1.1,fontWeight:FontWeight.w800)),
          const Spacer(),
          if(widget.canManage)
            TextButton.icon(
              onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                builder:(_)=>const AdminCommunicationsPage())).then((_)=>_load()),
              icon:const Icon(Icons.edit_outlined,size:15),label:const Text('Manage board'),
              style:TextButton.styleFrom(foregroundColor:const Color(0xFFFFD98A),visualDensity:VisualDensity.compact))
          else if(_loading)
            const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:1.5,color:Color(0xFFFFD98A))),
        ]),
      ]),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Future<Map<String, dynamic>> account;
  final VoidCallback onOpenLearning;
  final bool owner;
  final bool admin;
  final bool tutor;
  final bool staffMember;
  final bool parent;
  final VoidCallback onOpenCentre;
  const _HomeTab({
    required this.account,
    required this.onOpenLearning,
    required this.owner,
    required this.admin,
    required this.tutor,
    required this.staffMember,
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
                Text(owner ? 'OWNER DASHBOARD' : admin ? 'CENTRE DASHBOARD' : tutor ? 'TUTOR PORTAL' : staffMember ? 'STAFF PORTAL' : parent ? 'PARENT PORTAL' : 'LEARNER PORTAL',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                    fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Welcome, $name',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 5),
                Text('Every Child Can Learn.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 22),
                _DashboardAnnouncementBoard(
                  fallbackTitle: parent ? 'Stay connected to your child’s learning' : staffMember ? 'Welcome to your staff workspace' : 'Your learning journey starts here',
                  fallbackBody: parent
                    ? 'Link your child’s learner account to follow assignments, results and attendance from one place.'
                    : staffMember ? 'Keep up with centre updates, team conversations and your staff responsibilities.'
                    : 'Your classes, subjects, learning materials and progress will appear here as the centre activates them.',
                  canManage: owner || admin,
                ),
                if (owner) ...[
                  const SizedBox(height: 20),
                  const _CentreOverview(),
                ],
                if (owner || tutor || staffMember) ...[
                  const SizedBox(height: 18),
                  Card(child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.paleGold,
                      child: Icon(Icons.forum_outlined, color: AppColors.brown)),
                    title: const Text('Staff Room', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    subtitle: const Text('Private updates and conversations with the centre team'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => StaffRoomPage(canAnnounce: owner || admin),
                    )),
                  )),
                ],
                if (!owner && !admin && !tutor && !staffMember && !parent) ...[
                  const SizedBox(height: 18),
                  Card(child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.paleGold,
                      child: Icon(Icons.record_voice_over_outlined, color: AppColors.brown)),
                    title: const Text('Become a tutor', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    subtitle: const Text('Apply to teach with Young Learners Tutorial'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const TutorInterviewCentrePage(),
                    )),
                  )),
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
                if (!parent && !staffMember) ...[
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

  Future<void> _openBoardResource(Map<String,dynamic> row) async {
    try {
      final path=row['media_path']?.toString();
      final url=path!=null
        ? await Supabase.instance.client.storage.from('classroom-resources').createSignedUrl(path,3600)
        : row['media_url']?.toString();
      if(url==null||!url.startsWith('https://'))throw Exception('Resource unavailable');
      await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open classroom resource: $e')));
    }
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
                  ? '${r['subject'] ?? 'Subject'} • ${r['status'] ?? 'Not submitted'} • ${r['score'] == null ? 'Not marked' : '${r['score']}/${r['max_score'] ?? '?'}'} • Due: ${_date(r['due_at'])}'
                  : title == 'Results'
                    ? '${r['period_title'] ?? 'Result'} ${r['academic_year'] ?? ''} • CA: ${r['ca_score'] ?? '—'}/${r['max_ca'] ?? '—'} • Exam: ${r['exam_score'] ?? '—'}/${r['max_exam'] ?? '—'} • Total: ${r['score'] ?? '-'} • Grade: ${r['grade'] ?? 'Not graded'} • ${r['remark'] ?? ''} • ${_date(r['published_at'])}'
                    : title == 'Upcoming live and recorded lessons'
                      ? '${r['subject'] ?? 'Lesson'} • ${r['scheduled_at'] == null ? 'Schedule to be announced' : _date(r['scheduled_at'])} • ${r['duration_minutes'] ?? '—'} minutes'
                      : title == 'Learning materials'
                        ? '${r['material_type'] ?? 'Resource'} • ${r['subject'] ?? 'Learning'} • ${r['lesson_title'] ?? 'Lesson material'}'
                        : title == 'Assessments and CBT'
                          ? '${r['subject'] ?? 'Subject'} • ${r['assessment_type'] ?? 'Assessment'} • ${r['starts_at'] == null ? 'Schedule to be announced' : _date(r['starts_at'])} • ${r['duration_minutes'] ?? '—'} minutes'
                          : title == 'Classroom signboard'
                            ? '${(r['post_type'] ?? 'Class update').toString().toUpperCase()} • ${_date(r['created_at'])} • ${r['body'] ?? ''}'
                            : '${r['status'] ?? ''} • ${_date(r['date'])}',
                style: const TextStyle(color: AppColors.muted, height: 1.4)),
              if (r['feedback'] != null && r['feedback'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Tutor feedback: ${r['feedback']}', style: const TextStyle(height: 1.4))),
              if (r['comment'] != null && r['comment'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Tutor comment: ${r['comment']}', style: const TextStyle(height: 1.4))),
              if (title == 'Results' && (r['class_teacher_comment'] ?? '').toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Class teacher: ${r['class_teacher_comment']}', style: const TextStyle(height: 1.4))),
              if (title == 'Results' && (r['head_teacher_comment'] ?? '').toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Centre coordinator: ${r['head_teacher_comment']}', style: const TextStyle(height: 1.4))),
              if (r['note'] != null && r['note'].toString().trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Note: ${r['note']}', style: const TextStyle(height: 1.4))),
              if (title == 'Classroom signboard' && ((r['media_path'] ?? '').toString().isNotEmpty || (r['media_url'] ?? '').toString().isNotEmpty))
                Align(alignment:Alignment.centerLeft,child:TextButton.icon(
                  onPressed:()=>_openBoardResource(r),icon:const Icon(Icons.open_in_new_rounded),
                  label:const Text('Open classroom resource'))),
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
          final lessonProgress = Map<String,dynamic>.from(data['lesson_progress'] ?? {});
          final completedLessons = List<Map<String,dynamic>>.from(lessonProgress['items'] ?? []);
          final upcomingLessons = List<Map<String,dynamic>>.from(data['upcoming_lessons'] ?? []);
          final materials = List<Map<String,dynamic>>.from(data['materials'] ?? []);
          final assessments = List<Map<String,dynamic>>.from(data['assessments'] ?? []);
          final classroomBoard = List<Map<String,dynamic>>.from(data['classroom_board'] ?? []);
          final pendingAssignments = assignments.where((r) =>
            (r['status'] ?? 'not_submitted').toString() == 'not_submitted' ||
            (r['status'] ?? '').toString() == 'returned').length;
          return ListView(padding: const EdgeInsets.all(18), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((child['name'] ?? widget.childName).toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text('${child['class_name'] ?? child['level'] ?? 'Class not set'} • Supervised student view',
                  style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 13),
                Row(children: [
                  Expanded(child: _guardianMetric('Lessons', (lessonProgress['completed'] ?? 0) as int)),
                  const SizedBox(width: 7),
                  Expanded(child: _guardianMetric('To submit', pendingAssignments)),
                  const SizedBox(width: 7),
                  Expanded(child: _guardianMetric('Results', results.length)),
                ]),
                const SizedBox(height: 8),
                const Text('This is a parent view of the learner’s portal. You can monitor learning activity and feedback here; the child’s sign-in and submitted work remain separate.',
                  style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 12)),
              ],
            ))),
            _section('Upcoming live and recorded lessons', upcomingLessons, 'No upcoming lessons have been published for this learner yet.'),
            _section('Learning materials', materials, 'No learning materials have been added for this learner yet.'),
            _section('Classroom signboard', classroomBoard, 'There are no classroom notices or shared resources yet.'),
            _section('Assignments', assignments, 'No assignments have been published for this learner yet.'),
            _section('Assessments and CBT', assessments, 'No upcoming assessments have been published for this learner yet.'),
            _section('Lessons completed', completedLessons, 'No lessons have been marked as completed yet.'),
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
  String _adminFilter = 'Pending';
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
    final note = TextEditingController();
    final approving = decision == 'approved';
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(approving ? 'Verify and approve parent link' : 'Reject parent link request'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Parent: ' + (row['guardian_name'] ?? 'Parent account').toString()),
        Text('Parent email: ' + (row['guardian_email'] ?? 'Not available').toString()),
        const SizedBox(height: 8),
        Text('Learner: ' + (row['student_name'] ?? 'Not found').toString()),
        Text('Learner email: ' + (row['requested_email'] ?? '').toString()),
        Text('Relationship: ' + (row['relationship'] ?? 'Parent').toString()),
        const SizedBox(height: 12),
        Text(approving
          ? 'Confirm that the learner account matches this email and that the requester is authorised to view the child’s learning information.'
          : 'Give the parent a clear reason so they know what needs to be corrected.'),
        const SizedBox(height: 10),
        TextField(controller: note, maxLines: 3, decoration: InputDecoration(
          labelText: approving ? 'Verification note (optional)' : 'Reason for rejection')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(approving ? 'Confirm approval' : 'Reject request')),
      ],
    ));
    if (confirmed == true && !approving && note.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a short reason before rejecting this request.')));
      note.dispose();
      return;
    }
    if (confirmed == true) {
      setState(() => _busy = true);
      try {
        await Supabase.instance.client.rpc('review_guardian_link_request', params: {
          'p_request_id': row['id'],
          'p_decision': decision,
          'p_admin_note': note.text.trim().isEmpty ? null : note.text.trim(),
        });
        await _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approving ? 'Parent account linked successfully.' : 'Request rejected and parent notified.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request could not be reviewed: $e')));
      } finally { if (mounted) setState(() => _busy = false); }
    }
    note.dispose();
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
            final pendingCount = rows.where((r) => r['status'] != 'approved' && r['status'] != 'rejected').length;
            final approvedCount = rows.where((r) => r['status'] == 'approved').length;
            final rejectedCount = rows.where((r) => r['status'] == 'rejected').length;
            final visibleRows = rows.where((r) {
              if (_adminFilter == 'Pending') return r['status'] != 'approved' && r['status'] != 'rejected';
              if (_adminFilter == 'Approved') return r['status'] == 'approved';
              if (_adminFilter == 'Rejected') return r['status'] == 'rejected';
              return true;
            }).toList();
            if (rows.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: const [
              Text('Parent verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              SizedBox(height: 10),
              _InfoNotice(message: 'There are no parent link requests waiting for review.')
            ]);
            return ListView(padding: const EdgeInsets.all(18), children: [
              const Text('Verify parent and learner accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              const Text('Review the parent account, learner email and stated relationship. Approval gives the parent access to that learner’s progress and learning records.', style: TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _guardianMetric('Pending', pendingCount)),
                const SizedBox(width: 7),
                Expanded(child: _guardianMetric('Approved', approvedCount)),
                const SizedBox(width: 7),
                Expanded(child: _guardianMetric('Rejected', rejectedCount)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 7, children: [
                for (final filter in ['Pending', 'Approved', 'Rejected', 'All'])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _adminFilter == filter,
                    onSelected: (_) => setState(() => _adminFilter = filter),
                    selectedColor: AppColors.paleGold,
                  ),
              ]),
              const SizedBox(height: 10),
              if (visibleRows.isEmpty)
                _InfoNotice(message: 'There are no ' + _adminFilter.toLowerCase() + ' parent link requests.'),
              ...visibleRows.map((r) => Card(
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
                      const Padding(padding: EdgeInsets.only(top: 7), child: _InfoNotice(
                        message: 'No learner account matches this email yet. Do not approve until the learner registers with this exact email and the parent resubmits.')),
                    if (r['admin_note'] != null && r['admin_note'].toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 7), child: Text('Previous note: ' + r['admin_note'].toString(),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12))),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: _busy ? null : () => _review(r, 'rejected'),
                        child: const Text('Reject'))),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton(
                        onPressed: _busy || r['student_id'] == null ? null : () => _review(r, 'approved'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.brown),
                        child: const Text('Verify & approve'))),
                    ]),
                  ]),
                ),
              )),
            ]);
          }

          final data = Map<String, dynamic>.from(snapshot.data as Map);
          final children = List<Map<String, dynamic>>.from(data['children'] ?? []);
          final requests = List<Map<String, dynamic>>.from(data['requests'] ?? []);
          final totalSubmitted = children.fold<int>(0, (sum, c) =>
            sum + (int.tryParse((c['assignments_submitted'] ?? 0).toString()) ?? 0));
          final attendanceValues = children
            .where((c) => c['attendance_rate'] != null)
            .map((c) => double.tryParse(c['attendance_rate'].toString()) ?? 0)
            .toList();
          final familyAttendance = attendanceValues.isEmpty ? null :
            (attendanceValues.reduce((a,b) => a+b) / attendanceValues.length).round();
          return ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Family learning dashboard', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('One parent account for all your linked children. Choose a child to open their supervised student portal and review their learning activity.', style: TextStyle(color: AppColors.muted, height: 1.45)),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _guardianMetric('Children', children.length)),
              const SizedBox(width: 8),
              Expanded(child: _guardianMetric('Submitted', totalSubmitted)),
              const SizedBox(width: 8),
              Expanded(child: _guardianMetric('Attendance', familyAttendance == null ? 0 : familyAttendance)),
            ]),
            const SizedBox(height: 7),
            const Text('Attendance is an average across children with attendance records.',
              style: TextStyle(color: AppColors.muted, fontSize: 11)),
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
            const Text('Your children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
                '\nLessons completed: ${c['lessons_completed'] ?? 0} of ${c['lessons_available'] ?? 0}'
                '${c['latest_result'] == null ? '' : '\nLatest result: ${c['latest_result']} in ${c['latest_subject'] ?? 'a subject'}'}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.brown),
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



Widget _guardianMetric(String label, int value) => Card(
  child: Padding(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 7),
    child: Column(children: [
      Text(value.toString(), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.brown)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  ),
);

class TutorWorkspacePage extends StatefulWidget {
  const TutorWorkspacePage({super.key});
  @override
  State<TutorWorkspacePage> createState() => _TutorWorkspacePageState();
}
class _TutorWorkspacePageState extends State<TutorWorkspacePage> {
  late Future<Map<String,dynamic>> _workspace;
  @override
  void initState() { super.initState(); _workspace = _load(); }
  Future<Map<String,dynamic>> _load() async {
    final raw = await Supabase.instance.client.rpc('tutor_workspace_summary');
    return Map<String,dynamic>.from(raw as Map);
  }
  Future<void> _refresh() async { final next=_load(); setState(()=>_workspace=next); await next; }
  String _date(dynamic raw) {
    final value=DateTime.tryParse(raw?.toString()??'')?.toLocal();
    if(value==null)return 'Time not scheduled';
    return '${value.day.toString().padLeft(2,'0')}/${value.month.toString().padLeft(2,'0')}/${value.year} • ${TimeOfDay.fromDateTime(value).format(context)}';
  }
  @override
  Widget build(BuildContext context)=>RefreshIndicator(
    color:AppColors.brown,onRefresh:_refresh,
    child:FutureBuilder<Map<String,dynamic>>(future:_workspace,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)
        return const Center(child:CircularProgressIndicator(color:AppColors.brown));
      if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[
        _InfoNotice(message:'Your tutor workspace could not be loaded: ${s.error}')
      ]);
      final data=s.data!;
      final classes=List<Map<String,dynamic>>.from(data['classes'] as List);
      final lessons=List<Map<String,dynamic>>.from(data['lessons'] as List);
      final assignments=List<Map<String,dynamic>>.from(data['assignments'] as List);
      return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,32),children:[
        const Text('Your teaching workspace',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:AppColors.ink)),
        const SizedBox(height:5),
        const Text('Your assigned classes, published lessons and homework are gathered here.',
          style:TextStyle(color:AppColors.muted,height:1.4)),
        const SizedBox(height:16),
        Card(child:ListTile(
          leading:const Icon(Icons.fact_check_outlined,color:AppColors.brown,size:28),
          title:const Text('Class attendance',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
          subtitle:const Text('Take or update attendance for your assigned classes'),
          trailing:const Icon(Icons.chevron_right_rounded),
          onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(
            builder:(_)=>Scaffold(appBar:AppBar(title:const Text('Class attendance')),body:const AdminAttendancePage()))),
        )),
        const SizedBox(height:18),
        const Text('MY CLASSES & SUBJECTS',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:8),
        if(classes.isEmpty)const _InfoNotice(message:'No classes or subjects have been assigned to your tutor account yet. Contact the centre administrator.'),
        ...classes.map((c)=>Card(child:ListTile(
          leading:const Icon(Icons.school_outlined,color:AppColors.brown),
          title:Text((c['class_name']??'Class').toString(),style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
          subtitle:Text('${c['level']??''} • ${c['subject_name']??'Subject'}'),
        ))),
        const SizedBox(height:16),
        const Text('PUBLISHED LESSONS',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:8),
        if(lessons.isEmpty)const _InfoNotice(message:'Published lessons for your assigned classes will appear here.'),
        ...lessons.map((l)=>Card(child:ListTile(
          leading:const Icon(Icons.menu_book_outlined,color:AppColors.brown),
          title:Text((l['title']??'Lesson').toString(),style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
          subtitle:Text('${l['class_name']??''} • ${l['subject_name']??''} • ${_date(l['scheduled_at'])}'),
          trailing:const Icon(Icons.chevron_right_rounded),
          onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>LessonDetailPage(lesson:l,allowCompletion:false))),
        ))),
        const SizedBox(height:16),
        const Text('ASSIGNMENTS & STUDENT WORK',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:8),
        if(assignments.isEmpty)const _InfoNotice(message:'Assignments specifically assigned to you will appear here. The centre administrator can assign a tutor when creating or managing class homework.'),
        ...assignments.map((a)=>Card(child:ListTile(
          leading:const Icon(Icons.assignment_outlined,color:AppColors.brown),
          title:Text((a['title']??'Assignment').toString(),style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
          subtitle:Text('${a['class_name']??''} • ${a['subject_name']??''}\n${a['submission_count']??0} submissions • ${a['graded_count']??0} marked'),
          isThreeLine:true,
          trailing:const Icon(Icons.chevron_right_rounded),
          onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(
            builder:(_)=>TutorAssignmentSubmissionsPage(assignment:a))).then((_)=>_refresh()),
        ))),
      ]);
    }),
  );
}

class TutorAssignmentSubmissionsPage extends StatefulWidget {
  final Map<String,dynamic> assignment;
  const TutorAssignmentSubmissionsPage({super.key,required this.assignment});
  @override
  State<TutorAssignmentSubmissionsPage> createState()=>_TutorAssignmentSubmissionsPageState();
}
class _TutorAssignmentSubmissionsPageState extends State<TutorAssignmentSubmissionsPage>{
  late Future<List<Map<String,dynamic>>> _submissions;
  bool _busy=false;
  @override
  void initState(){super.initState();_submissions=_load();}
  Future<List<Map<String,dynamic>>> _load() async{
    final raw=await Supabase.instance.client.rpc('tutor_assignment_submissions',
      params:{'p_assignment_id':widget.assignment['id']});
    if(raw is! List)return [];
    return raw.map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<void> _refresh() async{final next=_load();setState(()=>_submissions=next);await next;}
  Future<void> _grade(Map<String,dynamic> submission) async{
    final score=TextEditingController(text:submission['score']?.toString()??'');
    final feedback=TextEditingController(text:submission['tutor_feedback']?.toString()??'');
    try{
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
        title:const Text('Mark student work'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text('Maximum score: ${widget.assignment['max_score']??0}'),
          const SizedBox(height:10),
          TextField(controller:score,keyboardType:const TextInputType.numberWithOptions(decimal:true),
            decoration:const InputDecoration(labelText:'Score awarded')),
          const SizedBox(height:10),
          TextField(controller:feedback,minLines:3,maxLines:6,
            decoration:const InputDecoration(labelText:'Feedback for the learner')),
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save mark'))],
      ));
      if(ok==true){
        final value=num.tryParse(score.text.trim());
        if(value==null||value<0){
          if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid score.')));
          return;
        }
        setState(()=>_busy=true);
        await Supabase.instance.client.rpc('tutor_grade_assignment_submission',params:{
          'p_submission_id':submission['id'],'p_score':value,'p_feedback':feedback.text.trim(),
        });
        await _refresh();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Mark and feedback saved.')));
      }
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save the mark: $e')));
    }finally{
      score.dispose();feedback.dispose();
      if(mounted)setState(()=>_busy=false);
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Student submissions')),
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,
      child:FutureBuilder<List<Map<String,dynamic>>>(future:_submissions,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[
          _InfoNotice(message:'Student submissions could not be loaded: ${s.error}')
        ]);
        final rows=s.data??[];
        if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(20),children:[
          const _InfoNotice(message:'No learner has submitted this assignment yet.')
        ]);
        return ListView(padding:const EdgeInsets.all(16),children:[
          Text((widget.assignment['title']??'Assignment').toString(),
            style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:5),
          Text('${widget.assignment['class_name']??''} • ${widget.assignment['subject_name']??''} • Maximum ${widget.assignment['max_score']??0} marks',
            style:const TextStyle(color:AppColors.muted)),
          const SizedBox(height:12),
          ...rows.map((r){
            final status=(r['status']??'submitted').toString();
            return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(
              padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Expanded(child:Text((r['student_name']??'Learner').toString(),
                    style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink))),
                  Text(status=='graded'?'Marked':'Awaiting marking',
                    style:TextStyle(fontWeight:FontWeight.w700,color:status=='graded'?Colors.green.shade700:AppColors.brown)),
                ]),
                if(r['student_level']!=null)Text(r['student_level'].toString(),style:const TextStyle(fontSize:12,color:AppColors.muted)),
                const SizedBox(height:10),
                const Text('STUDENT ANSWER',style:TextStyle(fontSize:10,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.muted)),
                const SizedBox(height:5),
                SelectableText((r['answer_text']??'No text answer').toString(),
                  style:const TextStyle(height:1.5,color:AppColors.ink)),
                if(r['score']!=null)...[
                  const SizedBox(height:8),
                  Text('Score: ${r['score']} / ${widget.assignment['max_score']??0}',
                    style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.brown)),
                ],
                if((r['tutor_feedback']??'').toString().isNotEmpty)...[
                  const SizedBox(height:6),Text('Feedback: ${r['tutor_feedback']}',
                    style:const TextStyle(color:AppColors.muted)),
                ],
                const SizedBox(height:10),
                Align(alignment:Alignment.centerRight,child:OutlinedButton.icon(
                  onPressed:_busy?null:()=>_grade(r),
                  icon:const Icon(Icons.edit_note),label:Text(status=='graded'?'Update mark':'Mark work'),
                )),
              ]),
            ));
          }),
        ]);
      }),
    ),
  );
}

class _LearningTab extends StatefulWidget {
  final bool owner;
  final bool admin;
  final bool tutor;
  final bool parent;
  const _LearningTab({this.owner = false, this.admin = false, this.tutor = false, this.parent = false});
  @override
  State<_LearningTab> createState() => _LearningTabState();
}
class _LearningTabState extends State<_LearningTab> {
  late Future<List<Map<String, dynamic>>> _lessons;
  @override
  void initState() { super.initState(); _lessons = _loadLessons(); }
  Future<List<Map<String, dynamic>>> _loadLessons() async {
    if (widget.tutor || widget.parent) return [];
    final db = Supabase.instance.client;
    var query = db.from('lessons')
      .select('id,title,description,content,live_class_url,scheduled_at,duration_minutes,subjects(name),classes(name)')
      .eq('is_published', true);
    // Owners and authorised administrators can inspect the centre's published
    // catalogue. Learners only receive lessons for approved learning programmes.
    if (!widget.owner && !widget.admin) {
      final currentUserId = db.auth.currentUser?.id;
      if (currentUserId == null) return [];
      final approvedRequests = await db.from('learning_access_requests')
        .select('learning_programmes(class_id)')
        .eq('user_id', currentUserId)
        .eq('status', 'approved');
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
  Widget build(BuildContext context) {
    if (widget.tutor) return const TutorWorkspacePage();
    return RefreshIndicator(
    color: AppColors.brown, onRefresh: _refresh,
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.tutor ? 'Tutor workspace' : widget.parent ? 'Parent learning' : 'My learning', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 7),
      Text(widget.tutor ? 'Take attendance for the classes assigned to you.' : widget.parent ? 'Follow your child’s learning progress, assignments and results.' : 'Open a lesson to read its notes and learning materials.', style: const TextStyle(color: AppColors.muted, height: 1.45)),
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
      if (widget.parent) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.family_restroom_outlined, color: AppColors.brown)),
          title: const Text('Parent / guardian dashboard', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('Link your child and follow their learning activity'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GuardianPortalPage())),
        ),
      ),
      if (widget.parent) const SizedBox(height: 10),

      if (!widget.parent) Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ClassroomDirectoryPage(owner: widget.owner, admin: widget.admin, tutor: widget.tutor),
          )),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.meeting_room_outlined, color: AppColors.brown, size: 27)),
              const SizedBox(width: 13),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Classrooms', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
                SizedBox(height: 3),
                Text('Your class space for lessons, videos, explanations, assignments and notices.',
                  style: TextStyle(color: AppColors.muted, height: 1.35, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: AppColors.brown),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.school_outlined, color: AppColors.brown)),
          title: const Text('Learning programmes', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('Choose a class programme, view fees and request classroom access'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LearningAccessPage())),
        ),
      ),
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.event_available_outlined, color: AppColors.brown)),
          title: const Text('My attendance', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          subtitle: const Text('View your attendance history and attendance rate'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StudentAttendancePage())),
        ),
      ),
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) const SizedBox(height: 10),
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) Card(
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
      if (!widget.owner && !widget.admin && !widget.tutor && !widget.parent) const SizedBox(height: 10),
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
          final scheduled = DateTime.tryParse(lesson['scheduled_at']?.toString() ?? '')?.toLocal();
          final scheduledLabel = scheduled == null ? null :
            '${scheduled.day.toString().padLeft(2,'0')}/${scheduled.month.toString().padLeft(2,'0')}/${scheduled.year} ${TimeOfDay.fromDateTime(scheduled).format(context)}';
          final meta = [
            if (subject is Map && subject['name'] != null) subject['name'],
            if (classInfo is Map && classInfo['name'] != null) classInfo['name'],
            if (scheduledLabel != null) scheduledLabel,
            if (lesson['duration_minutes'] != null) '${lesson['duration_minutes']} min',
          ].join(' • ');
          return Padding(padding: const EdgeInsets.only(bottom: 11), child: Card(child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.paleGold, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.menu_book_rounded, color: AppColors.brown)),
            title: Text(lesson['title'] ?? 'Lesson', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(meta, style: const TextStyle(color: AppColors.muted))),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonDetailPage(lesson: lesson))),
          )));
        }).toList());
      }),
    ]),
  );
  }
}

class ClassroomDirectoryPage extends StatefulWidget {
  final bool owner, admin, tutor;
  const ClassroomDirectoryPage({super.key, this.owner=false, this.admin=false, this.tutor=false});
  @override
  State<ClassroomDirectoryPage> createState()=>_ClassroomDirectoryPageState();
}

class _ClassroomDirectoryPageState extends State<ClassroomDirectoryPage> {
  late Future<List<Map<String,dynamic>>> _classes;
  @override
  void initState(){super.initState();_classes=_load();}
  Future<List<Map<String,dynamic>>> _load() async {
    final db=Supabase.instance.client;
    final userId=db.auth.currentUser?.id;
    if(userId==null)return [];
    if(widget.owner||widget.admin){
      final rows=await db.from('classes').select('id,name,level,status').eq('status','active');
      return _sortSchoolClasses(List<Map<String,dynamic>>.from(rows));
    }
    if(widget.tutor){
      final tutor=await db.from('tutors').select('id').eq('user_id',userId).eq('status','active').maybeSingle();
      if(tutor==null)return [];
      final rows=await db.from('class_tutors').select('class_id,classes(id,name,level,status)').eq('tutor_id',tutor['id']);
      final unique=<String,Map<String,dynamic>>{};
      for(final row in rows){
        final c=row['classes'];
        if(c is Map && c['id']!=null && c['status']=='active') unique[c['id'].toString()]=Map<String,dynamic>.from(c);
      }
      return _sortSchoolClasses(unique.values.toList());
    }
    final requests=await db.from('learning_access_requests').select('learning_programmes(class_id)')
      .eq('user_id',userId).eq('status','approved');
    final ids=requests.map((r){
      final p=r['learning_programmes'];
      return p is Map ? p['class_id']?.toString() : null;
    }).whereType<String>().toSet().toList();
    if(ids.isEmpty)return [];
    final rows=await db.from('classes').select('id,name,level,status').inFilter('id',ids).eq('status','active');
    return _sortSchoolClasses(List<Map<String,dynamic>>.from(rows));
  }
  Future<void> _refresh() async {final f=_load();setState(()=>_classes=f);await f;}
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Classrooms')),
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,
      child:FutureBuilder<List<Map<String,dynamic>>>(future:_classes,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(s.hasError)return ListView(children:[_InfoNotice(message:'Classrooms could not be loaded. '+s.error.toString())]);
        final classes=s.data??[];
        return ListView(padding:const EdgeInsets.all(18),children:[
          ClipRRect(borderRadius:BorderRadius.circular(20),child:SvgPicture.asset('assets/classroom_hero.svg',height:150,width:double.infinity,fit:BoxFit.cover)),
          const SizedBox(height:17),
          const Text('Choose your classroom',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:AppColors.ink)),
          const SizedBox(height:5),
          Text(widget.owner||widget.admin?'All active classrooms, arranged from Primary 1 through SS 3. Open a class to manage its board and learning resources.':widget.tutor?'Your assigned classrooms. Open a class to share learning materials and class notices.':'Your approved classroom. Lessons and resources are kept separate by class level.',
            style:const TextStyle(color:AppColors.muted,height:1.45)),
          const SizedBox(height:15),
          if(classes.isEmpty) _InfoNotice(message:widget.tutor?'No active classrooms have been assigned to your tutor account yet.':'No classroom access is active yet. Submit a learning programme request and wait for payment verification and approval.'),
          for(var i=0;i<classes.length;i++)
            Padding(padding:const EdgeInsets.only(bottom:10),child:_ClassroomTile(
              classroom:classes[i], index:i+1, onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                builder:(_)=>ClassroomPage(classroom:classes[i],canManage:widget.owner||widget.admin||widget.tutor),
              )),
            )),
        ]);
      })),
  );
}

class _ClassroomTile extends StatelessWidget {
  final Map<String,dynamic> classroom; final int index; final VoidCallback onTap;
  const _ClassroomTile({required this.classroom,required this.index,required this.onTap});
  @override
  Widget build(BuildContext context){
    final name=(classroom['name']??classroom['level']??'Classroom').toString();
    final isPrimary=name.toLowerCase().contains('primary');
    final isJunior=name.toUpperCase().contains('JSS')||name.toUpperCase().contains('JS');
    final icon=isPrimary?Icons.auto_stories_rounded:isJunior?Icons.science_outlined:Icons.school_rounded;
    return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Padding(
      padding:const EdgeInsets.all(14),child:Row(children:[
        Container(width:48,height:48,decoration:BoxDecoration(color:AppColors.paleGold,borderRadius:BorderRadius.circular(14)),
          child:Icon(icon,color:AppColors.brown,size:26)),
        const SizedBox(width:13),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:AppColors.ink)),
          const SizedBox(height:3),
          Text(isPrimary?'Primary classroom':isJunior?'Junior secondary classroom':'Senior secondary classroom',
            style:const TextStyle(color:AppColors.muted,fontSize:12)),
        ])),
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:AppColors.cream,borderRadius:BorderRadius.circular(20)),
          child:Text('OPEN',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,letterSpacing:.8,color:AppColors.brown))),
        const SizedBox(width:7),const Icon(Icons.chevron_right_rounded,color:AppColors.muted),
      ]),
    )));
  }
}

class ClassroomPage extends StatefulWidget {
  final Map<String,dynamic> classroom; final bool canManage;
  const ClassroomPage({super.key,required this.classroom,this.canManage=false});
  @override
  State<ClassroomPage> createState()=>_ClassroomPageState();
}
class _ClassroomPageState extends State<ClassroomPage> {
  late Future<Map<String,dynamic>> _data;
  bool _busy=false;
  String get _classId=>widget.classroom['id'].toString();
  @override
  void initState(){super.initState();_data=_load();}
  Future<Map<String,dynamic>> _load() async {
    final db=Supabase.instance.client;
    final results=await Future.wait<dynamic>([
      db.from('lessons').select('id,title,description,content,live_class_url,scheduled_at,duration_minutes,subjects(name)')
        .eq('class_id',_classId).eq('is_published',true).order('scheduled_at'),
      db.from('classroom_posts').select('id,post_type,title,body,media_path,media_url,created_at')
        .eq('class_id',_classId).eq('is_published',true).order('created_at',ascending:false),
      widget.canManage
        ? db.from('assignments').select('id,title,due_at,max_score,subjects(name)')
            .eq('class_id',_classId).not('published_at','is',null).order('due_at')
        : db.rpc('student_assignments'),
    ]);
    final lessons=List<Map<String,dynamic>>.from(results[0] as List);
    final posts=List<Map<String,dynamic>>.from(results[1] as List);
    final rawAssignments=(results[2] as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    final assignments=widget.canManage
      ? rawAssignments.map((a)=>{'id':a['id'],'title':a['title'],'due_at':a['due_at'],'max_score':a['max_score'],
          'subject_name':a['subjects'] is Map ? a['subjects']['name'] : 'Subject','submission_status':'Published'}).toList()
      : rawAssignments.where((a)=>(a['class_name']??'').toString()==(widget.classroom['name']??'').toString()).toList();
    return {'lessons':lessons,'posts':posts,'assignments':assignments};
  }
  Future<void> _refresh() async {final f=_load();setState(()=>_data=f);await f;}
  Future<void> _createAssignment() async {
    final db=Supabase.instance.client;
    final subjects=List<Map<String,dynamic>>.from(await db.from('subjects')
      .select('id,name').eq('status','active').order('name'));
    if(subjects.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add an active subject before creating an assignment.')));return;}
    final title=TextEditingController(),instructions=TextEditingController(),marks=TextEditingController(text:'10'),due=TextEditingController();
    String? subjectId=subjects.first['id'].toString();
    final submit=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(
      title:const Text('Create class assignment'),
      content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:subjectId,decoration:const InputDecoration(labelText:'Subject'),
          items:subjects.map((x)=>DropdownMenuItem(value:x['id'].toString(),child:Text(x['name'].toString()))).toList(),
          onChanged:(v)=>setDialogState(()=>subjectId=v)),
        const SizedBox(height:10),TextField(controller:title,decoration:const InputDecoration(labelText:'Assignment title')),
        const SizedBox(height:10),TextField(controller:instructions,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Instructions')),
        const SizedBox(height:10),TextField(controller:marks,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Maximum marks')),
        const SizedBox(height:10),TextField(controller:due,decoration:const InputDecoration(labelText:'Due date (YYYY-MM-DD)',hintText:'2026-12-01')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Publish assignment'))],
    )));
    if(submit!=true){title.dispose();instructions.dispose();marks.dispose();due.dispose();return;}
    final maxScore=double.tryParse(marks.text.trim());
    final dueDate=due.text.trim().isEmpty?null:DateTime.tryParse(due.text.trim());
    if(title.text.trim().length<3||maxScore==null||maxScore<=0||(due.text.trim().isNotEmpty&&dueDate==null)){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check the title, maximum marks and due date.')));
      title.dispose();instructions.dispose();marks.dispose();due.dispose();return;
    }
    setState(()=>_busy=true);
    try{
      final tutorRecord=await db.from('tutors').select('id')
        .eq('user_id',db.auth.currentUser!.id).eq('status','active').maybeSingle();
      await db.from('assignments').insert({
        'class_id':_classId,'subject_id':subjectId,'tutor_id':tutorRecord?['id'],
        'title':title.text.trim(),'instructions':instructions.text.trim().isEmpty?null:instructions.text.trim(),
        'max_score':maxScore,'due_at':dueDate?.toUtc().toIso8601String(),
        'published_at':DateTime.now().toUtc().toIso8601String(),
      });
      await _refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Assignment published to this classroom.')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not publish assignment: $e')));
    }finally{title.dispose();instructions.dispose();marks.dispose();due.dispose();if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _createPost() async {
    final title=TextEditingController(),body=TextEditingController(),url=TextEditingController();
    String type='notice'; PlatformFile? file;
    final result=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(
      title:const Text('Add to classroom board'),
      content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Post type'),
          items:const [DropdownMenuItem(value:'notice',child:Text('Class notice')),DropdownMenuItem(value:'explanation',child:Text('Lesson explanation')),DropdownMenuItem(value:'resource',child:Text('Learning resource')),DropdownMenuItem(value:'whiteboard',child:Text('Signboard / whiteboard'))],
          onChanged:(v)=>setDialogState(()=>type=v??'notice')),
        const SizedBox(height:10),TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
        const SizedBox(height:10),TextField(controller:body,minLines:3,maxLines:7,decoration:const InputDecoration(labelText:'Explanation or notice')),
        const SizedBox(height:10),TextField(controller:url,decoration:const InputDecoration(labelText:'Optional video or image URL',hintText:'https://...')),
        const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{
          final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:const ['jpg','jpeg','png','webp','gif','mp4','webm','mov','pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','rtf'],withData:true);
          if(picked!=null&&picked.files.isNotEmpty)setDialogState(()=>file=picked.files.first);
        },icon:const Icon(Icons.attach_file),label:Text(file==null?'Choose image, video or PDF':'Selected: ${file!.name}')),
        const Text('Maximum file size: 100 MB. Files are stored privately for this classroom.',style:TextStyle(fontSize:11,color:AppColors.muted)),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Publish'))],
    )));
    if(result!=true){title.dispose();body.dispose();url.dispose();return;}
    if(title.text.trim().length<3){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a title of at least 3 characters.')));title.dispose();body.dispose();url.dispose();return;}
    if(file==null&&url.text.trim().isNotEmpty&&!url.text.trim().startsWith('https://')){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Resource links must begin with https://')));title.dispose();body.dispose();url.dispose();return;}
    setState(()=>_busy=true);
    try{
      String? mediaPath;
      if(file!=null){
        final bytes=file!.bytes;
        if(bytes==null)throw Exception('This device could not read the selected file. Please choose it again.');
        if(bytes.length>104857600)throw Exception('The selected file is larger than 100 MB.');
        final ext=file!.extension?.toLowerCase()??'bin';
        final mime=const {'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','mp4':'video/mp4','webm':'video/webm','mov':'video/quicktime','pdf':'application/pdf','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','txt':'text/plain','csv':'text/csv','rtf':'application/rtf'}[ext]??'application/octet-stream';
        final safeName=file!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
        mediaPath='$_classId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        await Supabase.instance.client.storage.from('classroom-resources').uploadBinary(mediaPath!,bytes,fileOptions:FileOptions(contentType:mime,upsert:false));
      }
      await Supabase.instance.client.from('classroom_posts').insert({
        'class_id':_classId,'author_id':Supabase.instance.client.auth.currentUser!.id,
        'post_type':type,'title':title.text.trim(),'body':body.text.trim().isEmpty?null:body.text.trim(),
        'media_path':mediaPath,'media_url':url.text.trim().isEmpty?null:url.text.trim(),'is_published':true,
      });
      if(mounted){await _refresh();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Classroom post published.')));}
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not publish: $e')));
    }finally{title.dispose();body.dispose();url.dispose();if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _openMedia(Map<String,dynamic> post) async {
    try{
      final path=post['media_path']?.toString();
      final url=path!=null?await Supabase.instance.client.storage.from('classroom-resources').createSignedUrl(path,3600):post['media_url']?.toString();
      if(url==null||!url.startsWith('https://'))throw Exception('Resource link is unavailable.');
      await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open resource: $e')));}
  }
  IconData _postIcon(String type)=>type=='notice'?Icons.campaign_outlined:type=='explanation'?Icons.lightbulb_outline_rounded:type=='whiteboard'?Icons.edit_note_rounded:Icons.perm_media_outlined;
  String _postLabel(String type)=>type=='notice'?'CLASS NOTICE':type=='explanation'?'EXPLANATION':type=='whiteboard'?'SIGNBOARD':'RESOURCE';
  Widget _postCard(Map<String,dynamic> post){
    final path=post['media_path']?.toString();final url=post['media_url']?.toString();
    final hasMedia=(path!=null&&path.isNotEmpty)||(url!=null&&url.isNotEmpty);
    return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(_postIcon(post['post_type']?.toString()??''),color:AppColors.brown),const SizedBox(width:8),
        Text(_postLabel(post['post_type']?.toString()??''),style:const TextStyle(fontSize:10,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.brown))]),
      const SizedBox(height:8),Text(post['title']?.toString()??'Class post',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:AppColors.ink)),
      if((post['body']??'').toString().isNotEmpty)...[const SizedBox(height:6),Text(post['body'].toString(),style:const TextStyle(color:AppColors.muted,height:1.5))],
      if(hasMedia)...[
        const SizedBox(height:10),
        _mediaPreview(post),
        const SizedBox(height:5),
        OutlinedButton.icon(onPressed:()=>_openMedia(post),
          icon:Icon((path??url??'').toLowerCase().contains('.mp4')||(path??url??'').toLowerCase().contains('.webm')?Icons.play_circle_outline:Icons.open_in_new_rounded),
          label:const Text('Open attached resource')),
      ],
    ])));
  }
  Widget _mediaPreview(Map<String,dynamic> post){
    final path=post['media_path']?.toString();
    final external=post['media_url']?.toString();
    final source=(path??external??'').split('?').first.toLowerCase();
    final isImage=['.jpg','.jpeg','.png','.webp','.gif'].any(source.endsWith);
    final isPdf=source.endsWith('.pdf');
    final isDocument=['.doc','.docx','.xls','.xlsx','.ppt','.pptx','.txt','.csv','.rtf'].any(source.endsWith);
    if(!isImage)return Container(width:double.infinity,padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:AppColors.cream,borderRadius:BorderRadius.circular(12)),
      child:Row(children:[Icon(isPdf?Icons.picture_as_pdf_outlined:isDocument?Icons.description_outlined:Icons.play_circle_outline_rounded,
        color:AppColors.brown,size:30),const SizedBox(width:10),
        Expanded(child:Text(isPdf?'PDF learning material':isDocument?'Attached document':'Video learning resource',
          style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)))]));
    final future=path!=null
      ?Supabase.instance.client.storage.from('classroom-resources').createSignedUrl(path,3600)
      :Future<String>.value(external??'');
    return FutureBuilder<String>(future:future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done||!s.hasData)return const SizedBox(height:80,child:Center(child:CircularProgressIndicator(strokeWidth:2)));
      return ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(s.data!,height:170,width:double.infinity,fit:BoxFit.cover,
        errorBuilder:(_,__,___)=>const SizedBox(height:70,child:Center(child:Text('Image preview unavailable')))));
    });
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text((widget.classroom['name']??'Classroom').toString()),
      actions:[if(widget.canManage)IconButton(onPressed:_busy?null:_createAssignment,icon:const Icon(Icons.post_add_outlined),tooltip:'Create assignment'),
        if(widget.canManage)IconButton(onPressed:_busy?null:_createPost,icon:const Icon(Icons.add_circle_outline),tooltip:'Add classroom content')]),
    floatingActionButton:widget.canManage?FloatingActionButton.extended(onPressed:_busy?null:_createPost,backgroundColor:AppColors.brown,icon:const Icon(Icons.add,color:Colors.white),label:const Text('Add to board',style:TextStyle(color:Colors.white))):null,
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,child:FutureBuilder<Map<String,dynamic>>(future:_data,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
      if(s.hasError)return ListView(children:[_InfoNotice(message:'This classroom could not be loaded. '+s.error.toString())]);
      final d=s.data??{};final lessons=List<Map<String,dynamic>>.from(d['lessons']??[]);final posts=List<Map<String,dynamic>>.from(d['posts']??[]);final assignments=List<Map<String,dynamic>>.from(d['assignments']??[]);
      return ListView(padding:const EdgeInsets.fromLTRB(16,14,16,90),children:[
        ClipRRect(borderRadius:BorderRadius.circular(18),child:SvgPicture.asset('assets/classroom_hero.svg',height:145,width:double.infinity,fit:BoxFit.cover)),
        const SizedBox(height:14),
        Text((widget.classroom['name']??'Classroom').toString()+' learning space',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:AppColors.ink)),
        const SizedBox(height:5),const Text('Everything for this class, organised in one place.',style:TextStyle(color:AppColors.muted)),
        const SizedBox(height:13),
        Row(children:[
          Expanded(child:_classroomStat(Icons.menu_book_outlined,'Lessons',lessons.length)),
          const SizedBox(width:8),Expanded(child:_classroomStat(Icons.assignment_outlined,'Assignments',assignments.length)),
          const SizedBox(width:8),Expanded(child:_classroomStat(Icons.dashboard_outlined,'Board posts',posts.length)),
        ]),
        const SizedBox(height:19),
        _classroomHeading('Class signboard','Notices, explanations and shared resources'),
        if(posts.isEmpty)const _InfoNotice(message:'The classroom board is empty. Your tutor will post explanations, learning resources and notices here.'),
        ...posts.map(_postCard),
        const SizedBox(height:8),_classroomHeading('Lessons and teaching','Published lessons for this class'),
        if(lessons.isEmpty)const _InfoNotice(message:'No lessons have been published for this classroom yet.'),
        ...lessons.map((lesson)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
          leading:const CircleAvatar(backgroundColor:AppColors.paleGold,child:Icon(Icons.play_lesson_outlined,color:AppColors.brown)),
          title:Text(lesson['title']?.toString()??'Lesson',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
          subtitle:Text((lesson['subjects'] is Map?lesson['subjects']['name']:'Learning')?.toString()??'Learning'),
          trailing:const Icon(Icons.chevron_right_rounded),
          onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>LessonDetailPage(lesson:lesson))),
        ))),
        const SizedBox(height:8),_classroomHeading('Assignments','Homework published for this class'),
        if(assignments.isEmpty)const _InfoNotice(message:'No assignments have been published for this classroom yet.'),
        ...assignments.map((a)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
          leading:const CircleAvatar(backgroundColor:AppColors.paleGold,child:Icon(Icons.assignment_outlined,color:AppColors.brown)),
          title:Text(a['title']?.toString()??'Assignment',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
          subtitle:Text('${a['subject_name']??'Subject'} • ${widget.canManage?'Published':(a['submission_status']??'To do')}'),
          trailing:widget.canManage?null:const Icon(Icons.chevron_right_rounded),
          onTap:widget.canManage?null:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>StudentAssignmentDetailPage(assignment:a))),
        ))),
      ]);
    })),
  );
}

Widget _classroomStat(IconData icon,String label,int value)=>Container(
  padding:const EdgeInsets.symmetric(vertical:12,horizontal:7),
  decoration:BoxDecoration(color:AppColors.cream,borderRadius:BorderRadius.circular(13)),
  child:Column(children:[Icon(icon,color:AppColors.brown,size:19),const SizedBox(height:5),
    Text(value.toString(),style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900,color:AppColors.ink)),
    Text(label,style:const TextStyle(fontSize:10,color:AppColors.muted))]),
);
Widget _classroomHeading(String title,String subtitle)=>Padding(
  padding:const EdgeInsets.only(bottom:10,top:8),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:AppColors.ink)),
    const SizedBox(height:3),Text(subtitle,style:const TextStyle(fontSize:12,color:AppColors.muted)),
  ]),
);

class LessonDetailPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final bool allowCompletion;
  const LessonDetailPage({super.key, required this.lesson, this.allowCompletion = true});
  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}
class _LessonDetailPageState extends State<LessonDetailPage> {
  late Future<List<Map<String, dynamic>>> _materials;
  late Future<bool> _completed;
  bool _markingComplete = false;
  @override
  void initState() {
    super.initState();
    _materials = Supabase.instance.client.from('learning_materials').select('id,title,material_type,storage_path,external_url')
      .eq('lesson_id', widget.lesson['id']).then((rows) => List<Map<String, dynamic>>.from(rows));
    _completed = widget.allowCompletion ? _loadCompletion() : Future<bool>.value(false);
  }
  Future<bool> _loadCompletion() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await Supabase.instance.client.from('lesson_completions').select('id')
      .eq('user_id', userId).eq('lesson_id', widget.lesson['id']).maybeSingle();
    return row != null;
  }
  Future<void> _markComplete() async {
    setState(() => _markingComplete = true);
    try {
      await Supabase.instance.client.rpc('mark_lesson_completed', params: {'p_lesson_id': widget.lesson['id']});
      if (mounted) {
        setState(() => _completed = Future<bool>.value(true));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson marked as completed.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update lesson progress: $e')));
    } finally { if (mounted) setState(() => _markingComplete = false); }
  }
  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(appBar: AppBar(title: const Text('Lesson details')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(lesson['title'] ?? 'Lesson', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
      const SizedBox(height: 9),
      if (lesson['description'] != null) Text(lesson['description'], style: const TextStyle(color: AppColors.muted, height: 1.5)),
      if (lesson['live_class_url'] is String && (lesson['live_class_url'] as String).startsWith('https://')) ...[
        const SizedBox(height: 14),
        Card(child: ListTile(
          leading: const Icon(Icons.video_camera_front_outlined, color: AppColors.brown),
          title: const Text('Join live class', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Open your tutor’s virtual classroom'),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () => launchUrl(Uri.parse(lesson['live_class_url'] as String), mode: LaunchMode.externalApplication),
        )),
      ],
      if (lesson['scheduled_at'] != null) ...[
        const SizedBox(height: 8),
        Text('Live class schedule: ${DateTime.tryParse(lesson['scheduled_at'].toString())?.toLocal().toString() ?? ''}',
          style: const TextStyle(color: AppColors.muted)),
      ],
      if (widget.allowCompletion) ...[
        const SizedBox(height: 14),
        FutureBuilder<bool>(future: _completed, builder: (context, progress) {
          final done = progress.data == true;
          return Card(child: ListTile(
            leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? Colors.green.shade700 : AppColors.brown),
            title: Text(done ? 'Lesson completed' : 'Mark lesson as completed',
              style: const TextStyle(fontWeight: FontWeight.w700,color:AppColors.ink)),
            subtitle: Text(done ? 'Your progress has been saved.' : 'Mark this lesson when you have finished studying it.'),
            trailing: _markingComplete ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : null,
            onTap: done || _markingComplete ? null : _markComplete,
          ));
        }),
      ],
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
  final bool parent;
  const _AnalyticsTab({this.owner = false, this.admin = false, this.parent = false});
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
      client.from('learning_access_requests').select('id').eq('user_id', userId).eq('status', 'approved'),
      client.from('assignment_submissions').select('id,status,score,assignments(max_score)').eq('student_id', studentId),
      client.from('assessment_attempts').select('id').eq('student_id', studentId),
      client.from('results').select('id').eq('student_id', studentId).not('published_at', 'is', null),
      client.from('attendance_records').select('id,status').eq('student_id', studentId),
      client.from('lesson_completions').select('id').eq('user_id', userId),
      client.from('lessons').select('id').eq('is_published', true),
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
      'programmes': values[0].length,
      'submissions': submissions.length,
      'graded': graded.length,
      'assignment_average': average,
      'attempts': values[2].length,
      'results': values[3].length,
      'attendance_days': attendance.length,
      'attendance_rate': attendanceRate,
      'completed_lessons': values[5].length,
      'available_lessons': values[6].length,
    };
  }

  Future<void> _refresh() async {
    final next = _loadStats();
    setState(() => _stats = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parent) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Your child’s progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 7),
        const Text('View linked children, assignments, published results and attendance from your parent dashboard.',
          style: TextStyle(color: AppColors.muted, height: 1.45)),
        const SizedBox(height: 18),
        Card(child: ListTile(
          leading: const Icon(Icons.family_restroom_outlined, color: AppColors.brown),
          title: const Text('Open parent dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Review your linked children and learning progress'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const GuardianPortalPage())),
        )),
      ]);
    }
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
                message: 'Your learner profile is not ready yet. Your learning statistics will appear once your account is activated for a programme.',
              );
            }
            return Column(
              children: [
                _FeatureRow(
                  icon: Icons.class_outlined,
                  title: 'Active learning programmes',
                  detail: stats['programmes'].toString() + ' approved programmes',
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
                _FeatureRow(
                  icon: Icons.menu_book_outlined,
                  title: 'Lessons completed',
                  detail: stats['completed_lessons'].toString() + ' of ' + stats['available_lessons'].toString() + ' published lessons completed',
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
  const _ProfileTab({required this.account,required this.onRetry,required this.onSignOut});

  Widget _detail(String label, String value, IconData icon) => value.trim().isEmpty
      ? const SizedBox.shrink()
      : Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
          leading:Icon(icon,color:AppColors.brown),title:Text(label),
          subtitle:Text(value,style:const TextStyle(height:1.35))));

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String,dynamic>>(
    future:account,
    builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)
        return const Center(child:CircularProgressIndicator(color:AppColors.brown));
      if(snapshot.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('Your profile could not be loaded.'),
          const SizedBox(height:12),OutlinedButton(onPressed:onRetry,child:const Text('Try again')),
        ])));
      final data=snapshot.data!;
      final avatar=(data['avatar_url']??'').toString();
      return ListView(padding:const EdgeInsets.all(20),children:[
        Center(child:Column(children:[
          CircleAvatar(radius:46,backgroundColor:AppColors.paleGold,
            backgroundImage:avatar.isEmpty?null:NetworkImage(avatar),
            child:avatar.isEmpty?Text((data['name'] as String).trim().isEmpty?'L':(data['name'] as String).trim()[0].toUpperCase(),
              style:const TextStyle(fontSize:30,fontWeight:FontWeight.w700,color:AppColors.brown)):null),
          const SizedBox(height:12),
          Text(data['name'] as String,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:AppColors.ink)),
          const SizedBox(height:4),Text(data['role'] as String,style:const TextStyle(color:AppColors.muted)),
          const SizedBox(height:12),
          OutlinedButton.icon(
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>ProfileEditorPage(onSaved:onRetry))),
            icon:const Icon(Icons.edit_outlined),label:const Text('Edit my profile')),
        ])),
        const SizedBox(height:24),
        const Text('ACCOUNT DETAILS',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:10),
        Card(child:ListTile(leading:const Icon(Icons.email_outlined,color:AppColors.brown),
          title:const Text('Email address'),subtitle:Text(data['email'] as String))),
        const SizedBox(height:8),
        Card(child:ListTile(leading:const Icon(Icons.verified_user_outlined,color:AppColors.brown),
          title:const Text('Account type'),subtitle:Text(data['role'] as String))),
        const SizedBox(height:22),
        const Text('ABOUT ME',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:10),
        _detail('About me',(data['about_me']??'').toString(),Icons.person_outline),
        _detail('What I do',(data['occupation']??'').toString(),Icons.work_outline),
        _detail('Class / level',(data['profile_class']??'').toString(),Icons.school_outlined),
        _detail('Interests',(data['interests']??'').toString(),Icons.favorite_border),
        _detail('Skills',(data['skills']??'').toString(),Icons.auto_awesome_outlined),
        _detail('What I hope to become',(data['aspirations']??'').toString(),Icons.flag_outlined),
        _detail('Phone / WhatsApp',(data['phone']??'').toString(),Icons.phone_outlined),
        const SizedBox(height:20),
        const Text('APPEARANCE',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
        const SizedBox(height:10),
        Card(child:ValueListenableBuilder<ThemeMode>(valueListenable:AppThemeController.mode,
          builder:(context,mode,_)=>SwitchListTile(
            secondary:Icon(mode==ThemeMode.dark?Icons.dark_mode_rounded:Icons.light_mode_rounded,color:Theme.of(context).colorScheme.primary),
            title:const Text('Dark theme'),subtitle:Text(mode==ThemeMode.dark?'Dark appearance is enabled':'Use the light appearance'),
            value:mode==ThemeMode.dark,activeColor:AppColors.gold,onChanged:AppThemeController.setDark))),
        const SizedBox(height:24),
        OutlinedButton.icon(onPressed:onSignOut,icon:const Icon(Icons.logout_rounded),label:const Text('Sign out'),
          style:OutlinedButton.styleFrom(foregroundColor:AppColors.brown,padding:const EdgeInsets.symmetric(vertical:14),side:const BorderSide(color:AppColors.line))),
      ]);
    });
}

class ProfileEditorPage extends StatefulWidget {
  final VoidCallback onSaved;
  const ProfileEditorPage({super.key,required this.onSaved});
  @override
  State<ProfileEditorPage> createState()=>_ProfileEditorPageState();
}
class _ProfileEditorPageState extends State<ProfileEditorPage>{
  final _about=TextEditingController(),_occupation=TextEditingController(),_class=TextEditingController(),
    _interests=TextEditingController(),_skills=TextEditingController(),_goals=TextEditingController(),_phone=TextEditingController();
  bool _loading=true,_saving=false,_removeAvatar=false;
  String? _avatarUrl;
  PlatformFile? _photo;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load()async{
    try{
      final uid=Supabase.instance.client.auth.currentUser!.id;
      final row=await Supabase.instance.client.from('profiles')
        .select('phone,avatar_url,about_me,occupation,profile_class,interests,skills,aspirations')
        .eq('id',uid).single();
      _about.text=(row['about_me']??'').toString();_occupation.text=(row['occupation']??'').toString();
      _class.text=(row['profile_class']??'').toString();_interests.text=(row['interests']??'').toString();
      _skills.text=(row['skills']??'').toString();_goals.text=(row['aspirations']??'').toString();
      _phone.text=(row['phone']??'').toString();_avatarUrl=row['avatar_url']?.toString();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Profile details could not load: $e')));}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _choosePhoto()async{
    final result=await FilePicker.platform.pickFiles(type:FileType.image,withData:true);
    if(result==null||result.files.isEmpty)return;
    final file=result.files.first;
    if(file.size>5242880){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Choose an image smaller than 5 MB.')));return;}
    if(!['jpg','jpeg','png','webp'].contains(file.extension?.toLowerCase())){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Use a JPG, PNG or WebP image.')));return;}
    if(mounted)setState((){_photo=file;_removeAvatar=false;});
  }
  Future<void> _save()async{
    setState(()=>_saving=true);
    String? uploadedPath;
    try{
      final db=Supabase.instance.client,uid=db.auth.currentUser!.id;
      String? nextAvatar=_removeAvatar?null:_avatarUrl;
      if(_photo!=null){
        final bytes=_photo!.bytes;if(bytes==null)throw Exception('The selected image could not be read.');
        final ext=_photo!.extension!.toLowerCase();
        uploadedPath='$uid/avatar.$ext';
        await db.storage.from('profile-avatars').uploadBinary(uploadedPath!,bytes,
          fileOptions:FileOptions(contentType:ext=='jpg'||ext=='jpeg'?'image/jpeg':'image/$ext',upsert:true));
        nextAvatar=db.storage.from('profile-avatars').getPublicUrl(uploadedPath!);
      }
      String? optional(String v)=>v.trim().isEmpty?null:v.trim();
      await db.from('profiles').update({
        'phone':optional(_phone.text),'avatar_url':nextAvatar,
        'about_me':optional(_about.text),'occupation':optional(_occupation.text),
        'profile_class':optional(_class.text),'interests':optional(_interests.text),
        'skills':optional(_skills.text),'aspirations':optional(_goals.text),
      }).eq('id',uid);
      if(_removeAvatar&&_avatarUrl!=null){
        try{final uri=Uri.parse(_avatarUrl!);final marker='/profile-avatars/';final i=uri.path.indexOf(marker);
          if(i>=0)await db.storage.from('profile-avatars').remove([uri.path.substring(i+marker.length)]);
        }catch(_){}
      }
      if(!mounted)return;
      final messenger=ScaffoldMessenger.of(context);
      widget.onSaved();Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content:Text('Your profile has been updated.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Profile could not be saved: $e')));}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  Widget _field(TextEditingController c,String label,{int lines=1,int maxLength=300,String? hint})=>Padding(
    padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c,minLines:lines,maxLines:lines==1?1:4,
      maxLength:maxLength,decoration:InputDecoration(labelText:label,hintText:hint,alignLabelWithHint:lines>1)));
  @override
  void dispose(){_about.dispose();_occupation.dispose();_class.dispose();_interests.dispose();_skills.dispose();_goals.dispose();_phone.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){
    final ImageProvider? photoProvider=_photo?.bytes!=null
      ?MemoryImage(_photo!.bytes!)
      :(_removeAvatar||_avatarUrl==null?null:NetworkImage(_avatarUrl!));
    return Scaffold(appBar:AppBar(title:const Text('Edit my profile')),
    body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Make your profile your own',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),const Text('Everything here is optional. Add one detail, several details, or leave everything blank. Your account will work normally either way.',style:TextStyle(color:AppColors.muted,height:1.45)),
      const SizedBox(height:18),
      Center(child:Column(children:[
        CircleAvatar(radius:48,backgroundColor:AppColors.paleGold,
          backgroundImage:photoProvider,
          child:_photo==null&&(_avatarUrl==null||_removeAvatar)?const Icon(Icons.person_outline,size:42,color:AppColors.brown):null),
        const SizedBox(height:8),Wrap(spacing:8,children:[
          OutlinedButton.icon(onPressed:_saving?null:_choosePhoto,icon:const Icon(Icons.photo_camera_outlined),label:const Text('Choose photo')),
          if(_avatarUrl!=null&&!_removeAvatar)TextButton(onPressed:()=>setState(()=>_removeAvatar=true),child:const Text('Remove photo')),
          if(_removeAvatar)TextButton(onPressed:()=>setState(()=>_removeAvatar=false),child:const Text('Keep current photo')),
        ]),
      ])),
      const SizedBox(height:20),
      _field(_about,'About me',lines:3,maxLength:600,hint:'A little about yourself...'),
      _field(_occupation,'What I do',maxLength:100,hint:'Student, teacher, designer, business owner...'),
      _field(_class,'Class / level',maxLength:80,hint:'Optional profile description of your class or level'),
      _field(_interests,'Interests',lines:2,hint:'Things you enjoy learning or doing...'),
      _field(_skills,'Skills',lines:2,hint:'Skills you have or are developing...'),
      _field(_goals,'What I hope to become',lines:2,hint:'Your dreams, career goals or ambitions...'),
      _field(_phone,'Phone / WhatsApp number',hint:'Optional contact number'),
      const SizedBox(height:8),
      FilledButton.icon(onPressed:_saving?null:_save,icon:const Icon(Icons.save_outlined),label:Text(_saving?'Saving...':'Save profile')),
      const SizedBox(height:12),const Text('Your name and sign-in email are managed by your account and are not changed here.',style:TextStyle(fontSize:12,color:AppColors.muted)),
    ]));
  }
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 46, height: 46,
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: colors.onSecondaryContainer)),
        title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w800, color: colors.onSurface)),
        subtitle: Text(detail, style: TextStyle(
          color: colors.onSurfaceVariant, height: 1.45)),
        trailing: Icon(Icons.chevron_right_rounded,
          color: colors.onSurfaceVariant),
      ),
    );
  }
}



class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});
  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}
class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  late Future<List<Map<String,dynamic>>> _items;
  String _filter = 'All';
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
  String _status(Map<String,dynamic> row) {
    final status=(row['submission_status']??'not submitted').toString();
    if(status=='graded')return 'Graded';
    if(status=='submitted')return 'Submitted';
    if(status=='returned')return 'Returned';
    final due=DateTime.tryParse(row['due_at']?.toString()??'');
    if(due!=null&&due.isBefore(DateTime.now().toUtc()))return 'Overdue';
    return 'To do';
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('My assignments')),
    body:RefreshIndicator(color:AppColors.brown,onRefresh:_refresh,
      child:FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Assignments could not be loaded. '+s.error.toString())]);
        final all=s.data??[];
        final rows=all.where((r)=>_filter=='All'||_status(r)==_filter).toList();
        final pending=all.where((r)=>_status(r)=='To do'||_status(r)=='Overdue'||_status(r)=='Returned').length;
        final grouped=<String,Map<String,List<Map<String,dynamic>>>>{};
        for(final row in rows){
          final className=(row['class_name']??'Class not specified').toString();
          final subject=(row['subject_name']??'Other subjects').toString();
          grouped.putIfAbsent(className,()=>{});
          grouped[className]!.putIfAbsent(subject,()=>[]).add(row);
        }
        final classNames=grouped.keys.toList()..sort((a,b){
          final rank=_schoolLevelRank(a).compareTo(_schoolLevelRank(b));
          return rank!=0?rank:a.compareTo(b);
        });
        return ListView(padding:const EdgeInsets.all(18),children:[
          const Text('Class assignments',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:5),
          const Text('Your published homework is arranged by subject. Check the due date and submission status before opening each task.',style:TextStyle(color:AppColors.muted,height:1.4)),
          const SizedBox(height:13),
          Wrap(spacing:7,runSpacing:7,children:[
            for(final filter in ['All','To do','Overdue','Submitted','Returned','Graded'])
              ChoiceChip(label:Text(filter=='To do'?'To do ($pending)':filter),selected:_filter==filter,
                onSelected:(_)=>setState(()=>_filter=filter),selectedColor:AppColors.paleGold),
          ]),
          const SizedBox(height:13),
          if(all.isEmpty) const _InfoNotice(message:'No assignments have been published for your approved class yet. When your tutor publishes homework, it will appear here under its subject.'),
          if(all.isNotEmpty&&rows.isEmpty) _InfoNotice(message:'There are no assignments in the '+_filter.toLowerCase()+' category.'),
          for(final className in classNames)...[
            Padding(padding:const EdgeInsets.only(top:12,bottom:5),child:Text(className.toUpperCase(),
              style:const TextStyle(fontSize:14,letterSpacing:.6,fontWeight:FontWeight.w900,color:AppColors.ink))),
            for(final subject in (grouped[className]!.keys.toList()..sort()))...[
              Padding(padding:const EdgeInsets.only(top:6,bottom:7,left:5),child:Text(subject.toUpperCase(),
                style:const TextStyle(fontSize:11,letterSpacing:1,fontWeight:FontWeight.w800,color:AppColors.brown))),
            ...grouped[className]![subject]!.map((r){
              final status=_status(r);
              final isOverdue=status=='Overdue';
              final done=status=='Graded';
              return Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(
                contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:8),
                leading:Container(width:42,height:42,decoration:BoxDecoration(color:AppColors.paleGold,borderRadius:BorderRadius.circular(11)),
                  child:const Icon(Icons.assignment_outlined,color:AppColors.brown)),
                title:Text(r['title']?.toString()??'Assignment',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.ink)),
                subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Text(
                  _date(r['due_at'])+'\\n'+(done?'Graded • '+(r['score']??'—').toString()+' marks':status=='Submitted'?'Submitted • Awaiting marking':status=='Returned'?'Returned for correction':isOverdue?'Overdue • Not submitted':'Not submitted'),
                  style:const TextStyle(color:AppColors.muted,height:1.45))),
                trailing:const Icon(Icons.chevron_right_rounded,color:AppColors.brown),
                onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>StudentAssignmentDetailPage(assignment:r))).then((_)=>_refresh()),
              ));
            }),
            ],
          ],
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
    return raw.map((e) => Map<String, dynamic>.from(e as Map))
      .where((e) => e['is_past_question'] != true).toList();
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
          const Text('Only tests for your approved learning programmes appear here.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StudentQuestionBankPage())),
            icon: const Icon(Icons.library_books_outlined), label: const Text('Browse past-question bank')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _openHistory, icon: const Icon(Icons.history_rounded), label: const Text('View my previous results')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>const StudentReleasedResultsPage())),
            icon:const Icon(Icons.school_outlined),
            label:const Text('View released school report cards'),
          ),
          const SizedBox(height:8),
          OutlinedButton.icon(
            onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>const StudentDirectChatPage())),
            icon:const Icon(Icons.chat_bubble_outline),
            label:const Text('Message the Centre'),
          ),
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


class StudentQuestionBankPage extends StatefulWidget {
  const StudentQuestionBankPage({super.key});
  @override
  State<StudentQuestionBankPage> createState() => _StudentQuestionBankPageState();
}

class _StudentQuestionBankPageState extends State<StudentQuestionBankPage> {
  late Future<List<Map<String,dynamic>>> _items;
  late Future<Set<String>> _saved;
  String _body = 'All';
  String _subject = 'All';
  bool _savedOnly = false;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() { super.initState(); _items = _loadItems(); _saved = _loadSaved(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<List<Map<String,dynamic>>> _loadItems() async {
    final raw = await Supabase.instance.client.rpc('student_available_assessments');
    if (raw is! List) return [];
    return raw.map((e) => Map<String,dynamic>.from(e as Map))
      .where((e) => e['is_past_question'] == true).toList();
  }
  Future<Set<String>> _loadSaved() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return <String>{};
    final rows = await Supabase.instance.client.from('assessment_bookmarks')
      .select('assessment_id').eq('user_id', uid);
    return List<Map<String,dynamic>>.from(rows).map((e) => e['assessment_id'].toString()).toSet();
  }
  Future<void> _refresh() async {
    final items = _loadItems(); final saved = _loadSaved();
    setState(() { _items = items; _saved = saved; });
    await Future.wait([items,saved]);
  }
  Future<void> _toggleSaved(String id, Set<String> saved) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (saved.contains(id)) {
        await Supabase.instance.client.from('assessment_bookmarks').delete()
          .eq('user_id',uid).eq('assessment_id',id);
      } else {
        await Supabase.instance.client.from('assessment_bookmarks')
          .insert({'user_id':uid,'assessment_id':id});
      }
      if (mounted) setState(() => _saved = _loadSaved());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark could not be updated: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Past-question bank')),
    body: RefreshIndicator(color: AppColors.brown,onRefresh:_refresh,
      child: FutureBuilder<List<Map<String,dynamic>>>(future:_items,builder:(context,itemsSnap){
        if(itemsSnap.connectionState!=ConnectionState.done)
          return const Center(child:CircularProgressIndicator(color:AppColors.brown));
        if(itemsSnap.hasError)
          return ListView(padding:const EdgeInsets.all(20),children:[
            _InfoNotice(message:'The question bank could not be loaded. '+itemsSnap.error.toString())]);
        final all=itemsSnap.data??[];
        final bodies=all.map((e)=>e['exam_body']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList()..sort();
        bodies.insert(0,'All');
        final subjects=all.map((e)=>e['subject_name']?.toString()??'').where((e)=>e.isNotEmpty).toSet().toList()..sort();
        subjects.insert(0,'All');
        return FutureBuilder<Set<String>>(future:_saved,builder:(context,savedSnap){
          final saved=savedSnap.data??<String>{};
          final query=_search.text.trim().toLowerCase();
          final filtered=all.where((e){
            final body=e['exam_body']?.toString()??'';
            final subject=e['subject_name']?.toString()??'';
            final searchable=[e['title'],e['exam_name'],e['topic'],e['exam_year'],subject,e['class_name']]
              .whereType<Object>().join(' ').toLowerCase();
            return (_body=='All'||body==_body)&&(_subject=='All'||subject==_subject)
              &&(!_savedOnly||saved.contains(e['id'].toString()))&&(query.isEmpty||searchable.contains(query));
          }).toList();
          return ListView(padding:const EdgeInsets.all(18),children:[
            const Text('Practise with organised examination questions',
              style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:AppColors.ink)),
            const SizedBox(height:5),
            const Text('Choose an examination body, subject or topic. Save useful sets to return to them later.',
              style:TextStyle(color:AppColors.muted)),
            const SizedBox(height:14),
            TextField(controller:_search,onChanged:(_)=>setState((){}),
              decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search topic, year or exam')),
            const SizedBox(height:10),
            DropdownButtonFormField<String>(value:_body,decoration:const InputDecoration(labelText:'Examination body'),
              items:bodies.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
              onChanged:(v)=>setState(()=>_body=v??'All')),
            const SizedBox(height:8),
            DropdownButtonFormField<String>(value:_subject,decoration:const InputDecoration(labelText:'Subject'),
              items:subjects.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
              onChanged:(v)=>setState(()=>_subject=v??'All')),
            SwitchListTile(contentPadding:EdgeInsets.zero,value:_savedOnly,
              title:const Text('Show saved question sets'),onChanged:(v)=>setState(()=>_savedOnly=v)),
            const SizedBox(height:8),
            if(savedSnap.connectionState!=ConnectionState.done) const LinearProgressIndicator(),
            if(filtered.isEmpty) const _InfoNotice(message:'No question sets match these filters yet. Published past-question sets for your approved class will appear here.'),
            ...filtered.map((e){
              final id=e['id'].toString();
              final count=(e['question_count'] as num?)?.toInt()??0;
              final year=e['exam_year']?.toString();
              final meta=[e['exam_body'],e['exam_name'],year,e['subject_name'],e['class_name']]
                .where((v)=>v!=null&&v.toString().isNotEmpty).join(' • ');
              return Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:ListTile(
                contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
                title:Text(e['title']?.toString()??'Question set',
                  style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
                subtitle:Padding(padding:const EdgeInsets.only(top:6),child:Text(
                  meta+(e['topic']==null?'':'\nTopic: '+e['topic'].toString())+'\n'+count.toString()+' questions',
                  style:const TextStyle(color:AppColors.muted))),
                trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  IconButton(tooltip:saved.contains(id)?'Remove bookmark':'Save question set',
                    onPressed:()=>_toggleSaved(id,saved),
                    icon:Icon(saved.contains(id)?Icons.bookmark:Icons.bookmark_border,color:AppColors.brown)),
                  const Icon(Icons.chevron_right,color:AppColors.brown),
                ]),
                onTap:count==0?null:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                  builder:(_)=>StudentAssessmentRunnerPage(assessment:e))),
              )));
            }),
          ]);
        });
      }),
    ),
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

class StaffRoomPage extends StatefulWidget {
  final bool canAnnounce;
  const StaffRoomPage({super.key,this.canAnnounce=false});
  @override
  State<StaffRoomPage> createState()=>_StaffRoomPageState();
}
class _StaffRoomPageState extends State<StaffRoomPage>{
  final _composer=TextEditingController();
  late Future<List<Map<String,dynamic>>> _messages;
  dynamic _channel;
  bool _sending=false,_announcement=false;
  PlatformFile? _attachment;
  static const _extensions=['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','rtf','jpg','jpeg','png','webp','gif','mp4','webm','mov'];
  @override
  void initState(){super.initState();_messages=_load();_subscribe();}
  Future<List<Map<String,dynamic>>> _load() async{
    final rows=await Supabase.instance.client.from('staff_room_messages')
      .select('id,sender_id,sender_name,body,message_type,pinned,created_at,attachment_path,attachment_name,attachment_mime_type,attachment_size')
      .order('created_at',ascending:false).limit(150);
    return List<Map<String,dynamic>>.from(rows);
  }
  void _subscribe(){
    _channel=Supabase.instance.client.channel('staff-room-live')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'staff_room_messages',callback:(_)=>_refresh()).subscribe();
  }
  Future<void> _refresh() async{final next=_load();if(mounted)setState(()=>_messages=next);await next;}
  String _mime(PlatformFile file){
    final ext=file.extension?.toLowerCase()??'';
    return const {
      'pdf':'application/pdf','doc':'application/msword',
      'docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt':'text/plain','csv':'text/csv','rtf':'application/rtf',
      'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif',
      'mp4':'video/mp4','webm':'video/webm','mov':'video/quicktime',
    }[ext]??'application/octet-stream';
  }
  Future<void> _chooseFile() async{
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:_extensions,withData:true);
    if(result!=null&&result.files.isNotEmpty&&mounted){
      final file=result.files.first;
      if(file.size>52428800){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Attachments must be 50 MB or smaller.')));return;}
      setState(()=>_attachment=file);
    }
  }
  Future<void> _openAttachment(Map<String,dynamic> row) async{
    try{
      final path=row['attachment_path']?.toString();
      if(path==null||path.isEmpty)throw Exception('Attachment not found.');
      final url=await Supabase.instance.client.storage.from('platform-attachments').createSignedUrl(path,3600);
      await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open attachment: $e')));}
  }
  Future<void> _send() async{
    final body=_composer.text.trim();
    if((body.isEmpty&&_attachment==null)||_sending)return;
    setState(()=>_sending=true);
    String? path;
    try{
      String? fileName,mime;int? size;
      if(_attachment!=null){
        final file=_attachment!,bytes=file.bytes;
        if(bytes==null)throw Exception('The selected file could not be read. Please choose it again.');
        final uid=Supabase.instance.client.auth.currentUser!.id;
        fileName=file.name;mime=_mime(file);size=file.size;
        final safe=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
        path='staff-room/$uid/${DateTime.now().microsecondsSinceEpoch}_$safe';
        await Supabase.instance.client.storage.from('platform-attachments')
          .uploadBinary(path!,bytes,fileOptions:FileOptions(contentType:mime,upsert:false));
      }
      await Supabase.instance.client.from('staff_room_messages').insert({
        'sender_id':Supabase.instance.client.auth.currentUser!.id,
        'body':body.isEmpty?'Shared a file':body,
        'message_type':_announcement?'announcement':'message',
        'attachment_path':path,'attachment_name':fileName,
        'attachment_mime_type':mime,'attachment_size':size,
      });
      _composer.clear();
      if(mounted)setState((){_announcement=false;_attachment=null;});
      await _refresh();
    }catch(e){
      if(path!=null){try{await Supabase.instance.client.storage.from('platform-attachments').remove([path]);}catch(_){}}
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Message could not be sent: $e')));
    }finally{if(mounted)setState(()=>_sending=false);}
  }
  @override
  void dispose(){_composer.dispose();if(_channel!=null)Supabase.instance.client.removeChannel(_channel);super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Staff Room')),
    body:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(16),color:AppColors.cream,
        child:const Row(children:[Icon(Icons.lock_outline,color:AppColors.brown),SizedBox(width:10),
          Expanded(child:Text('A private space for tutors, employees and centre coordinators.',style:TextStyle(color:AppColors.ink,fontWeight:FontWeight.w600)))])),
      Expanded(child:RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<Map<String,dynamic>>>(
        future:_messages,builder:(context,s){
          if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
          if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Staff messages could not be loaded. Check your staff access and try again.')]);
          final rows=s.data??[];
          if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(24),children:[const SizedBox(height:60),
            Icon(Icons.forum_outlined,size:48,color:AppColors.gold),const SizedBox(height:12),
            const _InfoNotice(message:'The staff room is ready. The first coordinator message or staff conversation will appear here.')]);
          return ListView.builder(reverse:true,padding:const EdgeInsets.all(14),itemCount:rows.length,itemBuilder:(context,index){
            final r=rows[index];final announcement=r['message_type']=='announcement';
            return Card(color:announcement?AppColors.cream:null,margin:const EdgeInsets.only(bottom:9),
              child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Expanded(child:Text(r['sender_name']?.toString()??'Staff member',style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink))),
                  if(announcement)const Chip(label:Text('CENTRE NOTICE'),visualDensity:VisualDensity.compact)]),
                const SizedBox(height:5),Text(r['body'].toString(),style:const TextStyle(height:1.45,color:AppColors.ink)),
                if((r['attachment_path']??'').toString().isNotEmpty)
                  Align(alignment:Alignment.centerLeft,child:TextButton.icon(
                    onPressed:()=>_openAttachment(r),icon:const Icon(Icons.attach_file),
                    label:Text((r['attachment_name']??'Open attachment').toString(),maxLines:1,overflow:TextOverflow.ellipsis))),
                const SizedBox(height:5),Text(_staffDate(r['created_at']),style:const TextStyle(fontSize:11,color:AppColors.muted)),
              ])));
          });
        }))),
      SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Column(children:[
        if(widget.canAnnounce)CheckboxListTile(value:_announcement,onChanged:(v)=>setState(()=>_announcement=v??false),
          dense:true,contentPadding:EdgeInsets.zero,title:const Text('Post as a centre announcement')),
        if(_attachment!=null)Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
          decoration:BoxDecoration(color:AppColors.cream,borderRadius:BorderRadius.circular(9)),
          child:Row(children:[const Icon(Icons.attach_file,size:17),Expanded(child:Text(_attachment!.name,maxLines:1,overflow:TextOverflow.ellipsis)),
            IconButton(onPressed:()=>setState(()=>_attachment=null),icon:const Icon(Icons.close,size:18))])),
        Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
          IconButton(onPressed:_sending?null:_chooseFile,tooltip:'Attach a document or file',icon:const Icon(Icons.attach_file)),
          Expanded(child:TextField(controller:_composer,minLines:1,maxLines:4,
            decoration:const InputDecoration(hintText:'Write a staff message...',border:OutlineInputBorder()))),
          const SizedBox(width:8),IconButton.filled(onPressed:_sending?null:_send,
            style:IconButton.styleFrom(backgroundColor:AppColors.brown,foregroundColor:Colors.white),
            icon:_sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.send_rounded)),
        ]),
      ]))),
    ]),
  );
}


class StudentDirectChatPage extends StatefulWidget {
  final String? studentId;
  final String? studentName;
  final bool admin;
  const StudentDirectChatPage({super.key,this.studentId,this.studentName,this.admin=false});
  @override
  State<StudentDirectChatPage> createState()=>_StudentDirectChatPageState();
}
class _StudentDirectChatPageState extends State<StudentDirectChatPage>{
  final _composer=TextEditingController();
  late Future<Map<String,dynamic>> _setup;
  Future<List<Map<String,dynamic>>>? _messages;
  String? _studentId;
  String _studentName='Learner';
  dynamic _channel;
  PlatformFile? _attachment;
  bool _sending=false;
  static const _extensions=['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','rtf','jpg','jpeg','png','webp','gif','mp4','webm','mov'];
  SupabaseClient get _db=>Supabase.instance.client;

  @override
  void initState(){super.initState();_setup=_resolveStudent();}
  Future<Map<String,dynamic>> _resolveStudent() async{
    Map<String,dynamic>? row;
    if(widget.studentId!=null){
      row=await _db.from('students').select('id,profiles(full_name)').eq('id',widget.studentId!).maybeSingle();
    }else{
      final uid=_db.auth.currentUser?.id;
      if(uid==null)throw Exception('Sign in to open your messages.');
      row=await _db.from('students').select('id,profiles(full_name)').eq('user_id',uid).maybeSingle();
    }
    if(row==null)throw Exception('The learner record could not be found.');
    _studentId=row['id'].toString();
    _studentName=(widget.studentName??row['profiles']?['full_name']??'Learner').toString();
    _messages=_loadMessages();
    _subscribe();
    return {'id':_studentId,'name':_studentName};
  }
  Future<List<Map<String,dynamic>>> _loadMessages() async{
    final rows=await _db.from('student_direct_messages')
      .select('id,student_id,sender_id,body,attachment_path,attachment_name,attachment_mime_type,attachment_size,read_at,created_at')
      .eq('student_id',_studentId!).order('created_at',ascending:true).limit(300);
    return List<Map<String,dynamic>>.from(rows);
  }
  void _subscribe(){
    _channel=_db.channel('student-direct-$_studentId')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'student_direct_messages',callback:(_)=>_refresh())
      .subscribe();
  }
  Future<void> _refresh() async{
    if(_studentId==null)return;
    final next=_loadMessages();if(mounted)setState(()=>_messages=next);await next;
  }
  String _mime(PlatformFile file){
    final ext=file.extension?.toLowerCase()??'';
    return const {
      'pdf':'application/pdf','doc':'application/msword',
      'docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt':'text/plain','csv':'text/csv','rtf':'application/rtf',
      'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif',
      'mp4':'video/mp4','webm':'video/webm','mov':'video/quicktime',
    }[ext]??'application/octet-stream';
  }
  Future<void> _chooseFile() async{
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:_extensions,withData:true);
    if(result!=null&&result.files.isNotEmpty&&mounted){
      final file=result.files.first;
      if(file.size>52428800){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Attachments must be 50 MB or smaller.')));return;}
      setState(()=>_attachment=file);
    }
  }
  Future<void> _openAttachment(Map<String,dynamic> row) async{
    try{
      final path=row['attachment_path']?.toString();
      if(path==null||path.isEmpty)throw Exception('Attachment not found.');
      final url=await _db.storage.from('platform-attachments').createSignedUrl(path,3600);
      await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open attachment: $e')));}
  }
  Future<void> _send() async{
    final body=_composer.text.trim();
    if((body.isEmpty&&_attachment==null)||_sending||_studentId==null)return;
    setState(()=>_sending=true);
    String? path;
    try{
      String? fileName,mime;int? size;
      if(_attachment!=null){
        final file=_attachment!;
        final bytes=file.bytes;
        if(bytes==null)throw Exception('The selected file could not be read. Please choose it again.');
        final uid=_db.auth.currentUser!.id;
        fileName=file.name;mime=_mime(file);size=file.size;
        final safe=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
        path='direct-messages/$_studentId/$uid/${DateTime.now().microsecondsSinceEpoch}_$safe';
        await _db.storage.from('platform-attachments').uploadBinary(path!,bytes,
          fileOptions:FileOptions(contentType:mime,upsert:false));
      }
      await _db.from('student_direct_messages').insert({
        'student_id':_studentId,'sender_id':_db.auth.currentUser!.id,
        'body':body.isEmpty?'Shared a file':body,
        'attachment_path':path,'attachment_name':fileName,
        'attachment_mime_type':mime,'attachment_size':size,
      });
      _composer.clear();if(mounted)setState(()=>_attachment=null);await _refresh();
    }catch(e){
      if(path!=null){try{await _db.storage.from('platform-attachments').remove([path]);}catch(_){}}
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Message could not be sent: $e')));
    }finally{if(mounted)setState(()=>_sending=false);}
  }
  @override
  void dispose(){
    _composer.dispose();
    if(_channel!=null)_db.removeChannel(_channel);
    super.dispose();
  }
  Widget _message(Map<String,dynamic> row){
    final mine=row['sender_id']==_db.auth.currentUser?.id;
    final path=(row['attachment_path']??'').toString();
    return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,
      child:Container(
        constraints:const BoxConstraints(maxWidth:340),
        margin:const EdgeInsets.only(bottom:9),
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(
          color:mine?AppColors.brown:Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius:BorderRadius.circular(15),
        ),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(mine?'You':widget.admin?_studentName:'Centre team',
            style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:mine?const Color(0xFFFFD98A):AppColors.brown)),
          const SizedBox(height:5),
          Text(row['body']?.toString()??'',style:TextStyle(height:1.4,color:mine?Colors.white:Theme.of(context).colorScheme.onSurface)),
          if(path.isNotEmpty)
            Align(alignment:Alignment.centerLeft,child:TextButton.icon(
              onPressed:()=>_openAttachment(row),icon:Icon(Icons.attach_file,color:mine?const Color(0xFFFFD98A):AppColors.brown),
              label:Text((row['attachment_name']??'Open attachment').toString(),maxLines:1,overflow:TextOverflow.ellipsis,
                style:TextStyle(color:mine?const Color(0xFFFFD98A):AppColors.brown)))),
          Align(alignment:Alignment.centerRight,child:Text(_staffDate(row['created_at']),
            style:TextStyle(fontSize:10,color:mine?const Color(0xFFE7DED6):AppColors.muted))),
        ]),
      ));
  }
  @override
  Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
    future:_setup,builder:(context,setup){
      if(setup.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));
      if(setup.hasError)return Scaffold(appBar:AppBar(title:const Text('Messages')),
        body:Center(child:Padding(padding:const EdgeInsets.all(22),child:Text('Could not open messages: ${setup.error}'))));
      return Scaffold(
        appBar:AppBar(title:Text(widget.admin?'Chat with $_studentName':'Message the Centre')),
        body:Column(children:[
          Container(width:double.infinity,padding:const EdgeInsets.all(12),color:AppColors.cream,
            child:Text(widget.admin?'Private conversation with this learner.':'A private conversation with the Young Learners Tutorial team.',
              style:const TextStyle(color:AppColors.ink,fontWeight:FontWeight.w600))),
          Expanded(child:RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<Map<String,dynamic>>>(
            future:_messages,builder:(context,s){
              if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
              if(s.hasError)return ListView(children:[_InfoNotice(message:'Messages could not be loaded: ${s.error}')]);
              final rows=s.data??[];
              if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(24),children:[
                const SizedBox(height:70),Icon(Icons.forum_outlined,size:48,color:AppColors.gold),
                const SizedBox(height:12),const Center(child:Text('No messages yet. Start the conversation below.',style:TextStyle(color:AppColors.muted))),
              ]);
              return ListView(reverse:true,padding:const EdgeInsets.all(14),children:rows.reversed.map(_message).toList());
            }))),
          SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Column(children:[
            if(_attachment!=null)Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
              decoration:BoxDecoration(color:AppColors.cream,borderRadius:BorderRadius.circular(9)),
              child:Row(children:[const Icon(Icons.attach_file,size:17),Expanded(child:Text(_attachment!.name,maxLines:1,overflow:TextOverflow.ellipsis)),
                IconButton(onPressed:()=>setState(()=>_attachment=null),icon:const Icon(Icons.close,size:18))])),
            Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
              IconButton(onPressed:_sending?null:_chooseFile,tooltip:'Attach a document or file',icon:const Icon(Icons.attach_file)),
              Expanded(child:TextField(controller:_composer,minLines:1,maxLines:4,
                decoration:const InputDecoration(hintText:'Write a message...',border:OutlineInputBorder()))),
              const SizedBox(width:8),IconButton.filled(onPressed:_sending?null:_send,
                style:IconButton.styleFrom(backgroundColor:AppColors.brown,foregroundColor:Colors.white),
                icon:_sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.send_rounded)),
            ]),
          ]))),
        ]),
      );
    },
  );
}

String _staffDate(dynamic raw){
  if(raw==null)return '';
  final d=DateTime.tryParse(raw.toString())?.toLocal();if(d==null)return '';
  String two(int n)=>n.toString().padLeft(2,'0');
  return '${d.day}/${d.month}/${d.year} • ${two(d.hour)}:${two(d.minute)}';
}

class TutorInterviewCentrePage extends StatefulWidget{
  final bool admin;
  const TutorInterviewCentrePage({super.key,this.admin=false});
  @override
  State<TutorInterviewCentrePage> createState()=>_TutorInterviewCentrePageState();
}
class _TutorInterviewCentrePageState extends State<TutorInterviewCentrePage>{
  late Future<List<Map<String,dynamic>>> _applications;
  final _phone=TextEditingController(),_qualification=TextEditingController(),_experience=TextEditingController(text:'0'),
    _intro=TextEditingController(),_portfolio=TextEditingController();
  List<Map<String,dynamic>> _subjects=[],_classes=[];
  final Set<String> _selectedSubjects={},_selectedClasses={};
  Map<String,dynamic>? _mine;
  bool _loading=true,_saving=false;
  @override
  void initState(){super.initState();if(widget.admin){_applications=_loadApplications();_loading=false;}else{_applications=Future.value([]);_loadForm();}}
  Future<void> _loadForm() async{
    try{
      final results=await Future.wait([
        Supabase.instance.client.from('subjects').select('id,name').eq('status','active').order('name'),
        Supabase.instance.client.from('classes').select('id,name').eq('status','active').order('name'),
        Supabase.instance.client.from('tutor_applications').select().eq('user_id',Supabase.instance.client.auth.currentUser!.id).maybeSingle(),
      ]);
      if(!mounted)return;setState(()=>_subjects=List<Map<String,dynamic>>.from(results[0] as List)..sort((a,b)=>a['name'].toString().compareTo(b['name'].toString())));
      setState(()=>_classes=List<Map<String,dynamic>>.from(results[1] as List)..sort((a,b)=>a['name'].toString().compareTo(b['name'].toString())));
      _mine=results[2] as Map<String,dynamic>?;
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Application form could not load: $e')));}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<List<Map<String,dynamic>>> _loadApplications() async{
    final rows=await Supabase.instance.client.from('tutor_applications')
      .select('*,profiles(full_name,email)')
      .order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> _submit() async{
    final exp=num.tryParse(_experience.text.trim())??-1;
    if(_phone.text.trim().isEmpty||_qualification.text.trim().isEmpty||exp<0||
      _selectedSubjects.isEmpty||_selectedClasses.isEmpty||_intro.text.trim().length<30){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Complete your contact, qualification, experience, subjects, class levels and introduction (at least 30 characters).')));return;
    }
    setState(()=>_saving=true);
    try{
      await Supabase.instance.client.from('tutor_applications').insert({
        'user_id':Supabase.instance.client.auth.currentUser!.id,'phone':_phone.text.trim(),
        'qualification':_qualification.text.trim(),'experience_years':exp,
        'subjects':_subjects.where((x)=>_selectedSubjects.contains(x['id'].toString())).map((x)=>x['name'].toString()).toList(),
        'class_levels':_classes.where((x)=>_selectedClasses.contains(x['id'].toString())).map((x)=>x['name'].toString()).toList(),
        'introduction':_intro.text.trim(),'portfolio_url':_portfolio.text.trim().isEmpty?null:_portfolio.text.trim(),
      });
      await _loadForm();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your tutor application has been submitted for review.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Application could not be submitted: $e')));}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  Future<void> _review(Map<String,dynamic> app) async{
    String status=(app['status']??'submitted').toString(),note=(app['review_note']??'').toString();
    DateTime? interview=app['interview_at']==null?null:DateTime.tryParse(app['interview_at'].toString())?.toLocal();
    final noteController=TextEditingController(text:note);
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      title:const Text('Review tutor application'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'Application stage'),
          items:['reviewing','shortlisted','interview_scheduled','approved','rejected'].map((v)=>DropdownMenuItem(value:v,child:Text(v.replaceAll('_',' ').toUpperCase()))).toList(),
          onChanged:(v)=>setDialog(()=>status=v??status)),
        if(status=='interview_scheduled')...[
          const SizedBox(height:10),
          OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)),initialDate:interview??DateTime.now());if(d==null)return;final t=await showTimePicker(context:ctx,initialTime:TimeOfDay.fromDateTime(interview??DateTime.now()));if(t!=null)setDialog(()=>interview=DateTime(d.year,d.month,d.day,t.hour,t.minute));},
            icon:const Icon(Icons.calendar_month_outlined),label:Text(interview==null?'Choose interview date and time':_staffDate(interview!.toIso8601String()))),
        ],
        TextField(controller:noteController,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Private review note')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save review'))],
    )));
    if(ok!=true){noteController.dispose();return;}
    if(status=='interview_scheduled'&&interview==null){noteController.dispose();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Choose the interview date and time.')));return;}
    try{
      await Supabase.instance.client.rpc('review_tutor_application',params:{
        'p_application_id':app['id'],'p_status':status,'p_review_note':noteController.text.trim().isEmpty?null:noteController.text.trim(),
        'p_interview_at':status=='interview_scheduled'?interview!.toUtc().toIso8601String():null,
      });
      setState(()=>_applications=_loadApplications());
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Application review failed: $e')));}
    finally{noteController.dispose();}
  }
  @override
  void dispose(){_phone.dispose();_qualification.dispose();_experience.dispose();_intro.dispose();_portfolio.dispose();super.dispose();}
  Widget _choiceList(String title,List<Map<String,dynamic>> rows,Set<String> selected){
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.ink)),
      const SizedBox(height:6),Wrap(spacing:7,runSpacing:5,children:rows.map((r){
        final id=r['id'].toString(),active=selected.contains(id);
        return FilterChip(label:Text(r['name'].toString()),selected:active,
          onSelected:(v)=>setState(()=>v?selected.add(id):selected.remove(id)));
      }).toList()),
    ]);
  }
  @override
  Widget build(BuildContext context){
    if(widget.admin)return Scaffold(appBar:AppBar(title:const Text('Tutor Interview Centre')),
      body:RefreshIndicator(onRefresh:()async=>setState(()=>_applications=_loadApplications()),
        child:FutureBuilder<List<Map<String,dynamic>>>(future:_applications,builder:(context,s){
          if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
          if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Applications could not be loaded: ${s.error}')]);
          final rows=s.data??[];
          if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(20),children:const [_InfoNotice(message:'No tutor applications yet. New applications will appear here.')]);
          return ListView(padding:const EdgeInsets.all(16),children:[
            const Text('TUTOR CANDIDATES',style:TextStyle(fontSize:11,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.muted)),
            const SizedBox(height:10),...rows.map((a){final p=a['profiles'] is Map?Map<String,dynamic>.from(a['profiles']):<String,dynamic>{};
              return Card(child:ListTile(isThreeLine:true,onTap:()=>_review(a),
                leading:const CircleAvatar(backgroundColor:AppColors.paleGold,child:Icon(Icons.person_outline,color:AppColors.brown)),
                title:Text(p['full_name']?.toString()??'Applicant',style:const TextStyle(fontWeight:FontWeight.w800)),
                subtitle:Text('${a['qualification']} • ${a['experience_years']} years\n${(a['subjects'] as List).join(', ')}\nStatus: ${a['status'].toString().replaceAll('_',' ')}'),
                trailing:const Icon(Icons.chevron_right_rounded)));
            }),
          ]);
        })));
    return Scaffold(appBar:AppBar(title:const Text('Tutor Interview Centre')),
      body:_loading?const Center(child:CircularProgressIndicator()):_mine!=null
        ?ListView(padding:const EdgeInsets.all(20),children:[
          const Icon(Icons.assignment_turned_in_outlined,size:52,color:AppColors.brown),
          const SizedBox(height:12),const Text('Your tutor application',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AppColors.ink)),
          const SizedBox(height:8),Text('Current stage: ${_mine!['status'].toString().replaceAll('_',' ').toUpperCase()}',style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.brown)),
          if(_mine!['interview_at']!=null)Text('Interview: ${_staffDate(_mine!['interview_at'])}'),
          if(_mine!['review_note']!=null)Text('Centre update: ${_mine!['review_note']}'),
          const SizedBox(height:12),const _InfoNotice(message:'The centre will notify you when your application moves to another stage. Approval is required before tutor access is activated.'),
        ])
        :ListView(padding:const EdgeInsets.all(18),children:[
          Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.brown,borderRadius:BorderRadius.circular(16)),
            child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Icon(Icons.school_outlined,color:AppColors.gold,size:34),SizedBox(height:10),
              Text('Teach. Inspire. Make a difference.',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w800)),
              SizedBox(height:7),Text('Tell us about your teaching experience and the subjects you can support. Our team will review your application and contact you about the next stage.',style:TextStyle(color:Color(0xFFE7DED6),height:1.5)),
            ])),
          const SizedBox(height:18),TextField(controller:_phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone / WhatsApp number')),
          const SizedBox(height:10),TextField(controller:_qualification,decoration:const InputDecoration(labelText:'Highest qualification')),
          const SizedBox(height:10),TextField(controller:_experience,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Teaching experience (years)')),
          const SizedBox(height:16),_choiceList('Subjects you can teach',_subjects,_selectedSubjects),
          const SizedBox(height:16),_choiceList('Class levels you can teach',_classes,_selectedClasses),
          const SizedBox(height:12),TextField(controller:_intro,minLines:4,maxLines:7,decoration:const InputDecoration(labelText:'Brief introduction and teaching approach',hintText:'Tell us about your experience and how you help learners understand...',alignLabelWithHint:true)),
          const SizedBox(height:10),TextField(controller:_portfolio,decoration:const InputDecoration(labelText:'Portfolio / sample lesson link (optional)')),
          const SizedBox(height:20),FilledButton.icon(onPressed:_saving?null:_submit,icon:const Icon(Icons.send_rounded),label:Text(_saving?'Submitting...':'Submit tutor application')),
          const SizedBox(height:12),const Text('Please note: submitting this form does not guarantee employment. The centre will review your application and may schedule an interview.',style:TextStyle(fontSize:12,color:AppColors.muted,height:1.4)),
        ]),
    );
  }
}

class AdminEmployeePage extends StatefulWidget{
  const AdminEmployeePage({super.key});
  @override
  State<AdminEmployeePage> createState()=>_AdminEmployeePageState();
}
class _AdminEmployeePageState extends State<AdminEmployeePage>{
  late Future<List<Map<String,dynamic>>> _staff;
  @override
  void initState(){super.initState();_staff=_load();}
  Future<List<Map<String,dynamic>>> _load() async{
    final r=await Supabase.instance.client.from('staff_members').select('id,user_id,job_title,department,status,profiles(full_name,email)').order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(r);
  }
  Future<void> _add() async{
    final db=Supabase.instance.client;
    try{
      final all=await db.from('profiles').select('id,full_name,email,account_type').eq('status','active').order('full_name');
      final existing=await db.from('staff_members').select('user_id');
      final tutors=await db.from('tutors').select('user_id').eq('status','active');
      final used={...(existing as List).map((x)=>x['user_id'].toString()),...(tutors as List).map((x)=>x['user_id'].toString())};
      final candidates=List<Map<String,dynamic>>.from(all).where((p)=>p['account_type']!='parent'&&!used.contains(p['id'].toString())).toList();
      if(candidates.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No eligible accounts found. The employee must create an account first.')));return;}
      final title=TextEditingController(),dept=TextEditingController();String? uid=candidates.first['id'].toString();
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
        title:const Text('Add employee to staff room'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          DropdownButtonFormField<String>(value:uid,decoration:const InputDecoration(labelText:'Account'),
            items:candidates.map((p)=>DropdownMenuItem(value:p['id'].toString(),child:Text('${p['full_name']??'Unnamed'} • ${p['email']??''}'))).toList(),onChanged:(v)=>setD(()=>uid=v)),
          TextField(controller:title,decoration:const InputDecoration(labelText:'Job title')),
          TextField(controller:dept,decoration:const InputDecoration(labelText:'Department / team (optional)')),
        ]),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add employee'))],
      )));
      if(ok==true&&uid!=null&&title.text.trim().isNotEmpty){
        await db.rpc('add_staff_member',params:{
          'p_user_id':uid,'p_job_title':title.text.trim(),
          'p_department':dept.text.trim().isEmpty?null:dept.text.trim(),
        });
        setState(()=>_staff=_load());
      }
      title.dispose();dept.dispose();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Employee could not be added: $e')));}
  }
  Future<void> _status(Map<String,dynamic> row,String status) async{
    await Supabase.instance.client.from('staff_members').update({'status':status}).eq('id',row['id']);
    if(mounted)setState(()=>_staff=_load());
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Staff directory')),
    floatingActionButton:FloatingActionButton.extended(onPressed:_add,backgroundColor:AppColors.brown,foregroundColor:Colors.white,
      icon:const Icon(Icons.person_add_alt_1),label:const Text('Add employee')),
    body:RefreshIndicator(onRefresh:()async=>setState(()=>_staff=_load()),child:FutureBuilder<List<Map<String,dynamic>>>(future:_staff,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return ListView(padding:const EdgeInsets.all(20),children:[_InfoNotice(message:'Staff list could not load: ${s.error}')]);
      final rows=s.data??[];
      if(rows.isEmpty)return ListView(padding:const EdgeInsets.all(20),children:const [_InfoNotice(message:'No employees have been added yet. Add an existing account to give them staff-room access.')]);
      return ListView(padding:const EdgeInsets.all(16),children:rows.map((r){final p=r['profiles'] is Map?Map<String,dynamic>.from(r['profiles']):<String,dynamic>{};final active=r['status']=='active';
        return Card(child:ListTile(title:Text(p['full_name']?.toString()??'Employee'),subtitle:Text('${r['job_title']} • ${r['department']??'General'} • ${r['status']}'),
          trailing:PopupMenuButton<String>(onSelected:(v)=>_status(r,v),itemBuilder:(_)=>[
            PopupMenuItem(value:active?'inactive':'active',child:Text(active?'Deactivate':'Reactivate')),
          ])));
      }).toList());
    })));
}
