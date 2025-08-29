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
  String get wishlistNameRequired => 'Nome da wishlist é obrigatório';

  @override
  String get privacySectionTitle => 'Privacidade';

  @override
  String get privateWishlistSubtitle => 'Apenas tu podes ver esta wishlist';

  @override
  String get publicWishlistSubtitle =>
      'Outros utilizadores podem ver esta wishlist';

  @override
  String get saveChanges => 'Guardar Alterações';

  @override
  String get addedToFavorites => 'Adicionado aos favoritos!';

  @override
  String get removedFromFavorites => 'Removido dos favoritos';

  @override
  String get contactSuggestionsTitle => 'Sugestões dos Contactos';

  @override
  String get loadingSuggestions => 'A carregar sugestões...';

  @override
  String get noSuggestionsTitle => 'Nenhuma sugestão';

  @override
  String get noSuggestionsSubtitle =>
      'Não foram encontrados utilizadores da app nos seus contactos.';

  @override
  String get contactsAccessTitle => 'Acesso aos Contactos';

  @override
  String get contactsAccessExplanation =>
      'Para encontrar amigos dos seus contactos que já usam a app, precisamos de acesso à sua lista de contactos.';

  @override
  String get grantContactsAccess => 'Permitir Acesso aos Contactos';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get profileNotFoundTitle => 'Perfil não encontrado';

  @override
  String get profileNotFoundSubtitle =>
      'Este utilizador pode ter sido removido.';

  @override
  String get shareProfileTooltip => 'Partilhar perfil';

  @override
  String get profileInfoSectionTitle => 'Informações do Perfil';

  @override
  String get memberSinceLabel => 'Membro desde';

  @override
  String get recentlyLabel => 'Recentemente';

  @override
  String get otpVerifyTitle => 'Verificar Código';

  @override
  String otpInstructionPhone(Object phone) {
    return 'Insira o código de 6 dígitos enviado para $phone.';
  }

  @override
  String get otpAutoDetectNote =>
      'O Firebase irá detectar automaticamente o SMS.';

  @override
  String get otpInvalidCode => 'Código inválido. Tente novamente.';

  @override
  String get otpCodeExpired => 'Código expirou. Reenvie o código.';

  @override
  String get otpPhoneInUse => 'Telefone já associado a outra conta.';

  @override
  String get otpInternalError => 'Erro interno. Tente novamente.';

  @override
  String get otpCodeResent => 'Código reenviado.';

  @override
  String get otpResend => 'Reenviar Código';

  @override
  String otpResendIn(Object seconds) {
    return 'Reenviar em $seconds s';
  }

  @override
  String get otpVerifyButton => 'Verificar';

  @override
  String shareProfileMessage(Object link) {
    return 'Vê o meu perfil no Wishlist App: $link';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Erro ao carregar perfil: $error';
  }

  @override
  String get languageSettings => 'Configurações de Idioma';

  @override
  String get automatic => 'Automático';

  @override
  String get systemLanguage => 'Seguir idioma do sistema';

  @override
  String get language => 'Idioma';

  @override
  String get themeSettings => 'Tema da App';

  @override
  String get themeLight => 'Tema Claro';

  @override
  String get themeLightSubtitle => 'Usar sempre o tema claro';

  @override
  String get themeDark => 'Tema Escuro';

  @override
  String get themeDarkSubtitle => 'Usar sempre o tema escuro';

  @override
  String get themeSystem => 'Automático';

  @override
  String get themeSystemSubtitle => 'Seguir as definições do sistema';

  @override
  String get close => 'Fechar';

  @override
  String get registerTitle => 'Registar nova conta';

  @override
  String get registerErrorPrefix => 'Erro ao registar: ';

  @override
  String get registerSystemError =>
      'Erro no sistema. Por favor tente novamente.';

  @override
  String get registerEmailInUse =>
      'Este email já está em uso. Tente fazer login.';

  @override
  String get registerWeakPassword =>
      'A password é muito fraca. Escolha uma password mais forte.';

  @override
  String get registerInvalidEmail => 'Email inválido. Verifique o formato.';

  @override
  String get registerEmailRequired => 'Email obrigatório';

  @override
  String get registerEmailInvalidFormat => 'Formato de email inválido';

  @override
  String get registerNameRequired => 'Nome obrigatório';

  @override
  String get registerNameTooShort => 'Nome demasiado curto';

  @override
  String get registerPasswordMinChars =>
      'Password deve ter pelo menos 8 caracteres';

  @override
  String get registerPasswordUppercase => 'Password deve conter uma maiúscula';

  @override
  String get registerPasswordLowercase => 'Password deve conter uma minúscula';

  @override
  String get registerPasswordNumber => 'Password deve conter um número';

  @override
  String get registerPasswordSpecial =>
      'Password deve conter um símbolo especial';

  @override
  String get registerPasswordsDoNotMatch => 'Passwords não coincidem';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirmar Password';

  @override
  String get registerPasswordRequirementsTitle => 'Requisitos da password:';

  @override
  String get registerAction => 'Registar';

  @override
  String get registerExistingAccountCta => 'Já tens conta? Fazer login!';

  @override
  String get scrapingExtractingInfo => 'Extraindo informações do produto...';

  @override
  String get scrapingFillingFields => 'Preenchendo campos automaticamente...';

  @override
  String get scrapingLoadingImage => 'Carregando imagem do produto...';

  @override
  String scrapingExtractedPrefix(String features) {
    return 'Extraído: $features. Verifique os dados!';
  }

  @override
  String get scrapingCompletedAdjust =>
      'Concluído! Verifique e ajuste os dados se necessário.';

  @override
  String get scrapingError => 'Erro ao extrair dados. Preencha manualmente.';

  @override
  String get scrapingFeatureTitle => 'título';

  @override
  String get scrapingFeaturePrice => 'preço';

  @override
  String get scrapingFeatureDescription => 'descrição';

  @override
  String get scrapingFeatureCategory => 'categoria';

  @override
  String get scrapingFeatureRating => 'avaliação';

  @override
  String get scrapingFeatureImage => 'imagem';

  @override
  String get addItemTitle => 'Adicionar Item';

  @override
  String get editItemTitle => 'Editar Item';

  @override
  String get chooseWishlistLabel => 'Escolha uma Wishlist';

  @override
  String get chooseWishlistValidation => 'Por favor, escolha uma wishlist';

  @override
  String get newWishlistNameLabel => 'Nome da nova wishlist';

  @override
  String get newWishlistNameRequired => 'Insira um nome para a wishlist';

  @override
  String get createWishlistAction => 'Criar Wishlist';

  @override
  String get itemNameLabel => 'Nome do Item';

  @override
  String get itemNameRequired => 'Nome do item é obrigatório';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get itemDescriptionLabel => 'Descrição';

  @override
  String get linkLabel => 'Link';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get quantityRequired => 'Insere a quantidade';

  @override
  String get quantityInvalid => 'Quantidade inválida';

  @override
  String get priceLabel => 'Preço';

  @override
  String get priceInvalid => 'Preço inválido';

  @override
  String get selectOrCreateWishlistPrompt =>
      'Por favor, selecione ou crie uma wishlist.';

  @override
  String errorCreatingWishlist(String error) {
    return 'Erro ao criar wishlist: $error';
  }

  @override
  String errorLoadingItem(String error) {
    return 'Erro ao carregar item: $error';
  }

  @override
  String imageUploadFailed(String error) {
    return 'Falha upload imagem: $error';
  }

  @override
  String get addItemAction => 'Adicionar';

  @override
  String get saveItemAction => 'Guardar';

  @override
  String get emailRequired => 'Email é obrigatório';

  @override
  String get emailInvalid => 'Email inválido';

  @override
  String get emailTooLong => 'Email demasiado longo';

  @override
  String get emailDomainInvalid => 'Domínio do email inválido';

  @override
  String get passwordRequired => 'Password é obrigatória';

  @override
  String get passwordTooShort => 'Password deve ter pelo menos 8 caracteres';

  @override
  String get passwordTooLong => 'Password demasiado longa';

  @override
  String get passwordNeedUpper =>
      'Password deve conter pelo menos uma letra maiúscula';

  @override
  String get passwordNeedLower =>
      'Password deve conter pelo menos uma letra minúscula';

  @override
  String get passwordNeedNumber => 'Password deve conter pelo menos um número';

  @override
  String get passwordNeedSpecial =>
      'Password deve conter pelo menos um caracter especial';

  @override
  String get nameRequired => 'Nome é obrigatório';

  @override
  String get nameTooShort => 'Nome deve ter pelo menos 2 caracteres';

  @override
  String get nameTooLong => 'Nome demasiado longo';

  @override
  String get nameInvalidChars => 'Nome contém caracteres inválidos';

  @override
  String get phoneRequired => 'Número de telefone é obrigatório';

  @override
  String get phoneInvalidFormat =>
      'Número de telefone inválido (formato: 9XXXXXXXX)';

  @override
  String get urlMustBeHttp => 'URL deve usar HTTP ou HTTPS';

  @override
  String get urlInvalid => 'URL inválido';

  @override
  String get urlLocalNotAllowed => 'URLs locais não são permitidos';

  @override
  String get urlTooLong => 'URL demasiado longo';

  @override
  String get priceNegative => 'Preço não pode ser negativo';

  @override
  String get priceTooHigh => 'Preço demasiado alto';

  @override
  String get descriptionTooLong =>
      'Descrição demasiado longa (máximo 500 caracteres)';

  @override
  String get wishlistNameTooShort =>
      'Nome da wishlist deve ter pelo menos 2 caracteres';

  @override
  String get wishlistNameTooLong => 'Nome da wishlist demasiado longo';

  @override
  String get itemNameTooShort =>
      'Nome do item deve ter pelo menos 2 caracteres';

  @override
  String get itemNameTooLong => 'Nome do item demasiado longo';

  @override
  String get imageTooLarge => 'Imagem demasiado grande (máximo 10MB)';

  @override
  String get imageFormatUnsupported =>
      'Formato de imagem não suportado (use JPG, PNG ou GIF)';

  @override
  String get otpCodeRequired => 'Código é obrigatório';

  @override
  String get otpCodeLength => 'Código deve ter 6 dígitos';

  @override
  String get otpCodeDigitsOnly => 'Código deve conter apenas números';
}
