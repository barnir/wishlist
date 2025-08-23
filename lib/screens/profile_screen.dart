import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wishlist_app/screens/link_email_screen.dart';
import 'package:wishlist_app/screens/link_phone_screen.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _cloudinaryService = CloudinaryService();

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
    final userId = _authService.currentUser!.uid;
    final userData = await _userService.getUserProfile(userId);
    if (userData != null) {
      _nameController.text = userData['display_name'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _isPrivate = userData['is_private'] ?? false;
      _phoneNumber = userData['phone_number'];
    }
    
    // Debug: Check user metadata
    final userMetadata = _authService.currentUser?.userMetadata;
    debugPrint('=== Profile Debug Information ===');
    debugPrint('Current user ID: $userId');
    debugPrint('UserMetadata: $userMetadata');
    debugPrint('Raw metadata keys: ${userMetadata?.keys.toList()}');
    
    // Load profile image from Firebase user or database
    _profileImageUrl = _authService.currentUser?.photoURL ?? userData?['photo_url'];
    debugPrint('Profile image URL found: $_profileImageUrl');

    // If no name in database, try to get from Google metadata
    debugPrint('Current display name from DB: "${_nameController.text}"');
    if (_nameController.text.isEmpty) {
      final googleName = userMetadata?['full_name'] ?? 
                        userMetadata?['name'] ?? 
                        userMetadata?['display_name'];
      debugPrint('Google name found: "$googleName"');
      if (googleName != null) {
        _nameController.text = googleName;
        debugPrint('Setting name to: "$googleName"');
        // Save to database for future use
        await _userService.updateUserProfile(userId, {
          'display_name': googleName,
        });
      }
    }

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
        // Reload user data to get updated photo URL
        await _loadProfileData();
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar imagem: \${e.toString()}'),
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
    final userId = _authService.currentUser!.uid;
    await _authService.updateUser(
      displayName: _nameController.text.trim(),
    ); // Update user metadata
    await _userService.updateUserProfile(userId, {
      'display_name': _nameController.text.trim(),
    });
    setState(() => _isEditingName = false);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBio() async {
    if (_bioController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser!.uid;
      await _userService.updateUserProfile(userId, {
        'bio': _bioController.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditingBio = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao guardar biografia: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrivacySetting(bool isPrivate) async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.uid;
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

  Future<void> _confirmDeleteAccount() async {
    final confirmationController = TextEditingController();
    bool isDeleting = false; // To manage loading state within the dialog

    // Unfocus any active text fields before showing the dialog
    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Apagar Conta'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Text(
                    'Esta ação é irreversível. Todos os seus dados serão perdidos. Para confirmar, escreva "APAGAR" na caixa abaixo.',
                  ),
                  const SizedBox(height: 16),
                  if (isDeleting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    TextField(
                      controller: confirmationController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(
                        () {},
                      ), // Rebuild to check button state
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed:
                    (confirmationController.text == 'APAGAR' && !isDeleting)
                    ? () async {
                        setDialogState(() => isDeleting = true);
                        await _deleteAccount();
                        // The dialog will be closed by navigation changes in _deleteAccount if successful,
                        // or manually on error.
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      // ignore: deprecated_member_use
                      return Colors.red.withOpacity(0.5);
                    }
                    return Colors.red;
                  }),
                ),
                child: const Text('Apagar Permanentemente'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;

    try {
      debugPrint('=== Deleting Firebase User Account ===');
      
      await _authService.deleteAccount();

      if (!mounted) return;

      // Close the dialog first before showing success message and navigating
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta apagada com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (!mounted) return;
      // Close the dialog if it's still open on error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao apagar conta: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
                          backgroundImage: _profileImageUrl != null
                              ? CachedNetworkImageProvider(
                                  _cloudinaryService.optimizeExistingUrl(
                                    _profileImageUrl!, 
                                    ImageType.profileLarge
                                  )
                                )
                              : null,
                          child: _profileImageUrl == null && !_isUploading
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: _saveName,
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: () =>
                                  setState(() => _isEditingName = false),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : user.displayName ??
                                      user.email ??
                                      'Sem nome',
                              style: const TextStyle(fontSize: 20),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  setState(() => _isEditingName = true),
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
                              onPressed: () =>
                                  setState(() => _isEditingBio = false),
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
                                onPressed: () =>
                                    setState(() => _isEditingBio = true),
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
                      Switch(value: _isPrivate, onChanged: _savePrivacySetting),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_phoneNumber == null ||
                      _phoneNumber!.isEmpty) // Check if phone number is linked
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LinkPhoneScreen(),
                          ),
                        );
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LinkPhoneScreen(),
                              ),
                            );
                          },
                          child: const Text('Alterar Telemóvel'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Email section - show similar to phone when user has email
                  if (user.email == null || user.email!.isEmpty)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // This method is still unimplemented in AuthService
                              // await _authService.linkGoogle();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Not implemented"),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                );
                              }
                              setState(() {}); // Rebuild to update the UI
                            } on Exception catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Adicionar Google'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LinkEmailScreen(),
                              ),
                            );
                          },
                          child: const Text('Adicionar Email'),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user.email}'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LinkEmailScreen(),
                              ),
                            );
                          },
                          child: const Text('Alterar Email'),
                        ),
                      ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Apagar Conta',
                      style: TextStyle(color: Colors.white),
                    ),
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
