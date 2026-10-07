import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/my_transaction.dart';
 
class AddEditTransactionScreen extends StatefulWidget {
  final MyTransaction? transaction;
 
  const AddEditTransactionScreen({super.key, this.transaction});
 
  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}
 
class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
 
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late TransactionType _selectedType;
 
  bool get isEditing => widget.transaction != null;
 
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: isEditing ? widget.transaction!.title : '',
    );
    _amountController = TextEditingController(
      text: isEditing ? widget.transaction!.amount.toString() : '',
    );
    _selectedDate = isEditing ? widget.transaction!.date : DateTime.now();
    _selectedType = isEditing
        ? widget.transaction!.type
        : TransactionType.expense;
  }
 
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
 
  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
 
  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
 
    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
 
    if (isEditing) {
      final updatedTx = MyTransaction(
        id: widget.transaction!.id,
        title: title,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
      );
      txProvider.updateTransaction(widget.transaction!.id!, updatedTx);
    } else {
      txProvider.addTransaction(title, amount, _selectedDate, _selectedType);
    }
 
    Navigator.of(context).pop();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // เลือกประเภท รายรับ / รายจ่าย
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('รายจ่าย'),
                    icon: Icon(Icons.arrow_downward, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('รายรับ'),
                    icon: Icon(Icons.arrow_upward, color: Colors.green),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
 
              // กรอกชื่อรายการ
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อรายการ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อรายการ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
 
              // กรอกจำนวนเงิน
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน',
                  border: OutlineInputBorder(),
                  suffixText: 'บาท',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนเงิน';
                  }
                  if (double.tryParse(value) == null) {
                    return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  }
                  if (double.parse(value) <= 0) {
                    return 'จำนวนเงินต้องมากกว่า 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
 
              // ตัวเลือกวันที่
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _presentDatePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('เลือกวันที่'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
 
              // ปุ่มบันทึก
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveForm,
                child: Text(
                  isEditing ? 'อัปเดตข้อมูล' : 'บันทึกรายการ',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
 