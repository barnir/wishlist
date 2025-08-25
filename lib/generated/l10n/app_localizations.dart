import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  // Main app strings
  String get appTitle;
  String get profile;
  String get editProfile;
  String get name;
  String get bio;
  String get email;
  String get phone;
  String get save;
  String get cancel;
  String get account;
  String get preferences;
  String get about;
  String get actions;
  String get theme;
  String get privacy;
  String get privacySettings;
  String get privateProfile;
  String get publicProfile;
  String get privateProfileDesc;
  String get publicProfileDesc;
  String get customizeAppearance;
  String get helpSupport;
  String get rateApp;
  String get signOut;
  String get deleteAccount;
  String get deleteAccountDesc;
  String get wishlists;
  String get items;
  String get favorites;
  String get shared;
  String get addBio;
  String get tellAboutYou;
  String get noName;
  String get noEmail;
  String get noEmailLinked;
  String get userNotFound;
  String get nameCannotBeEmpty;
  String errorSaving(String error);
  String get deleteAccountConfirmation;
  String get deleteAccountWarning;
  String get confirm;
  String get deletePermanently;
  String get accountDeletedSuccessfully;
  String errorDeletingAccount(String error);
  String get login;
  String get register;
  String get welcome;
  String get myWishlists;
  String get explore;
  String get createWishlist;
  String get wishlistName;
  String get description;
  String get public;
  String get private;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations _lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool.');
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appTitle => 'Wishlist';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get bio => 'Bio';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get actions => 'Actions';

  @override
  String get theme => 'Theme';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get privateProfile => 'Private Profile';

  @override
  String get publicProfile => 'Public Profile';

  @override
  String get privateProfileDesc => 'Only approved users can see your wishlists';

  @override
  String get publicProfileDesc => 'Any user can see your public wishlists';

  @override
  String get customizeAppearance => 'Customize appearance';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get rateApp => 'Rate App';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDesc => 'This action is irreversible';

  @override
  String get wishlists => 'Wishlists';

  @override
  String get items => 'Items';

  @override
  String get favorites => 'Favorites';

  @override
  String get shared => 'Shared';

  @override
  String get addBio => 'Add bio...';

  @override
  String get tellAboutYou => 'Tell a bit about yourself...';

  @override
  String get noName => 'No name';

  @override
  String get noEmail => 'No email';

  @override
  String get noEmailLinked => 'No email linked';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String errorSaving(String error) => 'Error saving: $error';

  @override
  String get deleteAccountConfirmation => 'Delete Account';

  @override
  String get deleteAccountWarning => 'This action is irreversible. All your data will be lost. To confirm, type "DELETE" in the box below.';

  @override
  String get confirm => 'Confirm';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully.';

  @override
  String errorDeletingAccount(String error) => 'Error deleting account: $error';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get welcome => 'Welcome';

  @override
  String get myWishlists => 'My Wishlists';

  @override
  String get explore => 'Explore';

  @override
  String get createWishlist => 'Create Wishlist';

  @override
  String get wishlistName => 'Wishlist Name';

  @override
  String get description => 'Description';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';
}

class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt() : super('pt');

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
  String get privateProfileDesc => 'Apenas utilizadores aprovados podem ver as suas wishlists';

  @override
  String get publicProfileDesc => 'Qualquer utilizador pode ver as suas wishlists públicas';

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
  String errorSaving(String error) => 'Erro ao guardar: $error';

  @override
  String get deleteAccountConfirmation => 'Apagar Conta';

  @override
  String get deleteAccountWarning => 'Esta ação é irreversível. Todos os seus dados serão perdidos. Para confirmar, escreva "APAGAR" na caixa abaixo.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get deletePermanently => 'Apagar Permanentemente';

  @override
  String get accountDeletedSuccessfully => 'Conta apagada com sucesso.';

  @override
  String errorDeletingAccount(String error) => 'Erro ao apagar conta: $error';

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