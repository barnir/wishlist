import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore
import '../models/wish_item.dart';

class AddItemScreen extends StatefulWidget {
  final WishItem? item; // Null para novo, preenchido para edição

  AddItemScreen({this.item});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Estado das variáveis que controlam o formulário
  late String title;
  late String link;
  late String description;
  late double? price; // Pode ser null se não for preenchido
  late String categoriaSelecionada;

  // Lista fixa de categorias
  final List<String> categorias = [
    'Livro',
    'Eletrónico',
    'Viagem',
    'Moda',
    'Casa',
    'Outro',
  ];

  final CollectionReference wishlistCollection =
      FirebaseFirestore.instance.collection('wishlist');

  @override
  void initState() {
    super.initState();

    // Inicializa os campos com os valores do item passado, se houver, senão padrões
    title = widget.item?.title ?? '';
    link = widget.item?.link ?? '';
    description = widget.item?.description ?? '';
    price = widget.item?.price;
    categoriaSelecionada = widget.item?.category ?? categorias[0];
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Cria o mapa de dados a salvar
    Map<String, dynamic> data = {
      'title': title,
      'link': link.isNotEmpty ? link : null,
      'description': description,
      'price': price,
      'category': categoriaSelecionada,
    };

    try {
      if (widget.item != null && widget.item!.id.isNotEmpty) {
        // Atualiza o documento existente
        await wishlistCollection.doc(widget.item!.id).update(data);
      } else {
        // Adiciona novo documento
        await wishlistCollection.add(data);
      }
      Navigator.pop(context);
    } catch (e) {
      // Trate erros aqui (ex: mostrar snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o item: $e')),
      );
    }
  }

  Widget categoriaIcone(String cat) {
    switch (cat) {
      case 'Livro':
        return Icon(Icons.book);
      case 'Eletrónico':
        return Icon(Icons.electrical_services);
      case 'Viagem':
        return Icon(Icons.flight);
      case 'Moda':
        return Icon(Icons.checkroom);
      case 'Casa':
        return Icon(Icons.home);
      default:
        return Icon(Icons.star);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item != null ? 'Editar Item' : 'Novo Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(  // Use ListView para o teclado não cobrir os campos
            children: [
              TextFormField(
                initialValue: title,
                decoration: InputDecoration(labelText: 'Nome do item'),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                onChanged: (v) => setState(() => title = v),
              ),
              TextFormField(
                initialValue: link,
                decoration: InputDecoration(labelText: 'Link (opcional)'),
                onChanged: (v) => setState(() => link = v),
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Descrição'),
                onChanged: (v) => setState(() => description = v),
              ),
              TextFormField(
                initialValue: price?.toString() ?? '',
                decoration: InputDecoration(labelText: 'Preço (opcional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  if (v.isEmpty) {
                    setState(() => price = null);
                  } else {
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    setState(() => price = parsed);
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                decoration: InputDecoration(labelText: 'Categoria'),
                items: categorias.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        categoriaIcone(cat),
                        SizedBox(width: 8),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => categoriaSelecionada = v);
                },
                selectedItemBuilder: (BuildContext context) {
                  return categorias.map<Widget>((String cat) {
                    return Row(
                      children: [
                        categoriaIcone(cat),
                        SizedBox(width: 8),
                        Text(cat),
                      ],
                    );
                  }).toList();
                },
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
