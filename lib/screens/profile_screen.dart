import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: user == null
          ? Center(child: Text('Sem sessão iniciada'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Icon(Icons.person, size: 48)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'Nome não definido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    user.email ?? 'Email não disponível',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 18),
                  ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Editar Perfil'),
                    onPressed: () {
                      // Navega para página de edição do perfil
                    },
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.logout),
                    label: Text('Terminar Sessão'),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                  Divider(height: 36),
                  // Aqui podes listar as wishlists, seguidores ou outras infos sociais
                  /*
                  Expanded(child: ListaDeWishlistsDoUtilizador()),
                  */
                ],
              ),
            ),
    );
  }
}
