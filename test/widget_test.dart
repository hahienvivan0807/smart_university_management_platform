import 'package:flutter_test/flutter_test.dart';
import 'package:smart_university_management_platform/main.dart';

void main() {
  testWidgets('App boots and shows the login switcher', (tester) async {
    await tester.pumpWidget(const SmartUniversityApp());
    expect(find.text('Sign in'), findsOneWidget); // Minimalist tab is default
  });
}