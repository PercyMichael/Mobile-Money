# Mobile-Money — MoMo Float Tracker

A fully **offline** Flutter mobile app for tracking MTN MoMo and Airtel Money float balances. Built for mobile money agents in Uganda who need a fast, reliable way to record transactions and monitor float levels without an internet connection.

---

## Features

| Feature | Description |
|---|---|
| **Offline Storage** | All data stored locally using SQLite — no internet required |
| **Dual Network Support** | Track MTN MoMo (yellow) and Airtel Money (red) separately |
| **Cash In / Cash Out** | Record both directions of float movement |
| **Auto Balance Calculation** | Running float balance updated automatically after every transaction |
| **Balance Validation** | Prevents recording a Cash Out that exceeds current float |
| **Customer Details** | Optionally attach customer name and phone to each transaction |
| **Fee Tracking** | Record commission/charges earned per transaction |
| **Daily Summary** | Dashboard showing today's Cash In, Cash Out, fees earned and net float flow |
| **Transaction History** | Full scrollable list of all transactions with expand-for-details |
| **Filter Transactions** | Filter history by network (MTN / Airtel) or by date range |
| **Swipe to Delete** | Delete any transaction with a swipe and confirmation dialog |
| **Export to CSV** | Export all transactions to a CSV file and share via any app |

---

## How the App Works

### 1. Home Screen
When you open the app, you see two large cards — one for MTN MoMo (yellow) and one for Airtel Money (red) — each showing the current float balance for that network.

Tap either card or use the **New Transaction** button at the bottom to record a transaction. The **Cash In** and **Cash Out** quick-action buttons let you jump straight into a specific transaction type. The bottom of the screen shows your 5 most recent transactions with a "See All" link.

---

### 2. Recording a Transaction
On the Add Transaction screen, select whether it is a **Cash In** or **Cash Out**, enter the amount in UGX, and optionally add a fee, customer name, phone number, and notes. Tap **Record** and the app automatically calculates and saves the new float balance.

If you try to record a Cash Out greater than the current float balance, the app blocks it and shows an error message.

---

### 3. Transaction History
The History screen shows all recorded transactions in reverse chronological order. You can:
- Tap any row to expand and see full details including fee, customer info, notes and transaction ID
- Swipe left on a transaction to delete it (requires confirmation)
- Filter by MTN only, Airtel only, or a custom date range
- Share / export all transactions as a CSV file via the share icon

---

### 4. Daily Summary
The Summary screen shows statistics for today broken down per network — Cash In total, Cash Out total, and current float balance — as well as a combined overview showing total fees earned and net float flow. Pull down to refresh at any time.

---

## Tech Stack

| Package | Purpose |
|---|---|
| sqflite | Local SQLite database |
| path_provider | Device file system access |
| path | File path utilities |
| intl | Date and currency formatting |
| csv | CSV file generation |
| share_plus | Native share sheet for export |
| permission_handler | Runtime permissions |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Android SDK or Xcode for iOS

### Install and Run
Clone the repository, run `flutter pub get` to install dependencies, then run `flutter run` to launch on a connected device or emulator.

---

## License

This project is private and intended for personal or business use by mobile money agents.
