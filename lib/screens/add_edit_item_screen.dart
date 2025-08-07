import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditItemScreen extends StatefulWidget {
  final String wishlistId;
  final String? itemId;

  const AddEditItemScreen({
    super.key,
    required this.wishlistId,
    this.itemId,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  bool _isSaving = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _quantityController = TextEditingController(text: '1');

    if (widget.itemId != null) {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    setState(() => _isSaving = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wishlists')
          .doc(widget.wishlistId)
          .collection('items')
          .doc(widget.itemId)
          .get();

      if (doc.exists) {
        _nameController.text = doc['name'] ?? '';
        _descriptionController.text = doc['description'] ?? '';
        _quantityController.text = (doc['quantity'] ?? 1).toString();
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar item: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
      };

      if (widget.itemId == null) {
        await FirebaseFirestore.instance
            .collection('wishlists')
            .doc(widget.wishlistId)
            .collection('items')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('wishlists')
            .doc(widget.wishlistId)
            .collection('items')
            .doc(widget.itemId)
            .update(data);
      }

      if (!mounted) return; // Check if the widget is still mounted
      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      setState(() => _erro = 'Erro ao guardar item: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemId == null ? 'Adicionar Item' : 'Editar Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSaving && widget.itemId != null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_erro != null) ...[
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome do Item'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Insere o nome do item' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Insere a quantidade';
                        final n = int.tryParse(value);
                        if (n == null || n < 1) return 'Quantidade inválida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveItem,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.itemId == null ? 'Adicionar' : 'Guardar'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}