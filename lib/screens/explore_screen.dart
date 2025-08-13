import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

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
            child: ListView( // Changed to ListView to contain multiple sections
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Perfis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getPublicUsers(searchTerm: _termoPesquisa),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhum perfil encontrado.'));
                    }

                    final profiles = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true, // Important for nested ListViews
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
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
                      },
                    );
                  },
                ),
                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getPublicWishlists(searchTerm: _termoPesquisa),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhuma wishlist encontrada.'));
                    }

                    final wishlists = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true, // Important for nested ListViews
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                      itemCount: wishlists.length,
                      itemBuilder: (context, index) {
                        final wishlist = wishlists[index];
                        final data = wishlist.data() as Map<String, dynamic>;
                        final name = data['name'] as String? ?? 'Sem nome';
                        final ownerName = data['ownerName'] as String? ?? 'Desconhecido';
                        final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    imageBuilder: (context, imageProvider) => CircleAvatar(
                                      backgroundImage: imageProvider,
                                      radius: 50,
                                    ),
                                    placeholder: (context, url) => CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      child: const CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      child: const Icon(Icons.card_giftcard),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    child: const Icon(Icons.card_giftcard),
                                  ),
                          ),
                          title: Text(name),
                          subtitle: Text('Proprietário: $ownerName'),
                          onTap: () {
                            Navigator.pushNamed(context, '/wishlist_details', arguments: wishlist.id);
                          },
                        );
                      },
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
