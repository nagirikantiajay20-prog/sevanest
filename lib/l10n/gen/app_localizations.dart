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

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get discoverTitle;

  /// No description provided for @discoverStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String discoverStep(int n, int total);

  /// No description provided for @discoverContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get discoverContinue;

  /// No description provided for @discoverContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {what}'**
  String discoverContinueWith(String what);

  /// No description provided for @discoverClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get discoverClose;

  /// No description provided for @discoverDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this request?'**
  String get discoverDiscardTitle;

  /// No description provided for @discoverDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers so far will be cleared.'**
  String get discoverDiscardBody;

  /// No description provided for @discoverDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discoverDiscard;

  /// No description provided for @discoverKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discoverKeepEditing;

  /// No description provided for @discoverChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get discoverChange;

  /// No description provided for @discoverLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get discoverLoadFailedBody;

  /// No description provided for @serviceHeading.
  ///
  /// In en, this message translates to:
  /// **'What kind of help do you need?'**
  String get serviceHeading;

  /// No description provided for @serviceSub.
  ///
  /// In en, this message translates to:
  /// **'Pick one. You can search again for other services anytime.'**
  String get serviceSub;

  /// No description provided for @serviceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get serviceSearchHint;

  /// No description provided for @servicePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get servicePopular;

  /// No description provided for @serviceLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load services'**
  String get serviceLoadFailedTitle;

  /// No description provided for @serviceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No services available right now'**
  String get serviceEmptyTitle;

  /// No description provided for @serviceNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No services match “{q}”'**
  String serviceNoMatch(String q);

  /// No description provided for @serviceNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different word or choose something else.'**
  String get serviceNoMatchBody;

  /// No description provided for @serviceClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get serviceClearSearch;

  /// No description provided for @engagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Engagement type'**
  String get engagementTitle;

  /// No description provided for @engagementHeading.
  ///
  /// In en, this message translates to:
  /// **'How do you need them to work?'**
  String get engagementHeading;

  /// No description provided for @engagementSub.
  ///
  /// In en, this message translates to:
  /// **'Choose the arrangement that suits your home. You can compare options later.'**
  String get engagementSub;

  /// No description provided for @engagementLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load options'**
  String get engagementLoadFailedTitle;

  /// No description provided for @engFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get engFullTime;

  /// No description provided for @engFullTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Works fixed hours every day at your home.'**
  String get engFullTimeDesc;

  /// No description provided for @engFullTimeMeta.
  ///
  /// In en, this message translates to:
  /// **'6 to 10 hours · Most days'**
  String get engFullTimeMeta;

  /// No description provided for @engPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get engPartTime;

  /// No description provided for @engPartTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'A few set hours each day, such as mornings.'**
  String get engPartTimeDesc;

  /// No description provided for @engPartTimeMeta.
  ///
  /// In en, this message translates to:
  /// **'2 to 5 hours · Most days'**
  String get engPartTimeMeta;

  /// No description provided for @engDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get engDaily;

  /// No description provided for @engDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Comes on the days you choose, for a set job.'**
  String get engDailyDesc;

  /// No description provided for @engDailyMeta.
  ///
  /// In en, this message translates to:
  /// **'Pick your days each week'**
  String get engDailyMeta;

  /// No description provided for @engHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get engHourly;

  /// No description provided for @engHourlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay by the hour for short or one-off jobs.'**
  String get engHourlyDesc;

  /// No description provided for @engHourlyMeta.
  ///
  /// In en, this message translates to:
  /// **'Book by the hour'**
  String get engHourlyMeta;

  /// No description provided for @engLiveIn.
  ///
  /// In en, this message translates to:
  /// **'Live-in'**
  String get engLiveIn;

  /// No description provided for @engLiveInDesc.
  ///
  /// In en, this message translates to:
  /// **'Stays at your home with food and a room.'**
  String get engLiveInDesc;

  /// No description provided for @engLiveInMeta.
  ///
  /// In en, this message translates to:
  /// **'Stays on site'**
  String get engLiveInMeta;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @locationHeading.
  ///
  /// In en, this message translates to:
  /// **'Where do you need help?'**
  String get locationHeading;

  /// No description provided for @locationSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show workers who serve this area.'**
  String get locationSub;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationUseCurrent;

  /// No description provided for @locationUseCurrentSub.
  ///
  /// In en, this message translates to:
  /// **'Uses GPS, only while you use the app'**
  String get locationUseCurrentSub;

  /// No description provided for @locationFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get locationFinding;

  /// No description provided for @locationFindingSub.
  ///
  /// In en, this message translates to:
  /// **'This takes a few seconds'**
  String get locationFindingSub;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get locationSaved;

  /// No description provided for @locationSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} saved'**
  String locationSavedCount(int n);

  /// No description provided for @locationOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access is off'**
  String get locationOffTitle;

  /// No description provided for @locationOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings, or choose a saved address.'**
  String get locationOffBody;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @locationChooseSaved.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved address'**
  String get locationChooseSaved;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Choose a saved address instead.'**
  String get locationFailed;

  /// No description provided for @locationNoAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get locationNoAddressTitle;

  /// No description provided for @locationNoAddressBody.
  ///
  /// In en, this message translates to:
  /// **'We need it to find workers near you.'**
  String get locationNoAddressBody;

  /// No description provided for @locationLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your addresses'**
  String get locationLoadFailedTitle;

  /// No description provided for @locationContinueTo.
  ///
  /// In en, this message translates to:
  /// **'Continue to {area}'**
  String locationContinueTo(String area);

  /// No description provided for @locationMakeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make default'**
  String get locationMakeDefault;

  /// No description provided for @timingTitle.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timingTitle;

  /// No description provided for @timingHeading.
  ///
  /// In en, this message translates to:
  /// **'When do you need them?'**
  String get timingHeading;

  /// No description provided for @timingSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a time window. You\'ll agree exact timings in the interview.'**
  String get timingSub;

  /// No description provided for @timingLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load timing options'**
  String get timingLoadFailedTitle;

  /// No description provided for @timingWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred time of day'**
  String get timingWindowLabel;

  /// No description provided for @winEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning'**
  String get winEarlyMorning;

  /// No description provided for @winMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get winMorning;

  /// No description provided for @winAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get winAfternoon;

  /// No description provided for @winEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get winEvening;

  /// No description provided for @winNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get winNight;

  /// No description provided for @winFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get winFlexible;

  /// No description provided for @winFlexibleRange.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get winFlexibleRange;

  /// No description provided for @winEarlyMorningPlural.
  ///
  /// In en, this message translates to:
  /// **'Early mornings'**
  String get winEarlyMorningPlural;

  /// No description provided for @winMorningPlural.
  ///
  /// In en, this message translates to:
  /// **'Mornings'**
  String get winMorningPlural;

  /// No description provided for @winAfternoonPlural.
  ///
  /// In en, this message translates to:
  /// **'Afternoons'**
  String get winAfternoonPlural;

  /// No description provided for @winEveningPlural.
  ///
  /// In en, this message translates to:
  /// **'Evenings'**
  String get winEveningPlural;

  /// No description provided for @winNightPlural.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get winNightPlural;

  /// No description provided for @timingShiftHours.
  ///
  /// In en, this message translates to:
  /// **'Shift hours'**
  String get timingShiftHours;

  /// No description provided for @timingExactHours.
  ///
  /// In en, this message translates to:
  /// **'Exact hours'**
  String get timingExactHours;

  /// No description provided for @timingStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get timingStartTime;

  /// No description provided for @timingEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get timingEndTime;

  /// No description provided for @timingPickTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get timingPickTime;

  /// No description provided for @timingHoursPerDay.
  ///
  /// In en, this message translates to:
  /// **'{d} per day'**
  String timingHoursPerDay(String d);

  /// No description provided for @timingHoursPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours per day'**
  String get timingHoursPerDayLabel;

  /// No description provided for @timingHoursChip.
  ///
  /// In en, this message translates to:
  /// **'{n} hrs'**
  String timingHoursChip(int n);

  /// No description provided for @timingDays.
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get timingDays;

  /// No description provided for @daysEvery.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get daysEvery;

  /// No description provided for @daysWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get daysWeekdays;

  /// No description provided for @daysWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get daysWeekends;

  /// No description provided for @daysRange.
  ///
  /// In en, this message translates to:
  /// **'{a} to {b}'**
  String daysRange(String a, String b);

  /// No description provided for @timingDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get timingDate;

  /// No description provided for @timingChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get timingChooseDate;

  /// No description provided for @durHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour} other{{n} hours}}'**
  String durHours(num n);

  /// No description provided for @durMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String durMinutes(int n);

  /// No description provided for @timingErrEnd.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time.'**
  String get timingErrEnd;

  /// No description provided for @timingErrShort.
  ///
  /// In en, this message translates to:
  /// **'Choose at least {d}.'**
  String timingErrShort(String d);

  /// No description provided for @timingErrLong.
  ///
  /// In en, this message translates to:
  /// **'A shift can be at most {d}.'**
  String timingErrLong(String d);

  /// No description provided for @timingErrDays.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one day.'**
  String get timingErrDays;

  /// No description provided for @timingErrDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date.'**
  String get timingErrDate;

  /// No description provided for @timingEditSummary.
  ///
  /// In en, this message translates to:
  /// **'Edit times and days'**
  String get timingEditSummary;

  /// No description provided for @timeSheetSub.
  ///
  /// In en, this message translates to:
  /// **'In 15-minute steps'**
  String get timeSheetSub;

  /// No description provided for @timeSheetSet.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get timeSheetSet;

  /// No description provided for @timeSheetHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get timeSheetHour;

  /// No description provided for @timeSheetMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get timeSheetMinute;

  /// No description provided for @timeSheetPeriod.
  ///
  /// In en, this message translates to:
  /// **'AM or PM'**
  String get timeSheetPeriod;

  /// No description provided for @dateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get dateSheetTitle;

  /// No description provided for @dateSheetSet.
  ///
  /// In en, this message translates to:
  /// **'Set date: {date}'**
  String dateSheetSet(String date);

  /// No description provided for @dateSheetPick.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get dateSheetPick;

  /// No description provided for @startTitle.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startTitle;

  /// No description provided for @startHeading.
  ///
  /// In en, this message translates to:
  /// **'When should they start?'**
  String get startHeading;

  /// No description provided for @startSub.
  ///
  /// In en, this message translates to:
  /// **'Pick the first day. Workers will confirm they are free.'**
  String get startSub;

  /// No description provided for @startTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {date}'**
  String startTomorrow(String date);

  /// No description provided for @startInDays.
  ///
  /// In en, this message translates to:
  /// **'In {n} days, {date}'**
  String startInDays(int n, String date);

  /// No description provided for @startNextMonday.
  ///
  /// In en, this message translates to:
  /// **'Next Monday, {date}'**
  String startNextMonday(String date);

  /// No description provided for @startPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get startPickAnother;

  /// No description provided for @startLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load available dates'**
  String get startLoadFailedTitle;

  /// No description provided for @startLimitNote.
  ///
  /// In en, this message translates to:
  /// **'You can start up to {n} days from today (by {date}).'**
  String startLimitNote(int n, String date);

  /// No description provided for @startOutsideTitle.
  ///
  /// In en, this message translates to:
  /// **'{date} isn\'t one of your selected days'**
  String startOutsideTitle(String date);

  /// No description provided for @startOutsideBody.
  ///
  /// In en, this message translates to:
  /// **'You chose {days}. You can continue anyway, or adjust your days.'**
  String startOutsideBody(String days);

  /// No description provided for @startAdjustDays.
  ///
  /// In en, this message translates to:
  /// **'Adjust days'**
  String get startAdjustDays;

  /// No description provided for @calPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calPrev;

  /// No description provided for @calNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calNext;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @budgetHeading.
  ///
  /// In en, this message translates to:
  /// **'What\'s your budget?'**
  String get budgetHeading;

  /// No description provided for @budgetSubMonthly.
  ///
  /// In en, this message translates to:
  /// **'Set a range per month. You\'ll see exact prices before you book.'**
  String get budgetSubMonthly;

  /// No description provided for @budgetSubHourly.
  ///
  /// In en, this message translates to:
  /// **'Set a range per hour. You\'ll see exact prices before you book.'**
  String get budgetSubHourly;

  /// No description provided for @budgetPerMonth.
  ///
  /// In en, this message translates to:
  /// **'₹ per month'**
  String get budgetPerMonth;

  /// No description provided for @budgetPerHour.
  ///
  /// In en, this message translates to:
  /// **'₹ per hour'**
  String get budgetPerHour;

  /// No description provided for @guidanceTypical.
  ///
  /// In en, this message translates to:
  /// **'Typical for a {engagement} {service} in {city}'**
  String guidanceTypical(String engagement, String service, String city);

  /// No description provided for @budgetRangePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{range} per month'**
  String budgetRangePerMonth(String range);

  /// No description provided for @budgetRangePerHour.
  ///
  /// In en, this message translates to:
  /// **'{range} per hour'**
  String budgetRangePerHour(String range);

  /// No description provided for @guidanceUse.
  ///
  /// In en, this message translates to:
  /// **'Use this range'**
  String get guidanceUse;

  /// No description provided for @guidanceErrTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load price guidance'**
  String get guidanceErrTitle;

  /// No description provided for @guidanceErrBody.
  ///
  /// In en, this message translates to:
  /// **'You can still enter a range below.'**
  String get guidanceErrBody;

  /// No description provided for @budgetMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get budgetMinimum;

  /// No description provided for @budgetMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get budgetMaximum;

  /// No description provided for @budgetMinField.
  ///
  /// In en, this message translates to:
  /// **'Minimum (₹)'**
  String get budgetMinField;

  /// No description provided for @budgetMaxField.
  ///
  /// In en, this message translates to:
  /// **'Maximum (₹)'**
  String get budgetMaxField;

  /// No description provided for @budgetAny.
  ///
  /// In en, this message translates to:
  /// **'Any budget'**
  String get budgetAny;

  /// No description provided for @budgetAnyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see workers at every price. Adjust anytime.'**
  String get budgetAnyBody;

  /// No description provided for @budgetFlexibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Flexible budget'**
  String get budgetFlexibleLabel;

  /// No description provided for @budgetFlexibleBody.
  ///
  /// In en, this message translates to:
  /// **'Show workers at every price'**
  String get budgetFlexibleBody;

  /// No description provided for @budgetLow.
  ///
  /// In en, this message translates to:
  /// **'That\'s below the usual range, so you may see fewer workers. You can still continue.'**
  String get budgetLow;

  /// No description provided for @budgetErrMinMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum must be at least the minimum.'**
  String get budgetErrMinMax;

  /// No description provided for @budgetErrMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter a minimum and a maximum.'**
  String get budgetErrMissing;

  /// No description provided for @budgetErrHigh.
  ///
  /// In en, this message translates to:
  /// **'That amount looks too high. Please check it.'**
  String get budgetErrHigh;

  /// No description provided for @budgetReview.
  ///
  /// In en, this message translates to:
  /// **'Review requirement'**
  String get budgetReview;

  /// No description provided for @budgetDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get budgetDone;

  /// No description provided for @budgetSlider.
  ///
  /// In en, this message translates to:
  /// **'Budget range'**
  String get budgetSlider;

  /// No description provided for @gapNoService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service first.'**
  String get gapNoService;

  /// No description provided for @gapNoEngagement.
  ///
  /// In en, this message translates to:
  /// **'Choose how you need them to work.'**
  String get gapNoEngagement;

  /// No description provided for @gapNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose an address.'**
  String get gapNoAddress;

  /// No description provided for @gapTiming.
  ///
  /// In en, this message translates to:
  /// **'Complete the timing details.'**
  String get gapTiming;

  /// No description provided for @gapNoStartDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a start date.'**
  String get gapNoStartDate;

  /// No description provided for @gapStartDateRange.
  ///
  /// In en, this message translates to:
  /// **'Pick a start date within the allowed window.'**
  String get gapStartDateRange;

  /// No description provided for @gapBudget.
  ///
  /// In en, this message translates to:
  /// **'Check your budget.'**
  String get gapBudget;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume your request'**
  String get resumeTitle;

  /// No description provided for @resumeBody.
  ///
  /// In en, this message translates to:
  /// **'{what} · Step {n} of {total}'**
  String resumeBody(String what, int n, int total);

  /// No description provided for @resumeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get resumeContinue;

  /// No description provided for @resumeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get resumeDiscard;
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
