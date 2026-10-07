import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายรับ-รายจ่าย')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => provider
                        .fetchAndSetTransactions()
                        .catchError((Object _) {}),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final transactions = provider.transactions;
          if (transactions.isEmpty) {
            return const Center(child: Text('ไม่มีรายการ'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isIncome = transaction.type == TransactionType.income;
              return ListTile(
                leading: CircleAvatar(child: Text(isIncome ? 'รับ' : 'จ่าย')),
                title: Text(transaction.title),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AddEditTransactionScreen(transaction: transaction),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${transaction.amount.toStringAsFixed(2)} บาท',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    IconButton(
                      tooltip: 'ลบ ${transaction.title}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, transaction),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'เพิ่มรายการ',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AddEditTransactionScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(BuildContext context, MyTransaction transaction) async {
    try {
      await context.read<TransactionProvider>().deleteTransaction(
        transaction.id!,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบรายการไม่สำเร็จ: $error')));
    }
  }
}