import 'package:flutter/widgets.dart';

import 'controllers/history_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/summary_controller.dart';
import 'controllers/transaction_controller.dart';
import 'database/database_helper.dart';

/// Creates and holds app-wide controller instances.
class AppDependencies {
  AppDependencies._({
    required this.homeController,
    required this.historyController,
    required this.summaryController,
    required this.transactionController,
  });

  factory AppDependencies.create() {
    // Single shared database helper passed into all controllers.
    final databaseHelper = DatabaseHelper.instance;
    return AppDependencies._(
      homeController: HomeController(databaseHelper),
      historyController: HistoryController(databaseHelper),
      summaryController: SummaryController(databaseHelper),
      transactionController: TransactionController(databaseHelper),
    );
  }

  final HomeController homeController;
  final HistoryController historyController;
  final SummaryController summaryController;
  final TransactionController transactionController;
}

/// Makes [AppDependencies] available to all screens via context.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  /// Reads the shared dependencies from the widget tree.
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
