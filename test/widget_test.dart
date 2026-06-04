import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_helper_tool/main.dart';

void main() {
  testWidgets('Git Helper app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const GitHelperApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
