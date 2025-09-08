import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

/// Micro-interaction animation widget for enhanced visual feedback
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onTap;
  
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.onTap,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        child: widget.child,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

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
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              l10n.wishlists,
              wishlistsCount.toString(),
              Icons.list_alt_outlined,
            ),
          ),
          _buildDivider(context),
          Expanded(
            child: _buildStatItem(
              context,
              l10n.items,
              itemsCount.toString(),
              Icons.inventory_2_outlined,
            ),
          ),
          _buildDivider(context),
          Expanded(
            child: _buildStatItem(
              context,
              l10n.favorites,
              favoritesCount.toString(),
              Icons.favorite_outline,
            ),
          ),
          _buildDivider(context),
          Expanded(
            child: _buildStatItem(
              context,
              l10n.shared,
              sharedCount.toString(),
              Icons.share_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return PulseAnimation(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone primeiro, pequeno e discreto
          Icon(
            icon,
            size: 22.0,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8.0),
          // Número grande e prominente
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              fontSize: 36.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4.0),
          // Label pequeno em baixo
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 1.0,
      height: 40.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
    final theme = Theme.of(context);
    return Card(
      elevation: 3, // Reduced elevation following Material 3 guidelines
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Simplified gradient for better contrast and modern look
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Enhanced Avatar - more compact
              PulseAnimation(
                onTap: onImageTap,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15), // Reduced shadow intensity
                        blurRadius: 6, // Slightly reduced
                        offset: const Offset(0, 2), // Less dramatic
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipOval(
                        child: AnimatedProfileImage(
                          key: ValueKey('profile_image_${profileImageUrl ?? 'no_image'}'),
                          profileImageUrl: profileImageUrl,
                          isUploading: isUploading,
                          onImageTap: onImageTap,
                          size: 65, // 70 - border width
                          showBadge: false,
                        ),
                      ),
                      // Enhanced camera badge - smaller
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary, // Use theme color instead of hardcoded white
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12), // Softer shadow
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Enhanced Profile info - more compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22, // Slightly larger for better hierarchy
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary, // Use theme color
                        letterSpacing: 0.3, // Reduced for better readability
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Enhanced privacy indicator - smaller
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2), // Use theme-based transparency
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrivate ? Icons.lock_outline : Icons.public_outlined,
                            size: 14, // Increased from 12 for better visibility
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPrivate
                                ? (AppLocalizations.of(context)?.privateLabel ?? 'Privada')
                                : (AppLocalizations.of(context)?.publicLabel ?? 'Pública'),
                            style: TextStyle(
                              fontSize: 12, // Increased from 11 for better readability
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio.isNotEmpty ? bio : (AppLocalizations.of(context)?.addBio ?? 'Adicionar biografia...'),
                      style: TextStyle(
                        fontSize: 14, // Increased from 13 for better readability
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9), // Use theme color
                        fontStyle: bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                        height: 1.4, // Better line height for readability
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Enhanced edit button - more compact
                    PulseAnimation(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onEditProfile,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.editProfile,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onPrimary, // Use theme color
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Improved touch target
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Consistent with card radius
                            ),
                            elevation: 1, // Reduced elevation
                            shadowColor: Colors.black.withValues(alpha: 0.1), // Softer shadow
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
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
    final theme = Theme.of(context);
    return PulseAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle != null 
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ) 
              : null,
          trailing: trailing ?? (onTap != null 
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ) 
              : null),
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
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