import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wish_item.dart';

class AddItemScreen extends StatefulWidget {
  final WishItem? item;   // Null para novo, preenchido para edição
  final dynamic itemKey;  // A chave da box para editar

  AddItemScreen({this.item, this.itemKey});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Estado das variáveis que controlam o formulário
  late String title;
  late String link;
  late String description;
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

  @override
  void initState() {
    super.initState();

    // Se estiver editando, inicializa os campos com os valores do item passado, senão com valores padrão
    title = widget.item?.title ?? '';
    link = widget.item?.link ?? '';
    description = widget.item?.description ?? '';
    categoriaSelecionada = widget.item?.category ?? categorias[0];
  }

  void saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    final box = Hive.box<WishItem>('wishlist');

    if (widget.item != null && widget.itemKey != null) {
      // Atualiza item existente
      await box.put(widget.itemKey, WishItem(
        title: title,
        link: link.isNotEmpty ? link : null,
        description: description,
        category: categoriaSelecionada,
      ));
    } else {
      // Novo item
      await box.add(WishItem(
        title: title,
        link: link.isNotEmpty ? link : null,
        description: description,
        category: categoriaSelecionada,
      ));
    }
    Navigator.pop(context);
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
          child: Column(
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
                    if (v != null) {
                      setState(() {
                        categoriaSelecionada = v;
                      });
                    }
                  },
                  // Este builder define como o item selecionado aparece no campo após escolha
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
