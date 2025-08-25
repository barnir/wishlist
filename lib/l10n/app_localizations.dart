import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get appTitle;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Button to edit profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Actions section title
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Privacy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Privacy settings title
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// Private profile setting
  ///
  /// In en, this message translates to:
  /// **'Private Profile'**
  String get privateProfile;

  /// Public profile setting
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// Private profile description
  ///
  /// In en, this message translates to:
  /// **'Only approved users can see your wishlists'**
  String get privateProfileDesc;

  /// Public profile description
  ///
  /// In en, this message translates to:
  /// **'Any user can see your public wishlists'**
  String get publicProfileDesc;

  /// Theme customization description
  ///
  /// In en, this message translates to:
  /// **'Customize appearance'**
  String get customizeAppearance;

  /// Help and support option
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Rate app option
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Delete account button
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account warning
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible'**
  String get deleteAccountDesc;

  /// Wishlists count label
  ///
  /// In en, this message translates to:
  /// **'Wishlists'**
  String get wishlists;

  /// Items count label
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Favorites count label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Shared count label
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// Add bio placeholder
  ///
  /// In en, this message translates to:
  /// **'Add bio...'**
  String get addBio;

  /// Bio placeholder text
  ///
  /// In en, this message translates to:
  /// **'Tell a bit about yourself...'**
  String get tellAboutYou;

  /// Default name when user has no name
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// Default text when user has no email
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No email linked message
  ///
  /// In en, this message translates to:
  /// **'No email linked'**
  String get noEmailLinked;

  /// User not found message
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// Name validation message
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// Error saving message
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// Delete account confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountConfirmation;

  /// Delete account warning message
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your data will be lost. To confirm, type \"DELETE\" in the box below.'**
  String get deleteAccountWarning;

  /// Confirm text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Delete permanently button
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// Account deletion success message
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeletedSuccessfully;

  /// Error deleting account message
  ///
  /// In en, this message translates to:
  /// **'Error deleting account: {error}'**
  String errorDeletingAccount(String error);

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register page title
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// My wishlists title
  ///
  /// In en, this message translates to:
  /// **'My Wishlists'**
  String get myWishlists;

  /// Explore page title
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Create wishlist button
  ///
  /// In en, this message translates to:
  /// **'Create Wishlist'**
  String get createWishlist;

  /// Wishlist name field
  ///
  /// In en, this message translates to:
  /// **'Wishlist Name'**
  String get wishlistName;

  /// Description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Public setting
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// Private setting
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
