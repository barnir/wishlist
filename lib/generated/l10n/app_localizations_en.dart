// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String get deleteAccountConfirmation => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action is irreversible. All your data will be lost. To confirm, type \"DELETE\" in the box below.';

  @override
  String get confirm => 'Confirm';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully.';

  @override
  String errorDeletingAccount(String error) {
    return 'Error deleting account: $error';
  }

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

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String errorLoadingWishlists(String error) {
    return 'Error loading wishlists: $error';
  }

  @override
  String get noWishlistsYetTitle => 'No wishlists yet';

  @override
  String get noWishlistsYetSubtitle => 'Tap \"+\" to create your first!';

  @override
  String get pleaseLoginToSeeWishlists =>
      'Please log in to see your wishlists.';

  @override
  String get loadingWishlists => 'Loading wishlists...';

  @override
  String get addNewWishlistTooltip => 'Add new wishlist';

  @override
  String get publicWishlistsTab => 'Public Wishlists';

  @override
  String get aboutTab => 'About';

  @override
  String get noPublicWishlists => 'No public wishlist';

  @override
  String get noPublicWishlistsSubtitle =>
      'This user doesn\'t have public wishlists yet.';

  @override
  String get publicLabel => 'Public';

  @override
  String get privateLabel => 'Private';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get loadingFavorites => 'Loading favorites...';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Explore profiles and mark favorites to see their public wishlists!';

  @override
  String get searchProfilesTooltip => 'Search profiles';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get searchUsersPlaceholder => 'Search users...';

  @override
  String get searchUsersTitle => 'Search users';

  @override
  String get searchUsersSubtitle =>
      'Type a name or email to find users and their public wishlists.';

  @override
  String get searching => 'Searching...';

  @override
  String get noResults => 'No results';

  @override
  String get noResultsSubtitle => 'No users found for that term.';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get loadingMoreWishlists => 'Loading more wishlists...';

  @override
  String get loadingMoreFavorites => 'Loading more favorites...';

  @override
  String get loadingMoreResults => 'Loading more results...';

  @override
  String get loadingWishlist => 'Loading wishlist...';

  @override
  String get loadingItems => 'Loading items...';

  @override
  String get loadingMoreItems => 'Loading more items...';

  @override
  String get wishlistIsPrivate => 'This wishlist is private';

  @override
  String get wishlistIsPublic => 'This wishlist is public';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get noWishlistFoundCreateNew => 'No wishlist found. Create a new one.';

  @override
  String get privateWishlist => 'Private Wishlist';

  @override
  String errorLoadingFavorites(Object error) {
    return 'Error loading favorites: $error';
  }

  @override
  String errorLoadingResults(Object error) {
    return 'Error loading results: $error';
  }

  @override
  String get createWishlistTitle => 'Create Wishlist';

  @override
  String get editWishlistTitle => 'Edit Wishlist';

  @override
  String get wishlistDetailsSection => 'Wishlist Details';

  @override
  String get wishlistImageSection => 'Wishlist Image';

  @override
  String errorSavingWishlist(Object error) {
    return 'Error saving wishlist: $error';
  }

  @override
  String get wishlistEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistEmptySubtitle =>
      'Tap the + button to add your first item.';

  @override
  String get addNewItemTooltip => 'Add new item';

  @override
  String get favoriteBadge => 'FAVORITE';

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get publicProfileBadge => 'Public profile';

  @override
  String get privateProfileBadge => 'Private profile';

  @override
  String get filterAndSortTooltip => 'Filter & Sort';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get view => 'View';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get deleteItemTooltip => 'Delete item';

  @override
  String get deleteItemTitle => 'Delete item';

  @override
  String deleteItemConfirmation(Object itemName) {
    return 'Are you sure you want to delete \"$itemName\"?';
  }

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get processingImage => 'Processing...';

  @override
  String get recommendedImageSize => 'Recommended: 400x400px or higher';

  @override
  String get wishlistNameLabel => 'Wishlist Name';

  @override
  String get wishlistNameHint => 'Enter your wishlist name';

  @override
  String get wishlistNameRequired => 'Wishlist name is required';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get privateWishlistSubtitle => 'Only you can see this wishlist';

  @override
  String get publicWishlistSubtitle => 'Other users can see this wishlist';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addedToFavorites => 'Added to favorites!';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get contactSuggestionsTitle => 'Contact Suggestions';

  @override
  String get loadingSuggestions => 'Loading suggestions...';

  @override
  String get noSuggestionsTitle => 'No suggestions';

  @override
  String get noSuggestionsSubtitle =>
      'No app users were found in your contacts.';

  @override
  String get contactsAccessTitle => 'Contacts Access';

  @override
  String get contactsAccessExplanation =>
      'To find friends from your contacts who already use the app, we need access to your contacts list.';

  @override
  String get grantContactsAccess => 'Allow Contacts Access';

  @override
  String get viewProfile => 'View profile';

  @override
  String get profileNotFoundTitle => 'Profile not found';

  @override
  String get profileNotFoundSubtitle => 'This user may have been removed.';

  @override
  String get shareProfileTooltip => 'Share profile';

  @override
  String get profileInfoSectionTitle => 'Profile Information';

  @override
  String get memberSinceLabel => 'Member since';

  @override
  String get recentlyLabel => 'Recently';

  @override
  String get otpVerifyTitle => 'Verify Code';

  @override
  String otpInstructionPhone(Object phone) {
    return 'Enter the 6-digit code sent to $phone.';
  }

  @override
  String get otpAutoDetectNote => 'Firebase will automatically detect the SMS.';

  @override
  String get otpInvalidCode => 'Invalid code. Try again.';

  @override
  String get otpCodeExpired => 'Code expired. Resend the code.';

  @override
  String get otpPhoneInUse => 'Phone already linked to another account.';

  @override
  String get otpInternalError => 'Internal error. Try again.';

  @override
  String get otpCodeResent => 'Code resent.';

  @override
  String get otpResend => 'Resend Code';

  @override
  String otpResendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String shareProfileMessage(Object link) {
    return 'Check my profile on Wishlist App: $link';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Error loading profile: $error';
  }

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get automatic => 'Automatic';

  @override
  String get systemLanguage => 'Follow system language';

  @override
  String get language => 'Language';

  @override
  String get themeSettings => 'App Theme';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeLightSubtitle => 'Always use the light theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get themeDarkSubtitle => 'Always use the dark theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeSystemSubtitle => 'Follow system setting';

  @override
  String get close => 'Close';

  @override
  String get registerTitle => 'Register new account';

  @override
  String get registerErrorPrefix => 'Registration error: ';

  @override
  String get registerSystemError => 'System error. Please try again.';

  @override
  String get registerEmailInUse =>
      'This email is already in use. Try logging in.';

  @override
  String get registerWeakPassword =>
      'Password is too weak. Choose a stronger password.';

  @override
  String get registerInvalidEmail => 'Invalid email. Check the format.';

  @override
  String get registerEmailRequired => 'Email required';

  @override
  String get registerEmailInvalidFormat => 'Invalid email format';

  @override
  String get registerNameRequired => 'Name required';

  @override
  String get registerNameTooShort => 'Name too short';

  @override
  String get registerPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get registerPasswordRequirementsTitle => 'Password requirements:';

  @override
  String get registerAction => 'Register';

  @override
  String get registerExistingAccountCta => 'Already have an account? Log in!';

  @override
  String get scrapingExtractingInfo => 'Extracting product information...';

  @override
  String get scrapingFillingFields => 'Filling fields automatically...';

  @override
  String get scrapingLoadingImage => 'Loading product image...';

  @override
  String scrapingExtractedPrefix(String features) {
    return 'Extracted: $features. Review the data!';
  }

  @override
  String get scrapingCompletedAdjust =>
      'Done! Review and adjust the data if needed.';

  @override
  String get scrapingError => 'Error extracting data. Fill manually.';

  @override
  String get scrapingFeatureTitle => 'title';

  @override
  String get scrapingFeaturePrice => 'price';

  @override
  String get scrapingFeatureDescription => 'description';

  @override
  String get scrapingFeatureCategory => 'category';

  @override
  String get scrapingFeatureRating => 'rating';

  @override
  String get scrapingFeatureImage => 'image';

  @override
  String get addItemTitle => 'Add Item';

  @override
  String get editItemTitle => 'Edit Item';

  @override
  String get chooseWishlistLabel => 'Choose a Wishlist';

  @override
  String get chooseWishlistValidation => 'Please choose a wishlist';

  @override
  String get newWishlistNameLabel => 'New wishlist name';

  @override
  String get newWishlistNameRequired => 'Enter a name for the wishlist';

  @override
  String get createWishlistAction => 'Create Wishlist';

  @override
  String get itemNameLabel => 'Item Name';

  @override
  String get itemNameRequired => 'Item name is required';

  @override
  String get categoryLabel => 'Category';

  @override
  String get itemDescriptionLabel => 'Description';

  @override
  String get linkLabel => 'Link';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get quantityRequired => 'Enter the quantity';

  @override
  String get quantityInvalid => 'Invalid quantity';

  @override
  String get priceLabel => 'Price';

  @override
  String get priceInvalid => 'Invalid price';

  @override
  String get selectOrCreateWishlistPrompt =>
      'Please select or create a wishlist.';

  @override
  String errorCreatingWishlist(String error) {
    return 'Error creating wishlist: $error';
  }

  @override
  String errorLoadingItem(String error) {
    return 'Error loading item: $error';
  }

  @override
  String imageUploadFailed(String error) {
    return 'Image upload failed: $error';
  }

  @override
  String get addItemAction => 'Add';

  @override
  String get saveItemAction => 'Save';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get emailTooLong => 'Email too long';

  @override
  String get emailDomainInvalid => 'Invalid email domain';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordTooLong => 'Password too long';

  @override
  String get passwordNeedUpper =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordNeedLower =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordNeedNumber => 'Password must contain at least one number';

  @override
  String get passwordNeedSpecial =>
      'Password must contain at least one special character';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get nameTooLong => 'Name too long';

  @override
  String get nameInvalidChars => 'Name contains invalid characters';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalidFormat => 'Invalid phone number (format: 9XXXXXXXX)';

  @override
  String get urlMustBeHttp => 'URL must use HTTP or HTTPS';

  @override
  String get urlInvalid => 'Invalid URL';

  @override
  String get urlLocalNotAllowed => 'Local URLs are not allowed';

  @override
  String get urlTooLong => 'URL too long';

  @override
  String get priceNegative => 'Price cannot be negative';

  @override
  String get priceTooHigh => 'Price too high';

  @override
  String get descriptionTooLong => 'Description too long (max 500 characters)';

  @override
  String get wishlistNameTooShort =>
      'Wishlist name must be at least 2 characters';

  @override
  String get wishlistNameTooLong => 'Wishlist name too long';

  @override
  String get itemNameTooShort => 'Item name must be at least 2 characters';

  @override
  String get itemNameTooLong => 'Item name too long';

  @override
  String get imageTooLarge => 'Image too large (max 10MB)';

  @override
  String get imageFormatUnsupported =>
      'Unsupported image format (use JPG, PNG or GIF)';

  @override
  String get otpCodeRequired => 'Code is required';

  @override
  String get otpCodeLength => 'Code must be 6 digits';

  @override
  String get otpCodeDigitsOnly => 'Code must contain only numbers';

  @override
  String get languageSubtitlePtPt => 'European Portuguese';

  @override
  String get languageSubtitleInternational => 'International';
}
