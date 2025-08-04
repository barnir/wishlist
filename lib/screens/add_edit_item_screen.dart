import 'package:flutter/material.dart';

class AddEditItemScreen extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final int? initialQuantity;

  const AddEditItemScreen({
    Key? key,
    this.initialName,
    this.initialDescription,
    this.initialQuantity,
  }) : super(key: key);

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _quantityController = TextEditingController(text: widget.initialQuantity?.toString() ?? '1');
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

    // Aqui adiciona lógica para guardar item na base de dados ou coleção
    // Por exemplo, chamar API ou atualizar Firestore

    await Future.delayed(const Duration(seconds: 1)); // Simulação

    setState(() => _isSaving = false);
    Navigator.of(context).pop(true); // Pode enviar 'true' para indicar sucesso
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialName == null ? 'Adicionar Item' : 'Editar Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                    : Text(widget.initialName == null ? 'Adicionar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
