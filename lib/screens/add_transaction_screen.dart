import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction.dart';
import '../utils/ugx_input_formatter.dart';

/// Transaction form view for both create and edit flows.
class AddTransactionScreen extends StatefulWidget {
  final NetworkType network;
  final TransactionType? preselectedType;
  final FloatTransaction? existingTransaction;

  const AddTransactionScreen({
    super.key,
    required this.network,
    this.preselectedType,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionController _controller;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _ugxInputFormatter = UgxInputFormatter();

  late TransactionType _selectedType;
  late ServiceType _selectedServiceType;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // Read injected controller once from AppScope.
    _controller = AppScope.of(context).transactionController;
    _initialized = true;
    _selectedType = widget.existingTransaction?.type ??
        widget.preselectedType ??
        TransactionType.cashIn;
    _selectedServiceType =
        widget.existingTransaction?.serviceType ?? ServiceType.momo;

    // Prefill fields when editing an existing transaction.
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountController.text =
          NumberFormat.decimalPattern().format(existing.amount.round());
      if (existing.fee != null && existing.fee! > 0) {
        _feeController.text =
            NumberFormat.decimalPattern().format(existing.fee!.round());
      }
      _customerNameController.text = existing.customerName ?? '';
      _customerPhoneController.text = existing.customerPhone ?? '';
      _notesController.text = existing.notes ?? '';
    }
  }

  Color getNetworkColor() {
    return widget.network == NetworkType.mtn
        ? const Color(0xFFFFCC00)
        : const Color(0xFFE4002B);
  }

  @override
  Widget build(BuildContext context) {
    final isMtn = widget.network == NetworkType.mtn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isMtn ? 'MTN MoMo' : 'Airtel Money'} - ${widget.existingTransaction == null ? 'New Transaction' : 'Edit Transaction'}',
        ),
        backgroundColor: getNetworkColor(),
        foregroundColor: isMtn ? Colors.black : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.cashIn,
                    label: Text('Deposit'),
                    icon: Icon(Icons.add_circle_outline_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.cashOut,
                    label: Text('Withdraw'),
                    icon: Icon(Icons.remove_circle_outline_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              SegmentedButton<ServiceType>(
                segments: const [
                  ButtonSegment(
                    value: ServiceType.momo,
                    label: Text('Money'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: ServiceType.airtime,
                    label: Text('Airtime'),
                    icon: Icon(Icons.call_rounded),
                  ),
                  ButtonSegment(
                    value: ServiceType.data,
                    label: Text('Data'),
                    icon: Icon(Icons.wifi_rounded),
                  ),
                ],
                selected: {_selectedServiceType},
                onSelectionChanged: (Set<ServiceType> newSelection) {
                  setState(() {
                    _selectedServiceType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ugxInputFormatter],
                decoration: InputDecoration(
                  labelText: 'Amount (UGX)',
                  prefixText: 'UGX ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter amount';
                  final parsedValue = _parseCurrencyText(value);
                  if (parsedValue == null || parsedValue <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fee
              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ugxInputFormatter],
                decoration: InputDecoration(
                  labelText: 'Commission (UGX)',
                  prefixText: 'UGX ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter commission';
                  }
                  final parsedValue = _parseCurrencyText(value);
                  if (parsedValue == null || parsedValue <= 0) {
                    return 'Please enter a valid commission';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Customer Name
              TextFormField(
                controller: _customerNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Customer Phone
              TextFormField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Customer Phone (Optional)',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getNetworkColor(),
                    foregroundColor: isMtn ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          '${widget.existingTransaction == null ? 'Record' : 'Save'} ${_selectedType == TransactionType.cashIn ? 'Deposit' : 'Withdraw'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = _parseCurrencyText(_amountController.text);
      final fee = _parseCurrencyText(_feeController.text);
      if (amount == null) {
        throw const FormatException('Invalid amount');
      }
      if (fee == null || fee <= 0) {
        throw const FormatException('Invalid commission');
      }
      final existing = widget.existingTransaction;
      final result = await _controller.submitTransaction(
        network: widget.network,
        type: _selectedType,
        serviceType: _selectedServiceType,
        amount: amount,
        fee: fee,
        customerName: _customerNameController.text.isNotEmpty
            ? _customerNameController.text
            : null,
        customerPhone: _customerPhoneController.text.isNotEmpty
            ? _customerPhoneController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        existingTransaction: existing,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double? _parseCurrencyText(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
