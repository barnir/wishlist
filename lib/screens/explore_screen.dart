import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _termoPesquisa = '';
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
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
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final profiles = snapshot.data!.docs
                        .where((doc) => (doc['displayName'] as String)
                            .toLowerCase()
                            .contains(_termoPesquisa.toLowerCase()) && (!(doc['private'] ?? false)))
                        .toList();

                    return Column(
                      children: profiles.map((profile) => ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(profile['displayName'] ?? 'Sem nome'),
                            onTap: () {
                              // Navega para página de perfil do utilizador
                              Navigator.pushNamed(context, '/profileView', arguments: profile.id);
                            },
                          )).toList(),
                    );
                  },
                ),
                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('wishlists').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final wishlists = snapshot.data!.docs
                        .where((doc) => (doc['name'] as String)
                            .toLowerCase()
                            .contains(_termoPesquisa.toLowerCase()) && (!(doc['isPrivate'] ?? false)))
                        .toList();

                    return Column(
                      children: wishlists.map((wishlist) => ListTile(
                            leading: const Icon(Icons.list_alt),
                            title: Text(wishlist['name'] ?? 'Sem nome'),
                            subtitle: Text('Proprietário: ${wishlist['ownerName'] ?? 'Desconhecido'}'),
                            onTap: () {
                              Navigator.pushNamed(context, '/wishlist_details', arguments: wishlist.id);
                            },
                          )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
