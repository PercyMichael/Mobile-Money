# Mobile-Money — MoMo Float Tracker

A fully **offline** Flutter mobile app for tracking MTN MoMo and Airtel Money float balances. Built for mobile money agents in Uganda who need a fast, reliable way to record transactions and monitor float levels without an internet connection.

---

## 📱 Screenshots

> Run `flutter run` to see the app in action on your device or emulator.

---

## 🚀 Features

| Feature | Description |
|---|---|
| **Offline Storage** | All data stored locally using SQLite via `sqflite` — no internet required |
| **Dual Network Support** | Track MTN MoMo (yellow) and Airtel Money (red) separately |
| **Cash In / Cash Out** | Record both directions of float movement |
| **Auto Balance Calculation** | Running float balance updated automatically after every transaction |
| **Balance Validation** | Prevents recording a Cash Out that exceeds current float |
| **Customer Details** | Optionally attach customer name and phone to each transaction |
| **Fee Tracking** | Record commission/charges earned per transaction |
| **Daily Summary** | Dashboard showing today's Cash In, Cash Out, fees earned and net float flow |
| **Transaction History** | Full scrollable list of all transactions with expand-for-details |
| **Filter Transactions** | Filter history by network (MTN / Airtel) or by date range |
| **Swipe to Delete** | Delete any transaction with a swipe + confirmation dialog |
| **Export to CSV** | Export all transactions to a `.csv` file |
| **Share Export** | Share the CSV file via any app on the device (WhatsApp, email, etc.) |

---

## 🏗️ Project Structure

```
lib/
├── main.dart                        # App entry point & theme setup
├── models/
│   └── transaction.dart             # FloatTransaction model + enums
├── database/
│   └── database_helper.dart         # SQLite singleton (CRUD + export)
├── screens/
│   ├── home_screen.dart             # Dashboard — balances & quick actions
│   ├── add_transaction_screen.dart  # Form to record Cash In / Cash Out
│   ├── history_screen.dart          # Transaction list with filter & share
│   └── summary_screen.dart          # Daily summary per network + combined
└── widgets/
    └── transaction_card.dart        # Reusable transaction list item
```

---

## ⚙️ How the App Works

### 1. Home Screen
When you open the app, you see two large cards:
- **MTN MoMo** (yellow) — shows current MTN float balance
- **Airtel Money** (red) — shows current Airtel float balance

Tap either card, or use the **New Transaction** FAB at the bottom, to record a transaction. Quick Action buttons (Cash In / Cash Out) let you jump straight into a transaction type.

The bottom of the home screen shows your **5 most recent transactions** with a "See All" link.

---

### 2. Recording a Transaction
On the **Add Transaction** screen:
1. Toggle between **Cash In** or **Cash Out** using the segmented button at the top.
2. Enter the **Amount** in UGX.
3. Optionally enter a **Fee/Charge** earned on the transaction.
4. Optionally enter the **Customer Name** and **Phone Number**.
5. Add any **Notes** if needed.
6. Tap **Record** — the app automatically calculates and saves the new balance.

> ⚠️ If you try to record a Cash Out greater than your current float, the app will block it and show an error.

---

### 3. Transaction History
The **History** screen (accessible from the top-right history icon) shows all recorded transactions in reverse chronological order.

- **Expand** any row to see full details (fee, customer, notes, transaction ID).
- **Swipe left** on a transaction to delete it (with a confirmation prompt).
- **Filter** by tapping the filter icon:
  - Show only MTN MoMo transactions
  - Show only Airtel Money transactions
  - Pick a custom date range
  - Clear all filters
- **Share / Export** by tapping the share icon — exports all transactions to a CSV file and opens the share sheet.

---

### 4. Daily Summary
The **Summary** screen (accessible from the summarize icon on the home app bar) shows statistics for **today**:

- Per-network breakdown: Cash In total, Cash Out total, current float balance
- Combined overview: total Cash In, total Cash Out, total fees earned, net float flow (positive = more cash received than given out)

Pull down to refresh at any time.

---

## 🗄️ Database

The app uses **SQLite** (via `sqflite`) stored in the device's application documents directory. The single table schema:

```sql
CREATE TABLE transactions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  network      INTEGER NOT NULL,   -- 0 = MTN, 1 = Airtel
  type         INTEGER NOT NULL,   -- 0 = Cash In, 1 = Cash Out
  amount       REAL    NOT NULL,
  fee          REAL,
  balanceAfter REAL    NOT NULL,
  customerName TEXT,
  customerPhone TEXT,
  notes        TEXT,
  timestamp    TEXT    NOT NULL    -- ISO 8601
)
```

---

## 🛠️ Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `sqflite` | ^2.3.0 | Local SQLite database |
| `path_provider` | ^2.1.1 | Device file system access |
| `path` | ^1.8.3 | File path utilities |
| `intl` | ^0.18.1 | Date & currency formatting |
| `csv` | ^5.1.1 | CSV generation |
| `share_plus` | ^7.2.1 | Native share sheet |
| `permission_handler` | ^11.0.1 | Runtime permissions |

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android SDK or Xcode (for iOS)

### Install & Run
```bash
git clone https://github.com/PercyMichael/Mobile-Money.git
cd Mobile-Money
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## 📄 License

This project is private and intended for personal/business use by mobile money agents.
