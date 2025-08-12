import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isPrivate = false;
  File? _imageFile;

  bool _isLoading = false;
  

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.uid;
    final userData = await _userService.getUserProfile(userId);
    if (userData.exists) {
      setState(() {
        _nameController.text = userData.get('displayName') ?? '';
        _isPrivate = userData.get('isPrivate') ?? false;
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    await _authService.updateProfilePicture(_imageFile!);
    await _loadProfileData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.uid;
    await _authService.currentUser?.updateDisplayName(_nameController.text.trim());
    await _userService.updateUserProfile(userId, {'displayName': _nameController.text.trim()});
    setState(() => _isEditingName = false);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySetting(bool isPrivate) async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.uid;
    await _userService.updateUserProfile(userId, {'isPrivate': isPrivate});
    setState(() => _isPrivate = isPrivate);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Utilizador não encontrado.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : user.photoURL != null
                                  ? CachedNetworkImageProvider(user.photoURL!)
                                  : null,
                          child: _imageFile == null && user.photoURL == null
                              ? const Icon(Icons.add_a_photo, size: 50)
                              : null,
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
                                Text(user.displayName ?? 'Sem nome', style: const TextStyle(fontSize: 20)),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => setState(() => _isEditingName = true),
                                ),
                              ],
                            ),
                      const SizedBox(height: 8),
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
                      ElevatedButton(
                        onPressed: _signOut,
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
