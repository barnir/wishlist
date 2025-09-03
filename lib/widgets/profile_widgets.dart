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
    // Use a Stack so the avatar can visually float above the card and its gradient
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
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
            // Add left padding to leave room for the overlapping avatar
            child: Padding(
              padding: const EdgeInsets.fromLTRB(132.0, 20.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 8),
                  Text(
                    bio.isNotEmpty ? bio : (AppLocalizations.of(context)?.addBio ?? 'Adicionar biografia...'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
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
        ),
        // Positioned avatar that floats above the card
        Positioned(
          left: 20,
          top: -28,
          child: Material(
            color: Colors.transparent,
            elevation: 6,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 100,
              height: 100,
              // Use a Stack so we can place a circular mask behind the avatar and an overlay badge
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Circular mask same size as avatar to tightly hug the image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Actual avatar container with border and padding
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    child: AnimatedProfileImage(
                      key: ValueKey('profile_image_${profileImageUrl ?? 'no_image'}'),
                      profileImageUrl: profileImageUrl,
                      isUploading: isUploading,
                      onImageTap: onImageTap,
                      size: 92,
                      showBadge: false, // hide internal badge; we'll render badge above everything here
                    ),
                  ),
                  // Overlay badge positioned to be above all other children
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
  final double size;
  final bool showBadge;

  const AnimatedProfileImage({
    super.key,
    this.profileImageUrl,
    required this.isUploading,
    required this.onImageTap,
    this.localPreviewPath,
  this.size = 80,
  this.showBadge = true,
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
                          width: widget.size,
                          height: widget.size,
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
                              ? Container(
                                  width: widget.size,
                                  height: widget.size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: effectiveProvider!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: widget.size,
                                  height: widget.size,
                                  child: Icon(
                                    Icons.person,
                                    size: (widget.size * 0.5).clamp(24.0, 64.0),
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                        );
                      }),
                    ),
                    if (widget.isUploading)
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: (widget.size * 0.33).clamp(18.0, 40.0),
                            height: (widget.size * 0.33).clamp(18.0, 40.0),
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
          if (widget.showBadge)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.all((widget.size * 0.045).clamp(3.0, 6.0)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: (widget.size * 0.18).clamp(12.0, 20.0),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}