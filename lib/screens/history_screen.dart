import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  NetworkType? _filterNetwork;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<List<FloatTransaction>> _getTransactions() async {
    if (_startDate != null && _endDate != null) {
      return await DatabaseHelper.instance.getTransactionsByDateRange(_startDate!, _endDate!);
    }
    if (_filterNetwork != null) {
      return await DatabaseHelper.instance.getTransactionsByNetwork(_filterNetwork!);
    }
    return await DatabaseHelper.instance.getAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportAndShare,
          ),
        ],
      ),
      body: FutureBuilder<List<FloatTransaction>>(
        future: _getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            itemCount: transactions.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final t = transactions[index];
              return Dismissible(
                key: Key(t.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await DatabaseHelper.instance.deleteTransaction(t.id!);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction deleted')),
                    );
                  }
                },
                child: Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: t.network == NetworkType.mtn
                          ? const Color(0xFFFFCC00)
                          : const Color(0xFFE4002B),
                      child: Icon(
                        t.isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: t.network == NetworkType.mtn ? Colors.black : Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      '${t.typeLabel} - UGX ${t.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(t.formattedDate),
                    trailing: Text(
                      'Bal: UGX ${t.balanceAfter.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.fee != null) _buildDetailRow('Fee/Charges', 'UGX ${t.fee!.toStringAsFixed(0)}'),
                            if (t.customerName != null) _buildDetailRow('Customer', t.customerName!),
                            if (t.customerPhone != null) _buildDetailRow('Phone', t.customerPhone!),
                            if (t.notes != null) _buildDetailRow('Notes', t.notes!),
                            _buildDetailRow('Transaction ID', '#${t.id}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Filter By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFCC00), child: Icon(Icons.phone_android, color: Colors.black)),
                title: const Text('MTN MoMo Only'),
                trailing: _filterNetwork == NetworkType.mtn ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() => _filterNetwork = _filterNetwork == NetworkType.mtn ? null : NetworkType.mtn);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE4002B), child: Icon(Icons.phone_iphone, color: Colors.white)),
                title: const Text('Airtel Money Only'),
                trailing: _filterNetwork == NetworkType.airtel ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() => _filterNetwork = _filterNetwork == NetworkType.airtel ? null : NetworkType.airtel);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Select Date Range'),
                subtitle: _startDate != null
                    ? Text('${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}')
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
              ),
              if (_startDate != null || _filterNetwork != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterNetwork = null;
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAndShare() async {
    try {
      final path = await DatabaseHelper.instance.exportToCSV();
      await Share.shareXFiles([XFile(path)], text: 'MoMo Float Tracker Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
