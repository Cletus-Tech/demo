import 'package:flutter_test/flutter_test.dart';
import 'package:young_learners_tutorial/main.dart';

void main() {
  testWidgets('shows the Young Learners Tutorial learner dashboard',
      (tester) async {
    await tester.pumpWidget(const YoungLearnersApp());

    expect(find.text('YOUNG LEARNERS'), findsOneWidget);
    expect(find.text('Every Child Can Learn.'), findsOneWidget);
    expect(find.text('Explore learning'), findsOneWidget);
  });
}
