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

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @contactSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Suggestions'**
  String get contactSuggestionsTitle;

  /// No description provided for @loadingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Loading suggestions...'**
  String get loadingSuggestions;

  /// No description provided for @noSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get noSuggestionsTitle;

  /// No description provided for @noSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No app users were found in your contacts.'**
  String get noSuggestionsSubtitle;

  /// No description provided for @contactsAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts Access'**
  String get contactsAccessTitle;

  /// No description provided for @contactsAccessExplanation.
  ///
  /// In en, this message translates to:
  /// **'To find friends from your contacts who already use the app, we need access to your contacts list.'**
  String get contactsAccessExplanation;

  /// No description provided for @grantContactsAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Contacts Access'**
  String get grantContactsAccess;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @profileNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFoundTitle;

  /// No description provided for @profileNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This user may have been removed.'**
  String get profileNotFoundSubtitle;

  /// No description provided for @shareProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfileTooltip;

  /// No description provided for @profileInfoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfoSectionTitle;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSinceLabel;

  /// No description provided for @recentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recentlyLabel;

  /// No description provided for @otpVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerifyTitle;

  /// No description provided for @otpInstructionPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}.'**
  String otpInstructionPhone(Object phone);

  /// No description provided for @otpAutoDetectNote.
  ///
  /// In en, this message translates to:
  /// **'Firebase will automatically detect the SMS.'**
  String get otpAutoDetectNote;

  /// No description provided for @otpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Try again.'**
  String get otpInvalidCode;

  /// No description provided for @otpCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Resend the code.'**
  String get otpCodeExpired;

  /// No description provided for @otpPhoneInUse.
  ///
  /// In en, this message translates to:
  /// **'Phone already linked to another account.'**
  String get otpPhoneInUse;

  /// No description provided for @otpInternalError.
  ///
  /// In en, this message translates to:
  /// **'Internal error. Try again.'**
  String get otpInternalError;

  /// No description provided for @otpCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent.'**
  String get otpCodeResent;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(Object seconds);

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// No description provided for @shareProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Check my profile on Wishlist App: {link}'**
  String shareProfileMessage(Object link);

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(Object error);

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow system language'**
  String get systemLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeSettings;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use the light theme'**
  String get themeLightSubtitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @themeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use the dark theme'**
  String get themeDarkSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeSystem;

  /// No description provided for @themeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system setting'**
  String get themeSystemSubtitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register new account'**
  String get registerTitle;

  /// No description provided for @registerErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Registration error: '**
  String get registerErrorPrefix;

  /// No description provided for @registerSystemError.
  ///
  /// In en, this message translates to:
  /// **'System error. Please try again.'**
  String get registerSystemError;

  /// No description provided for @registerEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use. Try logging in.'**
  String get registerEmailInUse;

  /// No description provided for @registerWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Choose a stronger password.'**
  String get registerWeakPassword;

  /// No description provided for @registerInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email. Check the format.'**
  String get registerInvalidEmail;

  /// No description provided for @registerEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get registerEmailRequired;

  /// No description provided for @registerEmailInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get registerEmailInvalidFormat;

  /// No description provided for @registerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get registerNameRequired;

  /// No description provided for @registerNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get registerNameTooShort;

  /// No description provided for @registerPasswordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Password must have at least 8 characters'**
  String get registerPasswordMinChars;

  /// No description provided for @registerPasswordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter'**
  String get registerPasswordUppercase;

  /// No description provided for @registerPasswordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a lowercase letter'**
  String get registerPasswordLowercase;

  /// No description provided for @registerPasswordNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number'**
  String get registerPasswordNumber;

  /// No description provided for @registerPasswordSpecial.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a special symbol'**
  String get registerPasswordSpecial;

  /// No description provided for @registerPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordsDoNotMatch;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @registerPasswordRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get registerPasswordRequirementsTitle;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// No description provided for @registerExistingAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in!'**
  String get registerExistingAccountCta;

  /// No description provided for @scrapingExtractingInfo.
  ///
  /// In en, this message translates to:
  /// **'Extracting product information...'**
  String get scrapingExtractingInfo;

  /// No description provided for @scrapingFillingFields.
  ///
  /// In en, this message translates to:
  /// **'Filling fields automatically...'**
  String get scrapingFillingFields;

  /// No description provided for @scrapingLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading product image...'**
  String get scrapingLoadingImage;

  /// No description provided for @scrapingExtractedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Extracted: {features}. Review the data!'**
  String scrapingExtractedPrefix(Object features);

  /// No description provided for @scrapingCompletedAdjust.
  ///
  /// In en, this message translates to:
  /// **'Done! Review and adjust the data if needed.'**
  String get scrapingCompletedAdjust;

  /// No description provided for @scrapingError.
  ///
  /// In en, this message translates to:
  /// **'Error extracting data. Fill manually.'**
  String get scrapingError;

  /// No description provided for @scrapingFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get scrapingFeatureTitle;

  /// No description provided for @scrapingFeaturePrice.
  ///
  /// In en, this message translates to:
  /// **'price'**
  String get scrapingFeaturePrice;

  /// No description provided for @scrapingFeatureDescription.
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get scrapingFeatureDescription;

  /// No description provided for @scrapingFeatureCategory.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get scrapingFeatureCategory;

  /// No description provided for @scrapingFeatureRating.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get scrapingFeatureRating;

  /// No description provided for @scrapingFeatureImage.
  ///
  /// In en, this message translates to:
  /// **'image'**
  String get scrapingFeatureImage;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemTitle;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItemTitle;

  /// No description provided for @chooseWishlistLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a Wishlist'**
  String get chooseWishlistLabel;

  /// No description provided for @chooseWishlistValidation.
  ///
  /// In en, this message translates to:
  /// **'Please choose a wishlist'**
  String get chooseWishlistValidation;

  /// No description provided for @newWishlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New wishlist name'**
  String get newWishlistNameLabel;

  /// No description provided for @newWishlistNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the wishlist'**
  String get newWishlistNameRequired;

  /// No description provided for @createWishlistAction.
  ///
  /// In en, this message translates to:
  /// **'Create Wishlist'**
  String get createWishlistAction;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemNameLabel;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the item name'**
  String get itemNameRequired;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @itemDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescriptionLabel;

  /// No description provided for @linkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @quantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity'**
  String get quantityRequired;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get quantityInvalid;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @priceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get priceInvalid;

  /// No description provided for @selectOrCreateWishlistPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select or create a wishlist.'**
  String get selectOrCreateWishlistPrompt;

  /// No description provided for @errorCreatingWishlist.
  ///
  /// In en, this message translates to:
  /// **'Error creating wishlist: {error}'**
  String errorCreatingWishlist(Object error);

  /// No description provided for @errorLoadingItem.
  ///
  /// In en, this message translates to:
  /// **'Error loading item: {error}'**
  String errorLoadingItem(Object error);

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}'**
  String imageUploadFailed(Object error);

  /// No description provided for @addItemAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addItemAction;

  /// No description provided for @saveItemAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveItemAction;
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
