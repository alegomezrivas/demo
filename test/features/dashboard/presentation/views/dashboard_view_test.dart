import 'dart:async';

import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:demo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../auth/helpers/auth_mocks.dart';
import '../../../tasks/helpers/tasks_mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockGetTaskStatsUseCase getStats;
  late MockNavigationService navigation;
  late DataChangeNotifier changes;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');
  const stats = TaskStats(
    total: 8,
    done: 2,
    overdue: 3,
    highPriorityPending: 4,
  );

  setUp(() async {
    await resetLocator();
    getCurrentUser = MockGetCurrentUserUseCase();
    getStats = MockGetTaskStatsUseCase();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    when(getCurrentUser(any)).thenAnswer((_) async => right(user));
    when(getStats(any)).thenAnswer((_) async => right(stats));
    locator.registerFactory<DashboardViewModel>(
      () => DashboardViewModel(
        getCurrentUser: getCurrentUser,
        getStats: getStats,
        navigation: navigation,
        changes: changes,
      ),
    );
  });

  tearDown(resetLocator);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(tester, const DashboardView());
    await tester.pumpAndSettle();
  }

  group('DashboardView', () {
    testWidgets('greets the user and shows every statistic', (tester) async {
      await pumpView(tester);

      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('25% completado'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Prioridad alta pendientes'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.25,
      );
    });

    testWidgets('shows a progress indicator while loading', (tester) async {
      final completer = Completer<Either<Failure, TaskStats>>();
      when(getStats(any)).thenAnswer((_) => completer.future);
      await pumpLocalized(tester, const DashboardView());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(right(stats));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows an error with retry when statistics fail', (
      tester,
    ) async {
      when(getStats(any)).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);
      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );

      when(getStats(any)).thenAnswer((_) async => right(stats));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('25% completado'), findsOneWidget);
    });

    testWidgets('quick actions navigate', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Ver tareas'));
      await tester.tap(find.text('Nueva tarea'));
      await tester.pump();

      verify(navigation.go(AppRoutes.tasks)).called(1);
      verify(navigation.push<bool>(AppRoutes.taskNew)).called(1);
    });

    testWidgets('pull to refresh reloads the statistics', (tester) async {
      await pumpView(tester);
      clearInteractions(getStats);

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      verify(getStats(any)).called(1);
    });

    testWidgets('handles an empty workspace (no tasks)', (tester) async {
      when(getStats(any)).thenAnswer(
        (_) async => right(
          const TaskStats(
            total: 0,
            done: 0,
            overdue: 0,
            highPriorityPending: 0,
          ),
        ),
      );

      await pumpView(tester);

      expect(find.text('0% completado'), findsOneWidget);
    });
  });
}
