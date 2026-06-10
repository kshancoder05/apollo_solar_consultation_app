import 'package:flutter_test/flutter_test.dart';
import 'package:apollo_solar_consultation_app/main.dart';

void main() {
  testWidgets('app launches to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ApolloApp());

    expect(find.text('Apollo Solar Ventures'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}