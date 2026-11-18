import 'package:flutter/material.dart';

void main() => runApp(const YoungLearnersApp());

const ink = Color(0xFF382316);
const brown = Color(0xFF57351F);
const gold = Color(0xFFE4B94F);
const cream = Color(0xFFFFF9EF);
const muted = Color(0xFF827568);

class YoungLearnersApp extends StatelessWidget {
  const YoungLearnersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Young Learners Tutorial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: brown, primary: brown,
          secondary: gold, surface: cream),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: ink),
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
  final pages = const ['Home', 'My Learning', 'Classes', 'Progress', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_stories_rounded, color: gold)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUNG LEARNERS', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w900, letterSpacing: 1.1, color: ink)),
              Text('TUTORIAL', style: TextStyle(fontSize: 10, letterSpacing: 2.4,
                color: muted, fontWeight: FontWeight.w600)),
            ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
        ]),
      ),
      body: SafeArea(child: IndexedStack(index: selected, children: [
        _home(context), _placeholder('My Learning', Icons.menu_book_rounded),
        _placeholder('Classes', Icons.calendar_month_rounded),
        _placeholder('Progress', Icons.insights_rounded),
        _placeholder('Profile', Icons.person_outline_rounded),
      ])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFEDC2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learning'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Classes'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _home(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      const Text('Good afternoon, learner', style: TextStyle(color: muted, fontSize: 14)),
      const SizedBox(height: 5),
      const Text('Every child can learn.', style: TextStyle(color: ink,
        fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.5)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: brown, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('YOUR LEARNING SPACE', style: TextStyle(color: gold,
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
          const SizedBox(height: 14),
          const Text('Small steps.\nBig achievements.', style: TextStyle(color: Colors.white,
            fontSize: 25, height: 1.15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Your lessons, classes and progress — all in one place.',
            style: TextStyle(color: Color(0xFFEADFD3), height: 1.45)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: ink),
            onPressed: () => setState(() => selected = 1),
            child: const Text('Explore my learning')),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Quick access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 12),
      Row(children: [
        _quick(Icons.menu_book_rounded, 'Subjects', () => setState(() => selected = 1)),
        const SizedBox(width: 10),
        _quick(Icons.video_library_outlined, 'Lessons', () => setState(() => selected = 1)),
        const SizedBox(width: 10),
        _quick(Icons.assignment_outlined, 'Assignments', () => setState(() => selected = 1)),
      ]),
      const SizedBox(height: 24),
      const Text('Your learning overview', style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0E7DA))),
        child: const Row(children: [
          Icon(Icons.school_outlined, color: brown, size: 28),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your dashboard is ready', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
            SizedBox(height: 4),
            Text('Your enrolled subjects and activity will appear here after sign-in.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      const Center(child: Text('Every Child Can Learn', style: TextStyle(color: muted,
        fontSize: 12, fontWeight: FontWeight.w600))),
    ],
  );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E7DA))),
        child: Column(children: [
          Icon(icon, color: brown, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink)),
        ]))),
  );

  Widget _placeholder(String title, IconData icon) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: brown),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 8),
        const Text('This section will connect to your learning account in the next build.',
          textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
      ])),
  );
}
