import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../helpers/task_fixtures.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, {required TaskTileData data}) {
    return pumpLocalized(
      tester,
      Scaffold(
        body: TaskTile(
          task: data.task,
          now: fixtureNow,
          onToggle: data.onToggle,
          onTap: data.onTap,
          onDelete: data.onDelete,
        ),
      ),
    );
  }

  group('TaskTile', () {
    testWidgets('shows title, priority and due date', (tester) async {
      final data = TaskTileData(
        buildTask(
          title: 'Plan trip',
          priority: TaskPriority.high,
          dueDate: DateTime.utc(2026, 2, 20, 12),
        ),
      );

      await pumpTile(tester, data: data);

      expect(find.text('Plan trip'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.textContaining('Vence:'), findsOneWidget);
      expect(find.textContaining('Vencida'), findsNothing);
    });

    testWidgets('flags overdue open tasks', (tester) async {
      final data = TaskTileData(
        buildTask(dueDate: DateTime.utc(2026, 1, 1, 12)),
      );

      await pumpTile(tester, data: data);

      expect(find.textContaining('Vencida'), findsOneWidget);
    });

    testWidgets('does not flag completed tasks as overdue and strikes them', (
      tester,
    ) async {
      final data = TaskTileData(
        buildTask(isDone: true, dueDate: DateTime.utc(2026, 1, 1, 12)),
      );

      await pumpTile(tester, data: data);

      expect(find.textContaining('Vencida'), findsNothing);
      final text = tester.widget<Text>(find.text('Write tests'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('hides the date line when there is no deadline', (
      tester,
    ) async {
      await pumpTile(tester, data: TaskTileData(buildTask()));

      expect(find.textContaining('Vence:'), findsNothing);
    });

    testWidgets('reports toggle, tap and delete', (tester) async {
      final data = TaskTileData(buildTask());
      await pumpTile(tester, data: data);

      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.tap(find.text('Write tests'));

      expect(data.toggles, 1);
      expect(data.deletes, 1);
      expect(data.taps, 1);
    });
  });
}

class TaskTileData {
  TaskTileData(this.task);

  final TaskItem task;
  int toggles = 0;
  int taps = 0;
  int deletes = 0;

  void onToggle() => toggles++;
  void onTap() => taps++;
  void onDelete() => deletes++;
}
