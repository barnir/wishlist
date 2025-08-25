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
}
