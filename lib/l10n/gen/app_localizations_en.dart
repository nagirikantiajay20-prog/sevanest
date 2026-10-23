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
  String get loginHeadline => 'A safer, happier home starts here';

  @override
  String get loginSubhead =>
      'Book nearby professionals for all your home needs.';

  @override
  String get brandCaption => 'TRUSTED HOME SERVICES';

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
  String get loginTrustNearby => 'Nearby professionals';

  @override
  String get loginTrustSupport => 'Dedicated support';

  @override
  String get privateTitle => 'Your information stays private';

  @override
  String get privateBody => 'We never share your number with anyone.';

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
  String get addressLabelLabel => 'Label (optional)';

  @override
  String get addressLabelHint => 'Home, Parents\' home';

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
      'We will schedule your account and data for deletion. You can cancel the request until it is processed.';

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
  String get homeHeadline => 'Find the right help for your home';

  @override
  String get homeSubtitle => 'Nearby professionals for all your home needs.';

  @override
  String get homeExplore => 'Explore services';

  @override
  String get homeSeeAll => 'See all';

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
  String get offlineBanner => 'You are offline. Some things may not load.';

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
  String get homeViewAll => 'View all';

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
  String get locationNotServed =>
      'We do not serve this area yet. Please choose another address.';

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

  @override
  String get timingTitle => 'Timing';

  @override
  String get timingHeading => 'When do you need them?';

  @override
  String get timingSub =>
      'Pick a time window. You\'ll agree exact timings in the interview.';

  @override
  String get timingLoadFailedTitle => 'We couldn\'t load timing options';

  @override
  String get timingWindowLabel => 'Preferred time of day';

  @override
  String get winEarlyMorning => 'Early morning';

  @override
  String get winMorning => 'Morning';

  @override
  String get winAfternoon => 'Afternoon';

  @override
  String get winEvening => 'Evening';

  @override
  String get winNight => 'Night';

  @override
  String get winFlexible => 'Flexible';

  @override
  String get winFlexibleRange => 'Any time';

  @override
  String get winEarlyMorningPlural => 'Early mornings';

  @override
  String get winMorningPlural => 'Mornings';

  @override
  String get winAfternoonPlural => 'Afternoons';

  @override
  String get winEveningPlural => 'Evenings';

  @override
  String get winNightPlural => 'Nights';

  @override
  String get timingShiftHours => 'Shift hours';

  @override
  String get timingExactHours => 'Exact hours';

  @override
  String get timingStartTime => 'Start time';

  @override
  String get timingEndTime => 'End time';

  @override
  String get timingPickTime => 'Choose a time';

  @override
  String timingHoursPerDay(String d) {
    return '$d per day';
  }

  @override
  String get timingHoursPerDayLabel => 'Hours per day';

  @override
  String timingHoursChip(int n) {
    return '$n hrs';
  }

  @override
  String get timingDays => 'Days of the week';

  @override
  String get daysEvery => 'Every day';

  @override
  String get daysWeekdays => 'Weekdays';

  @override
  String get daysWeekends => 'Weekends';

  @override
  String daysRange(String a, String b) {
    return '$a to $b';
  }

  @override
  String get timingDate => 'Date';

  @override
  String get timingChooseDate => 'Choose a date';

  @override
  String durHours(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durMinutes(int n) {
    return '$n min';
  }

  @override
  String get timingErrEnd => 'End time must be after the start time.';

  @override
  String timingErrShort(String d) {
    return 'Choose at least $d.';
  }

  @override
  String timingErrLong(String d) {
    return 'A shift can be at most $d.';
  }

  @override
  String get timingErrDays => 'Choose at least one day.';

  @override
  String timingDaysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selected: $count days',
      one: 'Selected: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get timingErrDate => 'Choose a date.';

  @override
  String get timingEditSummary => 'Edit times and days';

  @override
  String get timeSheetSub => 'In 15-minute steps';

  @override
  String get timeSheetSet => 'Set time';

  @override
  String get timeSheetHour => 'Hour';

  @override
  String get timeSheetMinute => 'Minute';

  @override
  String get timeSheetPeriod => 'AM or PM';

  @override
  String get dateSheetTitle => 'Select date';

  @override
  String dateSheetSet(String date) {
    return 'Set date: $date';
  }

  @override
  String get dateSheetPick => 'Select a date';

  @override
  String get startTitle => 'Start date';

  @override
  String get startHeading => 'When should they start?';

  @override
  String get startSub =>
      'Pick the first day. Workers will confirm they are free.';

  @override
  String startTomorrow(String date) {
    return 'Tomorrow, $date';
  }

  @override
  String startInDays(int n, String date) {
    return 'In $n days, $date';
  }

  @override
  String startNextMonday(String date) {
    return 'Next Monday, $date';
  }

  @override
  String get startPickAnother => 'Pick another date';

  @override
  String get startLoadFailedTitle => 'We couldn\'t load available dates';

  @override
  String startLimitNote(int n, String date) {
    return 'You can start up to $n days from today (by $date).';
  }

  @override
  String startOutsideTitle(String date) {
    return '$date isn\'t one of your selected days';
  }

  @override
  String startOutsideBody(String days) {
    return 'You chose $days. You can continue anyway, or adjust your days.';
  }

  @override
  String get startAdjustDays => 'Adjust days';

  @override
  String get calPrev => 'Previous month';

  @override
  String get calNext => 'Next month';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetHeading => 'What\'s your budget?';

  @override
  String get budgetSubMonthly =>
      'Set a range per month. You\'ll see exact prices before you book.';

  @override
  String get budgetSubHourly =>
      'Set a range per hour. You\'ll see exact prices before you book.';

  @override
  String get budgetPerMonth => '₹ per month';

  @override
  String get budgetPerHour => '₹ per hour';

  @override
  String guidanceTypical(String engagement, String service, String city) {
    return 'Typical for a $engagement $service in $city';
  }

  @override
  String budgetRangePerMonth(String range) {
    return '$range per month';
  }

  @override
  String budgetRangePerHour(String range) {
    return '$range per hour';
  }

  @override
  String get guidanceUse => 'Use this range';

  @override
  String get guidanceErrTitle => 'We couldn\'t load price guidance';

  @override
  String get guidanceErrBody => 'You can still enter a range below.';

  @override
  String get budgetMinimum => 'Minimum';

  @override
  String get budgetMaximum => 'Maximum';

  @override
  String get budgetMinField => 'Minimum (₹)';

  @override
  String get budgetMaxField => 'Maximum (₹)';

  @override
  String get budgetAny => 'Any budget';

  @override
  String get budgetAnyBody =>
      'You\'ll see workers at every price. Adjust anytime.';

  @override
  String get budgetFlexibleLabel => 'Flexible budget';

  @override
  String get budgetFlexibleBody => 'Show workers at every price';

  @override
  String get budgetLow =>
      'That\'s below the usual range, so you may see fewer workers. You can still continue.';

  @override
  String get budgetErrMinMax => 'Maximum must be at least the minimum.';

  @override
  String get budgetErrMissing => 'Enter a minimum and a maximum.';

  @override
  String get budgetErrHigh => 'That amount looks too high. Please check it.';

  @override
  String get budgetReview => 'Review requirement';

  @override
  String get budgetDone => 'Done';

  @override
  String get budgetSlider => 'Budget range';

  @override
  String get gapNoService => 'Choose a service first.';

  @override
  String get gapNoEngagement => 'Choose how you need them to work.';

  @override
  String get gapNoAddress => 'Choose an address.';

  @override
  String get gapTiming => 'Complete the timing details.';

  @override
  String get gapNoStartDate => 'Choose a start date.';

  @override
  String get gapStartDateRange =>
      'Pick a start date within the allowed window.';

  @override
  String get gapBudget => 'Check your budget.';

  @override
  String get resumeTitle => 'Resume your request';

  @override
  String resumeBody(String what, int n, int total) {
    return '$what · Step $n of $total';
  }

  @override
  String get resumeContinue => 'Continue';

  @override
  String get resumeDiscard => 'Start over';

  @override
  String resultsTitle(String category, String area) {
    return '$category near $area';
  }

  @override
  String get resultsEmptyTitle => 'No matching workers found';

  @override
  String get resultsEmptyBody =>
      'Try changing your area, timing or engagement type.';

  @override
  String get resultsEditRequirement => 'Edit requirement';

  @override
  String get resultsStale => 'Showing earlier results';

  @override
  String get resultsLoadMoreRetry => 'Couldn\'t load more. Retry';

  @override
  String workerExperienceYears(int years) {
    return '$years yrs experience';
  }

  @override
  String workerExperienceMonths(int months) {
    return '$months months experience';
  }

  @override
  String get workerExperienceUnknown => 'Experience not listed';

  @override
  String get workerNew => 'New';

  @override
  String workerRatingSemantics(String rating, int count) {
    return 'Rated $rating from $count reviews';
  }

  @override
  String workerAvailableWindow(String start, String end) {
    return 'Available $start to $end';
  }

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterButton => 'Filter';

  @override
  String get filterAvailability => 'Available';

  @override
  String get filterMorning => 'Morning (6am-12pm)';

  @override
  String get filterAfternoon => 'Afternoon (12pm-5pm)';

  @override
  String get filterEvening => 'Evening (5pm-9pm)';

  @override
  String get filterLanguage => 'Language';

  @override
  String get filterRating => 'Rating';

  @override
  String filterRatingMin(String min) {
    return '$min+ rating';
  }

  @override
  String get filterSort => 'Sort by';

  @override
  String get filterSortRating => 'Highest rated';

  @override
  String get filterExperience => 'Experience';

  @override
  String filterExperienceYears(int years) {
    return '$years+ years';
  }

  @override
  String get filterApply => 'Apply';

  @override
  String get filterReset => 'Reset';

  @override
  String filterActiveSemantics(int count) {
    return '$count filters active';
  }

  @override
  String get favouriteAdd => 'Add to shortlist';

  @override
  String get favouriteRemove => 'Remove from shortlist';

  @override
  String get favouriteFailed => 'Couldn\'t update shortlist. Try again.';

  @override
  String get favouriteRemoved => 'Removed from shortlist';

  @override
  String get favouriteUndo => 'Undo';

  @override
  String get favsTitle => 'Shortlist';

  @override
  String get accountSectionActivity => 'My activity';

  @override
  String get accountSectionDetails => 'My details';

  @override
  String get accountSectionHelp => 'Help and legal';

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get favsSubtitle =>
      'Workers you saved. Request an interview when you are ready.';

  @override
  String get favsFilterAll => 'All';

  @override
  String get favsRequestInterview => 'Request interview';

  @override
  String get favsEmptyTitle => 'Your shortlist is empty';

  @override
  String get favsEmptyBody => 'Tap the heart on a worker to save them.';

  @override
  String get favsFindWorker => 'Find a worker';

  @override
  String get workerUnavailableTag => 'Unavailable';

  @override
  String get workerUnavailableTitle => 'This worker is no longer available';

  @override
  String get workerUnavailableBody => 'Let\'s find another.';

  @override
  String get workerFindAnother => 'Find another worker';

  @override
  String get workerProfileTitle => 'Worker profile';

  @override
  String get workerVerifiedInfo => 'What does verified mean?';

  @override
  String get workerVerifiedSheetTitle => 'What verified means';

  @override
  String get workerVerifiedSheetBody =>
      'Verified workers have passed the identity and background checks SevaNest requires before they can appear in search. We never show ID documents or contact details.';

  @override
  String get workerGotIt => 'Got it';

  @override
  String get workerRequestInterview => 'Request interview or trial';

  @override
  String get workerExperienceLabel => 'Experience';

  @override
  String get workerLanguagesLabel => 'Languages';

  @override
  String get workerAreasLabel => 'Areas';

  @override
  String get workerAvailabilityLabel => 'Availability';

  @override
  String get workerEngagementLabel => 'Prefers';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsSeeAll => 'See all reviews';

  @override
  String get reviewsEmpty => 'No reviews yet';

  @override
  String get workerStartSearchTitle => 'Start a search first';

  @override
  String get workerStartSearchBody =>
      'Tell us what you need, then request an interview with this worker.';

  @override
  String get workerStartSearch => 'Start a search';

  @override
  String get reviewTitle => 'Review your request';

  @override
  String get reviewAllDone => 'All steps done';

  @override
  String get reviewHeading => 'Check your requirement';

  @override
  String get reviewSub =>
      'Make sure everything looks right before we find workers.';

  @override
  String get reviewRowService => 'Service';

  @override
  String get reviewRowEngagement => 'Engagement';

  @override
  String get reviewRowAddress => 'Address';

  @override
  String get reviewRowTiming => 'Timing';

  @override
  String get reviewRowStartDate => 'Start date';

  @override
  String get reviewRowBudget => 'Budget';

  @override
  String get reviewEdit => 'Edit';

  @override
  String get reviewSearch => 'Find workers';

  @override
  String workerMoreChip(int count) {
    return '+$count';
  }

  @override
  String reviewEditSemantics(String field) {
    return 'Edit $field';
  }

  @override
  String reviewByline(String name, String date) {
    return '$name · $date';
  }

  @override
  String get workerSkillsLabel => 'Skills';

  @override
  String get workerVerificationInProgress => 'Verification in progress';

  @override
  String get workerCannotRequestReason =>
      'You can request an interview once this worker\'s verification is complete.';

  @override
  String workerStatReviews(int count) {
    return '$count reviews';
  }

  @override
  String get workerStatExperience => 'Experience';

  @override
  String workerStatYears(int years) {
    return '$years yrs';
  }

  @override
  String workerStatMonths(int months) {
    return '$months mo';
  }

  @override
  String get workerStatUnknown => 'Not listed';

  @override
  String get workerShortlist => 'Shortlist';

  @override
  String get workerShortlisted => 'Shortlisted';

  @override
  String get reviewsLoadFailed => 'Couldn\'t load reviews.';

  @override
  String get addressLocationFailed =>
      'Couldn\'t get your location. Check the location permission, or fill in the address yourself.';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out of SevaNest?';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again with your mobile number.';

  @override
  String get devMenuLive => 'Backend data';

  @override
  String get devMenuLiveOn => 'Live';

  @override
  String get devMenuLiveOff => 'Mock';

  @override
  String get interviewRequestTitle => 'Request an interview';

  @override
  String get interviewRescheduleTitle => 'Reschedule';

  @override
  String get interviewTypeLabel => 'What would you like?';

  @override
  String get interviewTypeInterview => 'Interview';

  @override
  String get interviewTypeTrial => 'Trial visit';

  @override
  String get interviewTypeInterviewHint =>
      'A short chat to talk about the work.';

  @override
  String get interviewTypeTrialHint => 'Meet in person and see them work.';

  @override
  String get interviewHeadline => 'Meet before you decide';

  @override
  String get interviewPickToContinue => 'Pick a date and time to continue';

  @override
  String get interviewDateLabel => 'Date';

  @override
  String get interviewDateButton => 'Choose a date';

  @override
  String get interviewSlotLabel => 'Time';

  @override
  String get interviewPickDateFirst => 'Pick a date to see free times.';

  @override
  String get interviewNoSlots =>
      'No times are free on this date. Try another day.';

  @override
  String get interviewNoteLabel => 'Note for the worker (optional)';

  @override
  String get interviewNoteHint => 'Anything the worker should know';

  @override
  String get interviewSubmit => 'Send request';

  @override
  String get interviewSubmitReschedule => 'Confirm new time';

  @override
  String get interviewSubmitting => 'Sending...';

  @override
  String get interviewSent => 'Request sent';

  @override
  String get interviewRescheduled => 'Time changed';

  @override
  String get interviewSlotTaken =>
      'That time is no longer available. Pick another.';

  @override
  String get interviewDetailTitle => 'Interview';

  @override
  String get interviewsTitle => 'Interviews';

  @override
  String get interviewStatusRequested => 'Requested';

  @override
  String get interviewStatusScheduled => 'Scheduled';

  @override
  String get interviewStatusProposed => 'New time suggested';

  @override
  String get interviewStatusCompleted => 'Completed';

  @override
  String get interviewStatusCancelled => 'Cancelled';

  @override
  String get interviewStatusDeclined => 'Declined';

  @override
  String get interviewStatusConfirmed => 'Confirmed';

  @override
  String get interviewStatusNotAFit => 'Not a fit';

  @override
  String get interviewStatusUnknown => 'Updated';

  @override
  String get interviewCopyRequested => 'Waiting for the worker to respond';

  @override
  String interviewCopyProposed(String date, String time) {
    return 'The worker suggested $date, $time';
  }

  @override
  String get interviewAcceptProposal => 'Accept new time';

  @override
  String get interviewKeepOriginal => 'Keep my time';

  @override
  String get interviewProposalAccepted => 'New time accepted';

  @override
  String get interviewProposalRejected => 'Kept your original time';

  @override
  String get interviewCopyCompleted => 'Decide whether to confirm this worker';

  @override
  String get interviewCopyCancelled => 'You cancelled this request';

  @override
  String get interviewCopyDeclined => 'The worker couldn\'t take this request';

  @override
  String get interviewCopyConfirmed => 'You confirmed this worker';

  @override
  String get interviewCopyNotAFit => 'You marked this worker as not a fit';

  @override
  String get interviewCopyUnknown => 'Status updated';

  @override
  String get interviewWhenRow => 'When';

  @override
  String get interviewTypeRow => 'Type';

  @override
  String get interviewRequirementRow => 'Your requirement';

  @override
  String get interviewProgress => 'Progress';

  @override
  String get interviewCancel => 'Cancel request';

  @override
  String get interviewCancelTitle => 'Cancel this request?';

  @override
  String get interviewCancelBody => 'The worker will be told.';

  @override
  String get interviewCancelKeep => 'Keep request';

  @override
  String get interviewCancelled => 'Request cancelled';

  @override
  String get interviewReschedule => 'Reschedule';

  @override
  String get interviewConfirmWorker => 'Confirm this worker';

  @override
  String get interviewDecline => 'Not a fit';

  @override
  String get interviewDeclineTitle => 'Not a fit?';

  @override
  String get interviewDeclineBody =>
      'We\'ll close this request so you can look for another worker.';

  @override
  String get interviewDeclineConfirm => 'Yes, not a fit';

  @override
  String get interviewDeclined => 'Marked as not a fit';

  @override
  String get interviewSupport => 'Contact support';

  @override
  String get interviewTlRequested => 'Request sent';

  @override
  String get interviewTlScheduled => 'Interview scheduled';

  @override
  String get interviewTlCompleted => 'Interview completed';

  @override
  String get interviewTlDecision => 'Your decision';

  @override
  String get interviewsEmptyTitle => 'No interviews yet';

  @override
  String get interviewsEmptyBody =>
      'Request an interview from a worker\'s profile.';

  @override
  String get interviewsFind => 'Find a worker';

  @override
  String get accountInterviews => 'Interviews';

  @override
  String interviewCopyScheduled(String kind, String date, String time) {
    return '$kind on $date, $time';
  }

  @override
  String interviewWhenValue(String date, String time) {
    return '$date, $time';
  }

  @override
  String get bookingsTitle => 'Bookings';

  @override
  String get bookingsTabCurrent => 'Current';

  @override
  String get bookingsTabPast => 'Past';

  @override
  String get bookingsEmptyTitle => 'No bookings yet';

  @override
  String get bookingsEmptyBody =>
      'When you hire a worker, your booking appears here.';

  @override
  String get bookingsPastEmpty => 'No past bookings';

  @override
  String get bookingsFind => 'Find a worker';

  @override
  String get bookingsPay => 'Complete payment';

  @override
  String get bookingDetailTitle => 'Booking';

  @override
  String get bookingStatusNewRequest => 'Request received';

  @override
  String get bookingStatusMatched => 'Worker matched';

  @override
  String get bookingStatusScheduled => 'Interview scheduled';

  @override
  String get bookingStatusInterviewDone => 'Interview done';

  @override
  String get bookingStatusPendingPayment => 'Payment due';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusActive => 'Active';

  @override
  String get bookingStatusReplacementRequested => 'Replacement requested';

  @override
  String get bookingStatusReplaced => 'Replaced';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusUnknown => 'Updated';

  @override
  String get bookingCopyNewRequest => 'We are finding a worker for you';

  @override
  String get bookingCopyMatched =>
      'A worker is matched. Schedule an interview or trial';

  @override
  String get bookingCopyScheduled => 'Interview or trial is scheduled';

  @override
  String get bookingCopyInterviewDone =>
      'Decide whether to confirm this worker';

  @override
  String get bookingCopyPendingPayment =>
      'Pay the booking fee to confirm this booking';

  @override
  String get bookingCopyConfirmed => 'Your booking is confirmed';

  @override
  String get bookingCopyActive => 'The service is under way';

  @override
  String get bookingCopyReplacementRequested =>
      'We are arranging a replacement';

  @override
  String get bookingCopyReplaced => 'This booking was replaced';

  @override
  String get bookingCopyCompleted => 'This booking is complete';

  @override
  String get bookingCopyCancelled => 'This booking was cancelled';

  @override
  String get bookingCopyUnknown => 'Status updated';

  @override
  String get bookingServiceRow => 'Service';

  @override
  String get bookingScheduleRow => 'Starts';

  @override
  String get bookingInterviewRow => 'Interview';

  @override
  String get bookingAreaRow => 'Area';

  @override
  String get bookingBudgetRow => 'Budget';

  @override
  String get bookingNoteRow => 'Note';

  @override
  String get bookingReferenceRow => 'Reference';

  @override
  String get bookingTimeline => 'Progress';

  @override
  String get bookingPayNow => 'Complete payment';

  @override
  String get bookingViewService => 'View active service';

  @override
  String get bookingRate => 'Rate worker';

  @override
  String get bookingReplace => 'Request replacement';

  @override
  String get bookingCancel => 'Cancel booking';

  @override
  String get bookingReceipt => 'Receipt';

  @override
  String get bookingSupport => 'Get help';

  @override
  String get bookingConfirmWorker => 'Confirm this worker';

  @override
  String get bookingSchedule => 'Schedule interview';

  @override
  String get bookingInterviewDone => 'Interview done';

  @override
  String get bookingNotAFit => 'Not a fit';

  @override
  String get bookingPreviousLink => 'See the replaced booking';

  @override
  String get bookingPaymentDue => 'Payment due';

  @override
  String get bookingPaymentNone => 'No payment due';

  @override
  String get cancelSheetTitle => 'Cancel this booking?';

  @override
  String get cancelSheetReason => 'Why are you cancelling?';

  @override
  String get cancelReasonFound => 'I found another worker';

  @override
  String get cancelReasonPlans => 'My plans changed';

  @override
  String get cancelReasonMistake => 'I booked by mistake';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get cancelNoteHint => 'Anything you would like to add (optional)';

  @override
  String get cancelConfirm => 'Cancel booking';

  @override
  String get cancelDismiss => 'Keep booking';

  @override
  String get cancelRequested => 'Cancellation requested';

  @override
  String get confirmTitle => 'Confirm worker';

  @override
  String get confirmHeading => 'Confirm this worker?';

  @override
  String get confirmSub =>
      'Check the details, then confirm. You pay the booking fee next.';

  @override
  String get confirmStartDate => 'Start date';

  @override
  String get confirmEditRequirement => 'Edit requirement';

  @override
  String get confirmFeeRow => 'Booking fee';

  @override
  String get confirmFeeNote =>
      'Estimate. The final amount is shown at the payment step.';

  @override
  String get confirmTaxRow => 'Taxes';

  @override
  String get confirmTotalRow => 'Total due today';

  @override
  String get confirmPriceDetails => 'Price details';

  @override
  String get confirmSummary => 'Booking summary';

  @override
  String get confirmButton => 'Confirm worker';

  @override
  String get confirmButtonBusy => 'Confirming...';

  @override
  String get confirmDone => 'Worker confirmed';

  @override
  String get confirmNotAllowed => 'This booking can\'t be confirmed right now.';

  @override
  String get confirmDateInvalid => 'Pick today or a later date.';

  @override
  String bookingCopyScheduledAt(String kind, String date, String time) {
    return '$kind on $date, $time';
  }

  @override
  String bookingBudgetRange(String range, String period) {
    return '$range $period';
  }

  @override
  String get interviewDuplicate =>
      'You already have an open request with this worker.';

  @override
  String get interviewComplete => 'Interview done';

  @override
  String get interviewSchedule => 'Choose a time';

  @override
  String bookingNextWhen(String date) {
    return '$date';
  }

  @override
  String get bookingViewInterview => 'Interview details';

  @override
  String get bookingPaymentRow => 'Payment';

  @override
  String get payTitle => 'Payment';

  @override
  String get payHeading => 'Complete your payment';

  @override
  String get paySub => 'Pay securely with UPI, cards or net banking.';

  @override
  String get payAmountLabel => 'Amount to pay';

  @override
  String payButton(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payButtonBusy => 'Opening payment…';

  @override
  String get payVerifying => 'Confirming your payment…';

  @override
  String get payVerifyingWait => 'Please wait, confirming your payment';

  @override
  String get payCancelledSnack => 'Payment cancelled. You can try again.';

  @override
  String get payLeaveTitle => 'Leave payment?';

  @override
  String get payLeaveBody => 'Your booking stays pending.';

  @override
  String get payLeaveStay => 'Stay';

  @override
  String get payLeaveConfirm => 'Leave';

  @override
  String get paySuccessTitle => 'Payment received';

  @override
  String get paySuccessBody => 'Thank you. We\'re updating your booking.';

  @override
  String payReceiptNumber(String number) {
    return 'Receipt $number';
  }

  @override
  String get payViewBooking => 'View booking';

  @override
  String get payViewReceipt => 'View receipt';

  @override
  String get payFailedTitle => 'Payment didn\'t go through';

  @override
  String get payFailedBody =>
      'Your booking is still waiting for payment. You can try again.';

  @override
  String get payFailedDebitNote =>
      'If any amount was debited, it will be refunded automatically.';

  @override
  String get payRetry => 'Try again';

  @override
  String get payGetHelp => 'Get help';

  @override
  String get payClose => 'Close';

  @override
  String get payPendingTitle => 'We\'re confirming your payment';

  @override
  String get payPendingBody =>
      'This can take a few minutes. Your booking will update when it\'s done.';

  @override
  String get payRefresh => 'Check again';

  @override
  String get payAgain => 'I haven\'t paid, pay again';

  @override
  String get payNotPayableTitle => 'Nothing to pay';

  @override
  String get payNotPayableBody =>
      'This booking isn\'t waiting for payment. It may already be paid.';

  @override
  String get payFeeNotConfigured =>
      'The booking fee isn\'t set up yet. Please try again later or contact support.';

  @override
  String get payRecoveredPaid => 'Your payment was received.';

  @override
  String get payRecoveredFailed => 'Your last payment didn\'t go through.';

  @override
  String get payRecoveredPending =>
      'We\'re still confirming your last payment.';

  @override
  String get payRecoveredView => 'View';

  @override
  String get accountTransactions => 'Transactions';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsEmpty => 'No transactions yet';

  @override
  String get transactionsEmptyBody => 'Payments you make will show up here.';

  @override
  String get txnFilterAll => 'All';

  @override
  String get txnFilterPaid => 'Paid';

  @override
  String get txnFilterRefunded => 'Refunded';

  @override
  String get txnStatusCreated => 'Not paid';

  @override
  String get txnStatusPending => 'Confirming';

  @override
  String get txnStatusSucceeded => 'Paid';

  @override
  String get txnStatusFailed => 'Failed';

  @override
  String get txnStatusRefundPending => 'Refund pending';

  @override
  String get txnStatusRefunded => 'Refunded';

  @override
  String get txnStatusRefundFailed => 'Refund failed';

  @override
  String get txnStatusUnknown => 'Updated';

  @override
  String get txnRowTitle => 'Booking payment';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get txnAmountRow => 'Amount';

  @override
  String get txnStatusRow => 'Status';

  @override
  String get txnReceiptRow => 'Receipt number';

  @override
  String get txnPaidOnRow => 'Paid on';

  @override
  String get txnBookingRow => 'Booking';

  @override
  String get txnMethodRow => 'Paid with';

  @override
  String get txnReferenceRow => 'Reference';

  @override
  String get txnRefundedOnRow => 'Refunded on';

  @override
  String get txnMethodUpi => 'UPI';

  @override
  String get txnMethodCard => 'Card';

  @override
  String get txnMethodNetbanking => 'Net banking';

  @override
  String get txnMethodWallet => 'Wallet';

  @override
  String get txnMethodEmi => 'EMI';

  @override
  String get txnNoReceipt => 'Issued once the payment succeeds';

  @override
  String get txnNeedHelp => 'Need help with this payment?';

  @override
  String get txnRefundNote =>
      'Refunds go back to your original payment method.';

  @override
  String get serviceTitle => 'Active service';

  @override
  String get serviceNoneTitle => 'No active service';

  @override
  String get serviceNoneBody => 'When a worker starts, you\'ll see them here.';

  @override
  String get servicePickTitle => 'Which service?';

  @override
  String serviceSince(String date) {
    return 'Since $date';
  }

  @override
  String get serviceTodayTitle => 'Today';

  @override
  String get serviceTodayNone => 'Not recorded yet';

  @override
  String get serviceMonthTitle => 'This month';

  @override
  String get serviceBookingLink => 'Booking details';

  @override
  String get serviceSupport => 'Report an issue';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceEmpty =>
      'No updates yet. You\'ll see your worker\'s status here.';

  @override
  String get attendanceLoadMore => 'Load more';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceException => 'Exception';

  @override
  String get attendanceUnknown => 'Updated';

  @override
  String get historyTitle => 'Service history';

  @override
  String get historyEmptyTitle => 'No past services yet';

  @override
  String get historyEmptyBody => 'Services you\'ve booked will appear here.';

  @override
  String get historySectionCurrent => 'Current';

  @override
  String get historySectionCompleted => 'Completed';

  @override
  String get historySectionCancelled => 'Cancelled';

  @override
  String get historySectionReplaced => 'Replaced';

  @override
  String get historyRate => 'Rate now';

  @override
  String historyRatedLabel(int score, int max) {
    return 'You rated $score out of $max';
  }

  @override
  String get accountHistory => 'Service history';

  @override
  String get ratingTitle => 'Rate your experience';

  @override
  String get ratingQuestion => 'How was your experience?';

  @override
  String get ratingTapHint => 'Tap a star to rate';

  @override
  String ratingStarLabel(int n, int max) {
    return '$n out of $max';
  }

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get notifSettingsBody =>
      'Choose which alerts pop up while you use the app. System notifications are managed in your phone\'s settings.';

  @override
  String get notifCatBookings => 'Bookings and interviews';

  @override
  String get notifCatPayments => 'Payments and refunds';

  @override
  String get notifCatReplacements => 'Replacements';

  @override
  String get notifCatSupport => 'Support tickets';

  @override
  String get policyLink => 'Cancellation and refund policy';

  @override
  String get policyCancellationTitle => 'Cancellation';

  @override
  String get policyRefundTitle => 'Refunds';

  @override
  String get policyReadMore => 'Read more';

  @override
  String get repNeededFrom => 'Needed from (optional)';

  @override
  String get repNeededFromPick => 'Pick a date';

  @override
  String get repNeededFromClear => 'Clear date';

  @override
  String get repNeededFromNote =>
      'For our team\'s information. It does not change the replacement\'s start date.';

  @override
  String get ratingTagsGood => 'What went well?';

  @override
  String get ratingTagsBad => 'What went wrong?';

  @override
  String get ratingTagPunctual => 'Punctual';

  @override
  String get ratingTagPolite => 'Polite';

  @override
  String get ratingTagSkilled => 'Skilled';

  @override
  String get ratingTagClean => 'Clean work';

  @override
  String get ratingTagTrustworthy => 'Trustworthy';

  @override
  String get ratingTagLate => 'Late';

  @override
  String get ratingTagRude => 'Rude';

  @override
  String get ratingTagPoorWork => 'Poor quality work';

  @override
  String get ratingTagUnreliable => 'Unreliable';

  @override
  String ratingTagsLine(String tags) {
    return 'Tags: $tags';
  }

  @override
  String get ratingReviewLabel => 'Write a review (optional)';

  @override
  String get ratingReviewHint => 'Tell others about your experience.';

  @override
  String get ratingReviewNote =>
      'Your review helps other families choose. Don\'t share phone numbers or personal details.';

  @override
  String get ratingChoose => 'Choose a star rating to continue';

  @override
  String get ratingSubmit => 'Submit review';

  @override
  String get ratingSkip => 'Skip for now';

  @override
  String get ratingThanksTitle => 'Thanks for your feedback';

  @override
  String get ratingThanksBody => 'Your rating helps other families choose.';

  @override
  String get ratingDone => 'Back to booking';

  @override
  String get ratingAlreadyTitle => 'You\'ve already rated this service';

  @override
  String get ratingNotEligibleTitle => 'You can\'t rate this service yet';

  @override
  String get ratingNotEligibleBody =>
      'You can rate a worker once the service is completed.';

  @override
  String get ratingScaleError =>
      'That rating isn\'t on the scale. Please choose again.';

  @override
  String get repRequestTitle => 'Request replacement';

  @override
  String get repStatusTitle => 'Replacement';

  @override
  String get repHeadline => 'Let\'s find you a better match';

  @override
  String get repIntro =>
      'Tell us what went wrong. We\'ll review your request and suggest alternatives.';

  @override
  String get repWhy => 'Why do you want a replacement?';

  @override
  String get repRequired => 'Required';

  @override
  String get repOptional => 'Optional';

  @override
  String get repReasonNotOnTime => 'Not arriving on time';

  @override
  String get repReasonFrequentAbsences => 'Frequent absences';

  @override
  String get repReasonWorkQuality => 'Work quality is not good';

  @override
  String get repReasonBehaviour => 'Behaviour concern';

  @override
  String get repReasonScheduleChanged => 'Schedule no longer suits';

  @override
  String get repReasonWorkerLeft => 'Worker left or can\'t continue';

  @override
  String get repReasonSafety => 'Safety or trust concern';

  @override
  String get repReasonOther => 'Other';

  @override
  String get repMore => 'Tell us more';

  @override
  String get repNotesHint => 'What happened? Include dates if you can.';

  @override
  String get repNotesNote => 'Don\'t share phone numbers or personal details.';

  @override
  String get repNotesRequired => 'Please tell us what happened';

  @override
  String get repNextTitle => 'What happens next';

  @override
  String get repNext1 => 'We review your request';

  @override
  String get repNext2 => 'We suggest verified alternatives';

  @override
  String get repNext3 => 'You choose, and a new booking is created';

  @override
  String get repStaysActive =>
      'Your current booking stays active until you choose a replacement.';

  @override
  String get repChooseReasonHint => 'Choose a reason to continue';

  @override
  String get repNoteHint => 'Tell us what happened to continue';

  @override
  String get repSubmit => 'Submit request';

  @override
  String get repSubmitting => 'Submitting...';

  @override
  String get repOfflineBanner => 'You\'re offline. Your answers are kept.';

  @override
  String get repOfflineHint => 'Connect to the internet to submit';

  @override
  String get repConfirmTitle => 'Submit replacement request?';

  @override
  String get repConfirmBody =>
      'We\'ll start looking for an alternative. Your current booking stays active until you choose.';

  @override
  String get repConfirmYes => 'Yes, submit';

  @override
  String get repGoBack => 'Go back';

  @override
  String get repErrTitle => 'We couldn\'t submit your request';

  @override
  String get repErrBody => 'Your details are saved. Please try again.';

  @override
  String get repTryAgain => 'Try again';

  @override
  String get repNotEligibleTitle =>
      'Replacement isn\'t available for this booking';

  @override
  String get repNotEligibleBody =>
      'If you think this is a mistake, our support team can help.';

  @override
  String get repSafetyTitle => 'If you feel unsafe, contact us right away.';

  @override
  String get repSafetyBody => 'Our support team can help you with priority.';

  @override
  String get repSafetyBtn => 'Talk to support now';

  @override
  String get repSent => 'Request sent';

  @override
  String get repReceivedTitle => 'Request received';

  @override
  String get repReceivedBody =>
      'We\'ll review it and suggest alternatives. You can check the status here any time.';

  @override
  String get repRowRequest => 'Request';

  @override
  String get repRowReason => 'Reason';

  @override
  String get repRowStatus => 'Status';

  @override
  String get repTrack => 'Track request';

  @override
  String get repBackBooking => 'Back to booking';

  @override
  String get repStatusRequested => 'Under review';

  @override
  String get repStatusApproved => 'Approved';

  @override
  String get repStatusRejected => 'Not approved';

  @override
  String get repStatusCancelled => 'Cancelled';

  @override
  String get repStatusCompleted => 'Completed';

  @override
  String get repStatusUnknown => 'Updated';

  @override
  String get repBannerReviewTitle => 'We\'re reviewing your request';

  @override
  String get repBannerReviewBody => 'We\'ll suggest alternatives soon.';

  @override
  String get repBannerFindingTitle => 'Finding alternatives for you';

  @override
  String get repBannerFindingBody =>
      'Your request is approved. Pull down to refresh.';

  @override
  String repBannerReadyTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alternatives are ready',
      one: '1 alternative is ready',
    );
    return '$_temp0';
  }

  @override
  String get repBannerReadyBody => 'Choose one to continue.';

  @override
  String get repBannerScheduledTitle => 'Replacement confirmed';

  @override
  String repBannerScheduledBody(String date) {
    return 'Your new booking is set to start on $date. Open it to follow the next steps.';
  }

  @override
  String get repBannerCompleteTitle => 'Replacement complete';

  @override
  String get repBannerCompleteBody =>
      'Your new booking has been created. Open it to follow the next steps.';

  @override
  String get repBannerRejectedTitle => 'We couldn\'t take this request forward';

  @override
  String get repBannerRejectedBody =>
      'Please contact support, or find a worker yourself.';

  @override
  String get repBannerCancelledTitle => 'Request cancelled';

  @override
  String get repBannerUnknownTitle => 'Updated';

  @override
  String repRequestNo(String ref) {
    return 'Request #$ref';
  }

  @override
  String get repTagCurrent => 'Current engagement';

  @override
  String get repTagPrevious => 'Previous engagement';

  @override
  String repSubmitted(String when) {
    return 'Submitted $when';
  }

  @override
  String get repCopyId => 'Copy request ID';

  @override
  String get repCopied => 'Request ID copied';

  @override
  String get repTeamNote => 'Note from our team';

  @override
  String get repProgress => 'Progress';

  @override
  String get repStepReceived => 'Request received';

  @override
  String get repStepReview => 'Under review';

  @override
  String get repStepReady => 'Alternatives ready';

  @override
  String get repStepChoose => 'You choose a worker';

  @override
  String get repStepStarts => 'Replacement starts';

  @override
  String get repStepRejected => 'Request not approved';

  @override
  String get repStepCancelled => 'Request cancelled';

  @override
  String get repStepCancelledSub => 'Your current worker continues.';

  @override
  String get repChipDone => 'Done';

  @override
  String get repChipNow => 'Now';

  @override
  String get repChipUpcoming => 'Upcoming';

  @override
  String get repChipCancelled => 'Cancelled';

  @override
  String get repChooseTitle => 'Choose a replacement';

  @override
  String get repChooseSub =>
      'Choose the worker you\'d like from these options.';

  @override
  String get repViewProfile => 'View profile';

  @override
  String get repSelectHint => 'Select a worker to continue';

  @override
  String get repConfirm => 'Confirm replacement';

  @override
  String get repSelectTitle => 'Confirm this replacement?';

  @override
  String get repSelectBody =>
      'A new booking will be created with the worker you chose, and your current booking will be marked as replaced. The new booking then follows the usual steps.';

  @override
  String get repSelectYes => 'Yes, confirm';

  @override
  String get repSelectGone =>
      'That worker is no longer available. Please choose another.';

  @override
  String get repSelectSame =>
      'That is your current worker. Please choose someone else.';

  @override
  String get repChanged =>
      'This request has changed. Here is its latest status.';

  @override
  String get repRequestAgain => 'Request a new replacement';

  @override
  String get repSelectFail =>
      'We couldn\'t confirm the replacement. Please try again.';

  @override
  String get repOfflineContinue => 'Connect to the internet to continue.';

  @override
  String get repWithdraw => 'Cancel request';

  @override
  String get repWithdrawTitle => 'Cancel this request?';

  @override
  String get repWithdrawBody =>
      'Your current worker continues and your booking stays as it is.';

  @override
  String get repWithdrawYes => 'Yes, cancel request';

  @override
  String get repKeep => 'Keep request';

  @override
  String get repWithdrawFail =>
      'We couldn\'t cancel the request. Please try again.';

  @override
  String get repViewBooking => 'View booking';

  @override
  String get repViewOld => 'View previous booking';

  @override
  String get repFindWorker => 'Find a worker';

  @override
  String get repNeedHelp => 'Need help?';

  @override
  String get repLoadErrTitle => 'We couldn\'t load this request';

  @override
  String get repLoadErrBody => 'Please check your connection and try again.';

  @override
  String get repChainTitle => 'Replacement history';

  @override
  String repChainEntry(int n, String status) {
    return '$n. $status';
  }

  @override
  String get repChainThis => 'This booking';

  @override
  String get repViewRequest => 'View replacement request';

  @override
  String get supTitle => 'Support';

  @override
  String get supHeadline => 'How can we help?';

  @override
  String get supSubtitle => 'You\'ll be notified in the app when we reply.';

  @override
  String get supSafetyTitle => 'Feeling unsafe or facing an emergency?';

  @override
  String get supSafetyBody =>
      'Call local emergency services first, then tell us.';

  @override
  String get supSafetyBtn => 'Report a safety issue';

  @override
  String get supQuickHelp => 'Quick help';

  @override
  String get supLoadErrorTitle => 'We couldn\'t load support';

  @override
  String get supLoadErrorBody => 'Please try again.';

  @override
  String get supOfflineBanner => 'You\'re offline. Tickets need a connection.';

  @override
  String get supOfflineHint => 'Connect to the internet to create a ticket.';

  @override
  String get supCreate => 'Create a ticket';

  @override
  String get supContactUs => 'Contact us';

  @override
  String get supCall => 'Call support';

  @override
  String get supEmail => 'Email support';

  @override
  String get supContactNA => 'Not available right now';

  @override
  String get supYourTickets => 'Your tickets';

  @override
  String get supNoTickets => 'No tickets yet';

  @override
  String get supNoTicketsBody => 'When you raise a ticket it appears here.';

  @override
  String get supTicketsError => 'We couldn\'t load your tickets.';

  @override
  String get supLoadMore => 'Load more';

  @override
  String supUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get tkStatusOpen => 'Open';

  @override
  String get tkStatusInProgress => 'In progress';

  @override
  String get tkStatusClosed => 'Closed';

  @override
  String get tkStatusUnknown => 'Updated';

  @override
  String get tkNewTitle => 'New ticket';

  @override
  String get tkNewAbout => 'What is this about?';

  @override
  String get tkNewRelated => 'Related booking (optional)';

  @override
  String get tkNewRelatedHint => 'Choose a booking';

  @override
  String get tkNewRelatedHelp => 'Attach one so we can help faster.';

  @override
  String tkNewAttached(String ref) {
    return 'Attached: Booking #$ref';
  }

  @override
  String get tkNewRemove => 'Remove';

  @override
  String get tkNewPickerTitle => 'Related booking';

  @override
  String get tkNewPickerSub => 'Recent bookings';

  @override
  String get tkNewPickerNone => 'None';

  @override
  String get tkNewPickerEmpty => 'You don\'t have any bookings yet.';

  @override
  String get tkNewDescribe => 'Describe the problem';

  @override
  String get tkNewDescribeHint =>
      'What happened? Include dates and times if you can.';

  @override
  String get tkNewDescribeShort => 'Please add a little more detail';

  @override
  String get tkNewPrivacy => 'Don\'t share OTPs, card numbers or passwords.';

  @override
  String get tkNewNotified => 'You\'ll be notified in the app when we reply.';

  @override
  String get tkNewSubmit => 'Submit ticket';

  @override
  String get tkNewSubmitting => 'Submitting…';

  @override
  String get tkNewTryAgain => 'Try again';

  @override
  String get tkNewHintCategory => 'Choose a category to continue';

  @override
  String get tkNewHintDescribe => 'Describe the problem to continue';

  @override
  String get tkNewHintMore => 'Add a little more detail to continue';

  @override
  String get tkNewHintOffline => 'Connect to the internet to submit';

  @override
  String get tkNewErrTitle => 'We couldn\'t submit your ticket';

  @override
  String get tkNewErrBody => 'Your details are saved. Please try again.';

  @override
  String get tkNewOfflineBanner => 'You\'re offline. Your details are saved.';

  @override
  String get tkNewCategoriesError => 'We couldn\'t load the categories.';

  @override
  String get tkNewDupTitle =>
      'You already have an open ticket for this booking';

  @override
  String get tkNewDupOpen => 'Open that ticket';

  @override
  String get tkNewSafetyTitle => 'Your safety comes first';

  @override
  String get tkNewSafetyBody =>
      'If you are in immediate danger, call local emergency services first.';

  @override
  String get tkNewCreatedTitle => 'Ticket created';

  @override
  String get tkNewCreatedBody =>
      'We\'ve got your request. You\'ll hear from us soon.';

  @override
  String get tkNewView => 'View ticket';

  @override
  String get tkNewBack => 'Back to support';

  @override
  String tkNewRef(String ref) {
    return 'Ticket #$ref';
  }

  @override
  String get tkNewCategoryGone =>
      'That category is no longer available. Please choose another.';

  @override
  String get tkNewBookingGone =>
      'We couldn\'t find that booking. Remove it and try again.';

  @override
  String tkdMeta(String created, String updated) {
    return 'Created $created · Updated $updated';
  }

  @override
  String tkdBooking(String ref) {
    return 'Booking #$ref';
  }

  @override
  String tkdEventCreated(String time) {
    return 'Ticket created · $time';
  }

  @override
  String tkdEventStatus(String status, String time) {
    return 'Status changed to $status · $time';
  }

  @override
  String tkdEventClosed(String time) {
    return 'Ticket closed · $time';
  }

  @override
  String get tkdSupportName => 'SevaNest Support';

  @override
  String get tkdWorkerName => 'Worker';

  @override
  String get tkdReplyHint => 'Write a reply';

  @override
  String get tkdSend => 'Send';

  @override
  String get tkdPrivacy => 'Don\'t share OTPs, PINs or card numbers.';

  @override
  String get tkdFailed => 'Failed';

  @override
  String get tkdRetry => 'Retry';

  @override
  String get tkdDismiss => 'Remove';

  @override
  String get tkdClosedBar => 'This ticket is closed.';

  @override
  String get tkdClosedNew => 'Create a new ticket';

  @override
  String get tkdResolutionTitle => 'Ticket closed';

  @override
  String get tkdLoadErrorTitle => 'We couldn\'t load this ticket';

  @override
  String get tkdLoadErrorBody => 'Check your connection and try again.';

  @override
  String get tkdOffline => 'You\'re offline. Reconnect to send messages.';

  @override
  String get tkdClosedErr =>
      'This ticket was closed, so your message wasn\'t sent.';

  @override
  String get tkdSending => 'Sending…';

  @override
  String get tkdGone => 'This ticket is no longer available.';

  @override
  String get safetyMenu => 'More options';

  @override
  String get safetyReport => 'Report this worker';

  @override
  String get safetyBlock => 'Block this worker';

  @override
  String get safetyReportTitle => 'Report a problem';

  @override
  String get safetyReportWhat => 'What went wrong?';

  @override
  String get safetyReasonNoShow => 'Didn\'t show up';

  @override
  String get safetyReasonMisconduct => 'Misconduct';

  @override
  String get safetyReasonHarassment => 'Harassment';

  @override
  String get safetyReasonTheft => 'Theft';

  @override
  String get safetyReasonFraud => 'Fraud or cheating';

  @override
  String get safetyReasonSafety => 'Safety concern';

  @override
  String get safetyReasonOther => 'Other';

  @override
  String get safetyNote => 'Tell us what happened';

  @override
  String get safetyNoteHint => 'Optional. Only our team reads this.';

  @override
  String get safetyAlsoBlock => 'Also block this worker';

  @override
  String get safetySubmit => 'Submit report';

  @override
  String get safetySubmitting => 'Submitting…';

  @override
  String get safetyThanks => 'Thanks, our team will review this';

  @override
  String get safetyEmergency =>
      'If you\'re in immediate danger, call local emergency services first.';

  @override
  String get safetyBlockTitle => 'Block this worker?';

  @override
  String get safetyBlockBody =>
      'You won\'t be matched with this worker again. They won\'t appear in your search or shortlist.';

  @override
  String get safetyBlockYes => 'Block';

  @override
  String get safetyBlocked => 'Worker blocked';

  @override
  String get safetyNotFound => 'We couldn\'t find that worker.';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifTabAll => 'All';

  @override
  String get notifTabUnread => 'Unread';

  @override
  String get notifMarkAll => 'Mark all as read';

  @override
  String get notifNew => 'New';

  @override
  String get notifEmptyTitle => 'No notifications yet';

  @override
  String get notifEmptyBody =>
      'Updates about your bookings, payments and support will appear here.';

  @override
  String get notifUnreadEmptyTitle => 'No unread notifications';

  @override
  String get notifUnreadEmptyBody => 'You\'re all caught up.';

  @override
  String get notifViewAll => 'View all notifications';

  @override
  String get notifCaughtUp => 'You\'re all caught up';

  @override
  String get notifErrTitle => 'We couldn\'t load your notifications';

  @override
  String get notifErrBody => 'Check your connection and try again.';

  @override
  String get notifOfflineBanner =>
      'You\'re offline. Showing saved notifications.';

  @override
  String get notifOffTitle => 'Notifications are turned off';

  @override
  String get notifOffBody =>
      'Turn them on so you don\'t miss interview and payment updates.';

  @override
  String get notifOpenSettings => 'Open settings';

  @override
  String get notifFallbackTitle => 'Update';

  @override
  String get notifPromptTitle => 'Stay in the loop';

  @override
  String get notifPromptBody =>
      'Get a heads-up about interviews, payments and replies from support. You can change this any time in your phone\'s settings.';

  @override
  String get notifPromptAllow => 'Allow notifications';

  @override
  String get notifPromptLater => 'Not now';

  @override
  String get notifAccountTitle => 'Notifications';

  @override
  String get notifAccountOn => 'On';

  @override
  String get notifAccountOff => 'Off';

  @override
  String get notifAccountNotAsked => 'Not turned on';

  @override
  String get accountSupport => 'Help and support';

  @override
  String get notifBannerOpen => 'Open notification';

  @override
  String get linkUnavailableTitle => 'This item isn\'t available';

  @override
  String get linkUnavailableBody =>
      'It may have been removed, or you may not have access to it.';

  @override
  String get linkGoHome => 'Go to Home';

  @override
  String get agoNow => 'Just now';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceLeave => 'On leave';

  @override
  String attendanceCheckIn(String time) {
    return 'In $time';
  }

  @override
  String attendanceCheckOut(String time) {
    return 'Out $time';
  }

  @override
  String serviceScheduled(String window) {
    return 'Scheduled $window';
  }

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterYear => 'Year';

  @override
  String get historyFilterCategory => 'Service';

  @override
  String get historyFilterStatus => 'Status';

  @override
  String get historySearchHint => 'Search services';

  @override
  String historySummaryLine(int services, int workers, String spent) {
    return '$services services · $workers workers · $spent total spent';
  }

  @override
  String get historyNoMatch => 'No services match these filters.';

  @override
  String get bookingHireAgain => 'Hire again';

  @override
  String get safetyInProgress =>
      'Still sending your last request. Please try again in a moment.';

  @override
  String get rebookFailed => 'Couldn\'t start a new booking. Please try again.';

  @override
  String get rebookNotAllowed =>
      'Only a completed booking can be booked again.';

  @override
  String get rebookWorkerUnavailable =>
      'This worker isn\'t available right now.';

  @override
  String get rebookWorkerNotEligible =>
      'This worker can\'t take a new booking right now.';

  @override
  String get rebookDuplicate =>
      'You already have an open booking with this worker.';

  @override
  String get serviceReportMissing => 'Report a missing day';

  @override
  String get exceptionTitle => 'Report a missing day';

  @override
  String get exceptionHint =>
      'Pick a day your worker didn\'t record and tell us what happened.';

  @override
  String get exceptionDate => 'Day';

  @override
  String get exceptionNote => 'What happened';

  @override
  String get exceptionSubmit => 'Send report';

  @override
  String get exceptionExists => 'That day already has an entry.';

  @override
  String get exceptionSent => 'Thanks, we\'ve recorded it.';

  @override
  String ratingReviewTooLong(int max) {
    return 'Your review is too long. Please shorten it to $max characters.';
  }

  @override
  String get accountShortlist => 'Shortlist';

  @override
  String get accountBookings => 'My bookings';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountTerms => 'Terms of Service';

  @override
  String get accountPrivacy => 'Privacy Policy';

  @override
  String get accountAbout => 'About SevaNest';

  @override
  String accountVersion(String version) {
    return 'Version $version';
  }

  @override
  String get accountLegalUnavailable =>
      'Not available yet. We\'ll publish this soon.';

  @override
  String get accountLanguageFailed =>
      'Couldn\'t change the language. Please try again.';

  @override
  String get gateUpdateTitle => 'Update required';

  @override
  String get gateUpdateBody =>
      'This version of SevaNest is no longer supported. Please update the app to continue.';

  @override
  String get gateUpdateBtn => 'Update';

  @override
  String get gateMaintTitle => 'We will be right back';

  @override
  String get gateMaintBody =>
      'SevaNest is down for maintenance. Please try again in a little while.';

  @override
  String get gateRetryFailed => 'Could not check right now. Please try again.';

  @override
  String get gateDevOff => 'Dev: switch off';

  @override
  String get devMenuGate => 'Launch gate';

  @override
  String get devMenuGateUpdate => 'Force update';

  @override
  String get devMenuGateMaint => 'Maintenance';

  @override
  String get legalConsentTitle => 'Accept our terms';

  @override
  String get legalConsentBody =>
      'To continue, please accept the latest Terms of Service and Privacy Policy.';

  @override
  String get legalConsentAccept => 'Accept and continue';

  @override
  String get legalConsentUnavailable =>
      'Terms and privacy documents aren\'t available yet. Please try again later.';

  @override
  String get legalConsentFailed =>
      'Couldn\'t save your acceptance. Please try again.';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get deleteTitle => 'Delete your account?';

  @override
  String get deleteConfirmButton => 'Request deletion';

  @override
  String get deleteStatusTitle => 'Account deletion';

  @override
  String deleteStatusRequested(String date) {
    return 'Deletion requested on $date. We\'ll let you know when it\'s done.';
  }

  @override
  String get deleteStatusNone => 'No deletion request.';

  @override
  String get deleteStatusCompleted => 'Your account has been deleted.';

  @override
  String get deleteCancelRequest => 'Cancel request';

  @override
  String get deleteFailed =>
      'Couldn\'t update your deletion request. Please try again.';
}
