import 'package:flutter/material.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/haptic_service.dart';

class EditProfileBottomSheet extends StatefulWidget {
  final String initialName;
  final String initialBio;
  final Function(String name, String bio) onSave;

  const EditProfileBottomSheet({
    super.key,
    required this.initialName,
    required this.initialBio,
    required this.onSave,
  });

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();

  static Future<void> show(
    BuildContext context, {
    required String initialName,
    required String initialBio,
    required Function(String name, String bio) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(
        initialName: initialName,
        initialBio: initialBio,
        onSave: onSave,
      ),
    );
  }
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nameCannotBeEmpty),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await widget.onSave(_nameController.text.trim(), _bioController.text.trim());
      HapticService.success();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.editProfile,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.bio,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info_outline),
                hintText: l10n.tellAboutYou,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class PrivacySettingsBottomSheet extends StatefulWidget {
  final bool initialIsPrivate;
  final Function(bool isPrivate) onSave;

  const PrivacySettingsBottomSheet({
    super.key,
    required this.initialIsPrivate,
    required this.onSave,
  });

  @override
  State<PrivacySettingsBottomSheet> createState() => _PrivacySettingsBottomSheetState();

  static Future<void> show(
    BuildContext context, {
    required bool initialIsPrivate,
    required Function(bool isPrivate) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacySettingsBottomSheet(
        initialIsPrivate: initialIsPrivate,
        onSave: onSave,
      ),
    );
  }
}

class _PrivacySettingsBottomSheetState extends State<PrivacySettingsBottomSheet> {
  late bool _isPrivate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.initialIsPrivate;
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    
    try {
      await widget.onSave(_isPrivate);
      HapticService.success();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.privacySettings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(l10n.privateProfile),
              subtitle: Text(
                _isPrivate 
                    ? l10n.privateProfileDesc
                    : l10n.publicProfileDesc,
              ),
              value: _isPrivate,
              onChanged: (value) {
                HapticService.lightImpact();
                setState(() => _isPrivate = value);
              },
              secondary: Icon(
                _isPrivate ? Icons.lock : Icons.public,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}