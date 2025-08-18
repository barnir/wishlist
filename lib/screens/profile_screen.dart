import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wishlist_app/screens/link_email_screen.dart';
import 'package:wishlist_app/screens/link_phone_screen.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  final _nameController = TextEditingController();
  final _bioController = TextEditingController(); // New
  bool _isEditingName = false;
  bool _isEditingBio = false; // New
  bool _isPrivate = false;
  bool _isUploading = false;
  String? _profileImageUrl; // Use String for URL
  String? _phoneNumber; // To store phone number from user profile

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.id;
    final userData = await _userService.getUserProfile(userId);
    if (userData != null) {
      _nameController.text = userData['display_name'] ?? '';
      _bioController.text = userData['bio'] ?? ''; // New: Load biography
      _isPrivate = userData['is_private'] ?? false;
      _phoneNumber = userData['phone_number']; // Get phone number from user profile
    }
    _profileImageUrl = _authService.currentUser?.userMetadata?['photoURL']; // Access from user_metadata

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile != null) {
      final tempFile = File(pickedFile.path);
      setState(() {
        _isUploading = true;
      });

      try {
        await _authService.updateProfilePicture(tempFile);
        final newUrl = _authService.currentUser?.userMetadata?['photoURL'];
        if (newUrl != null) {
          setState(() {
            _profileImageUrl = newUrl;
          });
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar imagem: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.id;
    await _authService.updateUser(displayName: _nameController.text.trim()); // Update user metadata
    await _userService.updateUserProfile(userId, {'display_name': _nameController.text.trim()});
    setState(() => _isEditingName = false);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBio() async {
    if (_bioController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.id;
    await _userService.updateUserProfile(userId, {'bio': _bioController.text.trim()});
    setState(() => _isEditingBio = false);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySetting(bool isPrivate) async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.id;
    await _userService.updateUserProfile(userId, {'is_private': isPrivate});
    setState(() => _isPrivate = isPrivate);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : user == null
              ? const Center(child: Text('Utilizador não encontrado.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                              backgroundImage: _profileImageUrl != null
                                  ? CachedNetworkImageProvider(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null && !_isUploading
                                  ? const Icon(Icons.add_a_photo, size: 50)
                                  : null,
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isEditingName
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(labelText: 'Nome'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save),
                                  onPressed: _saveName,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () => setState(() => _isEditingName = false),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(user.userMetadata?['display_name'] ?? user.email ?? 'Sem nome', style: const TextStyle(fontSize: 20)),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => setState(() => _isEditingName = true),
                                ),
                              ],
                            ),
                      const SizedBox(height: 8),
                      _isEditingBio
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _bioController,
                                    decoration: const InputDecoration(
                                      labelText: 'Biografia',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save),
                                  onPressed: _saveBio,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () => setState(() => _isEditingBio = false),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bioController.text.isNotEmpty
                                      ? _bioController.text
                                      : 'Adicionar biografia',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => setState(() => _isEditingBio = true),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16), // Add spacing after bio
                      Text(user.email ?? 'Sem email'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Privado'),
                          Switch(
                            value: _isPrivate,
                            onChanged: _savePrivacySetting,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_phoneNumber == null || _phoneNumber!.isEmpty) // Check if phone number is linked
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const LinkPhoneScreen(),
                            ));
                          },
                          child: const Text('Adicionar Telemóvel'),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Telemóvel: $_phoneNumber'),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const LinkPhoneScreen(),
                                ));
                              },
                              child: const Text('Alterar Telemóvel'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // Email linking (unimplemented for Supabase)
                      Text(user.email ?? 'Sem email'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const LinkEmailScreen(),
                          ));
                        },
                        child: const Text('Alterar Email'),
                      ),
                      // Google linking (unimplemented for Supabase)
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // This method is still unimplemented in AuthService
                            // await _authService.linkGoogle();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                            setState(() {}); // Rebuild to update the UI
                          } on Exception catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Adicionar Google'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _signOut,
                        child: const Text('Sair'),
                      ),
                      // Delete Account Button
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _confirmDeleteAccount,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Apagar Conta', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose(); // Dispose bio controller
    super.dispose();
  }
                      // Delete Account Button
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _confirmDeleteAccount,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Apagar Conta', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose(); // Dispose bio controller
    super.dispose();
  }
}