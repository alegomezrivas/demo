import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/error_view.dart';
import 'package:demo/core/widgets/stat_card.dart';
import 'package:demo/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Dashboard tab: greeting and task statistics.
class DashboardView extends StatelessWidget {
  /// Creates the view.
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<DashboardViewModel>.reactive(
      viewModelBuilder: () => locator<DashboardViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, _) {
        final stats = viewModel.stats;
        final failure = viewModel.failure;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.navDashboard)),
          body: Builder(
            builder: (context) {
              if (viewModel.isBusy && stats == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (failure != null && stats == null) {
                return ErrorView(
                  message: failure.message(l10n),
                  retryLabel: l10n.commonRetry,
                  onRetry: viewModel.refresh,
                );
              }
              return RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: ListView(
                  padding: context.spacing.screenPadding,
                  children: [
                    if (viewModel.user case final user?)
                      Text(
                        l10n.dashboardGreeting(user.name),
                        style: context.text.headline,
                      ),
                    SizedBox(height: context.spacing.xs),
                    Text(l10n.dashboardSubtitle, style: context.text.bodySmall),
                    SizedBox(height: context.spacing.lg),
                    if (stats != null) _Stats(stats: stats, l10n: l10n),
                    SizedBox(height: context.spacing.lg),
                    AppPrimaryButton(
                      label: l10n.dashboardViewTasks,
                      onPressed: viewModel.openTasks,
                    ),
                    SizedBox(height: context.spacing.sm),
                    OutlinedButton(
                      onPressed: viewModel.createTask,
                      child: Text(l10n.dashboardNewTask),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats, required this.l10n});

  final TaskStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (stats.completionRate * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = context.spacing.md;
        final width = (constraints.maxWidth - gap) / 2;
        Widget card(StatCard card) => SizedBox(width: width, child: card);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardCompletion(percent),
                      style: context.text.title,
                    ),
                    SizedBox(height: context.spacing.sm),
                    LinearProgressIndicator(
                      value: stats.completionRate,
                      minHeight: context.spacing.progressHeight,
                      borderRadius: context.spacing.borderRadiusSm,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                card(
                  StatCard(
                    label: l10n.dashboardStatTotal,
                    value: '${stats.total}',
                    icon: Icons.list_alt_outlined,
                  ),
                ),
                card(
                  StatCard(
                    label: l10n.dashboardStatDone,
                    value: '${stats.done}',
                    icon: Icons.check_circle_outline,
                    accent: colors.success,
                  ),
                ),
                card(
                  StatCard(
                    label: l10n.dashboardStatOverdue,
                    value: '${stats.overdue}',
                    icon: Icons.schedule,
                    accent: colors.warning,
                  ),
                ),
                card(
                  StatCard(
                    label: l10n.dashboardStatHighPriority,
                    value: '${stats.highPriorityPending}',
                    icon: Icons.priority_high,
                    accent: colors.error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
