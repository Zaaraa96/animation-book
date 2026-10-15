import 'package:flutter_test/flutter_test.dart';

import 'package:animation_book/main.dart';

void main() {
  testWidgets('book controls turn forward and backward', (tester) async {
    await tester.pumpWidget(const AnimationBookApp());
    await tester.pumpAndSettle();

    expect(find.text('1 / 8'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
  });
}
