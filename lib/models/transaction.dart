import 'package:intl/intl.dart';

enum NetworkType { mtn, airtel }
enum TransactionType { cashIn, cashOut }

class FloatTransaction {
  final int? id;
  final NetworkType network;
  final TransactionType type;
  final double amount;
  final double? fee;
  final double balanceAfter;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final DateTime timestamp;

  FloatTransaction({
    this.id,
    required this.network,
    required this.type,
    required this.amount,
    this.fee,
    required this.balanceAfter,
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'network': network.index,
      'type': type.index,
      'amount': amount,
      'fee': fee,
      'balanceAfter': balanceAfter,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FloatTransaction.fromMap(Map<String, dynamic> map) {
    return FloatTransaction(
      id: map['id'] as int?,
      network: NetworkType.values[map['network'] as int],
      type: TransactionType.values[map['type'] as int],
      amount: map['amount'] as double,
      fee: map['fee'] as double?,
      balanceAfter: map['balanceAfter'] as double,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String get networkLabel => network == NetworkType.mtn ? 'MTN MoMo' : 'Airtel Money';
  String get typeLabel => type == TransactionType.cashIn ? 'Cash In' : 'Cash Out';
  String get formattedDate => DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  String get formattedAmount => NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(amount);
  String get formattedBalance => NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(balanceAfter);

  bool get isCashIn => type == TransactionType.cashIn;
}
