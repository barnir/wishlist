import 'package:flutter/material.dart';

// Exemplo de dados simulados para perfis públicos e wishlists
final List<Map<String, String>> perfisPublicos = [
  {'id': 'user1', 'nome': 'João Silva'},
  {'id': 'user2', 'nome': 'Maria Santos'},
  {'id': 'user3', 'nome': 'Carlos Pereira'},
];

final List<Map<String, String>> wishlistsPublicas = [
  {'id': 'wl1', 'nome': 'Presentes de Natal', 'proprietario': 'João Silva', 'idProprietario': 'user1'},
  {'id': 'wl2', 'nome': 'Viagem dos Sonhos', 'proprietario': 'Maria Santos', 'idProprietario': 'user2'},
  {'id': 'wl3', 'nome': 'Casa Nova', 'proprietario': 'Carlos Pereira', 'idProprietario': 'user3'},
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _termoPesquisa = '';

  @override
  Widget build(BuildContext context) {
    // Filtra perfis e wishlists pela pesquisa
    final perfisFiltrados = perfisPublicos
        .where((p) => p['nome']!.toLowerCase().contains(_termoPesquisa.toLowerCase()))
        .toList();

    final wishlistsFiltradas = wishlistsPublicas
        .where((w) => w['nome']!.toLowerCase().contains(_termoPesquisa.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar perfis ou wishlists...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _termoPesquisa = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Perfis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...perfisFiltrados.map((perfil) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(perfil['nome']!),
                      onTap: () {
                        // Navega para página de perfil do utilizador
                        Navigator.pushNamed(context, '/profileView', arguments: perfil['id']);
                      },
                    )),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...wishlistsFiltradas.map((wl) => ListTile(
                      leading: const Icon(Icons.list_alt),
                      title: Text(wl['nome']!),
                      subtitle: Text('Proprietário: ${wl['proprietario']}'),
                      onTap: () {
                        Navigator.pushNamed(context, '/wishlist_details', arguments: wl['id']);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
