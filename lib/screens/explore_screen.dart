import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/firestore_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _firestoreService = FirestoreService();
  String _termoPesquisa = '';

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
                  stream: _firestoreService.getPublicUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final profiles = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final displayName = data['displayName'] as String? ?? '';
                      final isPrivate = data['isPrivate'] as bool? ?? false;
                      return displayName.toLowerCase().contains(_termoPesquisa.toLowerCase()) && !isPrivate;
                    }).toList();

                    return Column(
                      children: profiles.map((profile) {
                        final data = profile.data() as Map<String, dynamic>;
                        final displayName = data['displayName'] as String? ?? 'Sem nome';
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(displayName),
                          onTap: () {
                            // Navega para página de perfil do utilizador
                            // Navigator.pushNamed(context, '/profileView', arguments: profile.id);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getPublicWishlists(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final wishlists = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] as String? ?? '';
                      final isPrivate = data['private'] as bool? ?? false;
                      return name.toLowerCase().contains(_termoPesquisa.toLowerCase()) && !isPrivate;
                    }).toList();

                    return Column(
                      children: wishlists.map((wishlist) {
                        final data = wishlist.data() as Map<String, dynamic>;
                        final name = data['name'] as String? ?? 'Sem nome';
                        final ownerName = data['ownerName'] as String? ?? 'Desconhecido';
                        return ListTile(
                          leading: const Icon(Icons.list_alt),
                          title: Text(name),
                          subtitle: Text('Proprietário: $ownerName'),
                          onTap: () {
                            Navigator.pushNamed(context, '/wishlist_details', arguments: wishlist.id);
                          },
                        );
                      }).toList(),
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