import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtitle_blocker_flutter_refactor/app/app.dart';

void main() {
  testWidgets('App root renders the shell-ready placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AppRoot()));

    expect(find.text('Project shell ready'), findsOneWidget);
    expect(find.text('MainActivity -> planned /home Flutter entry'), findsOneWidget);
    expect(find.text('UsageActivity -> planned /usage Flutter page'), findsOneWidget);
  });
}
