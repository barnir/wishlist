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
}
