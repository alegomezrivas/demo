import 'package:demo/core/theme/app_colors.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/presentation/utils/task_labels.dart';
import 'package:demo/l10n/app_localizations_en.dart';
import 'package:demo/l10n/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final es = AppLocalizationsEs();
  final en = AppLocalizationsEn();

  group('TaskPriorityPresentation', () {
    test('localizes every priority', () {
      expect(TaskPriority.low.label(es), 'Baja');
      expect(TaskPriority.medium.label(es), 'Media');
      expect(TaskPriority.high.label(en), 'High');
    });

    test('maps priorities to semantic palette colors', () {
      expect(TaskPriority.low.color(AppColors.light), AppColors.light.success);
      expect(TaskPriority.medium.color(AppColors.dark), AppColors.dark.warning);
      expect(TaskPriority.high.color(AppColors.light), AppColors.light.error);
    });
  });

  group('TaskStatusFilterLabel', () {
    test('localizes every status', () {
      expect(TaskStatusFilter.all.label(es), 'Todas');
      expect(TaskStatusFilter.pending.label(en), 'Pending');
      expect(TaskStatusFilter.done.label(es), 'Completadas');
    });
  });
}
