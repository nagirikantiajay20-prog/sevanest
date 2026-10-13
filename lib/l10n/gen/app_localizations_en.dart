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
  String get addressLocationFailed =>
      'Couldn\'t get your location. Check the location permission, or fill in the address yourself.';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again with your mobile number.';

  @override
  String get devMenuLive => 'Backend data';

  @override
  String get devMenuLiveOn => 'Live';

  @override
  String get devMenuLiveOff => 'Mock';
}
