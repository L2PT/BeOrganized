library app.globals;

class Constants {
  static const String title = "Venturi Autospurghi App";
  static const bool debug = false;
  static const String web = "web";
  static const String mobile = "mobile";

  static const String passwordNewUsers = "adminVenturi";
  static const int fallbackColor = 0xFF119DD1;
  static const String fallbackHexColor = "#FDA90A";
  static const String categoryDefault = "Spurgo";
  
  
  static const String notificationSuccessTheme = "success";
  static const String notificationInfoTheme = "info";
  static const String notificationErrorTheme = "error";
  static const String eventNotification = "event";
  static const String feedNotification = "feed";

  // ROUTES
  static const String homeRoute = '/';
  static const String closeOverViewRoute = '/close_over_view';
  static const String monthlyCalendarRoute = '/view/monthly_calendar';
  static const String dailyCalendarRoute = '/view/daily_calendar';
  static const String operatorListRoute = '/view/op_list';
  static const String addWebOperatorRoute = '/view/op_web_list';
  static const String registerRoute = '/view/register';
  static const String detailsEventViewRoute = '/view/details_event';
  static const String createEventViewRoute = '/view/form_event_creator';
  static const String createCustomerViewRoute = '/view/form_customer_creator';
  static const String createAddressViewRoute = '/view/form_address_creator';
  static const String customerListRoute = '/view/customer_list';
  static const String waitingEventListRoute = '/view/waiting_event_list';
  static const String notUpadateversionAppRoute = '/view/version_app';
  static const String waitingNotificationRoute = '/view/persistent_notification';
  static const String historyEventListRoute = '/view/history_event_list';
  static const String profileRoute = '/view/profile';
  static const String resetCodeRoute = '/reset_code_page';
  static const String logInRoute = '/log_in';
  static const String loadingRoute = '/loading';
  static const String logOut = 'log_out';
  static const String filterEventListRoute = '/view/filter_event';
  static const String bozzeEventListRoute = '/view/bozze_event_list';
  static const String customerContactsListRoute = '/view/customer_contacts_list';
  static const String manageUtenzeRoute = '/view/manage_utenze';
  static const String noRoute = 'noRoute';

  // TABLES DATABASE
  static const String tabellaUtenti = 'Utenti';
  static const String tabellaCostanti = debug?'Costanti_DEBUG':'Costanti';
  static const String tabellaEventi = debug?'Eventi_DEBUG':'Eventi';
  static const String tabellaStorico = debug?'Storico_DEBUG':'Storico';
  static const String tabellaClienti = debug?'Clienti_DEBUG':'Clienti';
  static const String subtabellaStorico = debug?'StoricoEventi_DEBUG':'StoricoEventi';
  static const String tabellaEventiEliminati = debug?'/Storico_DEBUG/StoricoEliminati/StoricoEventi_DEBUG':'/Storico/StoricoEliminati/StoricoEventi';
  static const String tabellaEventiTerminati = debug?'/Storico_DEBUG/StoricoTerminati/StoricoEventi_DEBUG':'/Storico/StoricoTerminati/StoricoEventi';
  static const String tabellaEventiRifiutati = debug?'/Storico_DEBUG/StoricoRifiutati/StoricoEventi_DEBUG':'/Storico/StoricoRifiutati/StoricoEventi';

  // TABLE EVENTI
  static const String tabellaEventi_titolo = 'Titolo';
  static const String tabellaEventi_descrizione = 'Descrizione';
  static const String tabellaEventi_dataFine = 'DataFine';
  static const String tabellaEventi_dataInizio = 'DataInizio';
  static const String tabellaEventi_indirizzo = 'Indirizzo';
  static const String tabellaEventi_stato = 'Stato';
  static const String tabellaEventi_categoria = 'Categoria';
  static const String tabellaEventi_motivazione = 'Motivazione';
  static const String tabellaEventi_luogo = 'Luogo';
  static const String tabellaEventi_idOperatore = 'IdOperatore';
  static const String tabellaEventi_idOperatori = 'IdOperatori';
  static const String tabellaEventi_idResponsabile = 'IdResponsabile';
  static const String tabellaEventi_operatore = 'Operatore';
  static const String tabellaEventi_subOperatori = 'SubOperatori';
  static const String tabellaEventi_responsabile = 'Responsabile';
  static const String tabellaEventi_cliente = 'Cliente';
  static const String tabellaEventi_notaOperatore = 'NotaOperatore';
  static const String tabellaEventi_documenti = 'Documenti';

  // TABLE COSTANTI
  static const String tabellaCostanti_Categorie = 'Categorie';
  static const String tabellaCostanti_Telefoni = 'Telefoni';
  static const String tabellaCostanti_InfoApp = 'InfoApp';
  static const String tabellaCostanti_Tipologie = 'Tipologie';
  static const String tabellaCostanti_TipologieCliente = 'TipologieCliente';

  // TABLE UTENTI
  static const String tabellaUtenti_Nome = 'Nome';
  static const String tabellaUtenti_Cognome = 'Cognome';

  // TABLE CLIENTE
  static const String tabellaClienti_codicefiscale = 'CodiceFiscale';
  static const String tabellaClienti_tipologia = 'Tipologia';
  static const String tabellaClienti_email = 'Email';
  static const String tabellaClienti_nome = 'Nome';
  static const String tabellaClienti_cognome = 'Cognome';
  static const String tabellaClienti_partitaIva = 'PartitaIva';
  static const String tabellaClienti_telefono = 'Telefono';
  static const String tabellaClienti_telefoni = 'Telefoni';
  static const String tabellaClienti_indirizzi = 'Indirizzi';
  static const String tabellaClienti_indirizzo = 'Indirizzo';
  static const String tabellaClienti_indirizziSearch = 'IndirizziSearch';

  // HANDLES
  static const int MIN_WORKTIME = 7;
  static const int MAX_WORKTIME = 19;
  static const int WORKTIME_SPAN = 30;
  static const double MIN_CALENDAR_EVENT_HEIGHT = 60.0;

  static const String googleMapsApiKey = 'AIzaSyD3A8jbx8IRtXvnmoGSwJy2VyRCvo0yjGk';
  static const String googleMessagingApiKey = 'AIzaSyBF13XNJM1LDuRrLcWdQQxuEcZ5TakypEk';
  static const String webPushNotificationsVapidKey = 'BJstIUpFNSxgd1Ir1xQd_qt48ijnfLG2B3Md_9unMkA7nMBpZZRVX3_6A5f2HJJLCOZJoFH2CgpmtrimGRe-rWo';
  static const String agoliaApiKey = '485e3979c1cc1eb09770c7f45e11b20b';
  static const String agoliaApplicationId = '6JDU1L4FVI';

  //OVERVIEW SCREEN
  static const double WIDTH_OVERVIEW = 400;
  static const double HEIGHT_OVERVIEW = 655;

  //REGEXP
  static const String pattternPhoneValid = r'(^(?:[+3]9)?[0-9]{8,12}$)';
  static const String pattternPhone = r'\b(?:\+?39)?\d{9,12}\b';

  //AGOLIA INDEX
  static const String indexSearchCustomer = debug?'Clienti_Debug_Index':'Clienti_Index';
}