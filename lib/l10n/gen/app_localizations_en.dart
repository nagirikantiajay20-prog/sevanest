// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SevaNest';

  @override
  String get appTagline => 'Verified Help. Trusted Homes.';

  @override
  String get navHome => 'Home';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navFavourites => 'Shortlist';

  @override
  String get navAccount => 'Account';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get emptyDefaultTitle => 'Nothing here yet';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'Couldn\'t reach SevaNest. Check your connection and try again.';

  @override
  String get errorSessionExpired => 'Please sign in again.';

  @override
  String get errorForbidden => 'You don\'t have access to this.';

  @override
  String get errorServer =>
      'Our servers are having trouble. Please try again shortly.';

  @override
  String get staleBanner => 'Showing earlier data. Couldn\'t refresh.';

  @override
  String get verified => 'Verified';

  @override
  String get verificationInProgress => 'Verification in progress';

  @override
  String get splashTagline => 'Trusted help for your home';

  @override
  String get splashTaglineHi => 'आपके घर का भरोसेमंद साथी';

  @override
  String get splashLoading => 'Getting things ready...';

  @override
  String get splashSlow => 'Still loading. Your connection seems slow.';

  @override
  String get splashFailedTitle => 'Can\'t connect right now';

  @override
  String get splashFailedBody => 'Please check your internet and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get signInAgain => 'Sign in again';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get supportUnavailable =>
      'Support contact isn\'t available right now.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get trustVerifiedWorkers => 'Verified workers';

  @override
  String get trustSecurePayments => 'Secure payments';

  @override
  String get trustHelpSupport => 'Help & support';

  @override
  String get loginWelcome => 'Welcome to SevaNest';

  @override
  String get loginSubtitle => 'Find verified, trusted help for your home.';

  @override
  String get loginHeading => 'Log in or sign up';

  @override
  String loginHelp(int digits) {
    return 'We\'ll send a $digits-digit code to verify your number.';
  }

  @override
  String get mobileLabel => 'Mobile number';

  @override
  String get mobileHint => '98765 43210';

  @override
  String get mobileInvalid => 'Enter a valid 10-digit mobile number';

  @override
  String get getOtp => 'Get OTP';

  @override
  String get sendingCode => 'Sending code...';

  @override
  String get sendFailedTitle => 'Couldn\'t send the code';

  @override
  String get sendFailedNetwork =>
      'Check your internet connection and tap Get OTP again.';

  @override
  String rateLimitedWait(String time) {
    return 'Too many requests. Please try again in $time.';
  }

  @override
  String get secureAndPrivate => 'Secure & private';

  @override
  String get trustOtpLogin => 'OTP-secured login';

  @override
  String get trustNumberPrivate => 'Your number stays private';

  @override
  String get legalPrefix => 'By continuing, you agree to our ';

  @override
  String get legalAnd => ' and ';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get linkUnavailable => 'This link isn\'t available yet.';

  @override
  String get languageButtonLabel => 'Change language';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageHint => 'You can change this anytime in Settings.';

  @override
  String get otpTitle => 'Verify your number';

  @override
  String otpEnterCode(int digits) {
    return 'Enter the $digits-digit code we sent to';
  }

  @override
  String get changeNumber => 'Change number';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get otpDidntGet => 'Didn\'t get it? Check your number or try again.';

  @override
  String get verifyContinue => 'Verify & continue';

  @override
  String get verifying => 'Verifying...';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get numberVerified => 'Number verified';

  @override
  String get otpWrong => 'That code isn\'t correct. Please try again.';

  @override
  String get otpExpired => 'This code has expired. Request a new one.';

  @override
  String get tooManyAttempts => 'Too many attempts';

  @override
  String tooManyWait(int minutes) {
    return 'Please wait $minutes minutes or contact support.';
  }

  @override
  String otpFooter(int minutes) {
    return 'We never share your number. This code expires in $minutes minutes.';
  }

  @override
  String get otpSentAgain => 'Code sent again';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get continueLabel => 'Continue';

  @override
  String get saving => 'Saving...';

  @override
  String get requiredField => 'Required';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'Your changes will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get profileStep => 'Step 3 of 3';

  @override
  String get profileSetupTitle => 'Tell us about you';

  @override
  String get profileSetupSubtitle => 'Takes less than a minute.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'e.g. Priya Sharma';

  @override
  String get fullNameHelp => 'As you\'d like workers to address you.';

  @override
  String get nameInvalid => 'Enter your name (2–60 letters)';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get emailHelp => 'For receipts and booking updates.';

  @override
  String get emailInvalid => 'Enter a valid email like name@example.com';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get ageConfirm => 'By continuing you confirm you\'re 18 or older.';

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileMobileLocked =>
      'Your number is your login and can\'t be changed here.';

  @override
  String get verificationLabel => 'Verification';

  @override
  String get addressesTitle => 'Saved addresses';

  @override
  String get addAddress => 'Add address';

  @override
  String get editAddressTitle => 'Edit address';

  @override
  String get addFirstAddress => 'Add your first address';

  @override
  String get addFirstAddressHelp => 'We need it to find workers near you.';

  @override
  String get houseLabel => 'House / flat no.';

  @override
  String get houseHint => 'e.g. Flat 402';

  @override
  String get streetLabel => 'Building or street';

  @override
  String get streetHint => 'e.g. Sai Residency';

  @override
  String get areaLabel => 'Area';

  @override
  String get areaHint => 'Select your area';

  @override
  String get cityLabel => 'City';

  @override
  String get pincodeLabel => 'Pincode';

  @override
  String get pincodeHint => '6 digits';

  @override
  String get pincodeInvalid => 'Enter a 6-digit pincode';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get alreadyDefault => 'This is your default address.';

  @override
  String get defaultTag => 'Default';

  @override
  String get saveAddress => 'Save address';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get deleteAddress => 'Delete address';

  @override
  String get deleteConfirmTitle => 'Delete this address?';

  @override
  String get deleteConfirmBody =>
      'It will be removed from your saved addresses.';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get addressDeleted => 'Address deleted';

  @override
  String get defaultUpdated => 'Default address updated';

  @override
  String get addressInUse => 'This address is used by an active booking.';

  @override
  String get addressNotFound => 'This address isn\'t available any more.';

  @override
  String get chooseArea => 'Choose your area';

  @override
  String get areasUnavailable =>
      'Couldn\'t load areas. You can type your area instead.';

  @override
  String get addressMenu => 'Address options';

  @override
  String homeGreeting(String name) {
    return 'Namaste, $name';
  }

  @override
  String get homeGreetingNoName => 'Namaste';

  @override
  String get homeSubtitle => 'What help do you need today?';

  @override
  String get homeHeroCook => 'Verified cooks near you';

  @override
  String get homeHeroDriver => 'Trusted drivers near you';

  @override
  String get homeHeroMaid => 'Reliable maids near you';

  @override
  String get homePause => 'Pause';

  @override
  String get homePlay => 'Play';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String homeNotificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get homeFindWorkerCta => 'Find a worker for your home';

  @override
  String get homeAddAddress => 'Add address';

  @override
  String get homeAddressBanner => 'Add an address to find workers';

  @override
  String get homeOffline => 'You\'re offline. Showing saved info.';

  @override
  String get homeLoadFailedTitle => 'We couldn\'t load your home';

  @override
  String get homeLoadFailedBody => 'Please try again.';

  @override
  String get homeActivity => 'Your activity';

  @override
  String get homeStageInProgress => 'In progress';

  @override
  String homeBookingRef(String ref) {
    return 'Booking #$ref';
  }

  @override
  String get homeStageMatched => 'Matched';

  @override
  String get homeStageTrial => 'Trial';

  @override
  String get homeStageActive => 'Active';

  @override
  String get homeViewBooking => 'View booking';

  @override
  String homeInterviewWith(String name) {
    return 'Interview with $name';
  }

  @override
  String homeTrialVisitWith(String name) {
    return 'Trial visit with $name';
  }

  @override
  String get homeVideoCall => 'Video call';

  @override
  String get homeTrialVisit => 'Trial visit';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTomorrow => 'Tomorrow';

  @override
  String homeStartsInMinutes(int n) {
    return 'Starts in $n min';
  }

  @override
  String homeStartsInHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return 'Starts in $_temp0';
  }

  @override
  String homeStartsInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return 'Starts in $_temp0';
  }

  @override
  String get homeStartingNow => 'Starting now';

  @override
  String get homeNoBookingsTitle => 'No bookings yet';

  @override
  String get homeNoBookingsBody =>
      'Find your first trusted worker in 3 simple steps';

  @override
  String get homeStep1 => 'Tell us what help you need';

  @override
  String get homeStep2 => 'Meet verified workers near you';

  @override
  String get homeStep3 => 'Book a trial with confidence';

  @override
  String get homeFindWorker => 'Find a worker';

  @override
  String get homeShortlistTitle => 'Your shortlist';

  @override
  String get homeViewShortlist => 'View shortlist';

  @override
  String get homeSupportShortcut => 'Need help with something?';

  @override
  String get homeSupportShortcutBody => 'Our support team is here for you.';

  @override
  String get devMenuTitle => 'Developer menu';

  @override
  String get devMenuApiMode => 'API behaviour';

  @override
  String get devMenuUser => 'Customer';

  @override
  String get devMenuReturning => 'Returning';

  @override
  String get devMenuNew => 'New';

  @override
  String get discoverTitle => 'Find a worker';

  @override
  String discoverStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get discoverContinue => 'Continue';

  @override
  String discoverContinueWith(String what) {
    return 'Continue with $what';
  }

  @override
  String get discoverClose => 'Close';

  @override
  String get discoverDiscardTitle => 'Discard this request?';

  @override
  String get discoverDiscardBody => 'Your answers so far will be cleared.';

  @override
  String get discoverDiscard => 'Discard';

  @override
  String get discoverKeepEditing => 'Keep editing';

  @override
  String get discoverChange => 'Change';

  @override
  String get discoverLoadFailedBody => 'Check your connection and try again.';

  @override
  String get serviceHeading => 'What kind of help do you need?';

  @override
  String get serviceSub =>
      'Pick one. You can search again for other services anytime.';

  @override
  String get serviceSearchHint => 'Search services';

  @override
  String get servicePopular => 'Popular';

  @override
  String get serviceLoadFailedTitle => 'We couldn\'t load services';

  @override
  String get serviceEmptyTitle => 'No services available right now';

  @override
  String serviceNoMatch(String q) {
    return 'No services match “$q”';
  }

  @override
  String get serviceNoMatchBody =>
      'Try a different word or choose something else.';

  @override
  String get serviceClearSearch => 'Clear search';

  @override
  String get engagementTitle => 'Engagement type';

  @override
  String get engagementHeading => 'How do you need them to work?';

  @override
  String get engagementSub =>
      'Choose the arrangement that suits your home. You can compare options later.';

  @override
  String get engagementLoadFailedTitle => 'We couldn\'t load options';

  @override
  String get engFullTime => 'Full-time';

  @override
  String get engFullTimeDesc => 'Works fixed hours every day at your home.';

  @override
  String get engFullTimeMeta => '6 to 10 hours · Most days';

  @override
  String get engPartTime => 'Part-time';

  @override
  String get engPartTimeDesc => 'A few set hours each day, such as mornings.';

  @override
  String get engPartTimeMeta => '2 to 5 hours · Most days';

  @override
  String get engDaily => 'Daily';

  @override
  String get engDailyDesc => 'Comes on the days you choose, for a set job.';

  @override
  String get engDailyMeta => 'Pick your days each week';

  @override
  String get engHourly => 'Hourly';

  @override
  String get engHourlyDesc => 'Pay by the hour for short or one-off jobs.';

  @override
  String get engHourlyMeta => 'Book by the hour';

  @override
  String get engLiveIn => 'Live-in';

  @override
  String get engLiveInDesc => 'Stays at your home with food and a room.';

  @override
  String get engLiveInMeta => 'Stays on site';

  @override
  String get locationTitle => 'Location';

  @override
  String get locationHeading => 'Where do you need help?';

  @override
  String get locationSub => 'We\'ll show workers who serve this area.';

  @override
  String get locationUseCurrent => 'Use my current location';

  @override
  String get locationUseCurrentSub => 'Uses GPS, only while you use the app';

  @override
  String get locationFinding => 'Finding your location...';

  @override
  String get locationFindingSub => 'This takes a few seconds';

  @override
  String get locationSaved => 'Saved addresses';

  @override
  String locationSavedCount(int n) {
    return '$n saved';
  }

  @override
  String get locationOffTitle => 'Location access is off';

  @override
  String get locationOffBody =>
      'Turn it on in Settings, or choose a saved address.';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationChooseSaved => 'Choose a saved address';

  @override
  String get locationFailed =>
      'Couldn\'t get your location. Choose a saved address instead.';

  @override
  String get locationNoAddressTitle => 'Add your first address';

  @override
  String get locationNoAddressBody => 'We need it to find workers near you.';

  @override
  String get locationLoadFailedTitle => 'We couldn\'t load your addresses';

  @override
  String locationContinueTo(String area) {
    return 'Continue to $area';
  }

  @override
  String get locationMakeDefault => 'Make default';
}
