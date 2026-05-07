import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../controllers/summary_controller.dart';
import 'package:intl/intl.dart';

/// Summary view: renders daily totals and balances.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late SummaryController _controller;
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // Read injected controller once from AppScope.
    _controller = AppScope.of(context).summaryController;
    _initialized = true;
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final data = await _controller.loadSummary();
    if (!mounted) return;
    setState(() {
      summary = data;
      isLoading = false;
    });
  }

  String fmt(double val) =>
      NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(val);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
        actions: [
          IconButton(
            tooltip: 'Refresh summary',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => isLoading = true);
              _loadSummary();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Today - ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // MTN Summary
                    _buildNetworkSummary(
                      'MTN MoMo',
                      const Color(0xFFFFCC00),
                      Colors.black,
                      summary['mtnCashIn'] ?? 0.0,
                      summary['mtnCashOut'] ?? 0.0,
                      summary['mtnBalance'] ?? 0.0,
                    ),
                    const SizedBox(height: 16),

                    // Airtel Summary
                    _buildNetworkSummary(
                      'Airtel Money',
                      const Color(0xFFE4002B),
                      Colors.white,
                      summary['airtelCashIn'] ?? 0.0,
                      summary['airtelCashOut'] ?? 0.0,
                      summary['airtelBalance'] ?? 0.0,
                    ),
                    const SizedBox(height: 24),

                    // Combined Stats
                    _buildCombinedStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNetworkSummary(
    String network,
    Color color,
    Color textColor,
    double cashIn,
    double cashOut,
    double balance,
  ) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              network,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Deposit',
                    cashIn,
                    Colors.green,
                    textColor,
                    Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Withdraw',
                    cashOut,
                    Colors.red,
                    textColor,
                    Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: textColor.withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Float Balance',
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                  Text(
                    fmt(balance),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, double amount, Color amountColor,
      Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: amountColor, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: textColor.withOpacity(0.8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fmt(amount),
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedStats() {
    final totalCashIn =
        (summary['mtnCashIn'] ?? 0.0) + (summary['airtelCashIn'] ?? 0.0);
    final totalCashOut =
        (summary['mtnCashOut'] ?? 0.0) + (summary['airtelCashOut'] ?? 0.0);
    final totalFees = summary['totalFees'] ?? 0.0;
    final netFlow = totalCashIn - totalCashOut;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combined Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOverviewRow('Total Deposits', totalCashIn, Colors.green),
            const Divider(),
            _buildOverviewRow('Total Withdrawals', totalCashOut, Colors.red),
            const Divider(),
            _buildOverviewRow('Total Commission Earned', totalFees, Colors.blue),
            const Divider(),
            _buildOverviewRow('Net Float Flow', netFlow,
                netFlow >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_overviewIcon(label), color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(
            fmt(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _overviewIcon(String label) {
    switch (label) {
      case 'Total Deposits':
        return Icons.download_rounded;
      case 'Total Withdrawals':
        return Icons.upload_rounded;
      case 'Total Commission Earned':
        return Icons.savings_outlined;
      default:
        return Icons.show_chart_rounded;
    }
  }
}
