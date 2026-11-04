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
  /// **'Favourites'**
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

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @workerAppShort.
  ///
  /// In en, this message translates to:
  /// **'Worker App'**
  String get workerAppShort;

  /// No description provided for @workerAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Worker app link is not set up yet. Please try again later.'**
  String get workerAppUnavailable;

  /// No description provided for @homePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Home photo'**
  String get homePhotoLabel;

  /// No description provided for @homePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of your home to continue.'**
  String get homePhotoRequired;

  /// No description provided for @homePhotoUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Home Photo'**
  String get homePhotoUpload;

  /// No description provided for @homePhotoHelp.
  ///
  /// In en, this message translates to:
  /// **'Helps the worker find your home.'**
  String get homePhotoHelp;

  /// No description provided for @homePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get homePhotoGallery;

  /// No description provided for @homePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get homePhotoCamera;

  /// No description provided for @homePhotoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get homePhotoReplace;

  /// No description provided for @homePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get homePhotoRemove;

  /// No description provided for @homePhotoBadFormat.
  ///
  /// In en, this message translates to:
  /// **'Use a JPG or PNG photo.'**
  String get homePhotoBadFormat;

  /// No description provided for @homePhotoTooBig.
  ///
  /// In en, this message translates to:
  /// **'That photo is over 5 MB. Choose a smaller one.'**
  String get homePhotoTooBig;

  /// No description provided for @homePhotoPermission.
  ///
  /// In en, this message translates to:
  /// **'Photo or camera access is off. Allow it in Settings to add a photo.'**
  String get homePhotoPermission;

  /// No description provided for @homePhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Address saved, but the home photo could not be uploaded. Edit the address to try again.'**
  String get homePhotoUploadFailed;

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

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'A safer, happier home starts here'**
  String get loginHeadline;

  /// No description provided for @loginSubhead.
  ///
  /// In en, this message translates to:
  /// **'Book nearby professionals for all your home needs.'**
  String get loginSubhead;

  /// No description provided for @brandCaption.
  ///
  /// In en, this message translates to:
  /// **'TRUSTED HOME SERVICES'**
  String get brandCaption;

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

  /// No description provided for @loginTrustNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby professionals'**
  String get loginTrustNearby;

  /// No description provided for @loginTrustSupport.
  ///
  /// In en, this message translates to:
  /// **'Dedicated support'**
  String get loginTrustSupport;

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

  /// No description provided for @demoOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Your code (test mode)'**
  String get demoOtpLabel;

  /// No description provided for @demoOtpCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get demoOtpCopy;

  /// No description provided for @demoOtpCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get demoOtpCopied;

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

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

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

  /// No description provided for @profileProgress.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profileProgress(int percent);

  /// No description provided for @profileHintName.
  ///
  /// In en, this message translates to:
  /// **'Add your name to continue'**
  String get profileHintName;

  /// No description provided for @profileHintAddress.
  ///
  /// In en, this message translates to:
  /// **'Add your home address'**
  String get profileHintAddress;

  /// No description provided for @profileHintEmail.
  ///
  /// In en, this message translates to:
  /// **'Add an email for receipts'**
  String get profileHintEmail;

  /// No description provided for @profileHintDone.
  ///
  /// In en, this message translates to:
  /// **'All set. Tap Continue'**
  String get profileHintDone;

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

  /// No description provided for @profilePhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get profilePhotoAdd;

  /// No description provided for @profilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profilePhotoUpdated;

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

  /// No description provided for @addressLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get addressLabelLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Home, Parents\' home'**
  String get addressLabelHint;

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

  /// No description provided for @profileAddAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your home address'**
  String get profileAddAddressTitle;

  /// No description provided for @profileAddAddressSub.
  ///
  /// In en, this message translates to:
  /// **'So we can show workers near you.'**
  String get profileAddAddressSub;

  /// No description provided for @profileAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add your home address to continue.'**
  String get profileAddressRequired;

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
  /// **'We will schedule your account and data for deletion. You can cancel the request until it is processed.'**
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

  /// No description provided for @myAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get myAddressesTitle;

  /// No description provided for @addressesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Workers visit the address you save here.'**
  String get addressesEmptyBody;

  /// No description provided for @addressDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'You can add it again any time.'**
  String get addressDeleteBody;

  /// No description provided for @addressDeleteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get addressDeleteYes;

  /// No description provided for @addressKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep address'**
  String get addressKeep;

  /// No description provided for @profileEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditBtn;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileMobileVerified.
  ///
  /// In en, this message translates to:
  /// **'Mobile verified'**
  String get profileMobileVerified;

  /// No description provided for @profileMobileFixed.
  ///
  /// In en, this message translates to:
  /// **'Mobile number (cannot be changed)'**
  String get profileMobileFixed;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

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

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Find the right help for your home'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby professionals for all your home needs.'**
  String get homeSubtitle;

  /// No description provided for @homeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore services'**
  String get homeExplore;

  /// No description provided for @homePromoCleanEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Professional cleaning'**
  String get homePromoCleanEyebrow;

  /// No description provided for @homePromoCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'A cleaner, happier home'**
  String get homePromoCleanTitle;

  /// No description provided for @homePromoCleanBody.
  ///
  /// In en, this message translates to:
  /// **'Deep or basic cleaning, done by trained helpers.'**
  String get homePromoCleanBody;

  /// No description provided for @homePromoCleanCta.
  ///
  /// In en, this message translates to:
  /// **'Cleaning helper'**
  String get homePromoCleanCta;

  /// No description provided for @homePromoMaidEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Daily home care'**
  String get homePromoMaidEyebrow;

  /// No description provided for @homePromoMaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh rooms, every day'**
  String get homePromoMaidTitle;

  /// No description provided for @homePromoMaidBody.
  ///
  /// In en, this message translates to:
  /// **'Cleaning, utensils and basic household support.'**
  String get homePromoMaidBody;

  /// No description provided for @homePromoMaidCta.
  ///
  /// In en, this message translates to:
  /// **'Find a maid'**
  String get homePromoMaidCta;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

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

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some things may not load.'**
  String get offlineBanner;

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

  /// No description provided for @homeShortlistExperience.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs exp'**
  String homeShortlistExperience(int years);

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

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

  /// No description provided for @homeTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated near you'**
  String get homeTopRated;

  /// No description provided for @homeTopRatedCount.
  ///
  /// In en, this message translates to:
  /// **'({count})'**
  String homeTopRatedCount(int count);

  /// No description provided for @homeTopRatedJobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job done} other{{count} jobs done}}'**
  String homeTopRatedJobs(int count);

  /// No description provided for @homeAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s attendance'**
  String get homeAttendanceTitle;

  /// No description provided for @homeAttendanceArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String homeAttendanceArrived(String time);

  /// No description provided for @homeAttendanceNotArrived.
  ///
  /// In en, this message translates to:
  /// **'Not arrived yet'**
  String get homeAttendanceNotArrived;

  /// No description provided for @homeAttendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Marked absent today'**
  String get homeAttendanceAbsent;

  /// No description provided for @homeAttendanceLeave.
  ///
  /// In en, this message translates to:
  /// **'On leave today'**
  String get homeAttendanceLeave;

  /// No description provided for @homeAttendanceException.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get homeAttendanceException;

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

  /// No description provided for @discoverTypeCaption.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get discoverTypeCaption;

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

  /// No description provided for @serviceSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No services found. Try another search.'**
  String get serviceSearchNoResults;

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

  /// No description provided for @engShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get engShift;

  /// No description provided for @engShiftDesc.
  ///
  /// In en, this message translates to:
  /// **'Covers a set shift, such as a day or night shift.'**
  String get engShiftDesc;

  /// No description provided for @engShiftMeta.
  ///
  /// In en, this message translates to:
  /// **'Fixed shift hours'**
  String get engShiftMeta;

  /// No description provided for @engOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get engOneTime;

  /// No description provided for @engOneTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'A single visit for one job, with no repeat.'**
  String get engOneTimeDesc;

  /// No description provided for @engOneTimeMeta.
  ///
  /// In en, this message translates to:
  /// **'Single visit'**
  String get engOneTimeMeta;

  /// No description provided for @engMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get engMonthly;

  /// No description provided for @engMonthlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Works for you every day and is paid once a month.'**
  String get engMonthlyDesc;

  /// No description provided for @engMonthlyMeta.
  ///
  /// In en, this message translates to:
  /// **'Monthly pay · Most days'**
  String get engMonthlyMeta;

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

  /// No description provided for @locationNotServed.
  ///
  /// In en, this message translates to:
  /// **'Currently, SevaNest services are available only in Hyderabad. We\'re expanding to more locations soon. Stay tuned!'**
  String get locationNotServed;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationUseCurrent;

  /// No description provided for @setAsDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Used first when you book a worker.'**
  String get setAsDefaultSub;

  /// No description provided for @labelOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get labelOptional;

  /// No description provided for @addressLabelName.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabelName;

  /// No description provided for @addressLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding you...'**
  String get addressLocating;

  /// No description provided for @addressLocatingSub.
  ///
  /// In en, this message translates to:
  /// **'Checking GPS and your service area'**
  String get addressLocatingSub;

  /// No description provided for @addressLocationFound.
  ///
  /// In en, this message translates to:
  /// **'Location found'**
  String get addressLocationFound;

  /// No description provided for @addressLocationFoundSub.
  ///
  /// In en, this message translates to:
  /// **'Area, city and pincode filled in for you'**
  String get addressLocationFoundSub;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelParents.
  ///
  /// In en, this message translates to:
  /// **'Parents\' home'**
  String get addressLabelParents;

  /// No description provided for @addressLabelOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get addressLabelOffice;

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

  /// No description provided for @timingDaysSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Selected: 1 day} other{Selected: {count} days}}'**
  String timingDaysSelected(int count);

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
  /// **'Done'**
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

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} near {area}'**
  String resultsTitle(String category, String area);

  /// No description provided for @resultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching workers found'**
  String get resultsEmptyTitle;

  /// No description provided for @resultsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try changing your area, timing or engagement type.'**
  String get resultsEmptyBody;

  /// No description provided for @resultsEditRequirement.
  ///
  /// In en, this message translates to:
  /// **'Edit requirement'**
  String get resultsEditRequirement;

  /// No description provided for @resultsStale.
  ///
  /// In en, this message translates to:
  /// **'Showing earlier results'**
  String get resultsStale;

  /// No description provided for @resultsLoadMoreRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more. Retry'**
  String get resultsLoadMoreRetry;

  /// No description provided for @workerExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs experience'**
  String workerExperienceYears(int years);

  /// No description provided for @workerExperienceMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months experience'**
  String workerExperienceMonths(int months);

  /// No description provided for @workerExperienceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Experience not listed'**
  String get workerExperienceUnknown;

  /// No description provided for @workerNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get workerNew;

  /// No description provided for @workerRatingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} from {count} reviews'**
  String workerRatingSemantics(String rating, int count);

  /// No description provided for @workerAvailableWindow.
  ///
  /// In en, this message translates to:
  /// **'Available {start} to {end}'**
  String workerAvailableWindow(String start, String end);

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterButton;

  /// No description provided for @filterAvailability.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get filterAvailability;

  /// No description provided for @filterMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get filterMorning;

  /// No description provided for @filterAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get filterAfternoon;

  /// No description provided for @filterEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get filterEvening;

  /// No description provided for @filterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguage;

  /// No description provided for @filterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterRating;

  /// No description provided for @filterRatingMin.
  ///
  /// In en, this message translates to:
  /// **'{min}+ rating'**
  String filterRatingMin(String min);

  /// No description provided for @filterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filterSort;

  /// No description provided for @filterSortRating.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get filterSortRating;

  /// No description provided for @filterExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get filterExperience;

  /// No description provided for @filterExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{years}+ years'**
  String filterExperienceYears(int years);

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterActiveSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count} filters active'**
  String filterActiveSemantics(int count);

  /// No description provided for @favouriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get favouriteAdd;

  /// No description provided for @favouriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get favouriteRemove;

  /// No description provided for @favouriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update favourites. Try again.'**
  String get favouriteFailed;

  /// No description provided for @favouriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get favouriteRemoved;

  /// No description provided for @favouriteUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get favouriteUndo;

  /// No description provided for @favsTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favsTitle;

  /// No description provided for @accountSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get accountSectionActivity;

  /// No description provided for @accountSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Payments & profile'**
  String get accountSectionDetails;

  /// No description provided for @accountSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & legal'**
  String get accountSectionHelp;

  /// No description provided for @accountEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountEditProfile;

  /// No description provided for @accountNotifWarn.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You may miss worker replies.'**
  String get accountNotifWarn;

  /// No description provided for @accountNotifTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get accountNotifTurnOn;

  /// No description provided for @accountStayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in'**
  String get accountStayLoggedIn;

  /// No description provided for @accountAboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Find verified home workers near you.'**
  String get accountAboutTagline;

  /// No description provided for @accountVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get accountVersionLabel;

  /// No description provided for @favsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workers you have saved'**
  String get favsSubtitle;

  /// No description provided for @favsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get favsFilterAll;

  /// No description provided for @favsRequestInterview.
  ///
  /// In en, this message translates to:
  /// **'Request interview'**
  String get favsRequestInterview;

  /// No description provided for @favsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get favsEmptyTitle;

  /// No description provided for @favsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a worker to save them here, so you can come back to them later.'**
  String get favsEmptyBody;

  /// No description provided for @favsFindWorker.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get favsFindWorker;

  /// No description provided for @workerUnavailableTag.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get workerUnavailableTag;

  /// No description provided for @workerUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This worker is no longer available'**
  String get workerUnavailableTitle;

  /// No description provided for @workerUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s find another.'**
  String get workerUnavailableBody;

  /// No description provided for @workerFindAnother.
  ///
  /// In en, this message translates to:
  /// **'Find another worker'**
  String get workerFindAnother;

  /// No description provided for @workerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker profile'**
  String get workerProfileTitle;

  /// No description provided for @workerVerifiedInfo.
  ///
  /// In en, this message translates to:
  /// **'What does verified mean?'**
  String get workerVerifiedInfo;

  /// No description provided for @workerVerifiedSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What verified means'**
  String get workerVerifiedSheetTitle;

  /// No description provided for @workerVerifiedSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Verified workers have passed the identity and background checks SevaNest requires before they can appear in search. We never show ID documents or contact details.'**
  String get workerVerifiedSheetBody;

  /// No description provided for @workerGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get workerGotIt;

  /// No description provided for @workerRequestInterview.
  ///
  /// In en, this message translates to:
  /// **'Request interview'**
  String get workerRequestInterview;

  /// No description provided for @workerExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get workerExperienceLabel;

  /// No description provided for @workerLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get workerLanguagesLabel;

  /// No description provided for @workerAreasLabel.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get workerAreasLabel;

  /// No description provided for @workerAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get workerAvailabilityLabel;

  /// No description provided for @workerEngagementLabel.
  ///
  /// In en, this message translates to:
  /// **'Prefers'**
  String get workerEngagementLabel;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all reviews'**
  String get reviewsSeeAll;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsEmpty;

  /// No description provided for @workerStartSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a search first'**
  String get workerStartSearchTitle;

  /// No description provided for @workerStartSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you need, then request an interview with this worker.'**
  String get workerStartSearchBody;

  /// No description provided for @workerStartSearch.
  ///
  /// In en, this message translates to:
  /// **'Start a search'**
  String get workerStartSearch;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your request'**
  String get reviewTitle;

  /// No description provided for @reviewAllDone.
  ///
  /// In en, this message translates to:
  /// **'All steps done'**
  String get reviewAllDone;

  /// No description provided for @reviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Check your requirement'**
  String get reviewHeading;

  /// No description provided for @reviewSub.
  ///
  /// In en, this message translates to:
  /// **'Make sure everything looks right before we find workers.'**
  String get reviewSub;

  /// No description provided for @reviewRowService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get reviewRowService;

  /// No description provided for @reviewRowEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get reviewRowEngagement;

  /// No description provided for @reviewRowAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get reviewRowAddress;

  /// No description provided for @reviewRowTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get reviewRowTiming;

  /// No description provided for @reviewRowStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get reviewRowStartDate;

  /// No description provided for @reviewRowBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get reviewRowBudget;

  /// No description provided for @reviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reviewEdit;

  /// No description provided for @reviewSearch.
  ///
  /// In en, this message translates to:
  /// **'Find workers'**
  String get reviewSearch;

  /// No description provided for @workerMoreChip.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String workerMoreChip(int count);

  /// No description provided for @reviewEditSemantics.
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String reviewEditSemantics(String field);

  /// No description provided for @reviewByline.
  ///
  /// In en, this message translates to:
  /// **'{name} · {date}'**
  String reviewByline(String name, String date);

  /// No description provided for @workerSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get workerSkillsLabel;

  /// No description provided for @workerVerificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get workerVerificationInProgress;

  /// No description provided for @workerCannotRequestReason.
  ///
  /// In en, this message translates to:
  /// **'You can request an interview once this worker\'s verification is complete.'**
  String get workerCannotRequestReason;

  /// No description provided for @workerStatReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String workerStatReviews(int count);

  /// No description provided for @workerStatExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get workerStatExperience;

  /// No description provided for @workerStatYears.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs'**
  String workerStatYears(int years);

  /// No description provided for @workerStatMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} mo'**
  String workerStatMonths(int months);

  /// No description provided for @workerStatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get workerStatUnknown;

  /// No description provided for @workerShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get workerShortlist;

  /// No description provided for @workerShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get workerShortlisted;

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reviews.'**
  String get reviewsLoadFailed;

  /// No description provided for @addressLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Check the location permission, or fill in the address yourself.'**
  String get addressLocationFailed;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of SevaNest?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need your mobile number and a new code to log in again.'**
  String get logoutConfirmBody;

  /// No description provided for @devMenuLive.
  ///
  /// In en, this message translates to:
  /// **'Backend data'**
  String get devMenuLive;

  /// No description provided for @devMenuLiveOn.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get devMenuLiveOn;

  /// No description provided for @devMenuLiveOff.
  ///
  /// In en, this message translates to:
  /// **'Mock'**
  String get devMenuLiveOff;

  /// No description provided for @interviewRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request an interview'**
  String get interviewRequestTitle;

  /// No description provided for @interviewRescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get interviewRescheduleTitle;

  /// No description provided for @interviewTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'What would you like?'**
  String get interviewTypeLabel;

  /// No description provided for @interviewTypeInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interviewTypeInterview;

  /// No description provided for @interviewTypeTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get interviewTypeTrial;

  /// No description provided for @interviewTypeInterviewHint.
  ///
  /// In en, this message translates to:
  /// **'Talk with the worker first to see if they suit you.'**
  String get interviewTypeInterviewHint;

  /// No description provided for @interviewTypeTrialHint.
  ///
  /// In en, this message translates to:
  /// **'Try the worker for a short visit at your home.'**
  String get interviewTypeTrialHint;

  /// No description provided for @interviewHeadline.
  ///
  /// In en, this message translates to:
  /// **'Meet before you decide'**
  String get interviewHeadline;

  /// No description provided for @interviewPickToContinue.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time to continue'**
  String get interviewPickToContinue;

  /// No description provided for @interviewDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get interviewDateLabel;

  /// No description provided for @interviewDateButton.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get interviewDateButton;

  /// No description provided for @interviewSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get interviewSlotLabel;

  /// No description provided for @interviewPickDateFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a date above to see the free times.'**
  String get interviewPickDateFirst;

  /// No description provided for @interviewNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No times are free on this date. Try another day.'**
  String get interviewNoSlots;

  /// No description provided for @interviewNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the worker (optional)'**
  String get interviewNoteLabel;

  /// No description provided for @interviewNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the worker should know? (optional, up to 300 characters)'**
  String get interviewNoteHint;

  /// No description provided for @interviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get interviewSubmit;

  /// No description provided for @interviewSubmitReschedule.
  ///
  /// In en, this message translates to:
  /// **'Confirm new time'**
  String get interviewSubmitReschedule;

  /// No description provided for @interviewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get interviewSubmitting;

  /// No description provided for @interviewSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get interviewSent;

  /// No description provided for @interviewRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Time changed'**
  String get interviewRescheduled;

  /// No description provided for @interviewSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'That time is no longer available. Pick another.'**
  String get interviewSlotTaken;

  /// No description provided for @interviewDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview request'**
  String get interviewDetailTitle;

  /// No description provided for @interviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'My interviews'**
  String get interviewsTitle;

  /// No description provided for @interviewStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get interviewStatusRequested;

  /// No description provided for @interviewStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get interviewStatusScheduled;

  /// No description provided for @interviewStatusProposed.
  ///
  /// In en, this message translates to:
  /// **'New time suggested'**
  String get interviewStatusProposed;

  /// No description provided for @interviewStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get interviewStatusCompleted;

  /// No description provided for @interviewStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get interviewStatusCancelled;

  /// No description provided for @interviewStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get interviewStatusDeclined;

  /// No description provided for @interviewStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get interviewStatusConfirmed;

  /// No description provided for @interviewStatusNotAFit.
  ///
  /// In en, this message translates to:
  /// **'Not a fit'**
  String get interviewStatusNotAFit;

  /// No description provided for @interviewStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get interviewStatusUnknown;

  /// No description provided for @interviewCopyRequested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the worker to respond'**
  String get interviewCopyRequested;

  /// No description provided for @interviewCopyProposed.
  ///
  /// In en, this message translates to:
  /// **'The worker suggested {date}, {time}'**
  String interviewCopyProposed(String date, String time);

  /// No description provided for @interviewAcceptProposal.
  ///
  /// In en, this message translates to:
  /// **'Accept new time'**
  String get interviewAcceptProposal;

  /// No description provided for @interviewKeepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep my time'**
  String get interviewKeepOriginal;

  /// No description provided for @interviewProposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'New time accepted'**
  String get interviewProposalAccepted;

  /// No description provided for @interviewProposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Kept your original time'**
  String get interviewProposalRejected;

  /// No description provided for @interviewCopyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Decide whether to confirm this worker'**
  String get interviewCopyCompleted;

  /// No description provided for @interviewCopyCancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this request'**
  String get interviewCopyCancelled;

  /// No description provided for @interviewCopyDeclined.
  ///
  /// In en, this message translates to:
  /// **'The worker couldn\'t take this request'**
  String get interviewCopyDeclined;

  /// No description provided for @interviewCopyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You confirmed this worker'**
  String get interviewCopyConfirmed;

  /// No description provided for @interviewCopyNotAFit.
  ///
  /// In en, this message translates to:
  /// **'You marked this worker as not a fit'**
  String get interviewCopyNotAFit;

  /// No description provided for @interviewCopyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get interviewCopyUnknown;

  /// No description provided for @interviewWhenRow.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get interviewWhenRow;

  /// No description provided for @interviewTypeRow.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get interviewTypeRow;

  /// No description provided for @interviewRequirementRow.
  ///
  /// In en, this message translates to:
  /// **'Your requirement'**
  String get interviewRequirementRow;

  /// No description provided for @interviewProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get interviewProgress;

  /// No description provided for @interviewCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel interview'**
  String get interviewCancel;

  /// No description provided for @interviewCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this interview?'**
  String get interviewCancelTitle;

  /// No description provided for @interviewCancelBody.
  ///
  /// In en, this message translates to:
  /// **'The worker will be told it is cancelled. You can search for another worker any time.'**
  String get interviewCancelBody;

  /// No description provided for @interviewCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep interview'**
  String get interviewCancelKeep;

  /// No description provided for @interviewCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get interviewCancelled;

  /// No description provided for @interviewReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get interviewReschedule;

  /// No description provided for @interviewConfirmWorker.
  ///
  /// In en, this message translates to:
  /// **'Confirm this worker'**
  String get interviewConfirmWorker;

  /// No description provided for @interviewDecline.
  ///
  /// In en, this message translates to:
  /// **'This worker is not a fit'**
  String get interviewDecline;

  /// No description provided for @interviewDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a fit?'**
  String get interviewDeclineTitle;

  /// No description provided for @interviewDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll close this request so you can look for another worker.'**
  String get interviewDeclineBody;

  /// No description provided for @interviewDeclineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, not a fit'**
  String get interviewDeclineConfirm;

  /// No description provided for @interviewDeclined.
  ///
  /// In en, this message translates to:
  /// **'Marked as not a fit'**
  String get interviewDeclined;

  /// No description provided for @interviewSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get interviewSupport;

  /// No description provided for @interviewTlRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get interviewTlRequested;

  /// No description provided for @interviewTlScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview scheduled'**
  String get interviewTlScheduled;

  /// No description provided for @interviewTlCompleted.
  ///
  /// In en, this message translates to:
  /// **'Interview completed'**
  String get interviewTlCompleted;

  /// No description provided for @interviewTlDecision.
  ///
  /// In en, this message translates to:
  /// **'Your decision'**
  String get interviewTlDecision;

  /// No description provided for @interviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No interviews yet'**
  String get interviewsEmptyTitle;

  /// No description provided for @interviewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Meet a worker before you decide. Find a worker and request an interview.'**
  String get interviewsEmptyBody;

  /// No description provided for @interviewsFind.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get interviewsFind;

  /// No description provided for @accountInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews & trials'**
  String get accountInterviews;

  /// No description provided for @interviewCopyScheduled.
  ///
  /// In en, this message translates to:
  /// **'{kind} on {date}, {time}'**
  String interviewCopyScheduled(String kind, String date, String time);

  /// No description provided for @interviewWhenValue.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String interviewWhenValue(String date, String time);

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get bookingsTitle;

  /// No description provided for @bookingsTabCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bookingsTabCurrent;

  /// No description provided for @bookingsTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingsTabPast;

  /// No description provided for @bookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No current bookings'**
  String get bookingsEmptyTitle;

  /// No description provided for @bookingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Find a verified worker and book them in a few steps.'**
  String get bookingsEmptyBody;

  /// No description provided for @bookingsPastEmpty.
  ///
  /// In en, this message translates to:
  /// **'No past bookings'**
  String get bookingsPastEmpty;

  /// No description provided for @bookingsFind.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get bookingsFind;

  /// No description provided for @bookingsPay.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get bookingsPay;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailTitle;

  /// No description provided for @bookingStatusNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get bookingStatusNewRequest;

  /// No description provided for @bookingStatusMatched.
  ///
  /// In en, this message translates to:
  /// **'Worker matched'**
  String get bookingStatusMatched;

  /// No description provided for @bookingStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview scheduled'**
  String get bookingStatusScheduled;

  /// No description provided for @bookingStatusInterviewDone.
  ///
  /// In en, this message translates to:
  /// **'Interview done'**
  String get bookingStatusInterviewDone;

  /// No description provided for @bookingStatusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get bookingStatusPendingPayment;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bookingStatusActive;

  /// No description provided for @bookingStatusReplacementRequested.
  ///
  /// In en, this message translates to:
  /// **'Replacement requested'**
  String get bookingStatusReplacementRequested;

  /// No description provided for @bookingStatusReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get bookingStatusReplaced;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get bookingStatusUnknown;

  /// No description provided for @bookingCopyNewRequest.
  ///
  /// In en, this message translates to:
  /// **'We are finding a worker for you'**
  String get bookingCopyNewRequest;

  /// No description provided for @bookingCopyMatched.
  ///
  /// In en, this message translates to:
  /// **'A worker is matched. Schedule an interview or trial'**
  String get bookingCopyMatched;

  /// No description provided for @bookingCopyScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview or trial is scheduled'**
  String get bookingCopyScheduled;

  /// No description provided for @bookingCopyInterviewDone.
  ///
  /// In en, this message translates to:
  /// **'Decide whether to confirm this worker'**
  String get bookingCopyInterviewDone;

  /// No description provided for @bookingCopyPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pay the booking fee to confirm this booking'**
  String get bookingCopyPendingPayment;

  /// No description provided for @bookingCopyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your booking is confirmed'**
  String get bookingCopyConfirmed;

  /// No description provided for @bookingCopyActive.
  ///
  /// In en, this message translates to:
  /// **'The service is under way'**
  String get bookingCopyActive;

  /// No description provided for @bookingCopyReplacementRequested.
  ///
  /// In en, this message translates to:
  /// **'We are arranging a replacement'**
  String get bookingCopyReplacementRequested;

  /// No description provided for @bookingCopyReplaced.
  ///
  /// In en, this message translates to:
  /// **'This booking was replaced'**
  String get bookingCopyReplaced;

  /// No description provided for @bookingCopyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This booking is complete'**
  String get bookingCopyCompleted;

  /// No description provided for @bookingCopyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled'**
  String get bookingCopyCancelled;

  /// No description provided for @bookingCopyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get bookingCopyUnknown;

  /// No description provided for @bookingServiceRow.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingServiceRow;

  /// No description provided for @bookingScheduleRow.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get bookingScheduleRow;

  /// No description provided for @bookingInterviewRow.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get bookingInterviewRow;

  /// No description provided for @bookingAreaRow.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get bookingAreaRow;

  /// No description provided for @bookingBudgetRow.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get bookingBudgetRow;

  /// No description provided for @bookingNoteRow.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get bookingNoteRow;

  /// No description provided for @bookingReferenceRow.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get bookingReferenceRow;

  /// No description provided for @bookingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get bookingTimeline;

  /// No description provided for @bookingPayNow.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get bookingPayNow;

  /// No description provided for @bookingViewService.
  ///
  /// In en, this message translates to:
  /// **'View active service'**
  String get bookingViewService;

  /// No description provided for @bookingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate worker'**
  String get bookingRate;

  /// No description provided for @bookingReplace.
  ///
  /// In en, this message translates to:
  /// **'Request replacement'**
  String get bookingReplace;

  /// No description provided for @bookingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get bookingCancel;

  /// No description provided for @bookingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get bookingReceipt;

  /// No description provided for @bookingSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get bookingSupport;

  /// No description provided for @bookingConfirmWorker.
  ///
  /// In en, this message translates to:
  /// **'Confirm this worker'**
  String get bookingConfirmWorker;

  /// No description provided for @bookingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule interview'**
  String get bookingSchedule;

  /// No description provided for @bookingInterviewDone.
  ///
  /// In en, this message translates to:
  /// **'Interview done'**
  String get bookingInterviewDone;

  /// No description provided for @bookingNotAFit.
  ///
  /// In en, this message translates to:
  /// **'Not a fit'**
  String get bookingNotAFit;

  /// No description provided for @bookingPreviousLink.
  ///
  /// In en, this message translates to:
  /// **'See the replaced booking'**
  String get bookingPreviousLink;

  /// No description provided for @bookingPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get bookingPaymentDue;

  /// No description provided for @bookingPaymentNone.
  ///
  /// In en, this message translates to:
  /// **'No payment due'**
  String get bookingPaymentNone;

  /// No description provided for @cancelSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelSheetTitle;

  /// No description provided for @cancelSheetReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get cancelSheetReason;

  /// No description provided for @cancelReasonFound.
  ///
  /// In en, this message translates to:
  /// **'I found another worker'**
  String get cancelReasonFound;

  /// No description provided for @cancelReasonPlans.
  ///
  /// In en, this message translates to:
  /// **'My plans changed'**
  String get cancelReasonPlans;

  /// No description provided for @cancelReasonMistake.
  ///
  /// In en, this message translates to:
  /// **'I booked by mistake'**
  String get cancelReasonMistake;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @cancelNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything you would like to add (optional)'**
  String get cancelNoteHint;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelConfirm;

  /// No description provided for @cancelDismiss.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get cancelDismiss;

  /// No description provided for @cancelRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get cancelRequested;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm worker'**
  String get confirmTitle;

  /// No description provided for @confirmHeading.
  ///
  /// In en, this message translates to:
  /// **'Confirm your worker'**
  String get confirmHeading;

  /// No description provided for @confirmSub.
  ///
  /// In en, this message translates to:
  /// **'Check the details and pick a start date. You pay the booking fee next.'**
  String get confirmSub;

  /// No description provided for @confirmStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get confirmStartDate;

  /// No description provided for @confirmEditRequirement.
  ///
  /// In en, this message translates to:
  /// **'Edit requirement'**
  String get confirmEditRequirement;

  /// No description provided for @confirmFeeRow.
  ///
  /// In en, this message translates to:
  /// **'Booking fee'**
  String get confirmFeeRow;

  /// No description provided for @confirmFeeNote.
  ///
  /// In en, this message translates to:
  /// **'This is an estimate. The final fee is shown on the payment step.'**
  String get confirmFeeNote;

  /// No description provided for @confirmFeeTaxNote.
  ///
  /// In en, this message translates to:
  /// **'Taxes, if any, are confirmed on the payment step.'**
  String get confirmFeeTaxNote;

  /// No description provided for @confirmTaxRow.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get confirmTaxRow;

  /// No description provided for @confirmTotalRow.
  ///
  /// In en, this message translates to:
  /// **'Total today'**
  String get confirmTotalRow;

  /// No description provided for @confirmPriceDetails.
  ///
  /// In en, this message translates to:
  /// **'Price details'**
  String get confirmPriceDetails;

  /// No description provided for @confirmSummary.
  ///
  /// In en, this message translates to:
  /// **'Your requirement'**
  String get confirmSummary;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm worker'**
  String get confirmButton;

  /// No description provided for @confirmButtonBusy.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirmButtonBusy;

  /// No description provided for @confirmDone.
  ///
  /// In en, this message translates to:
  /// **'Worker confirmed'**
  String get confirmDone;

  /// No description provided for @confirmNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This booking can\'t be confirmed right now.'**
  String get confirmNotAllowed;

  /// No description provided for @confirmDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick today or a later date.'**
  String get confirmDateInvalid;

  /// No description provided for @confirmEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier day'**
  String get confirmEarlier;

  /// No description provided for @confirmLater.
  ///
  /// In en, this message translates to:
  /// **'Later day'**
  String get confirmLater;

  /// No description provided for @confirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get confirmContinue;

  /// No description provided for @confirmTkStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get confirmTkStarts;

  /// No description provided for @confirmTkAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get confirmTkAmount;

  /// No description provided for @confirmSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will start on {date}. Pay the booking fee to lock it in.'**
  String confirmSuccessBody(String name, String date);

  /// No description provided for @bookingStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String bookingStartsOn(String date);

  /// No description provided for @bookingStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String bookingStartedOn(String date);

  /// No description provided for @bookingCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {date}'**
  String bookingCancelledOn(String date);

  /// No description provided for @bookingPayPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get bookingPayPaid;

  /// No description provided for @bookingPayUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get bookingPayUnpaid;

  /// No description provided for @bookingPayNowAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now'**
  String bookingPayNowAmount(String amount);

  /// No description provided for @bookingPayBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get bookingPayBannerTitle;

  /// No description provided for @bookingPayBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Pay the booking fee to lock it in'**
  String get bookingPayBannerBody;

  /// No description provided for @bookingHeadPay.
  ///
  /// In en, this message translates to:
  /// **'One step left'**
  String get bookingHeadPay;

  /// No description provided for @bookingHeadConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You are all set'**
  String get bookingHeadConfirmed;

  /// No description provided for @bookingHeadActive.
  ///
  /// In en, this message translates to:
  /// **'Service in progress'**
  String get bookingHeadActive;

  /// No description provided for @bookingHeadRate.
  ///
  /// In en, this message translates to:
  /// **'How was {name}?'**
  String bookingHeadRate(String name);

  /// No description provided for @bookingHeadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingHeadCancelled;

  /// No description provided for @bookingCopyRef.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get bookingCopyRef;

  /// No description provided for @bookingRefCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get bookingRefCopied;

  /// No description provided for @bookingCopyScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'{kind} on {date}, {time}'**
  String bookingCopyScheduledAt(String kind, String date, String time);

  /// No description provided for @bookingBudgetRange.
  ///
  /// In en, this message translates to:
  /// **'{range} {period}'**
  String bookingBudgetRange(String range, String period);

  /// No description provided for @interviewDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have an open request with this worker.'**
  String get interviewDuplicate;

  /// No description provided for @interviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get interviewComplete;

  /// No description provided for @interviewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get interviewSchedule;

  /// No description provided for @bookingNextWhen.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String bookingNextWhen(String date);

  /// No description provided for @bookingViewInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview details'**
  String get bookingViewInterview;

  /// No description provided for @bookingPaymentRow.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingPaymentRow;

  /// No description provided for @payTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payTitle;

  /// No description provided for @payHeading.
  ///
  /// In en, this message translates to:
  /// **'Pay the booking fee'**
  String get payHeading;

  /// No description provided for @paySub.
  ///
  /// In en, this message translates to:
  /// **'This locks in your worker and your start date.'**
  String get paySub;

  /// No description provided for @payAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get payAmountLabel;

  /// No description provided for @payButton.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payButton(String amount);

  /// No description provided for @payButtonBusy.
  ///
  /// In en, this message translates to:
  /// **'Opening payment…'**
  String get payButtonBusy;

  /// No description provided for @payVerifying.
  ///
  /// In en, this message translates to:
  /// **'Confirming your payment…'**
  String get payVerifying;

  /// No description provided for @payVerifyingWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait, confirming your payment'**
  String get payVerifyingWait;

  /// No description provided for @payCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled. You can try again.'**
  String get payCancelledSnack;

  /// No description provided for @payLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave payment?'**
  String get payLeaveTitle;

  /// No description provided for @payLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking stays pending.'**
  String get payLeaveBody;

  /// No description provided for @payLeaveStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get payLeaveStay;

  /// No description provided for @payLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get payLeaveConfirm;

  /// No description provided for @paySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paySuccessTitle;

  /// No description provided for @paySuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking is confirmed.'**
  String get paySuccessBody;

  /// No description provided for @payReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String payReceiptNumber(String number);

  /// No description provided for @payViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get payViewBooking;

  /// No description provided for @payViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get payViewReceipt;

  /// No description provided for @payFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment didn\'t go through'**
  String get payFailedTitle;

  /// No description provided for @payFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking is still waiting for payment. You can try again.'**
  String get payFailedBody;

  /// No description provided for @payFailedDebitNote.
  ///
  /// In en, this message translates to:
  /// **'If any amount was debited, it will be refunded automatically.'**
  String get payFailedDebitNote;

  /// No description provided for @payRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get payRetry;

  /// No description provided for @payGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get payGetHelp;

  /// No description provided for @payClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get payClose;

  /// No description provided for @payPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re confirming your payment'**
  String get payPendingTitle;

  /// No description provided for @payPendingBody.
  ///
  /// In en, this message translates to:
  /// **'This can take a few minutes. Your booking will update when it\'s done.'**
  String get payPendingBody;

  /// No description provided for @payRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get payRefresh;

  /// No description provided for @payAgain.
  ///
  /// In en, this message translates to:
  /// **'I haven\'t paid, pay again'**
  String get payAgain;

  /// No description provided for @payNotPayableTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pay'**
  String get payNotPayableTitle;

  /// No description provided for @payNotPayableBody.
  ///
  /// In en, this message translates to:
  /// **'This booking isn\'t waiting for payment. It may already be paid.'**
  String get payNotPayableBody;

  /// No description provided for @payFeeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The booking fee isn\'t set up yet. Please try again later or contact support.'**
  String get payFeeNotConfigured;

  /// No description provided for @payRecoveredPaid.
  ///
  /// In en, this message translates to:
  /// **'Your payment was received.'**
  String get payRecoveredPaid;

  /// No description provided for @payRecoveredFailed.
  ///
  /// In en, this message translates to:
  /// **'Your last payment didn\'t go through.'**
  String get payRecoveredFailed;

  /// No description provided for @payRecoveredPending.
  ///
  /// In en, this message translates to:
  /// **'We\'re still confirming your last payment.'**
  String get payRecoveredPending;

  /// No description provided for @payRecoveredView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get payRecoveredView;

  /// No description provided for @accountTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions & receipts'**
  String get accountTransactions;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmpty;

  /// No description provided for @transactionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Payments you make will show up here.'**
  String get transactionsEmptyBody;

  /// No description provided for @txnFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get txnFilterAll;

  /// No description provided for @txnFilterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get txnFilterPaid;

  /// No description provided for @txnFilterRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get txnFilterRefunded;

  /// No description provided for @txnStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get txnStatusCreated;

  /// No description provided for @txnStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get txnStatusPending;

  /// No description provided for @txnStatusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get txnStatusSucceeded;

  /// No description provided for @txnStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get txnStatusFailed;

  /// No description provided for @txnStatusRefundPending.
  ///
  /// In en, this message translates to:
  /// **'Refund pending'**
  String get txnStatusRefundPending;

  /// No description provided for @txnStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get txnStatusRefunded;

  /// No description provided for @txnStatusRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed'**
  String get txnStatusRefundFailed;

  /// No description provided for @txnStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get txnStatusUnknown;

  /// No description provided for @txnRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking payment'**
  String get txnRowTitle;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @txnAmountRow.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txnAmountRow;

  /// No description provided for @txnStatusRow.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get txnStatusRow;

  /// No description provided for @txnReceiptRow.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get txnReceiptRow;

  /// No description provided for @txnPaidOnRow.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get txnPaidOnRow;

  /// No description provided for @txnBookingRow.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get txnBookingRow;

  /// No description provided for @txnMethodRow.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get txnMethodRow;

  /// No description provided for @txnReferenceRow.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get txnReferenceRow;

  /// No description provided for @txnRefundedOnRow.
  ///
  /// In en, this message translates to:
  /// **'Refunded on'**
  String get txnRefundedOnRow;

  /// No description provided for @txnMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get txnMethodUpi;

  /// No description provided for @txnMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get txnMethodCard;

  /// No description provided for @txnMethodNetbanking.
  ///
  /// In en, this message translates to:
  /// **'Net banking'**
  String get txnMethodNetbanking;

  /// No description provided for @txnMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get txnMethodWallet;

  /// No description provided for @txnMethodEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get txnMethodEmi;

  /// No description provided for @txnNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Issued once the payment succeeds'**
  String get txnNoReceipt;

  /// No description provided for @txnNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help with this payment?'**
  String get txnNeedHelp;

  /// No description provided for @txnRefundNote.
  ///
  /// In en, this message translates to:
  /// **'Refunds go back to your original payment method.'**
  String get txnRefundNote;

  /// No description provided for @payPayWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payPayWith;

  /// No description provided for @payFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get payFastest;

  /// No description provided for @payMethodUpiNote.
  ///
  /// In en, this message translates to:
  /// **'Google Pay, PhonePe, Paytm and more'**
  String get payMethodUpiNote;

  /// No description provided for @payMethodCardNote.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, RuPay'**
  String get payMethodCardNote;

  /// No description provided for @payMethodNetNote.
  ///
  /// In en, this message translates to:
  /// **'All major Indian banks'**
  String get payMethodNetNote;

  /// No description provided for @payMethodWalletNote.
  ///
  /// In en, this message translates to:
  /// **'Pay from your wallet balance'**
  String get payMethodWalletNote;

  /// No description provided for @payMethodCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Debit or credit card'**
  String get payMethodCardTitle;

  /// No description provided for @paySecureNote.
  ///
  /// In en, this message translates to:
  /// **'You will choose how to pay on the next step. Payments are secure and encrypted.'**
  String get paySecureNote;

  /// No description provided for @payStartsRow.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get payStartsRow;

  /// No description provided for @payAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get payAmountPaid;

  /// No description provided for @payReceiptRow.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get payReceiptRow;

  /// No description provided for @txnTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get txnTotalPaid;

  /// No description provided for @txnCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get txnCopy;

  /// No description provided for @txnCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get txnCopied;

  /// No description provided for @txnCopyReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Copy receipt number'**
  String get txnCopyReceiptNo;

  /// No description provided for @txnCopyReference.
  ///
  /// In en, this message translates to:
  /// **'Copy payment reference'**
  String get txnCopyReference;

  /// No description provided for @txnCopyReceipt.
  ///
  /// In en, this message translates to:
  /// **'Copy receipt details'**
  String get txnCopyReceipt;

  /// No description provided for @txnReceiptCopied.
  ///
  /// In en, this message translates to:
  /// **'Receipt details copied'**
  String get txnReceiptCopied;

  /// No description provided for @txnRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund of {amount} on its way'**
  String txnRefundTitle(String amount);

  /// No description provided for @txnRefundBody.
  ///
  /// In en, this message translates to:
  /// **'It usually reaches your original payment method within 5 to 7 working days.'**
  String get txnRefundBody;

  /// No description provided for @serviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Active service'**
  String get serviceTitle;

  /// No description provided for @serviceNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No active service'**
  String get serviceNoneTitle;

  /// No description provided for @serviceNoneBody.
  ///
  /// In en, this message translates to:
  /// **'When a worker starts, you\'ll see them here.'**
  String get serviceNoneBody;

  /// No description provided for @servicePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Which service?'**
  String get servicePickTitle;

  /// No description provided for @serviceSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String serviceSince(String date);

  /// No description provided for @serviceTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get serviceTodayTitle;

  /// No description provided for @serviceTodayNone.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get serviceTodayNone;

  /// No description provided for @serviceMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get serviceMonthTitle;

  /// No description provided for @serviceBookingLink.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get serviceBookingLink;

  /// No description provided for @serviceSupport.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get serviceSupport;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No updates yet. You\'ll see your worker\'s status here.'**
  String get attendanceEmpty;

  /// No description provided for @attendanceLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get attendanceLoadMore;

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceException.
  ///
  /// In en, this message translates to:
  /// **'Exception'**
  String get attendanceException;

  /// No description provided for @attendanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get attendanceUnknown;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No past services yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled services will show up here.'**
  String get historyEmptyBody;

  /// No description provided for @historySectionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get historySectionCurrent;

  /// No description provided for @historySectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historySectionCompleted;

  /// No description provided for @historySectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled & replaced'**
  String get historySectionCancelled;

  /// No description provided for @historySectionReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get historySectionReplaced;

  /// No description provided for @historyRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get historyRate;

  /// No description provided for @historyRatedLabel.
  ///
  /// In en, this message translates to:
  /// **'You rated {score} out of {max}'**
  String historyRatedLabel(int score, int max);

  /// No description provided for @accountHistory.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get accountHistory;

  /// No description provided for @ratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your worker'**
  String get ratingTitle;

  /// No description provided for @ratingQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was your worker?'**
  String get ratingQuestion;

  /// No description provided for @ratingTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get ratingTapHint;

  /// No description provided for @ratingStarLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} out of {max}'**
  String ratingStarLabel(int n, int max);

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifSettingsTitle;

  /// No description provided for @notifSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose which alerts pop up while you use the app. System notifications are managed in your phone\'s settings.'**
  String get notifSettingsBody;

  /// No description provided for @notifCatBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings and interviews'**
  String get notifCatBookings;

  /// No description provided for @notifCatPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments and refunds'**
  String get notifCatPayments;

  /// No description provided for @notifCatReplacements.
  ///
  /// In en, this message translates to:
  /// **'Replacements'**
  String get notifCatReplacements;

  /// No description provided for @notifCatSupport.
  ///
  /// In en, this message translates to:
  /// **'Support tickets'**
  String get notifCatSupport;

  /// No description provided for @policyLink.
  ///
  /// In en, this message translates to:
  /// **'Cancellation and refund policy'**
  String get policyLink;

  /// No description provided for @policyCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get policyCancellationTitle;

  /// No description provided for @policyRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get policyRefundTitle;

  /// No description provided for @policyReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get policyReadMore;

  /// No description provided for @repNeededFrom.
  ///
  /// In en, this message translates to:
  /// **'Needed from (optional)'**
  String get repNeededFrom;

  /// No description provided for @repNeededFromPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get repNeededFromPick;

  /// No description provided for @repNeededFromClear.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get repNeededFromClear;

  /// No description provided for @repNeededFromNote.
  ///
  /// In en, this message translates to:
  /// **'For our team\'s information. It does not change the replacement\'s start date.'**
  String get repNeededFromNote;

  /// No description provided for @ratingTagsGood.
  ///
  /// In en, this message translates to:
  /// **'What went well?'**
  String get ratingTagsGood;

  /// No description provided for @ratingTagsBad.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get ratingTagsBad;

  /// No description provided for @ratingTagPunctual.
  ///
  /// In en, this message translates to:
  /// **'Punctual'**
  String get ratingTagPunctual;

  /// No description provided for @ratingTagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get ratingTagPolite;

  /// No description provided for @ratingTagSkilled.
  ///
  /// In en, this message translates to:
  /// **'Skilled'**
  String get ratingTagSkilled;

  /// No description provided for @ratingTagClean.
  ///
  /// In en, this message translates to:
  /// **'Clean work'**
  String get ratingTagClean;

  /// No description provided for @ratingTagTrustworthy.
  ///
  /// In en, this message translates to:
  /// **'Trustworthy'**
  String get ratingTagTrustworthy;

  /// No description provided for @ratingTagLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get ratingTagLate;

  /// No description provided for @ratingTagRude.
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get ratingTagRude;

  /// No description provided for @ratingTagPoorWork.
  ///
  /// In en, this message translates to:
  /// **'Poor quality work'**
  String get ratingTagPoorWork;

  /// No description provided for @ratingTagUnreliable.
  ///
  /// In en, this message translates to:
  /// **'Unreliable'**
  String get ratingTagUnreliable;

  /// No description provided for @ratingReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get ratingReviewLabel;

  /// No description provided for @ratingReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your experience'**
  String get ratingReviewHint;

  /// No description provided for @ratingReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Your review helps other families choose. Don\'t share phone numbers or personal details.'**
  String get ratingReviewNote;

  /// No description provided for @ratingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get ratingSubmit;

  /// No description provided for @ratingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get ratingSkip;

  /// No description provided for @ratingThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback'**
  String get ratingThanksTitle;

  /// No description provided for @ratingThanksBody.
  ///
  /// In en, this message translates to:
  /// **'Your rating helps other families choose with confidence.'**
  String get ratingThanksBody;

  /// No description provided for @ratingDone.
  ///
  /// In en, this message translates to:
  /// **'Back to booking'**
  String get ratingDone;

  /// No description provided for @ratingAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated this service'**
  String get ratingAlreadyTitle;

  /// No description provided for @ratingNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t rate this service yet'**
  String get ratingNotEligibleTitle;

  /// No description provided for @ratingNotEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'You can rate a worker once the service is completed.'**
  String get ratingNotEligibleBody;

  /// No description provided for @ratingScaleError.
  ///
  /// In en, this message translates to:
  /// **'That rating isn\'t on the scale. Please choose again.'**
  String get ratingScaleError;

  /// No description provided for @repRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request replacement'**
  String get repRequestTitle;

  /// No description provided for @repStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement status'**
  String get repStatusTitle;

  /// No description provided for @repHeadline.
  ///
  /// In en, this message translates to:
  /// **'Let\'s find you a better match'**
  String get repHeadline;

  /// No description provided for @repIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. We\'ll review your request and suggest alternatives.'**
  String get repIntro;

  /// No description provided for @repWhy.
  ///
  /// In en, this message translates to:
  /// **'Why do you want a replacement?'**
  String get repWhy;

  /// No description provided for @repRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get repRequired;

  /// No description provided for @repOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get repOptional;

  /// No description provided for @repReasonNotOnTime.
  ///
  /// In en, this message translates to:
  /// **'Not arriving on time'**
  String get repReasonNotOnTime;

  /// No description provided for @repReasonFrequentAbsences.
  ///
  /// In en, this message translates to:
  /// **'Frequent absences'**
  String get repReasonFrequentAbsences;

  /// No description provided for @repReasonWorkQuality.
  ///
  /// In en, this message translates to:
  /// **'Work quality is not good'**
  String get repReasonWorkQuality;

  /// No description provided for @repReasonBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour concern'**
  String get repReasonBehaviour;

  /// No description provided for @repReasonScheduleChanged.
  ///
  /// In en, this message translates to:
  /// **'Schedule no longer suits'**
  String get repReasonScheduleChanged;

  /// No description provided for @repReasonWorkerLeft.
  ///
  /// In en, this message translates to:
  /// **'Worker left or can\'t continue'**
  String get repReasonWorkerLeft;

  /// No description provided for @repReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety or trust concern'**
  String get repReasonSafety;

  /// No description provided for @repReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get repReasonOther;

  /// No description provided for @repMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get repMore;

  /// No description provided for @repNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything we should know?'**
  String get repNotesHint;

  /// No description provided for @repNotesNote.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share phone numbers or personal details.'**
  String get repNotesNote;

  /// No description provided for @repNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please tell us what happened'**
  String get repNotesRequired;

  /// No description provided for @repNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get repNextTitle;

  /// No description provided for @repNext1.
  ///
  /// In en, this message translates to:
  /// **'We review your request'**
  String get repNext1;

  /// No description provided for @repNext2.
  ///
  /// In en, this message translates to:
  /// **'We suggest verified alternatives'**
  String get repNext2;

  /// No description provided for @repNext3.
  ///
  /// In en, this message translates to:
  /// **'You choose, and a new booking is created'**
  String get repNext3;

  /// No description provided for @repStaysActive.
  ///
  /// In en, this message translates to:
  /// **'Your current booking stays active until you choose a replacement.'**
  String get repStaysActive;

  /// No description provided for @repChooseReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason to continue'**
  String get repChooseReasonHint;

  /// No description provided for @repNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened to continue'**
  String get repNoteHint;

  /// No description provided for @repSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request replacement'**
  String get repSubmit;

  /// No description provided for @repSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get repSubmitting;

  /// No description provided for @repOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your answers are kept.'**
  String get repOfflineBanner;

  /// No description provided for @repOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to submit'**
  String get repOfflineHint;

  /// No description provided for @repConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a replacement?'**
  String get repConfirmTitle;

  /// No description provided for @repConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Our team will review it.'**
  String get repConfirmBody;

  /// No description provided for @repConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, send request'**
  String get repConfirmYes;

  /// No description provided for @repGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get repGoBack;

  /// No description provided for @repErrTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your request'**
  String get repErrTitle;

  /// No description provided for @repErrBody.
  ///
  /// In en, this message translates to:
  /// **'Your details are saved. Please try again.'**
  String get repErrBody;

  /// No description provided for @repTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get repTryAgain;

  /// No description provided for @repNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement isn\'t available for this booking'**
  String get repNotEligibleTitle;

  /// No description provided for @repNotEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'If you think this is a mistake, our support team can help.'**
  String get repNotEligibleBody;

  /// No description provided for @repSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'If you feel unsafe, contact us right away.'**
  String get repSafetyTitle;

  /// No description provided for @repSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Our support team can help you with priority.'**
  String get repSafetyBody;

  /// No description provided for @repSafetyBtn.
  ///
  /// In en, this message translates to:
  /// **'Talk to support now'**
  String get repSafetyBtn;

  /// No description provided for @repSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get repSent;

  /// No description provided for @repReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get repReceivedTitle;

  /// No description provided for @repReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review it and suggest alternatives. You can check the status here any time.'**
  String get repReceivedBody;

  /// No description provided for @repRowRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get repRowRequest;

  /// No description provided for @repRowReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get repRowReason;

  /// No description provided for @repRowStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get repRowStatus;

  /// No description provided for @repTrack.
  ///
  /// In en, this message translates to:
  /// **'Track request'**
  String get repTrack;

  /// No description provided for @repBackBooking.
  ///
  /// In en, this message translates to:
  /// **'Back to booking'**
  String get repBackBooking;

  /// No description provided for @repStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get repStatusRequested;

  /// No description provided for @repStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get repStatusApproved;

  /// No description provided for @repStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get repStatusRejected;

  /// No description provided for @repStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get repStatusCancelled;

  /// No description provided for @repStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get repStatusCompleted;

  /// No description provided for @repStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get repStatusUnknown;

  /// No description provided for @repBannerReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your request'**
  String get repBannerReviewTitle;

  /// No description provided for @repBannerReviewBody.
  ///
  /// In en, this message translates to:
  /// **'You will hear from us within one working day.'**
  String get repBannerReviewBody;

  /// No description provided for @repBannerFindingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding alternatives for you'**
  String get repBannerFindingTitle;

  /// No description provided for @repBannerFindingBody.
  ///
  /// In en, this message translates to:
  /// **'Your request is approved. Pull down to refresh.'**
  String get repBannerFindingBody;

  /// No description provided for @repBannerReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Workers ready for you'**
  String get repBannerReadyTitle;

  /// No description provided for @repBannerReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose one to continue.'**
  String get repBannerReadyBody;

  /// No description provided for @repBannerScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement confirmed'**
  String get repBannerScheduledTitle;

  /// No description provided for @repBannerScheduledBody.
  ///
  /// In en, this message translates to:
  /// **'Your new booking is set to start on {date}. Open it to follow the next steps.'**
  String repBannerScheduledBody(String date);

  /// No description provided for @repBannerCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement complete'**
  String get repBannerCompleteTitle;

  /// No description provided for @repBannerCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your new booking has been created. Open it to follow the next steps.'**
  String get repBannerCompleteBody;

  /// No description provided for @repBannerRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t take this request forward'**
  String get repBannerRejectedTitle;

  /// No description provided for @repBannerRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Please contact support, or find a worker yourself.'**
  String get repBannerRejectedBody;

  /// No description provided for @repBannerCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get repBannerCancelledTitle;

  /// No description provided for @repBannerUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get repBannerUnknownTitle;

  /// No description provided for @repRequestNo.
  ///
  /// In en, this message translates to:
  /// **'Request #{ref}'**
  String repRequestNo(String ref);

  /// No description provided for @repTagCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current engagement'**
  String get repTagCurrent;

  /// No description provided for @repTagPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous engagement'**
  String get repTagPrevious;

  /// No description provided for @repSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {when}'**
  String repSubmitted(String when);

  /// No description provided for @repCopyId.
  ///
  /// In en, this message translates to:
  /// **'Copy request ID'**
  String get repCopyId;

  /// No description provided for @repCopied.
  ///
  /// In en, this message translates to:
  /// **'Request ID copied'**
  String get repCopied;

  /// No description provided for @repTeamNote.
  ///
  /// In en, this message translates to:
  /// **'Note from our team'**
  String get repTeamNote;

  /// No description provided for @repProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get repProgress;

  /// No description provided for @repStepReceived.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get repStepReceived;

  /// No description provided for @repStepReview.
  ///
  /// In en, this message translates to:
  /// **'Team review'**
  String get repStepReview;

  /// No description provided for @repStepReady.
  ///
  /// In en, this message translates to:
  /// **'New workers for you'**
  String get repStepReady;

  /// No description provided for @repStepChoose.
  ///
  /// In en, this message translates to:
  /// **'You choose a worker'**
  String get repStepChoose;

  /// No description provided for @repStepStarts.
  ///
  /// In en, this message translates to:
  /// **'Replacement starts'**
  String get repStepStarts;

  /// No description provided for @repStepRejected.
  ///
  /// In en, this message translates to:
  /// **'Request not approved'**
  String get repStepRejected;

  /// No description provided for @repStepCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get repStepCancelled;

  /// No description provided for @repStepCancelledSub.
  ///
  /// In en, this message translates to:
  /// **'Your current worker continues.'**
  String get repStepCancelledSub;

  /// No description provided for @repChipDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get repChipDone;

  /// No description provided for @repChipNow.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get repChipNow;

  /// No description provided for @repChipUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get repChipUpcoming;

  /// No description provided for @repChipCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get repChipCancelled;

  /// No description provided for @repChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a replacement'**
  String get repChooseTitle;

  /// No description provided for @repChooseSub.
  ///
  /// In en, this message translates to:
  /// **'Choose the worker you\'d like from these options.'**
  String get repChooseSub;

  /// No description provided for @repViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get repViewProfile;

  /// No description provided for @repSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a worker to continue'**
  String get repSelectHint;

  /// No description provided for @repConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm replacement'**
  String get repConfirm;

  /// No description provided for @repSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm this replacement?'**
  String get repSelectTitle;

  /// No description provided for @repSelectBody.
  ///
  /// In en, this message translates to:
  /// **'A new booking will be created with the worker you chose, and your current booking will be marked as replaced. The new booking then follows the usual steps.'**
  String get repSelectBody;

  /// No description provided for @repSelectYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, confirm'**
  String get repSelectYes;

  /// No description provided for @repSelectGone.
  ///
  /// In en, this message translates to:
  /// **'That worker is no longer available. Please choose another.'**
  String get repSelectGone;

  /// No description provided for @repSelectSame.
  ///
  /// In en, this message translates to:
  /// **'That is your current worker. Please choose someone else.'**
  String get repSelectSame;

  /// No description provided for @repChanged.
  ///
  /// In en, this message translates to:
  /// **'This request has changed. Here is its latest status.'**
  String get repChanged;

  /// No description provided for @repRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request a new replacement'**
  String get repRequestAgain;

  /// No description provided for @repSelectFail.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm the replacement. Please try again.'**
  String get repSelectFail;

  /// No description provided for @repOfflineContinue.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to continue.'**
  String get repOfflineContinue;

  /// No description provided for @repWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get repWithdraw;

  /// No description provided for @repWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get repWithdrawTitle;

  /// No description provided for @repWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Your current worker continues and your booking stays as it is.'**
  String get repWithdrawBody;

  /// No description provided for @repWithdrawYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel request'**
  String get repWithdrawYes;

  /// No description provided for @repKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get repKeep;

  /// No description provided for @repWithdrawFail.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t cancel the request. Please try again.'**
  String get repWithdrawFail;

  /// No description provided for @repViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get repViewBooking;

  /// No description provided for @repViewOld.
  ///
  /// In en, this message translates to:
  /// **'View previous booking'**
  String get repViewOld;

  /// No description provided for @repFindWorker.
  ///
  /// In en, this message translates to:
  /// **'Find a worker'**
  String get repFindWorker;

  /// No description provided for @repNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get repNeedHelp;

  /// No description provided for @repLoadErrTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this request'**
  String get repLoadErrTitle;

  /// No description provided for @repLoadErrBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get repLoadErrBody;

  /// No description provided for @repChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement history'**
  String get repChainTitle;

  /// No description provided for @repChainEntry.
  ///
  /// In en, this message translates to:
  /// **'{n}. {status}'**
  String repChainEntry(int n, String status);

  /// No description provided for @repChainThis.
  ///
  /// In en, this message translates to:
  /// **'This booking'**
  String get repChainThis;

  /// No description provided for @repViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View replacement request'**
  String get repViewRequest;

  /// No description provided for @supTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supTitle;

  /// No description provided for @supHeadline.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supHeadline;

  /// No description provided for @supSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified in the app when we reply.'**
  String get supSubtitle;

  /// No description provided for @supSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Feeling unsafe or facing an emergency?'**
  String get supSafetyTitle;

  /// No description provided for @supSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Call local emergency services first, then tell us.'**
  String get supSafetyBody;

  /// No description provided for @supSafetyBtn.
  ///
  /// In en, this message translates to:
  /// **'Report a safety issue'**
  String get supSafetyBtn;

  /// No description provided for @supQuickHelp.
  ///
  /// In en, this message translates to:
  /// **'Quick help'**
  String get supQuickHelp;

  /// No description provided for @supLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load support'**
  String get supLoadErrorTitle;

  /// No description provided for @supLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get supLoadErrorBody;

  /// No description provided for @supOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Tickets need a connection.'**
  String get supOfflineBanner;

  /// No description provided for @supOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to create a ticket.'**
  String get supOfflineHint;

  /// No description provided for @supCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a ticket'**
  String get supCreate;

  /// No description provided for @supContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supContactUs;

  /// No description provided for @supCall.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get supCall;

  /// No description provided for @supEmail.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get supEmail;

  /// No description provided for @supContactNA.
  ///
  /// In en, this message translates to:
  /// **'Not available right now'**
  String get supContactNA;

  /// No description provided for @supYourTickets.
  ///
  /// In en, this message translates to:
  /// **'Your tickets'**
  String get supYourTickets;

  /// No description provided for @supNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get supNoTickets;

  /// No description provided for @supNoTicketsBody.
  ///
  /// In en, this message translates to:
  /// **'When you raise a ticket it appears here.'**
  String get supNoTicketsBody;

  /// No description provided for @supTicketsError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your tickets.'**
  String get supTicketsError;

  /// No description provided for @supLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get supLoadMore;

  /// No description provided for @supUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String supUpdated(String when);

  /// No description provided for @tkStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tkStatusOpen;

  /// No description provided for @tkStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tkStatusInProgress;

  /// No description provided for @tkStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get tkStatusClosed;

  /// No description provided for @tkStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get tkStatusUnknown;

  /// No description provided for @supRaise.
  ///
  /// In en, this message translates to:
  /// **'Raise a ticket'**
  String get supRaise;

  /// No description provided for @supFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter tickets'**
  String get supFilterLabel;

  /// No description provided for @supNoOpen.
  ///
  /// In en, this message translates to:
  /// **'No open tickets'**
  String get supNoOpen;

  /// No description provided for @supNoClosed.
  ///
  /// In en, this message translates to:
  /// **'No closed tickets'**
  String get supNoClosed;

  /// No description provided for @tkNewHeading.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get tkNewHeading;

  /// No description provided for @tkNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tkNewCategory;

  /// No description provided for @tkNewCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get tkNewCategoryHint;

  /// No description provided for @tkNewMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get tkNewMore;

  /// No description provided for @tkNewDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tkNewDescLabel;

  /// No description provided for @tkNewDescPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened (at least {min} characters)'**
  String tkNewDescPlaceholder(int min);

  /// No description provided for @tkNewRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Related to'**
  String get tkNewRelatedTo;

  /// No description provided for @tkdTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get tkdTitle;

  /// No description provided for @tkdRaised.
  ///
  /// In en, this message translates to:
  /// **'Raised'**
  String get tkdRaised;

  /// No description provided for @tkdRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Related to'**
  String get tkdRelatedTo;

  /// No description provided for @tkdConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get tkdConversation;

  /// No description provided for @tkdYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tkdYou;

  /// No description provided for @tkNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get tkNewTitle;

  /// No description provided for @tkNewAbout.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get tkNewAbout;

  /// No description provided for @tkNewRelated.
  ///
  /// In en, this message translates to:
  /// **'Related booking (optional)'**
  String get tkNewRelated;

  /// No description provided for @tkNewRelatedHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a booking'**
  String get tkNewRelatedHint;

  /// No description provided for @tkNewRelatedHelp.
  ///
  /// In en, this message translates to:
  /// **'Attach one so we can help faster.'**
  String get tkNewRelatedHelp;

  /// No description provided for @tkNewAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached: Booking #{ref}'**
  String tkNewAttached(String ref);

  /// No description provided for @tkNewRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tkNewRemove;

  /// No description provided for @tkNewPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Related booking'**
  String get tkNewPickerTitle;

  /// No description provided for @tkNewPickerSub.
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get tkNewPickerSub;

  /// No description provided for @tkNewPickerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get tkNewPickerNone;

  /// No description provided for @tkNewPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any bookings yet.'**
  String get tkNewPickerEmpty;

  /// No description provided for @tkNewDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get tkNewDescribe;

  /// No description provided for @tkNewDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? Include dates and times if you can.'**
  String get tkNewDescribeHint;

  /// No description provided for @tkNewDescribeShort.
  ///
  /// In en, this message translates to:
  /// **'Please add a little more detail'**
  String get tkNewDescribeShort;

  /// No description provided for @tkNewPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share OTPs, card numbers or passwords.'**
  String get tkNewPrivacy;

  /// No description provided for @tkNewNotified.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified in the app when we reply.'**
  String get tkNewNotified;

  /// No description provided for @tkNewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get tkNewSubmit;

  /// No description provided for @tkNewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get tkNewSubmitting;

  /// No description provided for @tkNewTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tkNewTryAgain;

  /// No description provided for @tkNewHintCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category to continue'**
  String get tkNewHintCategory;

  /// No description provided for @tkNewHintDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem to continue'**
  String get tkNewHintDescribe;

  /// No description provided for @tkNewHintMore.
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail to continue'**
  String get tkNewHintMore;

  /// No description provided for @tkNewHintOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to submit'**
  String get tkNewHintOffline;

  /// No description provided for @tkNewErrTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your ticket'**
  String get tkNewErrTitle;

  /// No description provided for @tkNewErrBody.
  ///
  /// In en, this message translates to:
  /// **'Your details are saved. Please try again.'**
  String get tkNewErrBody;

  /// No description provided for @tkNewOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your details are saved.'**
  String get tkNewOfflineBanner;

  /// No description provided for @tkNewCategoriesError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the categories.'**
  String get tkNewCategoriesError;

  /// No description provided for @tkNewDupTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have an open ticket for this booking'**
  String get tkNewDupTitle;

  /// No description provided for @tkNewDupOpen.
  ///
  /// In en, this message translates to:
  /// **'Open that ticket'**
  String get tkNewDupOpen;

  /// No description provided for @tkNewSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety comes first'**
  String get tkNewSafetyTitle;

  /// No description provided for @tkNewSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger, call local emergency services first.'**
  String get tkNewSafetyBody;

  /// No description provided for @tkNewCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get tkNewCreatedTitle;

  /// No description provided for @tkNewCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve got your request. You\'ll hear from us soon.'**
  String get tkNewCreatedBody;

  /// No description provided for @tkNewView.
  ///
  /// In en, this message translates to:
  /// **'View ticket'**
  String get tkNewView;

  /// No description provided for @tkNewBack.
  ///
  /// In en, this message translates to:
  /// **'Back to support'**
  String get tkNewBack;

  /// No description provided for @tkNewRef.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{ref}'**
  String tkNewRef(String ref);

  /// No description provided for @tkNewCategoryGone.
  ///
  /// In en, this message translates to:
  /// **'That category is no longer available. Please choose another.'**
  String get tkNewCategoryGone;

  /// No description provided for @tkNewBookingGone.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that booking. Remove it and try again.'**
  String get tkNewBookingGone;

  /// No description provided for @tkdMeta.
  ///
  /// In en, this message translates to:
  /// **'Created {created} · Updated {updated}'**
  String tkdMeta(String created, String updated);

  /// No description provided for @tkdBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking #{ref}'**
  String tkdBooking(String ref);

  /// No description provided for @tkdEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket created · {time}'**
  String tkdEventCreated(String time);

  /// No description provided for @tkdEventStatus.
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status} · {time}'**
  String tkdEventStatus(String status, String time);

  /// No description provided for @tkdEventClosed.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed · {time}'**
  String tkdEventClosed(String time);

  /// No description provided for @tkdSupportName.
  ///
  /// In en, this message translates to:
  /// **'SevaNest Support'**
  String get tkdSupportName;

  /// No description provided for @tkdWorkerName.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get tkdWorkerName;

  /// No description provided for @tkdReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get tkdReplyHint;

  /// No description provided for @tkdSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get tkdSend;

  /// No description provided for @tkdPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share OTPs, PINs or card numbers.'**
  String get tkdPrivacy;

  /// No description provided for @tkdFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get tkdFailed;

  /// No description provided for @tkdRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tkdRetry;

  /// No description provided for @tkdDismiss.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tkdDismiss;

  /// No description provided for @tkdClosedBar.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed.'**
  String get tkdClosedBar;

  /// No description provided for @tkdClosedNew.
  ///
  /// In en, this message translates to:
  /// **'Create a new ticket'**
  String get tkdClosedNew;

  /// No description provided for @tkdResolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed'**
  String get tkdResolutionTitle;

  /// No description provided for @tkdLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this ticket'**
  String get tkdLoadErrorTitle;

  /// No description provided for @tkdLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get tkdLoadErrorBody;

  /// No description provided for @tkdOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Reconnect to send messages.'**
  String get tkdOffline;

  /// No description provided for @tkdClosedErr.
  ///
  /// In en, this message translates to:
  /// **'This ticket was closed, so your message wasn\'t sent.'**
  String get tkdClosedErr;

  /// No description provided for @tkdSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get tkdSending;

  /// No description provided for @tkdGone.
  ///
  /// In en, this message translates to:
  /// **'This ticket is no longer available.'**
  String get tkdGone;

  /// No description provided for @safetyMenu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get safetyMenu;

  /// No description provided for @safetyReport.
  ///
  /// In en, this message translates to:
  /// **'Report this worker'**
  String get safetyReport;

  /// No description provided for @safetyBlock.
  ///
  /// In en, this message translates to:
  /// **'Block this worker'**
  String get safetyBlock;

  /// No description provided for @safetyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get safetyReportTitle;

  /// No description provided for @safetyReportWhat.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get safetyReportWhat;

  /// No description provided for @safetyReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t show up'**
  String get safetyReasonNoShow;

  /// No description provided for @safetyReasonMisconduct.
  ///
  /// In en, this message translates to:
  /// **'Misconduct'**
  String get safetyReasonMisconduct;

  /// No description provided for @safetyReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get safetyReasonHarassment;

  /// No description provided for @safetyReasonTheft.
  ///
  /// In en, this message translates to:
  /// **'Theft'**
  String get safetyReasonTheft;

  /// No description provided for @safetyReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or cheating'**
  String get safetyReasonFraud;

  /// No description provided for @safetyReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get safetyReasonSafety;

  /// No description provided for @safetyReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get safetyReasonOther;

  /// No description provided for @safetyNote.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get safetyNote;

  /// No description provided for @safetyNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Only our team reads this.'**
  String get safetyNoteHint;

  /// No description provided for @safetyAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block this worker'**
  String get safetyAlsoBlock;

  /// No description provided for @safetySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get safetySubmit;

  /// No description provided for @safetySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get safetySubmitting;

  /// No description provided for @safetyThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, our team will review this'**
  String get safetyThanks;

  /// No description provided for @safetyEmergency.
  ///
  /// In en, this message translates to:
  /// **'If you\'re in immediate danger, call local emergency services first.'**
  String get safetyEmergency;

  /// No description provided for @safetyBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this worker?'**
  String get safetyBlockTitle;

  /// No description provided for @safetyBlockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be matched with this worker again. They won\'t appear in your search or shortlist.'**
  String get safetyBlockBody;

  /// No description provided for @safetyBlockYes.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get safetyBlockYes;

  /// No description provided for @safetyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Worker blocked'**
  String get safetyBlocked;

  /// No description provided for @safetyNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that worker.'**
  String get safetyNotFound;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifTabAll;

  /// No description provided for @notifTabUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifTabUnread;

  /// No description provided for @notifMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAll;

  /// No description provided for @notifMarkedUnread.
  ///
  /// In en, this message translates to:
  /// **'Marked as unread'**
  String get notifMarkedUnread;

  /// No description provided for @notifNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get notifNew;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Updates about your bookings, payments and support will appear here.'**
  String get notifEmptyBody;

  /// No description provided for @notifUnreadEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notifUnreadEmptyTitle;

  /// No description provided for @notifUnreadEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notifUnreadEmptyBody;

  /// No description provided for @notifViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get notifViewAll;

  /// No description provided for @notifCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notifCaughtUp;

  /// No description provided for @notifErrTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your notifications'**
  String get notifErrTitle;

  /// No description provided for @notifErrBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get notifErrBody;

  /// No description provided for @notifOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing saved notifications.'**
  String get notifOfflineBanner;

  /// No description provided for @notifOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notifOffTitle;

  /// No description provided for @notifOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn them on so you don\'t miss interview and payment updates.'**
  String get notifOffBody;

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notifOpenSettings;

  /// No description provided for @notifFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notifFallbackTitle;

  /// No description provided for @notifUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notifUnreadCount(int count);

  /// No description provided for @notifNoUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread updates'**
  String get notifNoUnread;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @serviceScheduleRow.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get serviceScheduleRow;

  /// No description provided for @serviceLocationRow.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get serviceLocationRow;

  /// No description provided for @serviceBookingRow.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get serviceBookingRow;

  /// No description provided for @serviceViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking details'**
  String get serviceViewBooking;

  /// No description provided for @notifPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get notifPromptTitle;

  /// No description provided for @notifPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Get a heads-up about interviews, payments and replies from support. You can change this any time in your phone\'s settings.'**
  String get notifPromptBody;

  /// No description provided for @notifPromptAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifPromptAllow;

  /// No description provided for @notifPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifPromptLater;

  /// No description provided for @notifAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifAccountTitle;

  /// No description provided for @notifAccountOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notifAccountOn;

  /// No description provided for @notifAccountOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifAccountOff;

  /// No description provided for @notifAccountNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Not turned on'**
  String get notifAccountNotAsked;

  /// No description provided for @accountSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get accountSupport;

  /// No description provided for @notifBannerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open notification'**
  String get notifBannerOpen;

  /// No description provided for @linkUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This item isn\'t available'**
  String get linkUnavailableTitle;

  /// No description provided for @linkUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or you may not have access to it.'**
  String get linkUnavailableBody;

  /// No description provided for @linkGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get linkGoHome;

  /// No description provided for @agoNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get agoNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour ago} other{{n} hours ago}}'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String agoDays(int n);

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceLeave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get attendanceLeave;

  /// No description provided for @attendanceCheckIn.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String attendanceCheckIn(String time);

  /// No description provided for @attendanceCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Out {time}'**
  String attendanceCheckOut(String time);

  /// No description provided for @serviceScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {window}'**
  String serviceScheduled(String window);

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get historyFilterYear;

  /// No description provided for @historyFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get historyFilterCategory;

  /// No description provided for @historyFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get historyFilterStatus;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get historySearchHint;

  /// No description provided for @historySummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{services} services · {workers} workers · {spent} total spent'**
  String historySummaryLine(int services, int workers, String spent);

  /// No description provided for @historyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No services match these filters.'**
  String get historyNoMatch;

  /// No description provided for @bookingHireAgain.
  ///
  /// In en, this message translates to:
  /// **'Hire again'**
  String get bookingHireAgain;

  /// No description provided for @safetyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Still sending your last request. Please try again in a moment.'**
  String get safetyInProgress;

  /// No description provided for @rebookFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start a new booking. Please try again.'**
  String get rebookFailed;

  /// No description provided for @rebookNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only a completed booking can be booked again.'**
  String get rebookNotAllowed;

  /// No description provided for @rebookWorkerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This worker isn\'t available right now.'**
  String get rebookWorkerUnavailable;

  /// No description provided for @rebookWorkerNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This worker can\'t take a new booking right now.'**
  String get rebookWorkerNotEligible;

  /// No description provided for @rebookDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have an open booking with this worker.'**
  String get rebookDuplicate;

  /// No description provided for @serviceReportMissing.
  ///
  /// In en, this message translates to:
  /// **'Report a missing day'**
  String get serviceReportMissing;

  /// No description provided for @exceptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a missing day'**
  String get exceptionTitle;

  /// No description provided for @exceptionHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a day your worker didn\'t record and tell us what happened.'**
  String get exceptionHint;

  /// No description provided for @exceptionDate.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get exceptionDate;

  /// No description provided for @exceptionNote.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get exceptionNote;

  /// No description provided for @exceptionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get exceptionSubmit;

  /// No description provided for @exceptionExists.
  ///
  /// In en, this message translates to:
  /// **'That day already has an entry.'**
  String get exceptionExists;

  /// No description provided for @exceptionSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ve recorded it.'**
  String get exceptionSent;

  /// No description provided for @ratingReviewTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your review is too long. Please shorten it to {max} characters.'**
  String ratingReviewTooLong(int max);

  /// No description provided for @accountShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get accountShortlist;

  /// No description provided for @accountBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get accountBookings;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get accountTerms;

  /// No description provided for @accountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get accountPrivacy;

  /// No description provided for @accountAbout.
  ///
  /// In en, this message translates to:
  /// **'About SevaNest'**
  String get accountAbout;

  /// No description provided for @accountVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String accountVersion(String version);

  /// No description provided for @accountLegalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet. We\'ll publish this soon.'**
  String get accountLegalUnavailable;

  /// No description provided for @accountLanguageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the language. Please try again.'**
  String get accountLanguageFailed;

  /// No description provided for @gateUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get gateUpdateTitle;

  /// No description provided for @gateUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This version of SevaNest is no longer supported. Please update the app to continue.'**
  String get gateUpdateBody;

  /// No description provided for @gateUpdateBtn.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get gateUpdateBtn;

  /// No description provided for @gateMaintTitle.
  ///
  /// In en, this message translates to:
  /// **'We will be right back'**
  String get gateMaintTitle;

  /// No description provided for @gateMaintBody.
  ///
  /// In en, this message translates to:
  /// **'SevaNest is down for maintenance. Please try again in a little while.'**
  String get gateMaintBody;

  /// No description provided for @gateRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check right now. Please try again.'**
  String get gateRetryFailed;

  /// No description provided for @gateDevOff.
  ///
  /// In en, this message translates to:
  /// **'Dev: switch off'**
  String get gateDevOff;

  /// No description provided for @devMenuGate.
  ///
  /// In en, this message translates to:
  /// **'Launch gate'**
  String get devMenuGate;

  /// No description provided for @devMenuGateUpdate.
  ///
  /// In en, this message translates to:
  /// **'Force update'**
  String get devMenuGateUpdate;

  /// No description provided for @devMenuGateMaint.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get devMenuGateMaint;

  /// No description provided for @legalConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept our terms'**
  String get legalConsentTitle;

  /// No description provided for @legalConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To continue, please accept the latest Terms of Service and Privacy Policy.'**
  String get legalConsentBody;

  /// No description provided for @legalConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get legalConsentAccept;

  /// No description provided for @legalConsentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy documents aren\'t available yet. Please try again later.'**
  String get legalConsentUnavailable;

  /// No description provided for @legalConsentFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your acceptance. Please try again.'**
  String get legalConsentFailed;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteTitle;

  /// No description provided for @deleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Request deletion'**
  String get deleteConfirmButton;

  /// No description provided for @deleteStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deletion'**
  String get deleteStatusTitle;

  /// No description provided for @deleteStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Deletion requested on {date}. We\'ll let you know when it\'s done.'**
  String deleteStatusRequested(String date);

  /// No description provided for @deleteStatusNone.
  ///
  /// In en, this message translates to:
  /// **'No deletion request.'**
  String get deleteStatusNone;

  /// No description provided for @deleteStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteStatusCompleted;

  /// No description provided for @deleteCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get deleteCancelRequest;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your deletion request. Please try again.'**
  String get deleteFailed;

  /// No description provided for @homeDeliveringTo.
  ///
  /// In en, this message translates to:
  /// **'YOUR SPOT'**
  String get homeDeliveringTo;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search \'Cook\', \'House maid\''**
  String get homeSearchHint;

  /// No description provided for @homeHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of help do you need?'**
  String get homeHelpTitle;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured for your home'**
  String get homeFeatured;

  /// No description provided for @homeWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why families choose SevaNest'**
  String get homeWhyTitle;

  /// No description provided for @homeWhy1.
  ///
  /// In en, this message translates to:
  /// **'Verified professionals near you'**
  String get homeWhy1;

  /// No description provided for @homeWhy2.
  ///
  /// In en, this message translates to:
  /// **'Video interview before you hire'**
  String get homeWhy2;

  /// No description provided for @homeWhy3.
  ///
  /// In en, this message translates to:
  /// **'Replacement if it is not a fit'**
  String get homeWhy3;

  /// No description provided for @homeHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How SevaNest works'**
  String get homeHowTitle;

  /// No description provided for @homeHow1Title.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get homeHow1Title;

  /// No description provided for @homeHow1Body.
  ///
  /// In en, this message translates to:
  /// **'Pick the help you need and your schedule.'**
  String get homeHow1Body;

  /// No description provided for @homeHow2Title.
  ///
  /// In en, this message translates to:
  /// **'Meet your match'**
  String get homeHow2Title;

  /// No description provided for @homeHow2Body.
  ///
  /// In en, this message translates to:
  /// **'Interview by video call, then a trial visit.'**
  String get homeHow2Body;

  /// No description provided for @homeHow3Title.
  ///
  /// In en, this message translates to:
  /// **'Start with confidence'**
  String get homeHow3Title;

  /// No description provided for @homeHow3Body.
  ///
  /// In en, this message translates to:
  /// **'Track attendance and activity at home.'**
  String get homeHow3Body;

  /// No description provided for @homeHow4Title.
  ///
  /// In en, this message translates to:
  /// **'Pay securely'**
  String get homeHow4Title;

  /// No description provided for @homeHow4Body.
  ///
  /// In en, this message translates to:
  /// **'Rate your worker and get support anytime.'**
  String get homeHow4Body;

  /// No description provided for @homePromoCookEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Home cooking'**
  String get homePromoCookEyebrow;

  /// No description provided for @homePromoCookTitle.
  ///
  /// In en, this message translates to:
  /// **'Meals made at home'**
  String get homePromoCookTitle;

  /// No description provided for @homePromoCookBody.
  ///
  /// In en, this message translates to:
  /// **'Breakfast, lunch and dinner preparation.'**
  String get homePromoCookBody;

  /// No description provided for @homePromoCookCta.
  ///
  /// In en, this message translates to:
  /// **'Find a cook'**
  String get homePromoCookCta;

  /// No description provided for @homePromoDriverEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get homePromoDriverEyebrow;

  /// No description provided for @homePromoDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get homePromoDriverTitle;

  /// No description provided for @homePromoDriverBody.
  ///
  /// In en, this message translates to:
  /// **'Personal or family driver, temporary driver.'**
  String get homePromoDriverBody;

  /// No description provided for @homePromoDriverCta.
  ///
  /// In en, this message translates to:
  /// **'Find a driver'**
  String get homePromoDriverCta;

  /// No description provided for @homePromoBabyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Babysitter'**
  String get homePromoBabyEyebrow;

  /// No description provided for @homePromoBabyTitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle care for little ones'**
  String get homePromoBabyTitle;

  /// No description provided for @homePromoBabyBody.
  ///
  /// In en, this message translates to:
  /// **'Child supervision and basic care.'**
  String get homePromoBabyBody;

  /// No description provided for @homePromoBabyCta.
  ///
  /// In en, this message translates to:
  /// **'Find a babysitter'**
  String get homePromoBabyCta;

  /// No description provided for @homePromoElderEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Elderly care'**
  String get homePromoElderEyebrow;

  /// No description provided for @homePromoElderTitle.
  ///
  /// In en, this message translates to:
  /// **'Company and support'**
  String get homePromoElderTitle;

  /// No description provided for @homePromoElderBody.
  ///
  /// In en, this message translates to:
  /// **'Non-clinical assistance and companionship.'**
  String get homePromoElderBody;

  /// No description provided for @homePromoElderCta.
  ///
  /// In en, this message translates to:
  /// **'Find a helper'**
  String get homePromoElderCta;

  /// No description provided for @homeBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get homeBookAgain;

  /// No description provided for @timingSceneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Choose a time of day'**
  String get timingSceneEmpty;

  /// No description provided for @startNotSelectedDays.
  ///
  /// In en, this message translates to:
  /// **'Not in your selected days'**
  String get startNotSelectedDays;

  /// No description provided for @startCountdownTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Starts tomorrow · {date}'**
  String startCountdownTomorrow(String date);

  /// No description provided for @startCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'Starts in {n} days · {date}'**
  String startCountdownDays(int n, String date);

  /// No description provided for @reviewSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get reviewSearching;

  /// No description provided for @reviewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search to see who matches'**
  String get reviewSearchHint;

  /// No description provided for @reviewNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the worker'**
  String get reviewNoteLabel;

  /// No description provided for @reviewNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get reviewNoteOptional;

  /// No description provided for @reviewNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pets at home, please bring your own gloves'**
  String get reviewNoteHint;

  /// No description provided for @reviewReassure.
  ///
  /// In en, this message translates to:
  /// **'You will see exact prices before you book. Nothing is charged now.'**
  String get reviewReassure;

  /// No description provided for @budgetTypicalBand.
  ///
  /// In en, this message translates to:
  /// **'Typical range'**
  String get budgetTypicalBand;

  /// No description provided for @locationAreaCaption.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get locationAreaCaption;

  /// No description provided for @resultsMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 worker matches your requirement} other{{count} workers match your requirement}}'**
  String resultsMatchCount(int count);

  /// No description provided for @resultsSortBest.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get resultsSortBest;

  /// No description provided for @resultsSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get resultsSortRating;

  /// No description provided for @resultsSortExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get resultsSortExperience;

  /// No description provided for @resultsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort workers'**
  String get resultsSortLabel;

  /// No description provided for @resultsViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get resultsViewProfile;

  /// No description provided for @resultsInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get resultsInterview;

  /// No description provided for @resultsAreasNear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Area near you} other{Areas near you}}'**
  String resultsAreasNear(int count);

  /// No description provided for @resultsNotFit.
  ///
  /// In en, this message translates to:
  /// **'Not the right fit?'**
  String get resultsNotFit;

  /// No description provided for @resultsChangeRequirement.
  ///
  /// In en, this message translates to:
  /// **'Change your requirement'**
  String get resultsChangeRequirement;

  /// No description provided for @resultsShortlistCount.
  ///
  /// In en, this message translates to:
  /// **'Shortlist, {count} saved'**
  String resultsShortlistCount(int count);

  /// No description provided for @workerFitRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} rated'**
  String workerFitRating(String rating);

  /// No description provided for @filterShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all workers'**
  String get filterShowAll;

  /// No description provided for @filterShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show workers'**
  String get filterShowResults;

  /// No description provided for @filterShowCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workers match} =1{Show 1 worker} other{Show {count} workers}}'**
  String filterShowCount(int count);

  /// No description provided for @reviewsBreakdownRow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{score} stars: 1 review} other{{score} stars: {count} reviews}}'**
  String reviewsBreakdownRow(int score, int count);

  /// No description provided for @filterAvailabilitySub.
  ///
  /// In en, this message translates to:
  /// **'When the worker is free'**
  String get filterAvailabilitySub;

  /// No description provided for @filterLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'Languages the worker speaks'**
  String get filterLanguageSub;

  /// No description provided for @filterExperienceSub.
  ///
  /// In en, this message translates to:
  /// **'Minimum years of work'**
  String get filterExperienceSub;

  /// No description provided for @filterRatingSub.
  ///
  /// In en, this message translates to:
  /// **'Minimum customer rating'**
  String get filterRatingSub;

  /// No description provided for @filterSortSub.
  ///
  /// In en, this message translates to:
  /// **'How to order the results'**
  String get filterSortSub;

  /// No description provided for @filterSortBest.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get filterSortBest;

  /// No description provided for @filterSortExperienced.
  ///
  /// In en, this message translates to:
  /// **'Most experienced'**
  String get filterSortExperienced;

  /// No description provided for @reviewsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only the reviewer\'s first name is shown. No contact details are ever shared.'**
  String get reviewsPrivacy;

  /// No description provided for @reviewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has not been reviewed yet. Reviews appear here after a completed booking.'**
  String reviewsEmptyBody(String name);

  /// No description provided for @reviewsBackToProfile.
  ///
  /// In en, this message translates to:
  /// **'Back to profile'**
  String get reviewsBackToProfile;

  /// No description provided for @reviewsScrollMore.
  ///
  /// In en, this message translates to:
  /// **'Scroll to load more reviews'**
  String get reviewsScrollMore;

  /// No description provided for @reviewsAllLoaded.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen all reviews'**
  String get reviewsAllLoaded;

  /// No description provided for @interviewsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get interviewsAll;

  /// No description provided for @interviewsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get interviewsUpcoming;

  /// No description provided for @interviewsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get interviewsPast;

  /// No description provided for @interviewsAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All interviews'**
  String get interviewsAllTitle;

  /// No description provided for @interviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next interview'**
  String get interviewNext;

  /// No description provided for @interviewNextSemantics.
  ///
  /// In en, this message translates to:
  /// **'Next interview with {name}, open details'**
  String interviewNextSemantics(String name);

  /// No description provided for @interviewCdDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day} other{days}}'**
  String interviewCdDays(int n);

  /// No description provided for @interviewCdHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{hour} other{hours}}'**
  String interviewCdHours(int n);

  /// No description provided for @interviewCdMins.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{min} other{mins}}'**
  String interviewCdMins(int n);

  /// No description provided for @interviewHeadWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String interviewHeadWaiting(String name);

  /// No description provided for @interviewHeadBooked.
  ///
  /// In en, this message translates to:
  /// **'Interview booked'**
  String get interviewHeadBooked;

  /// No description provided for @interviewHeadDone.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get interviewHeadDone;

  /// No description provided for @interviewHeadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled'**
  String get interviewHeadCancelled;

  /// No description provided for @interviewPbDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get interviewPbDone;

  /// No description provided for @interviewPbDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get interviewPbDecision;

  /// No description provided for @interviewTlWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the worker'**
  String get interviewTlWaiting;

  /// No description provided for @interviewTlAfter.
  ///
  /// In en, this message translates to:
  /// **'After the meeting'**
  String get interviewTlAfter;

  /// No description provided for @interviewTlDecisionHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm or look for someone else'**
  String get interviewTlDecisionHint;

  /// No description provided for @interviewAddCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get interviewAddCalendar;

  /// No description provided for @interviewCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview with {name}'**
  String interviewCalendarTitle(String name);

  /// No description provided for @interviewCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your calendar.'**
  String get interviewCalendarFailed;

  /// No description provided for @interviewCancelYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get interviewCancelYes;

  /// No description provided for @interviewDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get interviewDateToday;

  /// No description provided for @interviewDateHorizon.
  ///
  /// In en, this message translates to:
  /// **'You can book up to {days} days ahead.'**
  String interviewDateHorizon(int days);

  /// No description provided for @interviewMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get interviewMorning;

  /// No description provided for @interviewAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon & evening'**
  String get interviewAfternoon;

  /// No description provided for @interviewSlotMeta.
  ///
  /// In en, this message translates to:
  /// **'{period} · {minutes} min'**
  String interviewSlotMeta(String period, int minutes);

  /// No description provided for @interviewNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get interviewNoteTitle;

  /// No description provided for @interviewNowPickTime.
  ///
  /// In en, this message translates to:
  /// **'Now pick a time'**
  String get interviewNowPickTime;

  /// No description provided for @interviewReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get interviewReadyToSend;

  /// No description provided for @interviewSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get interviewSentTitle;

  /// No description provided for @interviewSentBody.
  ///
  /// In en, this message translates to:
  /// **'We have asked {name} for your {kind} on {when}. You will get a notification when they reply.'**
  String interviewSentBody(String name, String kind, String when);

  /// No description provided for @interviewViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get interviewViewRequest;

  /// No description provided for @interviewTkWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get interviewTkWorker;

  /// No description provided for @interviewTkStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get interviewTkStatus;

  /// No description provided for @interviewTkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply'**
  String get interviewTkWaiting;

  /// No description provided for @interviewsTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get interviewsTabEmpty;

  /// No description provided for @ratingHow.
  ///
  /// In en, this message translates to:
  /// **'How was {name}?'**
  String ratingHow(String name);

  /// No description provided for @ratingWord1.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingWord1;

  /// No description provided for @ratingWord2.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get ratingWord2;

  /// No description provided for @ratingWord3.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingWord3;

  /// No description provided for @ratingWord4.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get ratingWord4;

  /// No description provided for @ratingWord5.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingWord5;

  /// No description provided for @historyNotRated.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get historyNotRated;

  /// No description provided for @historyYouRated.
  ///
  /// In en, this message translates to:
  /// **'You rated'**
  String get historyYouRated;

  /// No description provided for @repInfo.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Our team reviews it and finds you other verified workers. Your current worker stays until you choose.'**
  String get repInfo;

  /// No description provided for @repNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get repNotesTitle;

  /// No description provided for @repRequestCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get repRequestCancel;

  /// No description provided for @repChooseWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a worker'**
  String get repChooseWorkerTitle;

  /// No description provided for @repBannerReadyFor.
  ///
  /// In en, this message translates to:
  /// **'Pick one to replace {name}.'**
  String repBannerReadyFor(String name);

  /// No description provided for @hintOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get hintOptional;

  /// No description provided for @hintRequired.
  ///
  /// In en, this message translates to:
  /// **'(required)'**
  String get hintRequired;
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
