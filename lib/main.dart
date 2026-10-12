import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(router: AppRouter.create());
  runApp(
    App(
      routerConfig: locator<GoRouter>(),
      integrityViewModelBuilder: locator.call<IntegrityGateViewModel>,
    ),
  );
}
