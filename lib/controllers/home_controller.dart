import '../database/database_helper.dart';
import '../models/transaction.dart';

/// Business logic for the home dashboard.
class HomeController {
  const HomeController(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  /// Loads both network balances for the top cards.
  Future<(double mtnBalance, double airtelBalance)> loadBalances() async {
    final mtn = await _databaseHelper.getCurrentBalance(NetworkType.mtn);
    final airtel = await _databaseHelper.getCurrentBalance(NetworkType.airtel);
    return (mtn, airtel);
  }

  /// Loads recent transactions shown on home preview.
  Future<List<FloatTransaction>> loadRecentTransactions({int limit = 5}) async {
    final transactions = await _databaseHelper.getAllTransactions();
    return transactions.take(limit).toList();
  }
}
