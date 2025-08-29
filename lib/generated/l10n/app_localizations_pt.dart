// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Lista de Desejos';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get name => 'Nome';

  @override
  String get bio => 'Biografia';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Telemóvel';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get account => 'Conta';

  @override
  String get preferences => 'Preferências';

  @override
  String get about => 'Sobre';

  @override
  String get actions => 'Ações';

  @override
  String get theme => 'Tema';

  @override
  String get privacy => 'Privacidade';

  @override
  String get privacySettings => 'Configurações de Privacidade';

  @override
  String get privateProfile => 'Perfil Privado';

  @override
  String get publicProfile => 'Perfil Público';

  @override
  String get privateProfileDesc =>
      'Apenas utilizadores aprovados podem ver as suas wishlists';

  @override
  String get publicProfileDesc =>
      'Qualquer utilizador pode ver as suas wishlists públicas';

  @override
  String get customizeAppearance => 'Personalizar aparência';

  @override
  String get helpSupport => 'Ajuda e Suporte';

  @override
  String get rateApp => 'Avaliar App';

  @override
  String get signOut => 'Terminar Sessão';

  @override
  String get deleteAccount => 'Apagar Conta';

  @override
  String get deleteAccountDesc => 'Esta ação é irreversível';

  @override
  String get wishlists => 'Wishlists';

  @override
  String get items => 'Items';

  @override
  String get favorites => 'Favoritos';

  @override
  String get shared => 'Partilhadas';

  @override
  String get addBio => 'Adicionar biografia...';

  @override
  String get tellAboutYou => 'Conte um pouco sobre si...';

  @override
  String get noName => 'Sem nome';

  @override
  String get noEmail => 'Sem email';

  @override
  String get noEmailLinked => 'Nenhum email vinculado';

  @override
  String get userNotFound => 'Utilizador não encontrado.';

  @override
  String get nameCannotBeEmpty => 'Nome não pode estar vazio';

  @override
  String errorSaving(String error) {
    return 'Erro ao guardar: $error';
  }

  @override
  String get deleteAccountConfirmation => 'Apagar Conta';

  @override
  String get deleteAccountWarning =>
      'Esta ação é irreversível. Todos os seus dados serão perdidos. Para confirmar, escreva \"APAGAR\" na caixa abaixo.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get deletePermanently => 'Apagar Permanentemente';

  @override
  String get accountDeletedSuccessfully => 'Conta apagada com sucesso.';

  @override
  String errorDeletingAccount(String error) {
    return 'Erro ao apagar conta: $error';
  }

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registar';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get myWishlists => 'As Minhas Listas';

  @override
  String get explore => 'Explorar';

  @override
  String get createWishlist => 'Criar Lista';

  @override
  String get wishlistName => 'Nome da Lista';

  @override
  String get description => 'Descrição';

  @override
  String get public => 'Público';

  @override
  String get private => 'Privado';

  @override
  String get deleteConfirmWord => 'APAGAR';

  @override
  String errorLoadingWishlists(String error) {
    return 'Erro ao carregar wishlists: $error';
  }

  @override
  String get noWishlistsYetTitle => 'Nenhuma wishlist por aqui';

  @override
  String get noWishlistsYetSubtitle =>
      'Toque em \"+\" para criar a sua primeira!';

  @override
  String get pleaseLoginToSeeWishlists =>
      'Por favor, faça login para ver suas wishlists.';

  @override
  String get loadingWishlists => 'A carregar wishlists...';

  @override
  String get addNewWishlistTooltip => 'Adicionar nova wishlist';

  @override
  String get publicWishlistsTab => 'Wishlists Públicas';

  @override
  String get aboutTab => 'Sobre';

  @override
  String get noPublicWishlists => 'Nenhuma wishlist pública';

  @override
  String get noPublicWishlistsSubtitle =>
      'Este utilizador ainda não tem wishlists públicas.';

  @override
  String get publicLabel => 'Pública';

  @override
  String get privateLabel => 'Privada';

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String get loadingFavorites => 'A carregar favoritos...';

  @override
  String get noFavoritesYet => 'Nenhum favorito ainda';

  @override
  String get favoritesEmptySubtitle =>
      'Explora perfis e marca os teus utilizadores favoritos para veres as suas wishlists públicas!';

  @override
  String get searchProfilesTooltip => 'Explorar perfis';

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get searchUsersPlaceholder => 'Pesquisar utilizadores...';

  @override
  String get searchUsersTitle => 'Pesquisar utilizadores';

  @override
  String get searchUsersSubtitle =>
      'Digite um nome ou email para encontrar utilizadores e as suas wishlists públicas.';

  @override
  String get searching => 'A pesquisar...';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String get noResultsSubtitle =>
      'Não foram encontrados utilizadores com esse termo.';

  @override
  String get loadingMore => 'A carregar mais...';

  @override
  String get loadingMoreWishlists => 'A carregar mais wishlists...';

  @override
  String get loadingMoreFavorites => 'A carregar mais favoritos...';

  @override
  String get loadingMoreResults => 'A carregar mais resultados...';

  @override
  String get loadingWishlist => 'A carregar wishlist...';

  @override
  String get loadingItems => 'A carregar itens...';

  @override
  String get loadingMoreItems => 'A carregar mais itens...';

  @override
  String get wishlistIsPrivate => 'Esta wishlist é privada';

  @override
  String get wishlistIsPublic => 'Esta wishlist é pública';

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String get addToFavorites => 'Adicionar aos favoritos';

  @override
  String get noWishlistFoundCreateNew =>
      'Nenhuma wishlist encontrada. Crie uma nova.';

  @override
  String get privateWishlist => 'Wishlist Privada';

  @override
  String errorLoadingFavorites(Object error) {
    return 'Erro ao carregar favoritos: $error';
  }

  @override
  String errorLoadingResults(Object error) {
    return 'Erro ao carregar resultados: $error';
  }

  @override
  String get createWishlistTitle => 'Criar Wishlist';

  @override
  String get editWishlistTitle => 'Editar Wishlist';

  @override
  String get wishlistDetailsSection => 'Detalhes da Wishlist';

  @override
  String get wishlistImageSection => 'Imagem da Wishlist';

  @override
  String errorSavingWishlist(Object error) {
    return 'Erro ao salvar wishlist: $error';
  }

  @override
  String get wishlistEmptyTitle => 'A sua wishlist está vazia';

  @override
  String get wishlistEmptySubtitle =>
      'Toque no botão + para adicionar o primeiro item.';

  @override
  String get addNewItemTooltip => 'Adicionar novo item';

  @override
  String get favoriteBadge => 'FAVORITO';

  @override
  String errorPrefix(Object error) {
    return 'Erro: $error';
  }

  @override
  String get publicProfileBadge => 'Perfil público';

  @override
  String get privateProfileBadge => 'Perfil privado';

  @override
  String get filterAndSortTooltip => 'Filtrar e ordenar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get view => 'Ver';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String get deleteItemTooltip => 'Eliminar item';

  @override
  String get deleteItemTitle => 'Eliminar item';

  @override
  String deleteItemConfirmation(Object itemName) {
    return 'Tens a certeza que queres eliminar \"$itemName\"?';
  }

  @override
  String get tapToAdd => 'Toca para adicionar';

  @override
  String get processingImage => 'A processar...';

  @override
  String get recommendedImageSize => 'Recomendado: 400x400px ou superior';

  @override
  String get wishlistNameLabel => 'Nome da Wishlist';

  @override
  String get wishlistNameHint => 'Digite o nome da sua wishlist';

  @override
  String get wishlistNameRequired => 'Insere um nome';

  @override
  String get privacySectionTitle => 'Privacidade';

  @override
  String get privateWishlistSubtitle => 'Apenas tu podes ver esta wishlist';

  @override
  String get publicWishlistSubtitle =>
      'Outros utilizadores podem ver esta wishlist';

  @override
  String get saveChanges => 'Guardar Alterações';
}
