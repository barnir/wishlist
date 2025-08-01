import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wish_item.dart';

class AddItemScreen extends StatefulWidget {
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String link = '';
  String description = '';
String categoriaSelecionada = 'Livro';

final categorias = [
  'Livro',
  'Eletrónico',
  'Viagem',
  'Moda',
  'Casa',
  'Outro'
];
  void saveItem() {
    if (_formKey.currentState!.validate()) {
      Hive.box<WishItem>('wishlist').add(
        WishItem(
            title: title,
            link: link.isNotEmpty ? link : null,
            description: description,
            category: categoriaSelecionada),
        );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Novo Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome do item'),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                onChanged: (v) => setState(() => title = v),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Link (opcional)'),
                onChanged: (v) => setState(() => link = v),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Descrição'),
                onChanged: (v) => setState(() => description = v),
              ),
              DropdownButtonFormField<String>(
              value: categoriaSelecionada,
              items: categorias
                  .map((cat) => DropdownMenuItem(child: Text(cat), value: cat))
                  .toList(),
              onChanged: (v) => setState(() => categoriaSelecionada = v!),
              decoration: InputDecoration(labelText: 'Categoria'),
),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: saveItem,
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
