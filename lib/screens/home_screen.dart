import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double mtnBalance = 0.0;
  double airtelBalance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final mtn = await DatabaseHelper.instance.getCurrentBalance(NetworkType.mtn);
    final airtel = await DatabaseHelper.instance.getCurrentBalance(NetworkType.airtel);
    setState(() {
      mtnBalance = mtn;
      airtelBalance = airtel;
      isLoading = false;
    });
  }

  Color getMtnColor() => const Color(0xFFFFCC00);
  Color getAirtelColor() => const Color(0xFFE4002B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Float Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
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
                      icon: Icons.phone_android,
                      onTap: () => _navigateToAddTransaction(NetworkType.mtn),
                    ),
                    const SizedBox(height: 16),
                    // Airtel Card
                    _buildNetworkCard(
                      network: 'Airtel Money',
                      balance: airtelBalance,
                      color: getAirtelColor(),
                      textColor: Colors.white,
                      icon: Icons.phone_iphone,
                      onTap: () => _navigateToAddTransaction(NetworkType.airtel),
                    ),
                    const SizedBox(height: 24),
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    // Recent Activity Preview
                    _buildRecentActivityPreview(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNetworkSelection(),
        icon: const Icon(Icons.add),
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
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: textColor, size: 28),
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
                'UGX ${balance.toStringAsFixed(0)}',
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
                    'Tap to add transaction',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: textColor.withOpacity(0.7), size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.arrow_downward,
                label: 'Cash In',
                color: Colors.green,
                onTap: () => _showNetworkSelection(type: TransactionType.cashIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.arrow_upward,
                label: 'Cash Out',
                color: Colors.red,
                onTap: () => _showNetworkSelection(type: TransactionType.cashOut),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          future: DatabaseHelper.instance.getAllTransactions(),
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
              children: transactions.map((t) => _buildTransactionItem(t)).toList(),
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
            t.isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: isMtn ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          '${t.typeLabel} - ${t.networkLabel}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(t.formattedDate),
        trailing: Text(
          'UGX ${t.amount.toStringAsFixed(0)}',
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
                leading: CircleAvatar(backgroundColor: getMtnColor(), child: const Icon(Icons.phone_android, color: Colors.black)),
                title: const Text('MTN MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddTransaction(NetworkType.mtn, preselectedType: type);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: getAirtelColor(), child: const Icon(Icons.phone_iphone, color: Colors.white)),
                title: const Text('Airtel Money', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddTransaction(NetworkType.airtel, preselectedType: type);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddTransaction(NetworkType network, {TransactionType? preselectedType}) {
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
