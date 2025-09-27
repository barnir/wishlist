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

  /// Success message when marking the status of an item.
  ///
  /// In en, this message translates to:
  /// **'Item marked as {status}'**
  String itemMarkedStatus(Object status);

  /// Generic error message.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(Object error);

  /// Button to remove item status (reversible action)
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeStatusButton;

  /// Success message when removing item status
  ///
  /// In en, this message translates to:
  /// **'Status removed'**
  String get removeStatusSuccess;

  /// Error message when removing item status
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String removeStatusError(Object error);

  /// Description for 'will buy' option
  ///
  /// In en, this message translates to:
  /// **'Reserve to buy later'**
  String get willBuyDescription;

  /// Information about the 7-day period for reservations
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive reminders on days 6 and 7. After 7 days, the reservation will be automatically cancelled if you don\'t mark it as purchased.'**
  String get willBuyReminderInfo;

  /// Description for 'purchased' option
  ///
  /// In en, this message translates to:
  /// **'I already bought this item'**
  String get purchasedDescription;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(Object error);

  /// No description provided for @createWishlistError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create wishlist'**
  String get createWishlistError;

  /// No description provided for @openItemLink.
  ///
  /// In en, this message translates to:
  /// **'Open item link'**
  String get openItemLink;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'MyWishStash'**
  String get appTitle;

  /// Dialog title to cancel registration
  ///
  /// In en, this message translates to:
  /// **'Cancel Registration'**
  String get cancelRegistrationTitle;

  /// Dialog body for cancel registration
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel registration? You will lose current progress and must start again.'**
  String get cancelRegistrationMessage;

  /// Action to continue registration instead of cancelling
  ///
  /// In en, this message translates to:
  /// **'Continue Registration'**
  String get continueRegistration;

  /// Error message when cancellation fails
  ///
  /// In en, this message translates to:
  /// **'Error cancelling registration: {error}'**
  String errorCancelRegistration(Object error);

  /// Placeholder when user email/displayName still not resolved
  ///
  /// In en, this message translates to:
  /// **'User in registration process'**
  String get registrationUserPlaceholder;

  /// AppBar title for completing registration
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistrationTitle;

  /// Title shown when registration not finished
  ///
  /// In en, this message translates to:
  /// **'Incomplete Process'**
  String get incompleteProcessTitle;

  /// Label above user email
  ///
  /// In en, this message translates to:
  /// **'Continuing registration for:'**
  String get continuingRegistrationFor;

  /// Intro message before phone verification
  ///
  /// In en, this message translates to:
  /// **'To finish registration you need to verify a phone number.'**
  String get phoneVerificationIntro;

  /// Button to show phone form
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// Button to sign out and pick another method
  ///
  /// In en, this message translates to:
  /// **'Choose Another Method'**
  String get chooseAnotherMethod;

  /// Title of the phone form section
  ///
  /// In en, this message translates to:
  /// **'Add Phone'**
  String get addPhoneTitle;

  /// Instruction above phone field
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code.'**
  String get enterPhoneInstruction;

  /// Label for phone number field (avoid conflict with generic phone)
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabelLocal;

  /// Button to send OTP code
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// Warning when phone invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalidPhoneWarning;

  /// Error when logout fails from this screen
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String logoutError(Object error);

  /// Password rule - min length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get pwRuleMinLength;

  /// Password rule - lowercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter.'**
  String get pwRuleLower;

  /// Password rule - uppercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter.'**
  String get pwRuleUpper;

  /// Password rule - digit
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number.'**
  String get pwRuleDigit;

  /// Password rule - symbol
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one symbol.'**
  String get pwRuleSymbol;

  /// Invalid email error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailFormat;

  /// Short inline loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingInline;

  /// Error when fetching wishlist details
  ///
  /// In en, this message translates to:
  /// **'Error loading wishlist details: {error}'**
  String wishlistDetailsLoadError(Object error);

  /// Error when fetching wishlist items
  ///
  /// In en, this message translates to:
  /// **'Error loading items: {error}'**
  String itemsLoadError(Object error);

  /// Snack success after deleting item
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully!'**
  String get itemDeletedSuccess;

  /// Snack error deleting item
  ///
  /// In en, this message translates to:
  /// **'Error deleting item: {error}'**
  String itemDeleteError(Object error);

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

  /// Shown while metadata enrichment is pending
  ///
  /// In en, this message translates to:
  /// **'Enhancing details...'**
  String get enrichmentPending;

  /// Shown when user is rate limited for enrich link
  ///
  /// In en, this message translates to:
  /// **'Enrichment limit reached. Try later.'**
  String get enrichmentRateLimited;

  /// Shown when enrichment fails to fetch data
  ///
  /// In en, this message translates to:
  /// **'Enrichment failed'**
  String get enrichmentFailed;

  /// Shown when enrichment finishes
  ///
  /// In en, this message translates to:
  /// **'Details enriched.'**
  String get enrichmentCompleted;

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

  /// Section title for data backup actions
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get dataManagement;

  /// Action to export wishlists to a JSON file
  ///
  /// In en, this message translates to:
  /// **'Export wishlists'**
  String get exportWishlists;

  /// Subtitle explaining wishlist export
  ///
  /// In en, this message translates to:
  /// **'Generate a JSON backup you can share or store. Images are not included.'**
  String get exportWishlistsDescription;

  /// Action to import wishlists from a JSON file
  ///
  /// In en, this message translates to:
  /// **'Import wishlists'**
  String get importWishlists;

  /// Subtitle explaining wishlist import
  ///
  /// In en, this message translates to:
  /// **'Load wishlists from a JSON backup. Existing data is kept.'**
  String get importWishlistsDescription;

  /// Success message after exporting wishlists
  ///
  /// In en, this message translates to:
  /// **'Backup ready! Share it now to save a copy.'**
  String get exportWishlistsSuccess;

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Could not export wishlists. Try again in a moment.'**
  String get exportWishlistsError;

  /// Prompt asking user to choose save or share backup
  ///
  /// In en, this message translates to:
  /// **'What would you like to do with the backup?'**
  String get exportWishlistsChooseAction;

  /// Button to share backup file
  ///
  /// In en, this message translates to:
  /// **'Share backup'**
  String get exportWishlistsActionShare;

  /// Button to save backup file
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get exportWishlistsActionSave;

  /// Success message after saving backup
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String exportWishlistsSaveSuccess(Object path);

  /// Error message when saving backup fails
  ///
  /// In en, this message translates to:
  /// **'Could not save the backup file.'**
  String get exportWishlistsSaveError;

  /// Message when user cancels save location selection
  ///
  /// In en, this message translates to:
  /// **'No location selected.'**
  String get exportWishlistsSaveCancelled;

  /// Success message after importing wishlists
  ///
  /// In en, this message translates to:
  /// **'Imported {wishlists} wishlists and {items} items.'**
  String importWishlistsSuccess(Object wishlists, Object items);

  /// Partial success message after import
  ///
  /// In en, this message translates to:
  /// **'Imported {wishlists} wishlists and {items} items. {errors} entries failed.'**
  String importWishlistsPartial(Object wishlists, Object items, Object errors);

  /// Error message when import fails
  ///
  /// In en, this message translates to:
  /// **'Could not import the backup file.'**
  String get importWishlistsError;

  /// Message shown when user cancels file picker
  ///
  /// In en, this message translates to:
  /// **'No backup file selected.'**
  String get importWishlistsNoFile;

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

  /// Filter sheet title
  ///
  /// In en, this message translates to:
  /// **'Filters & Sorting'**
  String get filtersAndSortingTitle;

  /// Button to clear filters
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Button to apply filters
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Sort section label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Prefix for current filters summary
  ///
  /// In en, this message translates to:
  /// **'Current:'**
  String get filtersSummaryPrefix;

  /// Sort by newest
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// Sort by oldest
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// Sort by total value descending
  ///
  /// In en, this message translates to:
  /// **'Total value (High-Low)'**
  String get sortTotalDesc;

  /// Sort by total value ascending
  ///
  /// In en, this message translates to:
  /// **'Total value (Low-High)'**
  String get sortTotalAsc;

  /// Privacy section title
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// All wishlists filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get privacyAll;

  /// Public wishlists filter
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get privacyPublic;

  /// Private wishlists filter
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privacyPrivate;

  /// Total value filter title
  ///
  /// In en, this message translates to:
  /// **'Filter by total value (€)'**
  String get totalValueFilterTitle;

  /// Minimum value label
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minLabel;

  /// Maximum value label
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxLabel;

  /// Label for all categories option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// Name ascending
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAsc;

  /// Name descending
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortNameDesc;

  /// Price ascending
  ///
  /// In en, this message translates to:
  /// **'Price (Low-High)'**
  String get sortPriceAsc;

  /// Price descending
  ///
  /// In en, this message translates to:
  /// **'Price (High-Low)'**
  String get sortPriceDesc;

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

  /// Button label to re-authenticate user
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate'**
  String get reauthenticate;

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

  /// Validation: wishlist name empty (separate from generic name)
  ///
  /// In en, this message translates to:
  /// **'Wishlist name is required'**
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

  /// No description provided for @helpWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Wishlist App!'**
  String get helpWelcomeTitle;

  /// No description provided for @helpWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and share your wishlists in a simple, organized way.'**
  String get helpWelcomeSubtitle;

  /// No description provided for @helpHowToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get helpHowToUse;

  /// No description provided for @helpCreateWishlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Wishlists'**
  String get helpCreateWishlistsTitle;

  /// No description provided for @helpCreateWishlistsDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to create a new wishlist. You can make it public or private.'**
  String get helpCreateWishlistsDesc;

  /// No description provided for @helpAddItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get helpAddItemsTitle;

  /// No description provided for @helpAddItemsDesc.
  ///
  /// In en, this message translates to:
  /// **'Inside a wishlist, tap + to add items. You can attach photos, prices and links.'**
  String get helpAddItemsDesc;

  /// No description provided for @helpFaqAddWithoutLinkQ.
  ///
  /// In en, this message translates to:
  /// **'Can I add items without a link?'**
  String get helpFaqAddWithoutLinkQ;

  /// No description provided for @helpFaqAddWithoutLinkA.
  ///
  /// In en, this message translates to:
  /// **'Yes! You can add items manually by filling name, price and other details.'**
  String get helpFaqAddWithoutLinkA;

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

  /// Title of the bottom sheet / screen where user selects the app theme mode
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeSettings;

  /// Label for choosing the permanent light theme
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// Short explanatory subtitle under the Light Theme option
  ///
  /// In en, this message translates to:
  /// **'Always use the light theme'**
  String get themeLightSubtitle;

  /// Label for choosing the permanent dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// Short explanatory subtitle under the Dark Theme option
  ///
  /// In en, this message translates to:
  /// **'Always use the dark theme'**
  String get themeDarkSubtitle;

  /// Label for following the system (OS) theme setting
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeSystem;

  /// Subtitle explaining that the app appearance adapts to the device setting
  ///
  /// In en, this message translates to:
  /// **'Follow system setting'**
  String get themeSystemSubtitle;

  /// Generic close button tooltip / label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Title displayed at the top of the register/create account screen
  ///
  /// In en, this message translates to:
  /// **'Register new account'**
  String get registerTitle;

  /// Prefix used before a specific registration error message concatenated afterwards
  ///
  /// In en, this message translates to:
  /// **'Registration error: '**
  String get registerErrorPrefix;

  /// Generic catch-all system / unknown error during registration
  ///
  /// In en, this message translates to:
  /// **'System error. Please try again.'**
  String get registerSystemError;

  /// Error shown when Firebase returns email-already-in-use
  ///
  /// In en, this message translates to:
  /// **'This email is already in use. Try logging in.'**
  String get registerEmailInUse;

  /// Error shown when password strength does not meet backend rules
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Choose a stronger password.'**
  String get registerWeakPassword;

  /// Error shown when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email. Check the format.'**
  String get registerInvalidEmail;

  /// Validation message: email field empty
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get registerEmailRequired;

  /// Validation message: email fails regex
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get registerEmailInvalidFormat;

  /// Validation message: name field empty
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get registerNameRequired;

  /// Validation message: minimum length for name not met
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get registerNameTooShort;

  /// Validation when password and confirmation differ
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordsDoNotMatch;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for password confirmation field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Heading introducing password rules list
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get registerPasswordRequirementsTitle;

  /// Primary action button text to submit registration
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// Call to action linking to login when user already has an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in!'**
  String get registerExistingAccountCta;

  /// Status message while scraper parses initial HTML and metadata
  ///
  /// In en, this message translates to:
  /// **'Extracting product information...'**
  String get scrapingExtractingInfo;

  /// Status message while auto-filling form fields with scraped data
  ///
  /// In en, this message translates to:
  /// **'Filling fields automatically...'**
  String get scrapingFillingFields;

  /// Status message while attempting to fetch the product image
  ///
  /// In en, this message translates to:
  /// **'Loading product image...'**
  String get scrapingLoadingImage;

  /// Message listing which features were successfully extracted. {features} is a comma-separated list of localized feature names.
  ///
  /// In en, this message translates to:
  /// **'Extracted: {features}. Review the data!'**
  String scrapingExtractedPrefix(String features);

  /// Status message after all scraping steps complete
  ///
  /// In en, this message translates to:
  /// **'Done! Review and adjust the data if needed.'**
  String get scrapingCompletedAdjust;

  /// Shown when scraping fails and user must provide data manually
  ///
  /// In en, this message translates to:
  /// **'Error extracting data. Fill manually.'**
  String get scrapingError;

  /// Token name representing the product title feature
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get scrapingFeatureTitle;

  /// Token name representing the product price feature
  ///
  /// In en, this message translates to:
  /// **'price'**
  String get scrapingFeaturePrice;

  /// Token name representing the product description feature
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get scrapingFeatureDescription;

  /// Token name representing the product category feature
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get scrapingFeatureCategory;

  /// Token name representing the product rating feature
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get scrapingFeatureRating;

  /// Token name representing the product image feature
  ///
  /// In en, this message translates to:
  /// **'image'**
  String get scrapingFeatureImage;

  /// Title for screen to add a new item to a wishlist
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemTitle;

  /// Title for screen to edit an existing item
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItemTitle;

  /// Field label prompting user to pick a wishlist in the add item form
  ///
  /// In en, this message translates to:
  /// **'Choose a Wishlist'**
  String get chooseWishlistLabel;

  /// Validation error when no wishlist is selected
  ///
  /// In en, this message translates to:
  /// **'Please choose a wishlist'**
  String get chooseWishlistValidation;

  /// Label for the inline new wishlist name text field
  ///
  /// In en, this message translates to:
  /// **'New wishlist name'**
  String get newWishlistNameLabel;

  /// Validation error when the new wishlist name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the wishlist'**
  String get newWishlistNameRequired;

  /// Button label to create a wishlist from within add/edit item flow
  ///
  /// In en, this message translates to:
  /// **'Create Wishlist'**
  String get createWishlistAction;

  /// Label for item name input
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemNameLabel;

  /// Validation: item name empty
  ///
  /// In en, this message translates to:
  /// **'Item name is required'**
  String get itemNameRequired;

  /// Label for item category input or selector
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Category: Book
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get categoryLivro;

  /// Category: Electronics
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryEletronico;

  /// Category: Travel
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryViagem;

  /// Category: Fashion
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get categoryModa;

  /// Category: Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryCasa;

  /// Category: Other (fallback)
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOutros;

  /// Category: Beauty
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get categoryBeleza;

  /// Category: Health & Fitness
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get categorySaudeFitness;

  /// Category: Toys
  ///
  /// In en, this message translates to:
  /// **'Toys'**
  String get categoryBrinquedos;

  /// Category: Gourmet / Cooking
  ///
  /// In en, this message translates to:
  /// **'Gourmet'**
  String get categoryGourmet;

  /// Category: Gaming
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get categoryGaming;

  /// Category: Music
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusica;

  /// Category: Art & DIY
  ///
  /// In en, this message translates to:
  /// **'Art & DIY'**
  String get categoryArteDIY;

  /// Category: Photography
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get categoryFotografia;

  /// Category: Education
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducacao;

  /// Category: Garden
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get categoryJardim;

  /// Category: Baby
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get categoryBebe;

  /// Category: Experience
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get categoryExperiencia;

  /// Category: Eco / Sustainable
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get categoryEco;

  /// Category: Pet / Animals
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get categoryPet;

  /// Label for item description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescriptionLabel;

  /// Label for item external URL field
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkLabel;

  /// Label for quantity input
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// Validation error when quantity field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity'**
  String get quantityRequired;

  /// Validation error when quantity cannot be parsed or is negative
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get quantityInvalid;

  /// Label campo preço
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// Helper text indicating image was optimized via Cloudinary
  ///
  /// In en, this message translates to:
  /// **'Image optimized by Cloudinary'**
  String get cloudinary_optimized_image;

  /// Prompt shown when user must either select an existing wishlist or create one
  ///
  /// In en, this message translates to:
  /// **'Please select or create a wishlist.'**
  String get selectOrCreateWishlistPrompt;

  /// Error message when backend fails to create wishlist
  ///
  /// In en, this message translates to:
  /// **'Error creating wishlist: {error}'**
  String errorCreatingWishlist(String error);

  /// Error message when fetching existing item for editing fails
  ///
  /// In en, this message translates to:
  /// **'Error loading item: {error}'**
  String errorLoadingItem(String error);

  /// Error message when uploading image to Cloudinary fails
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}'**
  String imageUploadFailed(String error);

  /// Button label to submit the add item form
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addItemAction;

  /// Button label to save changes when editing an item
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveItemAction;

  /// Validation error: email field empty
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Validation error: email format invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// Validation error: email exceeds length limit
  ///
  /// In en, this message translates to:
  /// **'Email too long'**
  String get emailTooLong;

  /// Validation error: email domain part invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email domain'**
  String get emailDomainInvalid;

  /// Validation error: password missing
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Validation error: password shorter than minimum length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// Validation error: password longer than maximum allowed
  ///
  /// In en, this message translates to:
  /// **'Password too long'**
  String get passwordTooLong;

  /// Password rule: need uppercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordNeedUpper;

  /// Password rule: need lowercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordNeedLower;

  /// Password rule: need digit
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordNeedNumber;

  /// Password rule: need special symbol
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordNeedSpecial;

  /// Validation: name empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Validation: name below min length
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// Validation: name above max length
  ///
  /// In en, this message translates to:
  /// **'Name too long'**
  String get nameTooLong;

  /// Validation: name has disallowed chars
  ///
  /// In en, this message translates to:
  /// **'Name contains invalid characters'**
  String get nameInvalidChars;

  /// Validation: phone empty
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// Validation: phone does not match expected pattern
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number (format: 9XXXXXXXX)'**
  String get phoneInvalidFormat;

  /// Validation: URL scheme invalid
  ///
  /// In en, this message translates to:
  /// **'URL must use HTTP or HTTPS'**
  String get urlMustBeHttp;

  /// Validation: URL malformed
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get urlInvalid;

  /// Validation: local/internal URL rejected
  ///
  /// In en, this message translates to:
  /// **'Local URLs are not allowed'**
  String get urlLocalNotAllowed;

  /// Validation: URL exceeds length limit
  ///
  /// In en, this message translates to:
  /// **'URL too long'**
  String get urlTooLong;

  /// Validation: price parse failed
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get priceInvalid;

  /// Validation: price < 0
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative'**
  String get priceNegative;

  /// Validation: price exceeds business max
  ///
  /// In en, this message translates to:
  /// **'Price too high'**
  String get priceTooHigh;

  /// Validation: description length > 500
  ///
  /// In en, this message translates to:
  /// **'Description too long (max 500 characters)'**
  String get descriptionTooLong;

  /// Validation: wishlist name too short
  ///
  /// In en, this message translates to:
  /// **'Wishlist name must be at least 2 characters'**
  String get wishlistNameTooShort;

  /// Validation: wishlist name too long
  ///
  /// In en, this message translates to:
  /// **'Wishlist name too long'**
  String get wishlistNameTooLong;

  /// Validation: item name too short
  ///
  /// In en, this message translates to:
  /// **'Item name must be at least 2 characters'**
  String get itemNameTooShort;

  /// Validation: item name too long
  ///
  /// In en, this message translates to:
  /// **'Item name too long'**
  String get itemNameTooLong;

  /// Validation: image file size exceeds limit
  ///
  /// In en, this message translates to:
  /// **'Image too large (max 10MB)'**
  String get imageTooLarge;

  /// Validation: image extension not allowed
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format (use JPG, PNG or GIF)'**
  String get imageFormatUnsupported;

  /// Validation: OTP code empty
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get otpCodeRequired;

  /// Validation: OTP code length incorrect
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get otpCodeLength;

  /// Validation: OTP code non-digit chars present
  ///
  /// In en, this message translates to:
  /// **'Code must contain only numbers'**
  String get otpCodeDigitsOnly;

  /// Subtitle describing the pt locale variant
  ///
  /// In en, this message translates to:
  /// **'European Portuguese'**
  String get languageSubtitlePtPt;

  /// Subtitle describing the generic international locale
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get languageSubtitleInternational;

  /// Search tab in explore screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// Friends tab in explore screen
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTab;

  /// Invite tab in explore screen
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteTab;

  /// Title for friends discovery
  ///
  /// In en, this message translates to:
  /// **'Discover Friends'**
  String get discoverFriends;

  /// Button to allow contacts access
  ///
  /// In en, this message translates to:
  /// **'Allow Contacts Access'**
  String get allowContactsAccess;

  /// Description of contacts permission
  ///
  /// In en, this message translates to:
  /// **'Allow access to contacts to discover which of your friends already use the app'**
  String get contactsPermissionDescription;

  /// Loading text for friends discovery
  ///
  /// In en, this message translates to:
  /// **'Discovering friends...'**
  String get discoveringFriends;

  /// Loading text for contacts
  ///
  /// In en, this message translates to:
  /// **'Loading contacts...'**
  String get loadingContacts;

  /// Title when no friends found
  ///
  /// In en, this message translates to:
  /// **'No friends found'**
  String get noFriendsFound;

  /// Description when no friends found
  ///
  /// In en, this message translates to:
  /// **'Your contacts who use the app will appear here'**
  String get noFriendsFoundDescription;

  /// Title when all contacts already use the app
  ///
  /// In en, this message translates to:
  /// **'All your contacts already use the app!'**
  String get allFriendsUseApp;

  /// Subtitle when no contacts to invite
  ///
  /// In en, this message translates to:
  /// **'Or you have no contacts to invite'**
  String get noContactsToInvite;

  /// Badge indicating friend
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friendBadge;

  /// Label for contact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// Button to invite contact
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteButton;

  /// Invite subject
  ///
  /// In en, this message translates to:
  /// **'Invitation to WishlistApp'**
  String get inviteSubject;

  /// Play Store message in invite
  ///
  /// In en, this message translates to:
  /// **'📱 Coming soon to Play Store!'**
  String get invitePlayStoreMessage;

  /// Message when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Contacts permission required to discover friends'**
  String get contactsPermissionRequired;

  /// Error requesting permission
  ///
  /// In en, this message translates to:
  /// **'Error requesting permission: {error}'**
  String errorRequestingPermission(Object error);

  /// Error loading contacts
  ///
  /// In en, this message translates to:
  /// **'Error loading contacts: {error}'**
  String errorLoadingContacts(Object error);

  /// Error sending invite
  ///
  /// In en, this message translates to:
  /// **'Error sending invite: {error}'**
  String errorSendingInvite(Object error);

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Active notifications state
  ///
  /// In en, this message translates to:
  /// **'Notifications Active'**
  String get notificationsActive;

  /// Disabled notifications state
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// Notifications enabled status
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// Disabled notifications status with guidance
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled - enable in settings'**
  String get notificationsDisabledGoSettings;

  /// Not requested permission status
  ///
  /// In en, this message translates to:
  /// **'Notification permission not requested'**
  String get notificationsNotRequested;

  /// Silent notifications status
  ///
  /// In en, this message translates to:
  /// **'Silent notifications enabled'**
  String get notificationsSilent;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Notifications activated successfully!'**
  String get notificationsSuccess;

  /// Silent success message
  ///
  /// In en, this message translates to:
  /// **'Silent notifications activated!'**
  String get notificationsSilentSuccess;

  /// Permission denied message
  ///
  /// In en, this message translates to:
  /// **'Notifications denied. You can enable them in settings.'**
  String get notificationsDenied;

  /// Permission not determined message
  ///
  /// In en, this message translates to:
  /// **'Permission not determined. Try again?'**
  String get notificationsNotDetermined;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error requesting notification permissions'**
  String get notificationsError;

  /// Button to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationsActivate;

  /// Loading state
  ///
  /// In en, this message translates to:
  /// **'Requesting...'**
  String get notificationsRequesting;

  /// Button to go to settings
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get notificationsGoSettings;

  /// Button to try again
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get notificationsTryAgain;

  /// Benefits introduction text
  ///
  /// In en, this message translates to:
  /// **'Receive alerts about:'**
  String get notificationsReceiveAlerts;

  /// Benefit - price alerts
  ///
  /// In en, this message translates to:
  /// **'Price drops on your items'**
  String get notificationsBenefitPriceDrops;

  /// Benefit - shares
  ///
  /// In en, this message translates to:
  /// **'New list shares'**
  String get notificationsBenefitShares;

  /// Benefit - favorites
  ///
  /// In en, this message translates to:
  /// **'New favorites'**
  String get notificationsBenefitFavorites;

  /// Benefit - hints
  ///
  /// In en, this message translates to:
  /// **'Gift hints'**
  String get notificationsBenefitGiftHints;

  /// Instructions to enable in settings
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Apps > WishlistApp > Notifications to enable manually'**
  String get notificationsSettingsInstructions;

  /// Button to retry contacts permission request
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get contactsPermissionTryAgain;

  /// Button to open app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get contactsPermissionSettings;

  /// Message instructing user to enable permission manually
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Apps > WishlistApp > Permissions to enable manually'**
  String get contactsPermissionManual;

  /// Error message when contacts permission was revoked
  ///
  /// In en, this message translates to:
  /// **'Contacts permission was revoked. Try again.'**
  String get contactsPermissionRevoked;

  /// Menu action to enable incremental (streaming) contacts discovery
  ///
  /// In en, this message translates to:
  /// **'Enable incremental contacts'**
  String get enableIncrementalContacts;

  /// Menu action to disable incremental (streaming) contacts discovery
  ///
  /// In en, this message translates to:
  /// **'Disable incremental contacts'**
  String get disableIncrementalContacts;

  /// Generic search label/tab text (fallback)
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Generic contacts label/tab text (fallback)
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;
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
