import '../database/database_helper.dart';
import '../models/transaction.dart';

/// Business logic for listing, filtering, deleting, and exporting history.
class HistoryController {
  const HistoryController(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  /// Returns transactions based on active filters.
  Future<List<FloatTransaction>> getTransactions({
    NetworkType? network,
    ServiceType? serviceType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _databaseHelper.getTransactionsByFilters(
      network: network,
      serviceType: serviceType,
      start: startDate,
      end: endDate,
    );
  }

  /// Deletes one transaction and triggers DB-side balance recalculation.
  Future<void> deleteTransaction(int id) async {
    await _databaseHelper.deleteTransaction(id);
  }

  /// Exports full history to CSV and returns file path.
  Future<String> exportTransactionsCsv() {
    return _databaseHelper.exportToCSV();
  }
}
