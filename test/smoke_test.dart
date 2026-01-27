import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:shopping/main.dart'; // keep your package name correct
import 'package:shopping/storage/keys.dart';

void main() {
  setUpAll(() async {
    // Use a temp directory for Hive during tests
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);

    // Open the same box your app expects
    await Hive.openBox(HiveKeys.listsBox);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartShoppingApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Shopping Lists'), findsOneWidget);
  });
}
