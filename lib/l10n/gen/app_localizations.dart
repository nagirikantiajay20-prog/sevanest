import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SevaNest'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Verified Help. Trusted Homes.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navFavourites.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get navFavourites;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @emptyDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyDefaultTitle;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach SevaNest. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errorForbidden;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Our servers are having trouble. Please try again shortly.'**
  String get errorServer;

  /// No description provided for @staleBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing earlier data. Couldn\'t refresh.'**
  String get staleBanner;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationInProgress;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Trusted help for your home'**
  String get splashTagline;

  /// No description provided for @splashTaglineHi.
  ///
  /// In en, this message translates to:
  /// **'आपके घर का भरोसेमंद साथी'**
  String get splashTaglineHi;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready...'**
  String get splashLoading;

  /// No description provided for @splashSlow.
  ///
  /// In en, this message translates to:
  /// **'Still loading. Your connection seems slow.'**
  String get splashSlow;

  /// No description provided for @splashFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect right now'**
  String get splashFailedTitle;

  /// No description provided for @splashFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet and try again.'**
  String get splashFailedBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgain;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @supportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Support contact isn\'t available right now.'**
  String get supportUnavailable;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @trustVerifiedWorkers.
  ///
  /// In en, this message translates to:
  /// **'Verified workers'**
  String get trustVerifiedWorkers;

  /// No description provided for @trustSecurePayments.
  ///
  /// In en, this message translates to:
  /// **'Secure payments'**
  String get trustSecurePayments;

  /// No description provided for @trustHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get trustHelpSupport;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SevaNest'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find verified, trusted help for your home.'**
  String get loginSubtitle;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up'**
  String get loginHeading;

  /// No description provided for @loginHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a {digits}-digit code to verify your number.'**
  String loginHelp(int digits);

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileLabel;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'98765 43210'**
  String get mobileHint;

  /// No description provided for @mobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get mobileInvalid;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @sendingCode.
  ///
  /// In en, this message translates to:
  /// **'Sending code...'**
  String get sendingCode;

  /// No description provided for @sendFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the code'**
  String get sendFailedTitle;

  /// No description provided for @sendFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and tap Get OTP again.'**
  String get sendFailedNetwork;

  /// No description provided for @rateLimitedWait.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again in {time}.'**
  String rateLimitedWait(String time);

  /// No description provided for @secureAndPrivate.
  ///
  /// In en, this message translates to:
  /// **'Secure & private'**
  String get secureAndPrivate;

  /// No description provided for @trustOtpLogin.
  ///
  /// In en, this message translates to:
  /// **'OTP-secured login'**
  String get trustOtpLogin;

  /// No description provided for @trustNumberPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your number stays private'**
  String get trustNumberPrivate;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get legalPrefix;

  /// No description provided for @legalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalAnd;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t available yet.'**
  String get linkUnavailable;

  /// No description provided for @languageButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageButtonLabel;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get chooseLanguageHint;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpTitle;

  /// No description provided for @otpEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the {digits}-digit code we sent to'**
  String otpEnterCode(int digits);

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendIn(String time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @otpDidntGet.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Check your number or try again.'**
  String get otpDidntGet;

  /// No description provided for @verifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get verifyContinue;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @numberVerified.
  ///
  /// In en, this message translates to:
  /// **'Number verified'**
  String get numberVerified;

  /// No description provided for @otpWrong.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t correct. Please try again.'**
  String get otpWrong;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get tooManyAttempts;

  /// No description provided for @tooManyWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait {minutes} minutes or contact support.'**
  String tooManyWait(int minutes);

  /// No description provided for @otpFooter.
  ///
  /// In en, this message translates to:
  /// **'We never share your number. This code expires in {minutes} minutes.'**
  String otpFooter(int minutes);

  /// No description provided for @otpSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Code sent again'**
  String get otpSentAgain;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @profileStep.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3'**
  String get profileStep;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes less than a minute.'**
  String get profileSetupSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Priya Sharma'**
  String get fullNameHint;

  /// No description provided for @fullNameHelp.
  ///
  /// In en, this message translates to:
  /// **'As you\'d like workers to address you.'**
  String get fullNameHelp;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your name (2–60 letters)'**
  String get nameInvalid;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @emailHelp.
  ///
  /// In en, this message translates to:
  /// **'For receipts and booking updates.'**
  String get emailHelp;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email like name@example.com'**
  String get emailInvalid;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @ageConfirm.
  ///
  /// In en, this message translates to:
  /// **'By continuing you confirm you\'re 18 or older.'**
  String get ageConfirm;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileMobileLocked.
  ///
  /// In en, this message translates to:
  /// **'Your number is your login and can\'t be changed here.'**
  String get profileMobileLocked;

  /// No description provided for @verificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationLabel;

  /// No description provided for @addressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get addressesTitle;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @editAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddressTitle;

  /// No description provided for @addFirstAddress.
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get addFirstAddress;

  /// No description provided for @addFirstAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'We need it to find workers near you.'**
  String get addFirstAddressHelp;

  /// No description provided for @houseLabel.
  ///
  /// In en, this message translates to:
  /// **'House / flat no.'**
  String get houseLabel;

  /// No description provided for @houseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flat 402'**
  String get houseHint;

  /// No description provided for @streetLabel.
  ///
  /// In en, this message translates to:
  /// **'Building or street'**
  String get streetLabel;

  /// No description provided for @streetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sai Residency'**
  String get streetHint;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @areaHint.
  ///
  /// In en, this message translates to:
  /// **'Select your area'**
  String get areaHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincodeLabel;

  /// No description provided for @pincodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get pincodeHint;

  /// No description provided for @pincodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit pincode'**
  String get pincodeInvalid;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @alreadyDefault.
  ///
  /// In en, this message translates to:
  /// **'This is your default address.'**
  String get alreadyDefault;

  /// No description provided for @defaultTag.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTag;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete address'**
  String get deleteAddress;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your saved addresses.'**
  String get deleteConfirmBody;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressSaved;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @defaultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default address updated'**
  String get defaultUpdated;

  /// No description provided for @addressInUse.
  ///
  /// In en, this message translates to:
  /// **'This address is used by an active booking.'**
  String get addressInUse;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'This address isn\'t available any more.'**
  String get addressNotFound;

  /// No description provided for @chooseArea.
  ///
  /// In en, this message translates to:
  /// **'Choose your area'**
  String get chooseArea;

  /// No description provided for @areasUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load areas. You can type your area instead.'**
  String get areasUnavailable;

  /// No description provided for @addressMenu.
  ///
  /// In en, this message translates to:
  /// **'Address options'**
  String get addressMenu;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get homeGreetingNoName;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What help do you need today?'**
  String get homeSubtitle;

  /// No description provided for @homeHeroCook.
  ///
  /// In en, this message translates to:
  /// **'Verified cooks near you'**
  String get homeHeroCook;

  /// No description provided for @homeHeroDriver.
  ///
  /// In en, this message translates to:
  /// **'Trusted drivers near you'**
  String get homeHeroDriver;

  /// No description provided for @homeHeroMaid.
  ///
  /// In en, this message translates to:
  /// **'Reliable maids near you'**
  String get homeHeroMaid;

  /// No description provided for @homePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get homePause;

  /// No description provided for @homePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get homePlay;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeNotificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String homeNotificationsUnread(int count);

  /// No description provided for @homeFindWorkerCta.
  ///
  /// In en, this message translates to:
  /// **'Find a worker for your home'**
  String get homeFindWorkerCta;

  /// No description provided for @homeAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get homeAddAddress;

  /// No description provided for @homeAddressBanner.
  ///
  /// In en, this message translates to:
  /// **'Add an address to find workers'**
  String get homeAddressBanner;

  /// No description provided for @homeOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing saved info.'**
  String get homeOffline;

  /// No description provided for @homeLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your home'**
  String get homeLoadFailedTitle;

  /// No description provided for @homeLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get homeLoadFailedBody;

  /// No description provided for @homeActivity.
  ///
  /// In en, this message translates to:
  /// **'Your activity'**
  String get homeActivity;

  /// No description provided for @homeStageInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get homeStageInProgress;

  /// No description provided for @homeBookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking #{ref}'**
  String homeBookingRef(String ref);

  /// No description provided for @homeStageMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get homeStageMatched;

  /// No description provided for @homeStageTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get homeStageTrial;

  /// No description provided for @homeStageActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get homeStageActive;

  /// No description provided for @homeViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get homeViewBooking;

  /// No description provided for @homeInterviewWith.
  ///
  /// In en, this message translates to:
  /// **'Interview with {name}'**
  String homeInterviewWith(String name);

  /// No description provided for @homeTrialVisitWith.
  ///
  /// In en, this message translates to:
  /// **'Trial visit with {name}'**
  String homeTrialVisitWith(String name);

  /// No description provided for @homeVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get homeVideoCall;

  /// No description provided for @homeTrialVisit.
  ///
  /// In en, this message translates to:
  /// **'Trial visit'**
  String get homeTrialVisit;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTomorrow;

  /// No description provided for @homeStartsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in {n} min'**
  String homeStartsInMinutes(int n);

  /// No description provided for @homeStartsInHours.
  ///
  /// In en, this message translates to:
  /// **'Starts in {n, plural, =1{1 hour} other{{n} hours}}'**
  String homeStartsInHours(int n);

  /// No description provided for @homeStartsInDays.
  ///
  /// In en, this message translates to:
  /// **'Starts in {n, plural, =1{1 day} other{{n} days}}'**
  String homeStartsInDays(int n);

  /// No description provided for @homeStartingNow.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get homeStartingNow;

  /// No description provided for @homeNoBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get homeNoBookingsTitle;

  /// No description provided for @homeNoBookingsBody.
  ///
  /// In en, this message translates to:
  /// **'Find your first trusted worker in 3 simple steps'**
  String get homeNoBookingsBody;

  /// No description provided for @homeStep1.
  ///
  /// In en, this message translates to:
  /// **'Tell us what help you need'**
  String get homeStep1;

  /// No description provided for @homeStep2.
  ///
  /// In en, this message translates to:
  /// **'Meet verified workers near you'**
  String get homeStep2;

  /// No description provided for @homeStep3.
  ///
  /// In en, this message translates to:
  /// **'Book a trial with confidence'**
  String get homeStep3;

  /// No description provided for @homeFindWorker.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get homeFindWorker;

  /// No description provided for @homeShortlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist'**
  String get homeShortlistTitle;

  /// No description provided for @homeViewShortlist.
  ///
  /// In en, this message translates to:
  /// **'View shortlist'**
  String get homeViewShortlist;

  /// No description provided for @homeSupportShortcut.
  ///
  /// In en, this message translates to:
  /// **'Need help with something?'**
  String get homeSupportShortcut;

  /// No description provided for @homeSupportShortcutBody.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here for you.'**
  String get homeSupportShortcutBody;

  /// No description provided for @devMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer menu'**
  String get devMenuTitle;

  /// No description provided for @devMenuApiMode.
  ///
  /// In en, this message translates to:
  /// **'API behaviour'**
  String get devMenuApiMode;

  /// No description provided for @devMenuUser.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get devMenuUser;

  /// No description provided for @devMenuReturning.
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get devMenuReturning;

  /// No description provided for @devMenuNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get devMenuNew;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
