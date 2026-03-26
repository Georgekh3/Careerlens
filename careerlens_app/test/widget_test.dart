import 'package:flutter_test/flutter_test.dart';

import 'package:careerlens_app/main.dart';

void main() {
  testWidgets('renders Google-only login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CareerLensApp());
    await tester.pump();

    expect(find.text('CareerLens'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(
      find.text('Email/password registration has been removed.'),
      findsOneWidget,
    );
  });
}
