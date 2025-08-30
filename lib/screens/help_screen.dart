import 'package:flutter/material.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.waving_hand,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bem-vindo ao Wishlist App!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie e partilhe as suas listas de desejos de forma simples e organizada.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // How to use section
            Text(
              'Como Usar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildHelpItem(
              context,
              icon: Icons.add_circle_outline,
              title: 'Criar Wishlists',
              description: 'Toque no botão + para criar uma nova lista de desejos. Pode torná-la pública ou privada.',
            ),
            
            _buildHelpItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'Adicionar Items',
              description: 'Dentro de uma wishlist, toque no + para adicionar items. Pode adicionar fotos, preços e links.',
            ),
            
            _buildHelpItem(
              context,
              icon: Icons.link,
              title: 'Web Scraping',
              description: 'Cole um link de produto e a app tentará extrair automaticamente título, preço e imagem.',
            ),
            
            _buildHelpItem(
              context,
              icon: Icons.people_outline,
              title: 'Partilhar',
              description: 'Partilhe as suas wishlists públicas com amigos através do botão de partilha.',
            ),
            
            _buildHelpItem(
              context,
              icon: Icons.favorite_outline,
              title: AppLocalizations.of(context)?.favoritesTitle ?? 'Favoritos',
              description: 'Marque wishlists de outros utilizadores como favoritas para acesso rápido.',
            ),
            
            const SizedBox(height: 24),
            
            // Contact section
            Text(
              'Contacto e Suporte',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email de Suporte'),
                    subtitle: const Text('barnirapps@gmail.com'),
                    onTap: () => _launchEmail('barnirapps@gmail.com'),
                    trailing: const Icon(Icons.launch),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Reportar Bug'),
                    subtitle: const Text('Encontrou um problema? Conte-nos!'),
                    onTap: () => _launchEmail(
                      'barnirapps@gmail.com',
                      subject: 'Bug Report - Wishlist App',
                    ),
                    trailing: const Icon(Icons.launch),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outlined),
                    title: const Text('Sugestões'),
                    subtitle: const Text('Tem uma ideia? Partilhe connosco!'),
                    onTap: () => _launchEmail(
                      'barnirapps@gmail.com',
                      subject: 'Feature Request - Wishlist App',
                    ),
                    trailing: const Icon(Icons.launch),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQ section
            Text(
              'Perguntas Frequentes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFAQItem(
              context,
              question: 'Como torno uma wishlist privada?',
              answer: 'Nas definições da wishlist, pode alternar entre pública e privada. Wishlists privadas só são visíveis para si.',
            ),
            
            _buildFAQItem(
              context,
              question: 'Posso adicionar items sem link?',
              answer: 'Sim! Pode adicionar items manualmente preenchendo o nome, preço e outros detalhes.',
            ),
            
            _buildFAQItem(
              context,
              question: 'Como funciona o web scraping?',
              answer: 'Cole um link de uma loja online suportada e a app extrai automaticamente informações do produto.',
            ),
            
            _buildFAQItem(
              context,
              question: 'Os meus dados estão seguros?',
              answer: 'Sim! Usamos Firebase com regras de segurança rigorosas. Os seus dados privados são apenas seus.',
            ),
            
            const SizedBox(height: 32),
            
            // Version info
            Center(
              child: Text(
                'Wishlist App v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchEmail(String email, {String? subject}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }
}