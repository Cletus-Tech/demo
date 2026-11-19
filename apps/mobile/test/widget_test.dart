import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:young_learners_tutorial/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recognises a redeemed one-to-one classroom pass relation', () {
    expect(hasRedeemedClassroomPass({
      'redeemed_at': '2026-11-19T11:25:05Z',
      'revoked_at': null,
    }), isTrue);
  });

  test('recognises a redeemed classroom pass in a list relation', () {
    expect(hasRedeemedClassroomPass([
      {'redeemed_at': null, 'revoked_at': null},
      {'redeemed_at': '2026-11-19T11:25:05Z', 'revoked_at': null},
    ]), isTrue);
  });

  test('does not unlock missing, unredeemed or revoked passes', () {
    expect(hasRedeemedClassroomPass(null), isFalse);
    expect(hasRedeemedClassroomPass({
      'redeemed_at': null,
      'revoked_at': null,
    }), isFalse);
    expect(hasRedeemedClassroomPass({
      'redeemed_at': '2026-11-19T11:25:05Z',
      'revoked_at': '2026-11-19T11:30:00Z',
    }), isFalse);
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      anonKey: 'test-publishable-key',
    );
  });

  testWidgets('shows the Young Learners sign-in screen', (tester) async {
    await tester.pumpWidget(const YoungLearnersApp());

    expect(find.text('YOUNG LEARNERS'), findsOneWidget);
    expect(find.text('EVERY CHILD CAN LEARN'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });
}
