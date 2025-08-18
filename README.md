# Wishlist App

Aplicação de lista de desejos construída com Flutter. Permite aos utilizadores criar, gerir e partilhar as suas listas de desejos de forma fácil e intuitiva.

## ✨ Funcionalidades Principais

- **Autenticação de Utilizadores**: Registo e login seguros utilizando e-mail/palavra-passe, número de telemóvel e Google Sign-In, com o poder do Supabase.
- **Gestão de Wishlists**: Crie, edite e elimine múltiplas listas de desejos.
- **Adição de Itens Inteligente**: Adicione itens à sua wishlist partilhando um link de uma loja online. A aplicação extrai automaticamente o título, preço e imagem do produto.
- **Cache de Dados e Imagens**: Para uma experiência de utilizador mais rápida e fluida, a aplicação utiliza cache para imagens e dados, sincronizando em segundo plano.
- **Multi-plataforma**: Como uma aplicação Flutter, tem como alvo Android, iOS e Web a partir de uma única base de código.

## 🚀 Começar

Siga estas instruções para ter o projeto a correr na sua máquina local para desenvolvimento e testes.

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.8.1 ou superior)
- Um editor de código como [VS Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio)
- Uma conta [Supabase](https://supabase.com) para o backend.

### Instalação

1.  **Clone o repositório:**
    ```sh
    git clone <URL_DO_SEU_REPOSITÓRIO>
    cd wishlist_app
    ```

2.  **Crie o ficheiro de configuração de ambiente:**
    Copie o ficheiro `.env.example` para um novo ficheiro chamado `.env` e adicione as suas credenciais do Supabase.
    ```sh
    cp .env.example .env
    ```
    O seu ficheiro `.env` deverá ter o seguinte aspeto:
    ```
    SUPABASE_URL=https://<ID_DO_PROJETO>.supabase.co
    SUPABASE_ANON_KEY=<SUA_CHAVE_ANON>
    ```

3.  **Instale as dependências:**
    Execute o seguinte comando para obter todas as dependências do projeto:
    ```sh
    flutter pub get
    ```

### Executar a Aplicação

Para iniciar a aplicação, execute:
```sh
flutter run
```

## 🏗️ Estrutura do Projeto

O código fonte da aplicação está localizado no diretório `lib/` e segue uma arquitetura simples e organizada:

```
lib/
├── models/         # Contém as classes de modelo de dados (Wishlist, WishItem, etc.).
├── screens/        # Contém os widgets de ecrã (UI para cada página da app).
├── services/       # Lógica de negócio, como autenticação, base de dados e serviços web.
├── widgets/        # Widgets reutilizáveis usados em vários ecrãs.
├── config.dart     # Configurações gerais da aplicação.
└── main.dart       # O ponto de entrada da aplicação.
```

## 📦 Dependências Principais

- **[supabase_flutter](https://pub.dev/packages/supabase_flutter)**: Integração com o Supabase para autenticação e base de dados.
- **[google_sign_in](https://pub.dev/packages/google_sign_in)**: Para autenticação com contas Google.
- **[http](https://pub.dev/packages/http)** & **[html](https://pub.dev/packages/html)**: Para fazer scraping de dados de websites.
- **[cached_network_image](https://pub.dev/packages/cached_network_image)**: Para carregar e guardar imagens da web em cache.
- **[flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager)**: Gestão de cache genérica.
- **[share_plus](https://pub.dev/packages/share_plus)**: Para funcionalidades de partilha.
- **[flutter_sharing_intent](https://pub.dev/packages/flutter_sharing_intent)**: Para receber intents de partilha de outras apps.