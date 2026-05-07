import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../controllers/home_controller.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'summary_screen.dart';

/// Home view: displays balances and quick navigation actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;
  double mtnBalance = 0.0;
  double airtelBalance = 0.0;
  bool isLoading = true;
  bool _initialized = false;
  final _currency = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    // Read injected controller once from AppScope.
    _controller = AppScope.of(context).homeController;
    _initialized = true;
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final balances = await _controller.loadBalances();
    if (!mounted) return;
    setState(() {
      mtnBalance = balances.$1;
      airtelBalance = balances.$2;
      isLoading = false;
    });
  }

  Color getMtnColor() => const Color(0xFFFFCC00);
  Color getAirtelColor() => const Color(0xFFE4002B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MoMo Float Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'View summary',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'View history',
            icon: const Icon(Icons.history_toggle_off_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBalances,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // MTN Card
                    _buildNetworkCard(
                      network: 'MTN MoMo',
                      balance: mtnBalance,
                      color: getMtnColor(),
                      textColor: Colors.black,
                      icon: Icons.sim_card_rounded,
                      networkType: NetworkType.mtn,
                      onTap: () => _showNetworkSelection(),
                    ),
                    const SizedBox(height: 16),
                    // Airtel Card
                    _buildNetworkCard(
                      network: 'Airtel Money',
                      balance: airtelBalance,
                      color: getAirtelColor(),
                      textColor: Colors.white,
                      icon: Icons.contactless_rounded,
                      networkType: NetworkType.airtel,
                      onTap: () => _showNetworkSelection(),
                    ),
                    const SizedBox(height: 24),
                    // Recent Activity Preview
                    _buildRecentActivityPreview(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNetworkSelection(),
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildNetworkCard({
    required String network,
    required double balance,
    required Color color,
    required Color textColor,
    required IconData icon,
    required NetworkType networkType,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.85)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: textColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    network,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Current Float',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currency.format(balance),
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Choose action',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Icon(Icons.touch_app_rounded,
                      color: textColor.withOpacity(0.7), size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCardActionButton(
                      label: 'Deposit',
                      icon: Icons.south_west_rounded,
                      foregroundColor: textColor,
                      onTap: () => _navigateToAddTransaction(
                        networkType,
                        preselectedType: TransactionType.cashIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCardActionButton(
                      label: 'Withdraw',
                      icon: Icons.north_east_rounded,
                      foregroundColor: textColor,
                      onTap: () => _navigateToAddTransaction(
                        networkType,
                        preselectedType: TransactionType.cashOut,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: foregroundColor),
      label: Text(label, style: TextStyle(color: foregroundColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: foregroundColor.withOpacity(0.16),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecentActivityPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<FloatTransaction>>(
          future: _controller.loadRecentTransactions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No transactions yet')),
                ),
              );
            }
            final transactions = snapshot.data!.take(5).toList();
            return Column(
              children:
                  transactions.map((t) => _buildTransactionItem(t)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(FloatTransaction t) {
    final isMtn = t.network == NetworkType.mtn;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMtn ? getMtnColor() : getAirtelColor(),
          child: Icon(
            t.isCashIn ? Icons.call_received_rounded : Icons.call_made_rounded,
            color: isMtn ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          '${t.typeLabel} (${t.serviceLabel}) - ${t.networkLabel}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(t.formattedDate),
        trailing: Text(
          _currency.format(t.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.isCashIn ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showNetworkSelection({TransactionType? type}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Network',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: getMtnColor(),
                    child:
                        const Icon(Icons.phone_android, color: Colors.black)),
                title: const Text('MTN MoMo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddTransaction(NetworkType.mtn,
                      preselectedType: type);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: getAirtelColor(),
                    child: const Icon(Icons.phone_iphone, color: Colors.white)),
                title: const Text('Airtel Money',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddTransaction(NetworkType.airtel,
                      preselectedType: type);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddTransaction(NetworkType network,
      {TransactionType? preselectedType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          network: network,
          preselectedType: preselectedType,
        ),
      ),
    ).then((_) => _loadBalances());
  }
}
