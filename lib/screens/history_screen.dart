import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../controllers/history_controller.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// History view: browse, filter, edit, delete, and export transactions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryController _controller;
  NetworkType? _filterNetwork;
  ServiceType? _filterServiceType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _initialized = false;
  final _currency = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // Read injected controller once from AppScope.
    _controller = AppScope.of(context).historyController;
    _initialized = true;
  }

  Future<List<FloatTransaction>> _getTransactions() async {
    return await _controller.getTransactions(
      network: _filterNetwork,
      serviceType: _filterServiceType,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            tooltip: 'Filter transactions',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share_rounded),
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

          return Column(
            children: [
              if (_hasActiveFilters())
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      if (_filterNetwork != null)
                        _buildFilterChip(
                          label:
                              'Network: ${_filterNetwork == NetworkType.mtn ? 'MTN' : 'Airtel'}',
                          onDeleted: () =>
                              setState(() => _filterNetwork = null),
                          backgroundColor: _filterNetwork == NetworkType.mtn
                              ? const Color(0xFFFFF3B0)
                              : const Color(0xFFFFD7DE),
                        ),
                      if (_filterServiceType != null)
                        _buildFilterChip(
                          label:
                              'Service: ${_serviceFilterLabel(_filterServiceType!)}',
                          onDeleted: () =>
                              setState(() => _filterServiceType = null),
                          backgroundColor:
                              _serviceFilterColor(_filterServiceType!),
                        ),
                      if (_startDate != null && _endDate != null)
                        _buildFilterChip(
                          label:
                              'Date: ${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
                          onDeleted: () => setState(() {
                            _startDate = null;
                            _endDate = null;
                          }),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      _buildFilterChip(
                        label: 'Clear all',
                        onDeleted: () => setState(() {
                          _filterNetwork = null;
                          _filterServiceType = null;
                          _startDate = null;
                          _endDate = null;
                        }),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
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
                            content:
                                const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await _controller.deleteTransaction(t.id!);
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Transaction deleted')),
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
                              t.isCashIn
                                  ? Icons.call_received_rounded
                                  : Icons.call_made_rounded,
                              color: t.network == NetworkType.mtn
                                  ? Colors.black
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${t.typeLabel} (${t.serviceLabel}) - ${_currency.format(t.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(t.formattedDate),
                          trailing: Text(
                            'Bal: ${_currency.format(t.balanceAfter)}',
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
                                  if (t.fee != null)
                                    _buildDetailRow(
                                        'Commission', _currency.format(t.fee!)),
                                  if (t.customerName != null)
                                    _buildDetailRow(
                                        'Customer', t.customerName!),
                                  if (t.customerPhone != null)
                                    _buildDetailRow('Phone', t.customerPhone!),
                                  if (t.notes != null)
                                    _buildDetailRow('Notes', t.notes!),
                                  _buildDetailRow('Transaction ID', '#${t.id}'),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _editTransaction(t),
                                      icon: const Icon(Icons.edit_square),
                                      label: const Text('Edit Transaction'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filterNetwork != null ||
        _filterServiceType != null ||
        (_startDate != null && _endDate != null);
  }

  String _serviceFilterLabel(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.momo:
        return 'Money';
      case ServiceType.airtime:
        return 'Airtime';
      case ServiceType.data:
        return 'Data';
    }
  }

  Color _serviceFilterColor(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.momo:
        return Colors.green.shade50;
      case ServiceType.airtime:
        return Colors.orange.shade50;
      case ServiceType.data:
        return Colors.blue.shade50;
    }
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        backgroundColor: backgroundColor,
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
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Filter By',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFCC00),
                    child: Icon(Icons.phone_android, color: Colors.black)),
                title: const Text('MTN MoMo Only'),
                trailing: _filterNetwork == NetworkType.mtn
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _filterNetwork =
                      _filterNetwork == NetworkType.mtn
                          ? null
                          : NetworkType.mtn);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE4002B),
                    child: Icon(Icons.phone_iphone, color: Colors.white)),
                title: const Text('Airtel Money Only'),
                trailing: _filterNetwork == NetworkType.airtel
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _filterNetwork =
                      _filterNetwork == NetworkType.airtel
                          ? null
                          : NetworkType.airtel);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Money Service Only'),
                trailing: _filterServiceType == ServiceType.momo
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _filterServiceType =
                      _filterServiceType == ServiceType.momo
                          ? null
                          : ServiceType.momo);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_rounded),
                title: const Text('Airtime Service Only'),
                trailing: _filterServiceType == ServiceType.airtime
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _filterServiceType =
                      _filterServiceType == ServiceType.airtime
                          ? null
                          : ServiceType.airtime);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi_rounded),
                title: const Text('Data Service Only'),
                trailing: _filterServiceType == ServiceType.data
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _filterServiceType =
                      _filterServiceType == ServiceType.data
                          ? null
                          : ServiceType.data);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Select Date Range'),
                subtitle: _startDate != null
                    ? Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}')
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
              if (_startDate != null ||
                  _filterNetwork != null ||
                  _filterServiceType != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterNetwork = null;
                      _filterServiceType = null;
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
      final path = await _controller.exportTransactionsCsv();
      await Share.shareXFiles([XFile(path)], text: 'MoMo Float Tracker Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _editTransaction(FloatTransaction transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          network: transaction.network,
          existingTransaction: transaction,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}
