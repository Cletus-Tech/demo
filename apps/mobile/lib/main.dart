import 'package:flutter/material.dart';

void main() => runApp(const YoungLearnersApp());

abstract final class AppColors {
  static const ink = Color(0xFF29231F);
  static const brown = Color(0xFF4A3022);
  static const gold = Color(0xFFC99A3D);
  static const cream = Color(0xFFF7F5F1);
  static const surface = Colors.white;
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
      surface: AppColors.surface,
    );
    return MaterialApp(
      title: 'Young Learners Tutorial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
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
      home: const LearnerHomePage(),
    );
  }
}

class LearnerHomePage extends StatefulWidget {
  const LearnerHomePage({super.key});

  @override
  State<LearnerHomePage> createState() => _LearnerHomePageState();
}

class _LearnerHomePageState extends State<LearnerHomePage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final destinations = const [
      _Destination('Overview', Icons.space_dashboard_outlined),
      _Destination('My learning', Icons.menu_book_outlined),
      _Destination('Classes', Icons.calendar_today_outlined),
      _Destination('Progress', Icons.query_stats_outlined),
      _Destination('Profile', Icons.account_circle_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.school_outlined, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('YOUNG LEARNERS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        letterSpacing: 1.05, color: AppColors.ink)),
                SizedBox(height: 2),
                Text('TUTORIAL CENTRE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        letterSpacing: 1.6, color: AppColors.muted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (value) => setState(() => selected = value),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.paleGold,
              destinations: destinations.map((d) => NavigationRailDestination(
                icon: Icon(d.icon), label: Text(d.label),
              )).toList(),
            ),
          Expanded(
            child: IndexedStack(
              index: selected,
              children: const [
                _OverviewPage(),
                _SectionPage(title: 'My learning', subtitle: 'Your subjects, lessons and learning materials will be organised here.', icon: Icons.menu_book_outlined),
                _SectionPage(title: 'Classes', subtitle: 'View your class timetable and upcoming learning sessions here.', icon: Icons.calendar_today_outlined),
                _SectionPage(title: 'Progress', subtitle: 'Your assessment results and learning progress will appear here.', icon: Icons.query_stats_outlined),
                _SectionPage(title: 'Profile', subtitle: 'Your personal and learning account details will appear here.', icon: Icons.account_circle_outlined),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.paleGold,
        destinations: destinations.map((d) => NavigationDestination(
          icon: Icon(d.icon), label: d.label,
        )).toList(),
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  const _Destination(this.label, this.icon);
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final contentWidth = constraints.maxWidth > 1100 ? 1040.0 : 760.0;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STUDENT PORTAL',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                        fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 7),
                Text('Welcome to your learning space',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 7),
                const Text('Every Child Can Learn.',
                    style: TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.brown,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: LayoutBuilder(builder: (context, box) {
                    final compact = box.maxWidth < 500;
                    return Flex(
                      direction: compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      children: [
                        ExpandedIfWide(
                          enabled: !compact,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('A better way to learn',
                                  style: TextStyle(color: Colors.white,
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('Access lessons, classes and academic resources in one organised place.',
                                  style: TextStyle(color: Color(0xFFE7DED6),
                                    fontSize: 13, height: 1.5)),
                            ],
                          ),
                        ),
                        if (compact) const SizedBox(height: 16) else const SizedBox(width: 20),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFBDA98E)),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: const Text('Explore learning'),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 26),
                const Text('LEARNING SHORTCUTS',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.1,
                        fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, box) {
                  final columns = box.maxWidth > 650 ? 3 : (box.maxWidth > 390 ? 3 : 1);
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 4.2 : 1.65,
                    children: const [
                      _Shortcut(icon: Icons.library_books_outlined, title: 'Subjects', detail: 'Browse your subjects'),
                      _Shortcut(icon: Icons.play_circle_outline, title: 'Lessons', detail: 'Continue learning'),
                      _Shortcut(icon: Icons.assignment_outlined, title: 'Assignments', detail: 'Review your tasks'),
                    ],
                  );
                }),
                const SizedBox(height: 25),
                const Text('YOUR ACCOUNT',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.1,
                        fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.brown, size: 22),
                        const SizedBox(width: 13),
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your learning account is ready to be connected',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                            SizedBox(height: 5),
                            Text('Once secure sign-in is enabled, your enrolled subjects, timetable and activity will appear here.',
                                style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(child: Text('YOUNG LEARNERS TUTORIAL CENTRE',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.1,
                        fontWeight: FontWeight.w600, color: AppColors.muted))),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class ExpandedIfWide extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const ExpandedIfWide({super.key, required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) => enabled ? Expanded(child: child) : child;
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _Shortcut({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.paleGold,
              borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: AppColors.brown, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          )),
          const Icon(Icons.chevron_right, size: 19, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _SectionPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SectionPage({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.brown),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22,
              fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5)),
          ],
        ),
      ),
    ),
  );
}
