import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final FloatTransaction transaction;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  Color get _networkColor => transaction.network == NetworkType.mtn
      ? const Color(0xFFFFCC00)
      : const Color(0xFFE4002B);

  Color get _iconColor =>
      transaction.network == NetworkType.mtn ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _networkColor,
          child: Icon(
            transaction.isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: _iconColor,
            size: 18,
          ),
        ),
        title: Text(
          '${transaction.typeLabel} - ${transaction.networkLabel}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(transaction.formattedDate),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.isCashIn ? Colors.green : Colors.red,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
