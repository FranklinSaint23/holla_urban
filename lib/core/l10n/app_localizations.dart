import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['fr']![key] ?? key;

  // ── App ─────────────────────────────────────────────────────────────
  String get appName => _t('appName');
  String get appTagline => _t('appTagline');

  // ── Auth ─────────────────────────────────────────────────────────────
  String get welcomeBack => _t('welcomeBack');
  String get loginSubtitle => _t('loginSubtitle');
  String get emailOrPhone => _t('emailOrPhone');
  String get emailHint => _t('emailHint');
  String get password => _t('password');
  String get forgotPassword => _t('forgotPassword');
  String get signIn => _t('signIn');
  String get orConnectWith => _t('orConnectWith');
  String get noAccount => _t('noAccount');
  String get signUp => _t('signUp');
  String get createAccount => _t('createAccount');
  String get registerSubtitle => _t('registerSubtitle');
  String get fullName => _t('fullName');
  String get fullNameHint => _t('fullNameHint');
  String get email => _t('email');
  String get phoneNumber => _t('phoneNumber');
  String get phoneHint => _t('phoneHint');
  String get confirmPassword => _t('confirmPassword');
  String get orRegisterWith => _t('orRegisterWith');
  String get alreadyAccount => _t('alreadyAccount');

  // ── Role Selection ───────────────────────────────────────────────────
  String get welcomeTitle => _t('welcomeTitle');
  String get chooseRoleSubtitle => _t('chooseRoleSubtitle');
  String get roleClient => _t('roleClient');
  String get roleClientSub => _t('roleClientSub');
  String get rolePartner => _t('rolePartner');
  String get rolePartnerSub => _t('rolePartnerSub');
  String get roleDelivery => _t('roleDelivery');
  String get roleDeliverySub => _t('roleDeliverySub');
  String get roleProvider => _t('roleProvider');
  String get roleProviderSub => _t('roleProviderSub');
  String get continueBtn => _t('continueBtn');

  // ── Home ─────────────────────────────────────────────────────────────
  String get searchHint => _t('searchHint');
  String get popularIn => _t('popularIn');
  String get seeAll => _t('seeAll');
  String get specialOffer => _t('specialOffer');
  String get catRestaurant => _t('catRestaurant');
  String get catDelivery => _t('catDelivery');
  String get catShop => _t('catShop');
  String get catPlumber => _t('catPlumber');
  String get catElectrician => _t('catElectrician');
  String get catHealth => _t('catHealth');
  String get catTaxi => _t('catTaxi');
  String get catMore => _t('catMore');

  // ── Navigation ───────────────────────────────────────────────────────
  String get navHome => _t('navHome');
  String get navHistory => _t('navHistory');
  String get navServices => _t('navServices');
  String get navMessages => _t('navMessages');
  String get navProfile => _t('navProfile');

  // ── Track ────────────────────────────────────────────────────────────
  String get trackOrder => _t('trackOrder');
  String get trackStepOrdered => _t('trackStepOrdered');
  String get trackStepConfirmed => _t('trackStepConfirmed');
  String get trackStepPreparing => _t('trackStepPreparing');
  String get trackStepOnTheWay => _t('trackStepOnTheWay');
  String get trackStepDelivered => _t('trackStepDelivered');
  String get estimatedArrival => _t('estimatedArrival');
  String get fromYou => _t('fromYou');
  String get liveTracking => _t('liveTracking');
  String get yourDeliverer => _t('yourDeliverer');
  String get contactDriver => _t('contactDriver');

  // ── Order Details ────────────────────────────────────────────────────
  String get orderDetails => _t('orderDetails');
  String get orderNumber => _t('orderNumber');
  String get orderItems => _t('orderItems');

  // ── History ──────────────────────────────────────────────────────────
  String get historyTitle => _t('historyTitle');
  String get ongoing => _t('ongoing');
  String get previous => _t('previous');
  String get filter => _t('filter');
  String get track => _t('track');
  String get details => _t('details');
  String get reorder => _t('reorder');
  String get statusOngoing => _t('statusOngoing');
  String get statusDelivered => _t('statusDelivered');

  // ── Order ─────────────────────────────────────────────────────────────
  String get orderTitle => _t('orderTitle');
  String get deliveryAddress => _t('deliveryAddress');
  String get modify => _t('modify');
  String get selectedServices => _t('selectedServices');
  String get subtotal => _t('subtotal');
  String get serviceFee => _t('serviceFee');
  String get total => _t('total');
  String get confirmOrder => _t('confirmOrder');

  // ── Payment ──────────────────────────────────────────────────────────
  String get paymentTitle => _t('paymentTitle');
  String get summary => _t('summary');
  String get deliveryFee => _t('deliveryFee');
  String get paymentMethod => _t('paymentMethod');
  String get mtnDesc => _t('mtnDesc');
  String get orangeDesc => _t('orangeDesc');
  String get cardDesc => _t('cardDesc');
  String get cashDesc => _t('cashDesc');
  String get cashTitle => _t('cashTitle');
  String payBtn(String amount) =>
      _t('payBtn').replaceAll('{amount}', amount);
  String get securedBy => _t('securedBy');

  // ── Messages ─────────────────────────────────────────────────────────
  String get messagesTitle => _t('messagesTitle');
  String get searchConversation => _t('searchConversation');
  String get startDiscussion => _t('startDiscussion');
  String get typeMessage => _t('typeMessage');
  String get online => _t('online');

  // ── Profile ──────────────────────────────────────────────────────────
  String get profileTitle => _t('profileTitle');
  String get personalInfo => _t('personalInfo');
  String get appSettings => _t('appSettings');
  String get notifications => _t('notifications');
  String get language => _t('language');
  String get theme => _t('theme');
  String get darkMode => _t('darkMode');
  String get logout => _t('logout');
  String get premiumMember => _t('premiumMember');

  // ── Navigation rôles ──────────────────────────────────────────────────
  String get navOrders    => _t('navOrders');
  String get navMenu      => _t('navMenu');
  String get navEarnings  => _t('navEarnings');
  String get navRequests  => _t('navRequests');

  // ── Partner ───────────────────────────────────────────────────────────
  String get partnerWelcome => _t('partnerWelcome');
  String get storeOpen      => _t('storeOpen');
  String get storeClosed    => _t('storeClosed');
  String get todayOrders    => _t('todayOrders');
  String get todayRevenue   => _t('todayRevenue');
  String get pending        => _t('pending');
  String get rating         => _t('rating');
  String get newOrders      => _t('newOrders');
  String get statusNew      => _t('statusNew');
  String get statusPreparing => _t('statusPreparing');
  String get statusReady    => _t('statusReady');

  // ── Delivery ──────────────────────────────────────────────────────────
  String get deliveryWelcome  => _t('deliveryWelcome');
  String get youAreOnline     => _t('youAreOnline');
  String get youAreOffline    => _t('youAreOffline');
  String get availableForOrders => _t('availableForOrders');
  String get tapToGoOnline    => _t('tapToGoOnline');
  String get offline          => _t('offline');
  String get todayDeliveries  => _t('todayDeliveries');
  String get todayEarnings    => _t('todayEarnings');
  String get currentDelivery  => _t('currentDelivery');
  String get availableOrders  => _t('availableOrders');
  String get nearby           => _t('nearby');
  String get weeklyEarnings   => _t('weeklyEarnings');
  String get deliveries       => _t('deliveries');
  String get activeTime       => _t('activeTime');
  String get thisWeek         => _t('thisWeek');
  String get todayDetail      => _t('todayDetail');

  // ── Provider ──────────────────────────────────────────────────────────
  String get providerWelcome  => _t('providerWelcome');
  String get available        => _t('available');
  String get unavailable      => _t('unavailable');
  String get todayJobs        => _t('todayJobs');
  String get urgentRequest    => _t('urgentRequest');
  String get todaySchedule    => _t('todaySchedule');

  // ── Common ────────────────────────────────────────────────────────────
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get loading => _t('loading');
  String get error => _t('error');
  String get retry => _t('retry');
  String get fcfa => _t('fcfa');

  // ── Strings map ───────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _strings = {
    'fr': {
      'appName': 'Hôlla',
      'appTagline': 'Intelligent urban delivery',
      'welcomeBack': 'Bon retour !',
      'loginSubtitle': 'Connectez-vous pour continuer à naviguer.',
      'emailOrPhone': 'Email ou Téléphone',
      'emailHint': 'votre@email.com',
      'password': 'Mot de passe',
      'forgotPassword': 'Mot de passe oublié ?',
      'signIn': 'Se connecter',
      'orConnectWith': 'Ou connectez avec',
      'noAccount': "Vous n'avez pas de compte ? ",
      'signUp': "S'inscrire",
      'createAccount': 'Créer un compte',
      'registerSubtitle':
          'Inscrivez-vous pour améliorer\nvotre expérience avec Hôlla',
      'fullName': 'Nom complet',
      'fullNameHint': 'Jean Kamdem',
      'email': 'Email',
      'phoneNumber': 'Numéro de téléphone',
      'phoneHint': '+237 6XX XXX XXX',
      'confirmPassword': 'Confirmer le mot de passe',
      'orRegisterWith': 'Ou inscrivez avec',
      'alreadyAccount': 'Déjà un compte ? ',
      'welcomeTitle': 'Bienvenue\nsur Hôlla !',
      'chooseRoleSubtitle':
          'Choisissez votre rôle pour\npersonnaliser votre expérience.',
      'roleClient': 'Client',
      'roleClientSub': 'Commander des biens et services',
      'rolePartner': 'Partenaire',
      'rolePartnerSub': 'Restaurant, boutique, commerçant',
      'roleDelivery': 'Livreur',
      'roleDeliverySub': 'Effectuer des livraisons',
      'roleProvider': 'Prestataire',
      'roleProviderSub': 'Plombier, électricien, technicien…',
      'continueBtn': 'Continuer',
      'searchHint': "Qu'allez-vous commander aujourd'hui ?",
      'popularIn': 'Populaire au Cameroun',
      'seeAll': 'Tout voir',
      'specialOffer': 'OFFRE SPÉCIALE',
      'catRestaurant': 'Restaurant',
      'catDelivery': 'Livreurs',
      'catShop': 'Boutique',
      'catPlumber': 'Plombier',
      'catElectrician': 'Electriciens',
      'catHealth': 'Santé',
      'catTaxi': 'Taxi',
      'catMore': 'Plus',
      'navHome': 'Home',
      'navHistory': 'History',
      'navServices': 'Services',
      'navMessages': 'Messages',
      'navProfile': 'Profile',
      'historyTitle': 'Historique',
      'ongoing': 'En cours',
      'previous': 'Précédentes',
      'filter': 'Filtrer',
      'track': 'Suivre',
      'details': 'Détails',
      'reorder': 'Recommander',
      'trackOrder': 'Suivre ma commande',
      'trackStepOrdered': 'Commande passée',
      'trackStepConfirmed': 'Commande confirmée',
      'trackStepPreparing': 'En préparation',
      'trackStepOnTheWay': 'En route vers vous',
      'trackStepDelivered': 'Livré',
      'estimatedArrival': 'Arrivée estimée dans',
      'fromYou': 'de vous',
      'liveTracking': 'Suivi en temps réel',
      'yourDeliverer': 'Votre livreur',
      'contactDriver': 'Contacter le livreur',
      'orderDetails': 'Détails commande',
      'orderNumber': 'Commande n°',
      'orderItems': 'Articles commandés',
      'statusOngoing': 'EN COURS...',
      'statusDelivered': 'LIVRÉ',
      'orderTitle': 'Passer Commande',
      'deliveryAddress': 'Adresse de livraison',
      'modify': 'Modifier',
      'selectedServices': 'Services sélectionnés',
      'subtotal': 'Sous-total',
      'serviceFee': 'Frais de service',
      'total': 'Total',
      'confirmOrder': 'Confirmer la commande',
      'paymentTitle': 'Paiement',
      'summary': 'Récapitulatif',
      'deliveryFee': 'Frais de livraison',
      'paymentMethod': 'Mode de paiement',
      'mtnDesc': 'Paiement instantané',
      'orangeDesc': 'Validation via code USSD',
      'cardDesc': 'Visa, Mastercard',
      'cashTitle': 'Paiement à la livraison',
      'cashDesc': "Payez en espèces à l'arrivée",
      'payBtn': 'Payer {amount} FCFA',
      'securedBy': 'Transaction sécurisée par Holla Pay',
      'messagesTitle': 'Messages',
      'searchConversation': 'Rechercher une conversation...',
      'startDiscussion': 'Commencez une nouvelle discussion',
      'typeMessage': 'Écrire un message...',
      'online': 'En ligne',
      'profileTitle': 'Profil',
      'personalInfo': 'Informations personnelles',
      'appSettings': 'Paramètres',
      'notifications': 'Notifications',
      'language': 'Langue',
      'theme': 'Thème',
      'darkMode': 'Mode sombre',
      'logout': 'Se déconnecter',
      'premiumMember': 'Premium Member',
      'navOrders': 'Commandes',
      'navMenu': 'Menu',
      'navEarnings': 'Revenus',
      'navRequests': 'Demandes',
      'partnerWelcome': 'Bienvenue,',
      'storeOpen': 'Ouvert',
      'storeClosed': 'Fermé',
      'todayOrders': 'Commandes auj.',
      'todayRevenue': 'Revenus auj.',
      'pending': 'En attente',
      'rating': 'Note',
      'newOrders': 'Nouvelles commandes',
      'statusNew': 'Nouveau',
      'statusPreparing': 'Préparation',
      'statusReady': 'Prêt',
      'deliveryWelcome': 'Bonjour,',
      'youAreOnline': 'Vous êtes en ligne',
      'youAreOffline': 'Vous êtes hors ligne',
      'availableForOrders': 'Disponible pour les livraisons',
      'tapToGoOnline': 'Appuyez pour vous connecter',
      'offline': 'Hors ligne',
      'todayDeliveries': 'Livraisons auj.',
      'todayEarnings': 'Gains auj.',
      'currentDelivery': 'Livraison en cours',
      'availableOrders': 'Commandes disponibles',
      'nearby': 'à proximité',
      'weeklyEarnings': 'Gains de la semaine',
      'deliveries': 'livraisons',
      'activeTime': 'actif',
      'thisWeek': 'Cette semaine',
      'todayDetail': "Détail d'aujourd'hui",
      'providerWelcome': 'Bonjour,',
      'available': 'Disponible',
      'unavailable': 'Indisponible',
      'todayJobs': 'Jobs auj.',
      'urgentRequest': 'Demande urgente !',
      'todaySchedule': 'Planning du jour',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'fcfa': 'FCFA',
    },
    'en': {
      'appName': 'Hôlla',
      'appTagline': 'Intelligent urban delivery',
      'welcomeBack': 'Welcome back!',
      'loginSubtitle': 'Sign in to continue navigating.',
      'emailOrPhone': 'Email or Phone',
      'emailHint': 'your@email.com',
      'password': 'Password',
      'forgotPassword': 'Forgot password?',
      'signIn': 'Sign in',
      'orConnectWith': 'Or connect with',
      'noAccount': "Don't have an account? ",
      'signUp': 'Sign up',
      'createAccount': 'Create an account',
      'registerSubtitle':
          'Sign up to enhance\nyour experience with Hôlla',
      'fullName': 'Full name',
      'fullNameHint': 'Jean Kamdem',
      'email': 'Email',
      'phoneNumber': 'Phone number',
      'phoneHint': '+237 6XX XXX XXX',
      'confirmPassword': 'Confirm password',
      'orRegisterWith': 'Or register with',
      'alreadyAccount': 'Already have an account? ',
      'welcomeTitle': 'Welcome\nto Hôlla!',
      'chooseRoleSubtitle':
          'Choose your role to\npersonalize your experience.',
      'roleClient': 'Client',
      'roleClientSub': 'Order goods and services',
      'rolePartner': 'Partner',
      'rolePartnerSub': 'Restaurant, shop, merchant',
      'roleDelivery': 'Delivery Agent',
      'roleDeliverySub': 'Make deliveries',
      'roleProvider': 'Service Provider',
      'roleProviderSub': 'Plumber, electrician, technician…',
      'continueBtn': 'Continue',
      'searchHint': 'What will you order today?',
      'popularIn': 'Popular in Cameroon',
      'seeAll': 'See all',
      'specialOffer': 'SPECIAL OFFER',
      'catRestaurant': 'Restaurant',
      'catDelivery': 'Deliveries',
      'catShop': 'Shop',
      'catPlumber': 'Plumber',
      'catElectrician': 'Electricians',
      'catHealth': 'Health',
      'catTaxi': 'Taxi',
      'catMore': 'More',
      'navHome': 'Home',
      'navHistory': 'History',
      'navServices': 'Services',
      'navMessages': 'Messages',
      'navProfile': 'Profile',
      'historyTitle': 'History',
      'ongoing': 'Ongoing',
      'previous': 'Previous',
      'filter': 'Filter',
      'track': 'Track',
      'details': 'Details',
      'reorder': 'Reorder',
      'trackOrder': 'Track my order',
      'trackStepOrdered': 'Order placed',
      'trackStepConfirmed': 'Order confirmed',
      'trackStepPreparing': 'Preparing',
      'trackStepOnTheWay': 'On the way to you',
      'trackStepDelivered': 'Delivered',
      'estimatedArrival': 'Estimated arrival in',
      'fromYou': 'from you',
      'liveTracking': 'Live tracking',
      'yourDeliverer': 'Your deliverer',
      'contactDriver': 'Contact driver',
      'orderDetails': 'Order details',
      'orderNumber': 'Order #',
      'orderItems': 'Order items',
      'statusOngoing': 'ONGOING...',
      'statusDelivered': 'DELIVERED',
      'orderTitle': 'Place Order',
      'deliveryAddress': 'Delivery address',
      'modify': 'Edit',
      'selectedServices': 'Selected services',
      'subtotal': 'Subtotal',
      'serviceFee': 'Service fee',
      'total': 'Total',
      'confirmOrder': 'Confirm order',
      'paymentTitle': 'Payment',
      'summary': 'Summary',
      'deliveryFee': 'Delivery fee',
      'paymentMethod': 'Payment method',
      'mtnDesc': 'Instant payment',
      'orangeDesc': 'Validation via USSD code',
      'cardDesc': 'Visa, Mastercard',
      'cashTitle': 'Pay on delivery',
      'cashDesc': 'Pay in cash on arrival',
      'payBtn': 'Pay {amount} FCFA',
      'securedBy': 'Transaction secured by Holla Pay',
      'messagesTitle': 'Messages',
      'searchConversation': 'Search a conversation...',
      'startDiscussion': 'Start a new discussion',
      'typeMessage': 'Type a message...',
      'online': 'Online',
      'profileTitle': 'Profile',
      'personalInfo': 'Personal Info',
      'appSettings': 'App Settings',
      'notifications': 'Notifications',
      'language': 'Language',
      'theme': 'Theme',
      'darkMode': 'Dark mode',
      'logout': 'Sign out',
      'premiumMember': 'Premium Member',
      'navOrders': 'Orders',
      'navMenu': 'Menu',
      'navEarnings': 'Earnings',
      'navRequests': 'Requests',
      'partnerWelcome': 'Welcome,',
      'storeOpen': 'Open',
      'storeClosed': 'Closed',
      'todayOrders': 'Orders today',
      'todayRevenue': 'Revenue today',
      'pending': 'Pending',
      'rating': 'Rating',
      'newOrders': 'New orders',
      'statusNew': 'New',
      'statusPreparing': 'Preparing',
      'statusReady': 'Ready',
      'deliveryWelcome': 'Hello,',
      'youAreOnline': 'You are online',
      'youAreOffline': 'You are offline',
      'availableForOrders': 'Available for deliveries',
      'tapToGoOnline': 'Tap to go online',
      'offline': 'Offline',
      'todayDeliveries': 'Deliveries today',
      'todayEarnings': 'Earnings today',
      'currentDelivery': 'Current delivery',
      'availableOrders': 'Available orders',
      'nearby': 'nearby',
      'weeklyEarnings': 'Weekly earnings',
      'deliveries': 'deliveries',
      'activeTime': 'active',
      'thisWeek': 'This week',
      'todayDetail': "Today's detail",
      'providerWelcome': 'Hello,',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'todayJobs': 'Jobs today',
      'urgentRequest': 'Urgent request!',
      'todaySchedule': "Today's schedule",
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'fcfa': 'FCFA',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
