import '../database/database_helper.dart';

/// Business logic for summary metrics.
class SummaryController {
  const SummaryController(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  /// Loads computed daily summary values.
  Future<Map<String, dynamic>> loadSummary() {
    return _databaseHelper.getSummary();
  }
}
