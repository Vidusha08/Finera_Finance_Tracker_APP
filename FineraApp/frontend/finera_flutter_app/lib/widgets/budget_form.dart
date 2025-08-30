//widgets/budget_form.dart

import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart'; // defines CategoryModel

class BudgetForm extends StatefulWidget {
  final List<CategoryModel> categories;
  final Budget? budget;
  final Function(Budget) onSubmit;

  const BudgetForm({
    super.key,
    required this.categories,
    this.budget,
    required this.onSubmit,
  });

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  int? _categoryId;
  double? _amount;
  int? _month;
  int? _year;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _categoryId = widget.budget!.categoryId;
      _amount = widget.budget!.amount;
      _month = widget.budget!.month;
      _year = widget.budget!.year;
    } else {
      final now = DateTime.now();
      _month = now.month;
      _year = now.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.budget != null ? 'Edit Budget' : 'Add Budget'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .where((c) => c.id != null)
                    .map((c) => DropdownMenuItem(
                          value: c.id!,
                          child: Text(c.name),
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
                  if (val == null || val.isEmpty) return 'Enter amount';
                  final v = double.tryParse(val);
                  if (v == null || v <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              TextFormField(
                initialValue: _month?.toString(),
                decoration: const InputDecoration(labelText: 'Month (1-12)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _month = int.tryParse(val ?? '0'),
                validator: (val) {
                  final month = int.tryParse(val ?? '');
                  if (month == null || month < 1 || month > 12) {
                    return 'Enter 1-12';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _year?.toString(),
                decoration: const InputDecoration(labelText: 'Year (2020-2030)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _year = int.tryParse(val ?? '0'),
                validator: (val) {
                  final year = int.tryParse(val ?? '');
                  if (year == null || year < 2020 || year > 2030) {
                    return 'Enter valid year';
                  }
                  return null;
                },
              ),
            ],
          ),
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

                // Find the selected category to populate name/type
                final selectedCategory = widget.categories.firstWhere(
                  (c) => c.id == _categoryId,
                  orElse: () => CategoryModel(id: _categoryId!, name: '', type: '', color: ''),
                );

                final budget = Budget(
                  id: widget.budget?.id ?? 0,
                  categoryId: _categoryId!,
                  categoryName: selectedCategory.name,
                  categoryType: selectedCategory.type,
                  amount: _amount!,
                  spentAmount: widget.budget?.spentAmount ?? 0,
                  remainingAmount: widget.budget?.remainingAmount ?? 0,
                  percentageUsed: widget.budget?.percentageUsed ?? 0,
                  month: _month!,
                  year: _year!,
                );

                widget.onSubmit(budget);
              }
            },
            
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


