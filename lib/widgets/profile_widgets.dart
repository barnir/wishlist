import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

class ProfileStatsCard extends StatelessWidget {
  final int wishlistsCount;
  final int itemsCount;
  final int favoritesCount;
  final int sharedCount;

  const ProfileStatsCard({
    super.key,
    required this.wishlistsCount,
    required this.itemsCount,
    required this.favoritesCount,
    required this.sharedCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              l10n.wishlists,
              wishlistsCount.toString(),
              Icons.list_alt,
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              l10n.items,
              itemsCount.toString(),
              Icons.inventory_2,
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              l10n.favorites,
              favoritesCount.toString(),
              Icons.favorite,
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              l10n.shared,
              sharedCount.toString(),
              Icons.share,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  final String? profileImageUrl;
  final String name;
  final String bio;
  final bool isPrivate;
  final bool isUploading;
  final VoidCallback onImageTap;
  final VoidCallback onEditProfile;

  const ProfileHeaderCard({
    super.key,
    this.profileImageUrl,
    required this.name,
    required this.bio,
    required this.isPrivate,
    required this.isUploading,
    required this.onImageTap,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Use the new AnimatedProfileImage widget with stable key
                  // Wrap with a subtle white backing and elevation so the avatar isn't visually washed by the card gradient
                  Material(
                    color: Colors.transparent,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedProfileImage(
                        key: ValueKey('profile_image_${profileImageUrl ?? 'no_image'}'),
                        profileImageUrl: profileImageUrl,
                        isUploading: isUploading,
                        onImageTap: onImageTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPrivate ? Icons.lock : Icons.public,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                  isPrivate
                    ? (AppLocalizations.of(context)?.privateLabel ?? 'Privada')
                    : (AppLocalizations.of(context)?.publicLabel ?? 'Pública'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
              bio.isNotEmpty
                ? bio
                : (AppLocalizations.of(context)?.addBio ?? 'Adicionar biografia...'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontStyle: bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(context)!.editProfile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const ProfileListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Animated profile image widget that updates smoothly without page refresh
class AnimatedProfileImage extends StatefulWidget {
  final String? profileImageUrl;
  final bool isUploading;
  final VoidCallback onImageTap;
  final String? localPreviewPath; // path do ficheiro local para preview imediato

  const AnimatedProfileImage({
    super.key,
    this.profileImageUrl,
    required this.isUploading,
    required this.onImageTap,
    this.localPreviewPath,
  });

  @override
  State<AnimatedProfileImage> createState() => _AnimatedProfileImageState();
}

class _AnimatedProfileImageState extends State<AnimatedProfileImage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _currentImageUrl;
  String? _cachedImageUrlWithTimestamp;
  String? _newImageUrl;
  ImageProvider? _preloadedNext;
  ImageProvider? _localPreviewProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // mais rápido
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _currentImageUrl = widget.profileImageUrl;
    _updateCachedUrl();
    _animationController.value = 1.0;
    _initLocalPreview();
  }

  void _initLocalPreview() {
    if (widget.localPreviewPath != null) {
      try {
        _localPreviewProvider = FileImage(File(widget.localPreviewPath!));
      } catch (_) {}
    }
  }

  void _updateCachedUrl() {
    if (_currentImageUrl != null) {
      // Only add timestamp if URL doesn't already have one
      if (!_currentImageUrl!.contains('_t=')) {
        _cachedImageUrlWithTimestamp = _currentImageUrl!.contains('?') 
          ? '${_currentImageUrl!}&_t=${DateTime.now().millisecondsSinceEpoch}'
          : '${_currentImageUrl!}?_t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _cachedImageUrlWithTimestamp = _currentImageUrl;
      }
    } else {
      _cachedImageUrlWithTimestamp = null;
    }
  }

  @override
  void didUpdateWidget(AnimatedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only trigger transition if URL actually changed and is different
    if (oldWidget.profileImageUrl != widget.profileImageUrl && 
        widget.profileImageUrl != null &&
        _currentImageUrl != widget.profileImageUrl) {
      _transitionToNewImage(widget.profileImageUrl!);
    }
  }

  void _transitionToNewImage(String newUrl) {
    setState(() {
      _newImageUrl = newUrl;
    });
    _preloadedNext = CachedNetworkImageProvider(newUrl);
    final stream = _preloadedNext!.resolve(const ImageConfiguration());
    late ImageStreamListener l;
  l = ImageStreamListener((_, imageChunk) {
      stream.removeListener(l);
      if (!mounted) return;
      _animationController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentImageUrl = _newImageUrl;
          _updateCachedUrl();
          _preloadedNext = null;
        });
        _animationController.forward();
      });
  }, onError: (_, error) {
      stream.removeListener(l);
      if (!mounted) return;
      _animationController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentImageUrl = _newImageUrl;
          _updateCachedUrl();
          _preloadedNext = null;
        });
        _animationController.forward();
      });
    });
    stream.addListener(l);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return GestureDetector(
      onTap: widget.isUploading ? null : widget.onImageTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              final effectiveProvider = _localPreviewProvider ?? (_cachedImageUrlWithTimestamp != null
                  ? CachedNetworkImageProvider(_cachedImageUrlWithTimestamp!)
                  : null);
              return ClipOval(
                child: Stack(
                  children: [
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Builder(builder: (context) {
                        final hasImage = _localPreviewProvider != null || _cachedImageUrlWithTimestamp != null;
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Only show subtle background when there's no image to avoid washing out photos
                            color: hasImage ? Colors.transparent : Colors.white.withValues(alpha: 0.06),
                          ),
                          foregroundDecoration: widget.isUploading
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  // Reduce upload overlay opacity so the image remains visible
                                  color: Colors.black.withValues(alpha: 0.12),
                                )
                              : null,
                          child: hasImage
                              ? Ink.image(image: effectiveProvider!, fit: BoxFit.cover)
                              : Icon(Icons.person, size: 40, color: Colors.white.withValues(alpha: 0.9)),
                        );
                      }),
                    ),
                    if (widget.isUploading)
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}