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

  /// Word user must type to confirm account deletion
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmWord;

  /// Snackbar error when wishlists fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading wishlists: {error}'**
  String errorLoadingWishlists(String error);

  /// Empty state title for wishlists list
  ///
  /// In en, this message translates to:
  /// **'No wishlists yet'**
  String get noWishlistsYetTitle;

  /// Empty state subtitle for wishlists list
  ///
  /// In en, this message translates to:
  /// **'Tap \"+\" to create your first!'**
  String get noWishlistsYetSubtitle;

  /// Message shown when user not logged in on wishlists screen
  ///
  /// In en, this message translates to:
  /// **'Please log in to see your wishlists.'**
  String get pleaseLoginToSeeWishlists;

  /// Loading indicator message for wishlists
  ///
  /// In en, this message translates to:
  /// **'Loading wishlists...'**
  String get loadingWishlists;

  /// Tooltip for FAB to add a wishlist
  ///
  /// In en, this message translates to:
  /// **'Add new wishlist'**
  String get addNewWishlistTooltip;

  /// No description provided for @publicWishlistsTab.
  ///
  /// In en, this message translates to:
  /// **'Public Wishlists'**
  String get publicWishlistsTab;

  /// No description provided for @aboutTab.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTab;

  /// No description provided for @noPublicWishlists.
  ///
  /// In en, this message translates to:
  /// **'No public wishlist'**
  String get noPublicWishlists;

  /// No description provided for @noPublicWishlistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This user doesn\'t have public wishlists yet.'**
  String get noPublicWishlistsSubtitle;

  /// No description provided for @publicLabel.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicLabel;

  /// No description provided for @privateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateLabel;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @loadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...'**
  String get loadingFavorites;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore profiles and mark favorites to see their public wishlists!'**
  String get favoritesEmptySubtitle;

  /// No description provided for @searchProfilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search profiles'**
  String get searchProfilesTooltip;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @searchUsersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsersPlaceholder;

  /// No description provided for @searchUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get searchUsersTitle;

  /// No description provided for @searchUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a name or email to find users and their public wishlists.'**
  String get searchUsersSubtitle;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No users found for that term.'**
  String get noResultsSubtitle;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// No description provided for @loadingMoreWishlists.
  ///
  /// In en, this message translates to:
  /// **'Loading more wishlists...'**
  String get loadingMoreWishlists;

  /// No description provided for @loadingMoreFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading more favorites...'**
  String get loadingMoreFavorites;

  /// No description provided for @loadingMoreResults.
  ///
  /// In en, this message translates to:
  /// **'Loading more results...'**
  String get loadingMoreResults;

  /// No description provided for @loadingWishlist.
  ///
  /// In en, this message translates to:
  /// **'Loading wishlist...'**
  String get loadingWishlist;

  /// No description provided for @loadingItems.
  ///
  /// In en, this message translates to:
  /// **'Loading items...'**
  String get loadingItems;

  /// No description provided for @loadingMoreItems.
  ///
  /// In en, this message translates to:
  /// **'Loading more items...'**
  String get loadingMoreItems;

  /// No description provided for @wishlistIsPrivate.
  ///
  /// In en, this message translates to:
  /// **'This wishlist is private'**
  String get wishlistIsPrivate;

  /// No description provided for @wishlistIsPublic.
  ///
  /// In en, this message translates to:
  /// **'This wishlist is public'**
  String get wishlistIsPublic;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @noWishlistFoundCreateNew.
  ///
  /// In en, this message translates to:
  /// **'No wishlist found. Create a new one.'**
  String get noWishlistFoundCreateNew;

  /// No description provided for @privateWishlist.
  ///
  /// In en, this message translates to:
  /// **'Private Wishlist'**
  String get privateWishlist;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites: {error}'**
  String errorLoadingFavorites(Object error);

  /// No description provided for @errorLoadingResults.
  ///
  /// In en, this message translates to:
  /// **'Error loading results: {error}'**
  String errorLoadingResults(Object error);

  /// No description provided for @createWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Wishlist'**
  String get createWishlistTitle;

  /// No description provided for @editWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Wishlist'**
  String get editWishlistTitle;

  /// No description provided for @wishlistDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Wishlist Details'**
  String get wishlistDetailsSection;

  /// No description provided for @wishlistImageSection.
  ///
  /// In en, this message translates to:
  /// **'Wishlist Image'**
  String get wishlistImageSection;

  /// No description provided for @errorSavingWishlist.
  ///
  /// In en, this message translates to:
  /// **'Error saving wishlist: {error}'**
  String errorSavingWishlist(Object error);

  /// No description provided for @wishlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmptyTitle;

  /// No description provided for @wishlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first item.'**
  String get wishlistEmptySubtitle;

  /// No description provided for @addNewItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add new item'**
  String get addNewItemTooltip;

  /// No description provided for @favoriteBadge.
  ///
  /// In en, this message translates to:
  /// **'FAVORITE'**
  String get favoriteBadge;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @publicProfileBadge.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfileBadge;

  /// No description provided for @privateProfileBadge.
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get privateProfileBadge;

  /// No description provided for @filterAndSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterAndSortTooltip;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @deleteItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItemTooltip;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{itemName}\"?'**
  String deleteItemConfirmation(Object itemName);

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingImage;

  /// No description provided for @recommendedImageSize.
  ///
  /// In en, this message translates to:
  /// **'Recommended: 400x400px or higher'**
  String get recommendedImageSize;

  /// No description provided for @wishlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wishlist Name'**
  String get wishlistNameLabel;

  /// No description provided for @wishlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your wishlist name'**
  String get wishlistNameHint;

  /// No description provided for @wishlistNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get wishlistNameRequired;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @privateWishlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this wishlist'**
  String get privateWishlistSubtitle;

  /// No description provided for @publicWishlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Other users can see this wishlist'**
  String get publicWishlistSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;
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
