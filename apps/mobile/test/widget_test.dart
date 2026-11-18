import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:young_learners_tutorial/main.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      anonKey: 'test-publishable-key',
    );
  });

  testWidgets('shows the Young Learners sign-in screen', (tester) async {
    await tester.pumpWidget(const YoungLearnersApp());

    expect(find.text('YOUNG LEARNERS'), findsOneWidget);
    expect(find.text('Every Child Can Learn.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });
}
