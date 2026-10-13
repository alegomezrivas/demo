import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'pump_app.dart';

/// Pumps [child] inside a localized app and a `ReactiveForm` for [form].
Future<void> pumpForm(
  WidgetTester tester,
  FormGroup form,
  Widget child, {
  Locale locale = const Locale('es'),
}) {
  return pumpLocalized(
    tester,
    Scaffold(
      body: ReactiveForm(formGroup: form, child: child),
    ),
    locale: locale,
  );
}

/// Gives the test view a phone-like size, restored when the test ends.
void useViewSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
