import '../database/database_helper.dart';
import '../models/transaction.dart';

/// Result returned by transaction submit/update actions.
class TransactionSubmissionResult {
  const TransactionSubmissionResult({
    required this.success,
    required this.message,
    this.newBalance,
  });

  final bool success;
  final String message;
  final double? newBalance;
}

/// Business logic for creating and editing transactions.
class TransactionController {
  const TransactionController(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  /// Validates float constraints and writes transaction changes.
  Future<TransactionSubmissionResult> submitTransaction({
    required NetworkType network,
    required TransactionType type,
    ServiceType serviceType = ServiceType.momo,
    required double amount,
    double? fee,
    String? customerName,
    String? customerPhone,
    String? notes,
    FloatTransaction? existingTransaction,
  }) async {
    final currentBalance = await _databaseHelper.getCurrentBalance(network);
    var baseBalance = currentBalance;

    if (existingTransaction != null) {
      // Back out previous value so edits are validated against effective balance.
      baseBalance -= existingTransaction.type == TransactionType.cashIn
          ? existingTransaction.amount
          : -existingTransaction.amount;
    }

    double newBalance;
    if (type == TransactionType.cashIn) {
      newBalance = baseBalance + amount;
    } else {
      if (baseBalance < amount) {
        return const TransactionSubmissionResult(
          success: false,
          message: 'Insufficient float balance!',
        );
      }
      newBalance = baseBalance - amount;
    }

    final transaction = FloatTransaction(
      id: existingTransaction?.id,
      network: network,
      type: type,
      serviceType: serviceType,
      amount: amount,
      fee: fee,
      balanceAfter: newBalance,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      timestamp: existingTransaction?.timestamp ?? DateTime.now(),
    );

    if (existingTransaction == null) {
      await _databaseHelper.insertTransaction(transaction);
      return TransactionSubmissionResult(
        success: true,
        message:
            'Transaction recorded! New balance: UGX ${newBalance.toStringAsFixed(0)}',
        newBalance: newBalance,
      );
    }

    await _databaseHelper.updateTransaction(transaction);
    return TransactionSubmissionResult(
      success: true,
      message:
          'Transaction updated! New balance: UGX ${newBalance.toStringAsFixed(0)}',
      newBalance: newBalance,
    );
  }
}
