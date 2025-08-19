//widgets/category_form.dart (Add/Edit Categories)

import 'package:flutter/material.dart';
import '../models/category.dart';
import 'color_utils.dart';
import 'icon_registry.dart';

class CategoryForm extends StatefulWidget {
  final CategoryModel? initial; // null => create, non-null => edit

  const CategoryForm({super.key, this.initial});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _type = 'Expense';
  Color _color = const Color(0xFF007BFF);
  String? _iconName = 'work';

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _nameCtrl.text = init.name;
      _type = init.type;
      _color = colorFromHex(init.color);
      _iconName = init.icon ?? 'work';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final model = CategoryModel(
      id: widget.initial?.id,
      name: _nameCtrl.text.trim(),
      type: _type,
      color: hexFromColor(_color),
      icon: _iconName,
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initial == null ? 'Add Category' : 'Edit Category',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Income', child: Text('Income')),
                    DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'Expense'),
                ),
                const SizedBox(height: 16),

                // Color
                Row(
                  children: [
                    const Text('Color:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final c in [
                                    Colors.red,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.orange,
                                    Colors.purple,
                                    Colors.teal,
                                    Colors.brown,
                                    Colors.pink
                                  ])
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context, c),
                                      child: CircleAvatar(backgroundColor: c),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (picked != null) setState(() => _color = picked);
                      },
                      child: CircleAvatar(backgroundColor: _color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Icon
                DropdownButtonFormField<String>(
                  value: _iconName,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                  ),
                  items: iconRegistry.keys
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (v) => setState(() => _iconName = v),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.initial == null ? 'Add' : 'Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}