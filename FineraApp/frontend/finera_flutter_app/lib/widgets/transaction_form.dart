// widgets/transaction_form.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionForm extends StatefulWidget {
  final List<CategoryModel> categories;
  final TransactionModel? transaction;
  final Function(TransactionModel) onSubmit;

  const TransactionForm({
    super.key,
    required this.categories,
    this.transaction,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  int? _categoryId;
  double? _amount;
  String? _description;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _categoryId = widget.transaction!.categoryId;
      _amount = widget.transaction!.amount;
      _description = widget.transaction!.description;
      _date = widget.transaction!.transactionDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesWithIds = widget.categories.where((c) => c.id != null).toList();

    return AlertDialog(
      title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<int>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categoriesWithIds
                  .map((c) => DropdownMenuItem(
                        value: c.id!, // safe due to filter above
                        child: Text("${c.name} (${c.type})"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _categoryId = val),
              validator: (val) => val == null ? 'Select a category' : null,
            ),
            TextFormField(
              initialValue: _amount?.toString(),
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onSaved: (val) => _amount = double.tryParse(val ?? '0'),
              validator: (val) {
                final parsed = double.tryParse(val ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              onSaved: (val) => _description = val,
            ),
            Row(
              children: [
                Expanded(child: Text("Date: ${_date.toLocal().toString().split(' ')[0]}")),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                )
              ],
            ),
            // Type input REMOVED: we auto-derive from category (better UX + matches backend validation)
          ]),
        ),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 240, 109, 109), Color.fromARGB(255, 254, 86, 83)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          //TextButton(onPressed: () => Navigator.pop(context), 
              //child: const Text("Cancel")),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.indigoAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),//ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                // Get selected category to fill names/types and derive transaction type
                final selectedCategory = categoriesWithIds.firstWhere((c) => c.id == _categoryId);

                final tx = TransactionModel(
                  id: widget.transaction?.id ?? 0,
                  categoryId: _categoryId!,
                  categoryName: selectedCategory.name,
                  categoryType: selectedCategory.type, // "Income" or "Expense"
                  amount: _amount!,
                  description: _description,
                  transactionDate: _date,
                  type: selectedCategory.type, // derive type from category
                );
                widget.onSubmit(tx);
              }
            },
            //child: const Text("Save", style: TextStyle(color: Colors.white)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

