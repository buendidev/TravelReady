// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TravelReady!';

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Create account';

  @override
  String get logout => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get name => 'Full name';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get hasAccount => 'Already have an account? ';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get sendResetEmail => 'Send recovery email';

  @override
  String get home => 'Home';

  @override
  String get myTrips => 'My trips';

  @override
  String get packingLists => 'My bags';

  @override
  String get chats => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get newTrip => 'New trip';

  @override
  String get destination => 'Destination';

  @override
  String get startDate => 'Departure date';

  @override
  String get endDate => 'Return date';

  @override
  String get tripType => 'Trip type';

  @override
  String get transport => 'Transport';

  @override
  String get createTrip => 'Create trip';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get noTrips => 'No trips planned';

  @override
  String get days => 'days';

  @override
  String get newList => 'New bag';

  @override
  String get templates => 'Templates';

  @override
  String get addItem => 'Add item';

  @override
  String get itemName => 'Item name';

  @override
  String get category => 'Category';

  @override
  String get quantity => 'Quantity';

  @override
  String get packed => 'Packed';

  @override
  String get itemPacked => 'Packed';

  @override
  String get progress => 'completed';

  @override
  String get generateAI => 'Generate with AI';

  @override
  String get messages => 'Messages';

  @override
  String get newMessage => 'New message';

  @override
  String get createGroup => 'Create group';

  @override
  String get groupName => 'Group name';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get aiAssistant => 'Travel assistant';

  @override
  String get support => 'Technical support';

  @override
  String get noConversations => 'No conversations';

  @override
  String get myProfile => 'My profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Help & support';

  @override
  String get premium => 'Premium';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get premiumPlan => 'Premium Plan';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get errorEmptyField => 'This field is required.';

  @override
  String get errorInvalidEmail => 'Invalid email address.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorPasswordMatch => 'Passwords do not match.';

  @override
  String get errorGeneral => 'Something went wrong. Please try again.';

  @override
  String weatherIn(String city) {
    return 'Weather in $city';
  }

  @override
  String tripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
      zero: 'No trips',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Create';

  @override
  String get newPackingList => 'New bag';

  @override
  String get deletePackingList => 'Delete bag';

  @override
  String get deleteTripTitle => 'Delete trip';

  @override
  String deleteTripConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String deleteListConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get inProgress => 'IN PROGRESS';

  @override
  String get searchCity => 'Search city';

  @override
  String get cityHint => 'e.g., Barcelona, Paris...';

  @override
  String get search => 'Search';

  @override
  String get weather => 'Weather';

  @override
  String get weatherSetup => 'Set up OPENWEATHER_API_KEY in .env';

  @override
  String get goPremiumTitle => 'Go Premium';

  @override
  String get premiumDesc => 'Unlimited bags + AI + no ads';

  @override
  String get logoutTitle => 'Sign out';

  @override
  String get logoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get listNotFound => 'List not found';

  @override
  String get emptyList => 'Empty list';

  @override
  String get addItemsHint => 'Add items with the + button';

  @override
  String get activeSubscription => 'Subscription active';

  @override
  String get noResults => 'No results';

  @override
  String get tryAnotherFilter => 'Try another filter or search';

  @override
  String get noTripsPlanned => 'No trips planned';

  @override
  String get nameLabel => 'Name';

  @override
  String get listNameHint => 'e.g., Summer luggage, Weekend backpack...';

  @override
  String get packingList => 'Packing list';

  @override
  String get packingListsForTrip => 'Packing lists';

  @override
  String get tripPlanning => 'Plan your trip';

  @override
  String get tripPlanningDescription =>
      'Organize each day and discover places to visit';

  @override
  String get itinerary => 'Itinerary';

  @override
  String get itineraryDescription => 'Organize your day-by-day plan';

  @override
  String get discoverDestinations => 'Discover destinations';

  @override
  String get discoverDestinationsDescription => 'Find places to visit';

  @override
  String get categoryLabel => 'Category';

  @override
  String get quantityLabel => 'Quantity:';

  @override
  String itemsCount(int packed, int total) {
    return '$packed/$total items';
  }

  @override
  String itemsCountOf(int packed, int total) {
    return '$packed of $total items';
  }

  @override
  String progressPercent(int percent) {
    return '$percent% completed';
  }

  @override
  String templatesAvailable(int count) {
    return '$count available';
  }

  @override
  String get noListsYet => 'No lists yet';

  @override
  String get createListHint =>
      'Create a new list to organize your luggage according to the trip type';

  @override
  String get recentTrips => 'Recent trips';

  @override
  String get seeAll => 'See all';

  @override
  String get weatherNotAvailable => 'Weather not available';

  @override
  String weatherStaleAge(int minutes) {
    return 'Stale data · $minutes min ago';
  }

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get luggagePrep => 'Luggage prep';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get noTripsHint =>
      'Create your first trip and organize your luggage instantly';

  @override
  String get createTripBtn => 'Create trip';

  @override
  String get userDefault => 'User';

  @override
  String get statsTrips => 'Trips';

  @override
  String get supportChatTitle => 'Technical support';

  @override
  String get assistantChatTitle => 'Travel assistant';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get tripActive => 'Active trip';

  @override
  String tripUpcoming(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming trips',
      one: '1 upcoming trip',
      zero: 'No upcoming trips',
    );
    return '$_temp0';
  }

  @override
  String get tripReady => 'Ready to travel!';

  @override
  String get statsUpcoming => 'Upcoming';

  @override
  String get statsActive => 'Active';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get newBagQuick => 'New bag';

  @override
  String get newTripQuick => 'New trip';

  @override
  String get assistantQuick => 'Assistant';

  @override
  String get todayTrip => 'Today';

  @override
  String get dayLeft => '1 day left';

  @override
  String get welcomeFirstTime => 'Welcome to TravelReady! 🌟';

  @override
  String get subtitleFirstTime =>
      'Create your account and start planning your perfect trip';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get subtitleLogin => 'Sign in to continue planning your trips';

  @override
  String get accountCreatedBanner => 'Account created successfully';

  @override
  String get or => 'or';

  @override
  String get accountCreatedSnack => 'Account created! Sign in to continue';

  @override
  String get subtitleRegister =>
      'Create your account and start organizing your trips';

  @override
  String get hintName => 'John Doe';

  @override
  String get hintEmail => 'email@example.com';

  @override
  String get hintPassword => '••••••';

  @override
  String get hintConfirmPassword => '••••••';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordQuestion => 'Forgot your password?';

  @override
  String get forgotPasswordDesc =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get sendLink => 'Send link';

  @override
  String get emailSentTitle => 'Email sent!';

  @override
  String emailSentDesc(String email) {
    return 'We\'ve sent a recovery link to\n$email';
  }

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get requiredField => 'Required field.';

  @override
  String get emailInvalid => 'Invalid email.';

  @override
  String get myTripsTitle => 'My trips';

  @override
  String get searchTripHint => 'Search trip or destination...';

  @override
  String get tripName => 'Trip name';

  @override
  String get tripNameHint => 'e.g. Paris 2026';

  @override
  String get destinationHint => 'e.g. Paris, France';

  @override
  String get departureDate => 'Departure';

  @override
  String get returnDate => 'Return';

  @override
  String get tripTypeLabel => 'Trip type';

  @override
  String get transportLabel => 'Transport';

  @override
  String get createTripLabel => 'Create trip';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get noTripsHintSub =>
      'Create your first trip and organize\nyour luggage instantly';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get newChatTitle => 'New chat';

  @override
  String get noOtherUsers => 'No other registered users';

  @override
  String get conversationsLabel => 'Conversations';

  @override
  String get noPrivateChats => 'No private chats yet\nTap + to start one';

  @override
  String get noMessages => 'No messages yet';

  @override
  String errorPrefix(String msg) {
    return 'Error: $msg';
  }

  @override
  String get signInRequired => 'Sign in';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get essentialsTitle => 'Essential items';

  @override
  String get essentialsSubtitle => 'Things you should never forget on any trip';

  @override
  String get useTemplate => 'Use this template';

  @override
  String addEssentials(int count) {
    return 'Add $count essentials';
  }

  @override
  String essentialsAdded(int count, String name) {
    return '$count essentials added to \"$name\"';
  }

  @override
  String creatingTemplate(String name) {
    return 'Creating \"$name\"... ✓';
  }

  @override
  String get creatingEssentialsList => 'Creating essentials list...';

  @override
  String get retryLabel => 'Retry';

  @override
  String templateItemsCount(int count) {
    return '$count items included';
  }

  @override
  String get aiWelcome =>
      'Hello! 👋 I\'m your travel assistant.\n\nI can help you with:\n• 🧳 What to bring depending on your destination\n• 🌡️ Clothing according to the weather\n• ✈️ Flying tips\n• 📋 Luggage templates\n\nWhere are you going? What do you need?';

  @override
  String get aiReplyBeach =>
      '☀️ **Beach / Summer:**\n\n👙 Swimsuit ×2 · ☀️ Sunscreen FPS50+\n🕶️ UV Glasses · 👡 Flip-flops · 🏖️ Microfiber towel\n💧 Reusable bottle · 👒 Hat\n\n💡 Liquids in 100ml bag if flying.';

  @override
  String get aiReplyMountain =>
      '⛰️ **Mountain:**\n\n🥾 Waterproof boots · 🧥 Rain jacket\n🧣 Scarf+hat+gloves · 🧱 Thermal clothing\n🎒 20-30L backpack · 💊 First aid kit · 🔦 Flashlight';

  @override
  String get aiReplyCity =>
      '🏙️ **City Break:**\n\n👟 Comfortable sneakers · 🎒 Anti-theft backpack\n📱 Charger+power bank · 💳 No-fee card\n☔ Compact umbrella · 📄 Digitized ID/Passport copy';

  @override
  String get aiReplyBusiness =>
      '💼 **Business:**\n\n👔 Formal wear ×extra · 💻 Laptop+charger\n🔌 Plug adapter · 🎧 ANC headphones\n🖊️ Business cards';

  @override
  String get aiReplyFlight =>
      '✈️ **For flying:**\n\n💧 Liquids: max 100ml in 1L ZIP bag\n⚖️ Weigh your luggage before (avoid charges)\n😴 Travel pillow + sleep mask\n🥤 Empty bottle to fill after security\n\n💡 Arrive 2h early (3h for international flights).';

  @override
  String get aiReplyMedicine =>
      '💊 **Travel first aid kit:**\n\n🤕 Ibuprofen/paracetamol · 🤢 Anti-nausea\n🩹 Band-aids · 🧴 Disinfectant · 💊 Antihistamine\n💉 Regular medication (in carry-on)\n\n⚠️ Medical prescription for controlled medication.';

  @override
  String get aiReplyDocuments =>
      '📄 **Documents:**\n\n🛂 Passport (min. 6 months validity)\n🪪 ID for Europe · 🏥 EU health card\n🏦 2 bank cards · 📋 Travel insurance\n\n💡 Digital copy on Google Drive.';

  @override
  String get aiReplyDays =>
      '🗓️ **Clothing by days:**\n\n📅 1-3 days → cabin backpack\n📅 4-7 days → medium suitcase\n📅 +7 days → reuse and wash\n\n👕 1 t-shirt/day+1 extra · 👖 1 pants/3 days\n🧦 1 pair/day+1 extra';

  @override
  String get aiReplyHello =>
      'Hello! 😊 Where are you traveling to?\nTell me the destination and I\'ll help you pack.';

  @override
  String get aiReplyThanks => 'You\'re welcome! 😊 Have a great trip! ✈️🌍';

  @override
  String get aiReplyFallback =>
      '🤔 I can help you with:\n\n• Destination (beach, mountain, city, business)\n• Flying tips · First aid kit\n• Documents · How much clothing to bring\n\nJust tell me your destination 🌍';

  @override
  String get supportHowCanWeHelp => 'How can we help you?';

  @override
  String get supportAvailability =>
      'We\'re available Monday to Friday\nfrom 9:00 to 18:00 (CET)';

  @override
  String get supportEmailTitle => 'Email';

  @override
  String get supportEmailSubtitle => 'soporte@travelready.app';

  @override
  String get supportHelpCenter => 'Help center';

  @override
  String get supportHelpCenterSubtitle => 'FAQs and guides';

  @override
  String get supportReportProblem => 'Report a problem';

  @override
  String get supportReportProblemSubtitle => 'Tell us what went wrong';

  @override
  String get tripFilterAll => '🗓 All';

  @override
  String get tripFilterUpcoming => '✈️ Upcoming';

  @override
  String get tripFilterActive => '🟢 Active';

  @override
  String get tripFilterPast => '📁 Past';

  @override
  String get catClothing => 'Clothing';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catDocuments => 'Documents';

  @override
  String get catHygiene => 'Hygiene';

  @override
  String get catMedicine => 'Medicine';

  @override
  String get catFood => 'Food';

  @override
  String get catAccessories => 'Accessories';

  @override
  String get catSports => 'Sports';

  @override
  String get catOther => 'Other';

  @override
  String get essentialPassport => 'Passport / ID';

  @override
  String get essentialBankCard => 'Bank card';

  @override
  String get essentialTravelInsurance => 'Travel insurance';

  @override
  String get essentialPrintedReservations => 'Printed reservations';

  @override
  String get essentialToiletryBag => 'Toiletry bag';

  @override
  String get essentialToothbrush => 'Toothbrush & toothpaste';

  @override
  String get essentialDeodorant => 'Deodorant';

  @override
  String get essentialPhoneCharger => 'Phone charger';

  @override
  String get essentialRegularMedication => 'Regular medication';

  @override
  String get essentialUnderwear => 'Underwear';

  @override
  String get essentialExtraSocks => 'Extra socks';

  @override
  String get essentialHeadphones => 'Headphones';

  @override
  String get essentialWaterBottle => 'Water bottle';

  @override
  String get essentialTravelSnacks => 'Travel snacks';

  @override
  String get templateBeach => 'Beach / Summer';

  @override
  String get templateMountain => 'Mountain / Hiking';

  @override
  String get templateCity => 'City Break';

  @override
  String get templateBusiness => 'Business';

  @override
  String get templateWeekend => 'Weekend';

  @override
  String get templateLongFlight => 'Long flight';

  @override
  String get itemSwimsuit => 'Swimsuit';

  @override
  String get itemSunscreen => 'Sunscreen SPF 50';

  @override
  String get itemSunglasses => 'Sunglasses';

  @override
  String get itemFlipFlops => 'Flip-flops';

  @override
  String get itemBeachTowel => 'Beach towel';

  @override
  String get itemHat => 'Hat / Cap';

  @override
  String get itemHikingBoots => 'Hiking boots';

  @override
  String get itemRainJacket => 'Rain jacket';

  @override
  String get itemThermalClothing => 'Thermal clothing';

  @override
  String get itemBackpack20to30L => 'Backpack 20-30L';

  @override
  String get itemTrekkingPoles => 'Trekking poles';

  @override
  String get itemHeadlamp => 'Headlamp';

  @override
  String get itemFirstAidKit => 'Basic first aid kit';

  @override
  String get itemComfortableSneakers => 'Comfortable sneakers';

  @override
  String get itemUrbanBackpack => 'Urban backpack';

  @override
  String get itemPowerBank => 'Power bank';

  @override
  String get itemCompactUmbrella => 'Compact umbrella';

  @override
  String get itemTravelGuide => 'Travel guide';

  @override
  String get itemLaptopCharger => 'Laptop + charger';

  @override
  String get itemFormalWear => 'Suit / Formal wear';

  @override
  String get itemBusinessCards => 'Business cards';

  @override
  String get itemPlugAdapter => 'Plug adapter';

  @override
  String get itemAncHeadphones => 'ANC headphones';

  @override
  String get itemClothes2to3Days => 'Clothes for 2-3 days';

  @override
  String get itemBasicToiletryBag => 'Basic toiletry bag';

  @override
  String get itemTravelPillow => 'Travel pillow';

  @override
  String get itemSleepMask => 'Sleep mask';

  @override
  String get itemEarplugs => 'Earplugs';

  @override
  String get itemLiquidsBag100ml => '100ml liquids bag';

  @override
  String get itemWarmClothing => 'Warm clothing';

  @override
  String itineraryTitleWithTrip(String trip) {
    return 'Itinerary · $trip';
  }

  @override
  String get itineraryEmptyTitle => 'No plans yet';

  @override
  String get itineraryEmptyBody =>
      'Add your first visit, meal or activity with a day and time.';

  @override
  String get itineraryAddPlan => 'Add plan';

  @override
  String get itineraryDeletePlan => 'Delete plan';

  @override
  String get itineraryNewPlan => 'New plan';

  @override
  String get itineraryEditPlan => 'Edit plan';

  @override
  String get itineraryFieldTitle => 'Title';

  @override
  String get itineraryFieldTitleHint => 'Museum, restaurant, activity…';

  @override
  String get itineraryFieldNotes => 'Notes';

  @override
  String get itineraryFieldNotesHint => 'Optional';

  @override
  String itineraryStartAt(String time) {
    return 'Start · $time';
  }

  @override
  String get itineraryEndOptional => 'End · optional';

  @override
  String get itineraryAdd => 'Add';

  @override
  String get itineraryCategorySightseeing => 'Sightseeing';

  @override
  String get itineraryCategoryFood => 'Food';

  @override
  String get itineraryCategoryLodging => 'Lodging';

  @override
  String get itineraryCategoryActivity => 'Activity';

  @override
  String get itineraryCategoryOther => 'Other';

  @override
  String get discoveryTitle => 'Discover';

  @override
  String get discoverySearchHint => 'Search places, museums, restaurants…';

  @override
  String get discoveryAllCategories => 'All';

  @override
  String get discoveryDemoData => 'Sample data — no provider configured';

  @override
  String get discoveryProviderUnavailableTitle => 'Provider unavailable';

  @override
  String get discoveryProviderUnavailableBody =>
      'Searching for places needs a provider (Maps/Places). Meanwhile you can add plans to the itinerary by hand.';

  @override
  String get discoverySearchErrorTitle => 'Search failed';

  @override
  String get discoveryNoResultsTitle => 'No results';

  @override
  String get discoveryExploreTitle => 'Explore your destination';

  @override
  String get discoveryNoResultsBody => 'Try another search or category.';

  @override
  String get discoveryExploreBody =>
      'Search for museums, restaurants or corners of your destination.';

  @override
  String discoveryHoursIndicative(String hours) {
    return 'Hours (indicative): $hours';
  }

  @override
  String discoveryPriceIndicative(String price) {
    return 'Indicative price: $price';
  }

  @override
  String get discoveryOfficialSite => 'Official website';

  @override
  String get discoveryAddToItinerary => 'Add to itinerary';

  @override
  String get discoveryAddedToItinerary => 'Added to itinerary';

  @override
  String discoveryAddPlaceWithName(String name) {
    return 'Add \"$name\"';
  }

  @override
  String get discoveryDayLabel => 'Day';

  @override
  String get placeCategoryMonument => 'Monuments';

  @override
  String get placeCategoryMuseum => 'Museums';

  @override
  String get placeCategoryFood => 'Food';

  @override
  String get placeCategoryNature => 'Nature';

  @override
  String get placeCategoryNightlife => 'Nightlife';

  @override
  String get placeCategoryShopping => 'Shopping';

  @override
  String get placeCategoryHotel => 'Hotels';

  @override
  String itineraryEndAt(String time) {
    return 'End · $time';
  }

  @override
  String discoveryTimeLabel(String time) {
    return 'Time · $time';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get feedDislikeAction => 'Not interested';

  @override
  String get feedLikeAction => 'I like it';

  @override
  String get feedSwipeHint => 'Swipe right to save or left to skip';
}
