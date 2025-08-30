import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wishlist_app/services/auth_service.dart';

/// Widget wrapper que protege telas autenticadas de navegação incorreta
/// Garante que usuários logados nunca voltem para telas de login/registo
/// através do gesto back - em vez disso, saem da aplicação
class SafeNavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool isMainScreen;
  final VoidCallback? onBackPressed;

  const SafeNavigationWrapper({
    super.key,
    required this.child,
    this.isMainScreen = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    // Se não há usuário logado, não aplicar proteção
    if (user == null) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (onBackPressed != null) {
            // Se há callback personalizado, usar ele
            onBackPressed!();
          } else if (isMainScreen) {
            // Se é tela principal (wishlists), sair da app
            SystemNavigator.pop();
          } else {
            // Se é tela secundária, voltar para wishlists
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/wishlists', 
              (route) => false,
            );
          }
        }
      },
      child: child,
    );
  }
}
