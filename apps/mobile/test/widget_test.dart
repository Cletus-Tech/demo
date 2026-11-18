import 'package:flutter_test/flutter_test.dart';
import 'package:young_learners_tutorial/main.dart';

void main() {
  testWidgets('shows Young Learners Tutorial home', (tester) async {
    await tester.pumpWidget(const YoungLearnersApp());
    expect(find.text('Every child can learn.'), findsOneWidget);
    expect(find.text('Explore my learning'), findsOneWidget);
  });
}
