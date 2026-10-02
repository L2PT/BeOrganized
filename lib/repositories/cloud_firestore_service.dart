import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/models/contract.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/models/message/chat_overview.dart';
import 'package:venturiautospurghi/models/message/contact_whatsapp.dart';
import 'package:venturiautospurghi/models/message/message.dart';
import 'package:venturiautospurghi/models/message/message_config.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

class CloudFirestoreService {

  final FirebaseFirestore _cloudFirestore;
  late CollectionReference _collectionUtenti;
  late CollectionReference _collectionEventi;
  late CollectionReference _collectionClienti;
  late Query _collectionSubStoricoEventi;
  late CollectionReference _collectionStoricoEliminati;
  late CollectionReference _collectionStoricoTerminati;
  late CollectionReference _collectionStoricoRifiutati;
  late CollectionReference _collectionCostanti;
  late CollectionReference _collectionMessageConfig;
  late CollectionReference _collectionChats;
  late CollectionReference _collectionContactsWhatsapp;
  late Query _collectionMessaggi;
  late CollectionReference _collectionContratti;

  late Map<String,dynamic> categories;
  late Map<String,dynamic> typesEvent;
  late Map<String, dynamic> typesCustomer;
  late Map<String, dynamic> typesUser;

  CloudFirestoreService([FirebaseFirestore? cloudFirestore])
      : _cloudFirestore = cloudFirestore ??  FirebaseFirestore.instance {
    _collectionUtenti = _cloudFirestore.collection(Constants.tabellaUtenti) ;
    _collectionEventi = _cloudFirestore.collection(Constants.tabellaEventi);
    _collectionClienti = _cloudFirestore.collection(Constants.tabellaClienti);
    _collectionSubStoricoEventi = _cloudFirestore.collectionGroup(Constants.subtabellaStorico);
    _collectionStoricoEliminati = _cloudFirestore.collection(Constants.tabellaEventiEliminati);
    _collectionStoricoTerminati = _cloudFirestore.collection(Constants.tabellaEventiTerminati);
    _collectionStoricoRifiutati = _cloudFirestore.collection(Constants.tabellaEventiRifiutati);
    _collectionCostanti = _cloudFirestore.collection(Constants.tabellaCostanti);
    _collectionMessageConfig = _cloudFirestore.collection(Constants.tabellaMessageConfig);
    _collectionChats = _cloudFirestore.collection(Constants.tabellaChats);
    _collectionMessaggi = _cloudFirestore.collectionGroup(Constants.tabellaMessaggi);
    _collectionContactsWhatsapp = _cloudFirestore.collection(Constants.tabellaContattiWhatsapp);
    _collectionContratti = _cloudFirestore.collection(Constants.tabellaContratti);
  }

  static Future<CloudFirestoreService> create() async {
    CloudFirestoreService instance = CloudFirestoreService();
    instance.categories = await instance._getCategories();
    instance.typesEvent = await instance._getTypesEvent();
    instance.typesCustomer = await instance._getTypesCustomer();
    instance.typesUser = await instance._getTypesUser();
    return instance;
  }

  /// Function to retrieve from the database the information associated with the
  /// user logged in. The Firebase AuthUser uid must be the same as the id of the
  /// document in the "Utenti" [Constants.tabellaUtenti] collection.
  /// However the mail is also an unique field.
  Future<Account> getAccount({String? email, String? phoneId, String? id}) async {
    if(!string.isNullOrEmpty(id)){
      return _collectionUtenti.doc(id).get().then((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>));
    }
    else if(!string.isNullOrEmpty(email))
      return _collectionUtenti.where('Email', isEqualTo: email).get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).first);
    else
      return _collectionUtenti.where('TelefonoId', isEqualTo: phoneId??"").get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).first);
  }

  Stream<Account> subscribeAccount(String id)  {
    return _collectionUtenti.doc(id).snapshots().map((user) {
      return Account.fromMap(user.id, user.data()! as Map<String, dynamic>);
    });
  }

  Future<List<Account>> getOperatorsFree(String eventIdToIgnore, DateTime fromDate, DateTime toDate, {limit, startFrom}) async {
    bool endOfList = false;
    List<Account> accounts = await this.getOperators(limit: limit, startFrom: startFrom);

    if(limit == null || (limit != null && accounts.length < limit)) endOfList = true;

    final List<Event> listEvents = await this.getFutureEvents(fromDate);
    if(Constants.debug){
      listEvents.forEach((event) async {
        if (event.status == EventStatus.Refused || event.status == EventStatus.Deleted) {
          _collectionEventi.doc(event.id).delete();
        }
      });
      listEvents.removeWhere((event) => event.status == EventStatus.Refused || event.status == EventStatus.Deleted);
    }
    listEvents.forEach((event) {
      if (event.id != eventIdToIgnore) {
        if (event.isBetweenDate(fromDate, toDate)) {
          [event.operator, ...event.suboperators].map((e) => e.id).forEach((idOperator) {
            bool checkDelete = false;
            for (int i = 0; i < accounts.length && !checkDelete; i++) {
              if (accounts.elementAt(i).id == idOperator) {
                checkDelete = true;
                accounts.removeAt(i);
              }
            }
          });
        }
      }
    });
    return accounts.length==limit || endOfList ? accounts :
      [...accounts, ...(await getOperatorsFree(eventIdToIgnore, fromDate, toDate, limit: limit-accounts.length, startFrom: accounts.last.surname))];
  }

  Future<List<Account>> getOperators({limit, startFrom}) async {
    Query query = _collectionUtenti.orderBy(Constants.tabellaUtenti_Cognome);
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionUtenti, startFrom);
    query = addPagination(query, limit, documentSnapshot);
    return query.get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).toList());
  }

  void addOperator(Account u) {
    _collectionUtenti.doc(u.id).set(u.toDocument());
  }

  void updateUser(String id, Account data) {
    _collectionUtenti.doc(id).update(data.toDocument());
  }

  void deleteOperator(String id) {
    _collectionUtenti.doc(id).delete();
  }

  Future<void> updateAccountField(String id, String field, dynamic data) async {
    return _collectionUtenti.doc(id).update(Map.of({field:data}));
  }

  Future<void> deleteChat(String chatId) async {
    final messages = await _collectionChats.doc(chatId).collection(Constants.tabellaMessaggi).get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    await _collectionChats.doc(chatId).delete();
  }

  void updateToken(String id, List tokens){
    _collectionUtenti.doc(id).update(Map.of({"Tokens":tokens}));
  }

  Future<Account> getUserByPhone(String phoneNumber) async{
    return _collectionUtenti.where('Telefono', isEqualTo: phoneNumber).get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).first);
  }

  Future<List<Account>> getAccountsActiveFiltered(Map<String, FilterWrapper> filters, {limit, startFrom}) async {
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionUtenti, startFrom);
    return _getAccountsFiltered(_collectionUtenti, filters, limit, documentSnapshot, null);
  }

  Future<List<Account>> _getAccountsFiltered(CollectionReference query, Map<String, FilterWrapper> filters, [limit, startFrom, remaining]) async {
    Query startQuery = query;
    filters = Map.from(filters);
    // due to firebase limitations (we can't build a query with all filters) let the repository do ALL filtering work
    // despite some fields will be handled in the firebase query and some other in code
    bool endOfList = false;

    if (filters.containsKey("typology") && filters["typology"]!.fieldValue != null){
      startQuery = startQuery.where(Constants.tabellaUtenti_tipologia, isEqualTo: filters["typology"]!.fieldValue);
    }
    startQuery = startQuery.orderBy(
        Constants.tabellaUtenti_Cognome);
    startQuery = addPagination(startQuery, limit, startFrom);

    var docs = await startQuery.get().then((snapshot) => snapshot.docs);
    if (limit != null && docs.length < limit) endOfList = true;

    List<Account> account = docs.map((document) =>
        Account.fromMap(document.id, document.data() as Map<String, dynamic>)).toList();

    DocumentSnapshot? lastRetrieved = docs.isNotEmpty?await getDocument(query, docs.last.id):null;

    account = account.where((account) => filters.values.every((wrapper) =>
        account.filter(wrapper.filterFunction, wrapper.fieldValue))
    ).toList();

    var a = (account.length>=(remaining??limit) || endOfList) ? account :
    [...account, ...(await _getAccountsFiltered(query, filters, limit, lastRetrieved, limit-account.length))];
    return a;
  }

  Future<int> getAccountCountsByType( String? typology) async {

    // Query filtrata con aggregazione per il conteggio
    Query startQuery = _collectionUtenti;

    if(typology != null){
      startQuery = startQuery.where(Constants.tabellaUtenti_tipologia, isEqualTo: typology); // Filtra in base al campo e al valore
    }

    final aggregateQuerySnapshot = await startQuery.count().get();

    // Restituisce il conteggio
    return aggregateQuerySnapshot.count??0;
  }


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> _getCategories() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_Categorie).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _getTypesEvent() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_Tipologie).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _getTypesCustomer() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_TipologieCliente).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _getTypesUser() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_TipologieUtente).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Stream<Map<String, dynamic>> getInfoApp() {
    return _collectionCostanti.doc(Constants.tabellaCostanti_InfoApp).snapshots().map((document)  => document.data()! as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPhoneNumbers() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_Telefoni).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Future<Event?> getEvent(String id) async {
    return _collectionEventi.doc(id).get().then((document) => document.exists?
        Event.fromMap(document.id,  getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data()! as Map<String, dynamic>) : null);
  }

  Future<List<Event>> getEvents() async {
    return _collectionEventi.orderBy(Constants.tabellaEventi_dataInizio).get().then((snapshot) => snapshot.docs.map((document) =>
        Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList());
  }

  Future<List<Event>> getFutureEvents(DateTime date) async {
    date = date.subtract(const Duration(days: 1));

    // Query 1: eventi NON ricorrenti
    final snapshotNotRepeated = await _collectionEventi
        .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: date)
        .orderBy(Constants.tabellaEventi_dataInizio)
        .get();

    // Query 2: eventi ECCEZIONE (es. override da una serie ricorrente)
    final snapshotExceptions = await _collectionEventi
        .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: date)
        .where(Constants.tabellaEventi_isExcepeted, isEqualTo: true)
        .orderBy(Constants.tabellaEventi_dataInizio)
        .get();

    // Unione e parsing
    final eventsNotRepeated = snapshotNotRepeated.docs.map((document) => Event.fromMap(
      document.id,
      getColorByCategory(document.get(Constants.tabellaEventi_categoria)),
      document.data() as Map<String, dynamic>,
    )).where((event)=> event.isRepeated==false).toList();

    final eventExceptions = snapshotExceptions.docs.map((document) => Event.fromMap(
      document.id,
      getColorByCategory(document.get(Constants.tabellaEventi_categoria)),
      document.data() as Map<String, dynamic>,
    )).toList();
    final events = [
      ...eventsNotRepeated,
      ...eventExceptions,
    ];

    // Ordina di nuovo per sicurezza
    events.sort((a, b) => a.start.compareTo(b.start));

    return events;
  }


  Stream<List<Event>> subscribeEvents() {
    return _collectionEventi.orderBy(Constants.tabellaEventi_dataInizio, descending: true).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeDraftEvents() {
    return _collectionEventi.where(Constants.tabellaEventi_stato, isEqualTo: EventStatus.Bozza).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsByOperatorWaiting(String idOperator) {
    return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContains: idOperator).where(Constants.tabellaEventi_stato, isGreaterThanOrEqualTo: EventStatus.New).where(Constants.tabellaEventi_stato, isLessThanOrEqualTo: EventStatus.Seen).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }// TODO merge subscription queries

  Stream<List<Event>> subscribeEventsByOperator(List<String> idsOperator, {required int statusEqualOrAbove, DateTime? from, DateTime? to}) {
    if(from != null && to != null)
      return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
          .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: from)
          .where(Constants.tabellaEventi_dataInizio, isLessThan: to).snapshots().map((snapshot) {
        var documents = snapshot.docs;
        return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).where((event) => event.status>=statusEqualOrAbove).toList();
      });
    else
      return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
          .where(Constants.tabellaEventi_stato, isGreaterThanOrEqualTo: statusEqualOrAbove).snapshots().map((snapshot) {
        var documents = snapshot.docs;
        return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
      });
  }

  Stream<List<Event>> subscribeEventsByOperatorReapet(
      List<String> idsOperator, {
        required int statusEqualOrAbove,
        DateTime? from,
        DateTime? to,
      }) {
    final queryFrom = from ?? _.DateUtils.now().subtract(const Duration(days: 90));
    final queryTo = to ?? _.DateUtils.now().add(const Duration(days: 90));

    // Giorni inclusi nell’intervallo
    final daysInRange = List.generate(
      queryTo.difference(queryFrom).inDays + 1,
          (i) => queryFrom.add(Duration(days: i)).day,
    );

    // Spezza i giorni in batch da max 10 per whereIn
    List<List<int>> chunkedDays = [];
    for (var i = 0; i < daysInRange.length; i += 10) {
      chunkedDays.add(
          daysInRange.sublist(i, i + 10 > daysInRange.length ? daysInRange.length : i + 10));
    }

    // Query eventi non ricorrenti o override
    final baseQuery = _collectionEventi
        .where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
        .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: queryFrom)
        .where(Constants.tabellaEventi_dataInizio, isLessThan: queryTo);

    // Query eventi override di ricorrenze (recurringId != null)
    final overrideQuery = _collectionEventi
        .where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
        .where(Constants.tabellaEventi_recurrenceId, isNotEqualTo: '')
        .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: queryFrom)
        .where(Constants.tabellaEventi_dataInizio, isLessThan: queryTo);

    // Query eventi ricorrenti master (una per ogni batch di giorni)
    final recurringStreams = chunkedDays.map((days) {
      return _collectionEventi
          .where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
          .where(Constants.tabellaEventi_dataInizio, isLessThan: queryTo)
          .where(Constants.tabellaEventi_recurrenceDayOfMonth, whereIn: days)
          .where(Constants.tabellaEventi_recurrenceId, isEqualTo: '')
          .where(Constants.tabellaEventi_isRepeated, isEqualTo: true)
          .snapshots();
    }).toList();

    // Stream base + override
    final baseStream = baseQuery.snapshots();
    final overrideStream = overrideQuery.snapshots();

    // Combiniamo tutto
    return Rx.combineLatestList([
      baseStream,
      overrideStream,
      ...recurringStreams,
    ]).map((snapshots) {
      final baseSnap = snapshots[0] as QuerySnapshot;
      final overrideSnap = snapshots[1] as QuerySnapshot;
      final recurringSnaps = snapshots.sublist(2).cast<QuerySnapshot>();

      final baseEvents = baseSnap.docs
          .map((doc) => Event.fromMap(doc.id,
          getColorByCategory(doc.get(Constants.tabellaEventi_categoria)),
          doc.data() as Map<String, dynamic>))
          .where((event) => event.status >= statusEqualOrAbove && !event.isRepeated)
          .toList();

      List<Event> overrideEvents = overrideSnap.docs
          .map((doc) => Event.fromMap(doc.id,
          getColorByCategory(doc.get(Constants.tabellaEventi_categoria)),
          doc.data() as Map<String, dynamic>))
          .where((event) => event.status >= statusEqualOrAbove || event.status == EventStatus.Deleted)
          .toList();

      final recurringMasters = recurringSnaps.expand((snap) => snap.docs).map((doc) =>
          Event.fromMap(doc.id,
              getColorByCategory(doc.get(Constants.tabellaEventi_categoria)),
              doc.data() as Map<String, dynamic>))
          .where((event) => event.status >= statusEqualOrAbove)
          .toList();

      // Mappa override
      final overriddenMap = {
        for (final e in overrideEvents)
          "${e.recurrenceId}_${e.start.year}_${e.start.month}": true
      };

      // Genera istanze locali per eventi ricorrenti
      final recurringInstances = recurringMasters.expand((template) {
        return template.generateRecurringEvents(
            queryFrom, TimeUtils.minDate(template.end, queryTo))
            .where((e) =>
        !overriddenMap.containsKey("${e.recurrenceId}_${e.start.year}_${e.start.month}"));
      });

      return [
        ...baseEvents,
        ...overrideEvents.where((event) => event.status >= statusEqualOrAbove),
        ...recurringInstances,
      ]..sort((a, b) => a.start.compareTo(b.start));
    });
  }



  Stream<List<Event>> subscribeEventsHistory() {
    return _collectionSubStoricoEventi.orderBy(Constants.tabellaEventi_dataInizio, descending: true).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsDeleted() {
    return _collectionStoricoEliminati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsRefuse() {
    return _collectionStoricoRifiutati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsEnded() {
    return _collectionStoricoTerminati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<DocumentSnapshot> getDocument(CollectionReference table, String id) async {
    return await table.doc(id).get().then((doc) => doc);
  }

  Future<List<Event>> _getEventsFiltered(CollectionReference query, Map<String, FilterWrapper> filters, [limit, startFrom, remaining, history]) async {
    Query startQuery = query;
    filters = Map.from(filters);
    // due to firebase limitations (we can't build a query with all filters) let the repository do ALL filtering work
    // despite some fields will be handled in the firebase query and some other in code
    bool endOfList = false;
    bool filterStatus = false;
    if (filters.containsKey("status") && filters["status"]!.fieldValue != null){
      filterStatus = true;
      startQuery = startQuery.where(Constants.tabellaEventi_stato, isEqualTo: filters["status"]!.fieldValue);
    }

    bool useDataFine = history == true && (filters.containsKey("startDate") || filters.containsKey("endDate"));

    if (filters.containsKey("startDate") && filters["startDate"]!.fieldValue is DateTime) {
      if (!useDataFine) {
        startQuery = startQuery.where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: filters["startDate"]!.fieldValue);
      } else {
        startQuery = startQuery.where(Constants.tabellaEventi_dataFine, isGreaterThanOrEqualTo: filters["startDate"]!.fieldValue);
      }
    }
    if (filters.containsKey("endDate") && filters["endDate"]!.fieldValue is DateTime) {
      startQuery = startQuery.where(useDataFine ? Constants.tabellaEventi_dataFine : Constants.tabellaEventi_dataInizio, isLessThan: filters["endDate"]!.fieldValue);
    }
    startQuery = startQuery.orderBy(
        useDataFine ? Constants.tabellaEventi_dataFine : Constants.tabellaEventi_dataInizio, descending: true);
    startQuery = addPagination(startQuery, limit, startFrom);

    // if(filters.containsKey("title") && filters["title"]!.fieldValue!=null){
    //   String title = filters.remove("title")!.fieldValue;
    //   query = query.where(Constants.tabellaEventi_titolo, isGreaterThanOrEqualTo: title).where(Constants.tabellaEventi_titolo, isLessThanOrEqualTo: title + '~' ).orderBy(Constants.tabellaEventi_titolo, descending: false);
    // }

    if (filters.containsKey("suboperators") && filters["suboperators"]!.fieldValue != null) {
      List<Account> suboperators = new List.from(filters["suboperators"]!.fieldValue);
      if (suboperators.length > 0) {
        startQuery = startQuery.where(Constants.tabellaEventi_idOperatori, arrayContains: suboperators[0].id);
        if (suboperators.length == 1) filters.remove("suboperators");
      }
    }

    if (filters.containsKey("categories") && filters["categories"]!.fieldValue != null) {
      Map<String, bool> categories = Map.from(filters.remove("categories")!.fieldValue);
      categories.removeWhere((key, value) => !value);
      if (categories.length > 0) startQuery = startQuery.where(Constants.tabellaEventi_categoria, whereIn: categories.keys.toList());
    }

    var docs = await startQuery.get().then((snapshot) => snapshot.docs);
    if (limit != null && docs.length < limit) endOfList = true;

    List<Event> events = docs.map((document) =>
        Event.fromMap(document.id, getColorByCategory(
            document.get(Constants.tabellaEventi_categoria)),
            document.data() as Map<String, dynamic>)).toList();

    if(!history && !filterStatus) {
      events.removeWhere((element) => element.status < EventStatus.New);
    }

    events = events.where((event) => filters.values.every((wrapper) =>
            event.filter(wrapper.filterFunction, wrapper.fieldValue))
    ).toList();

    DocumentSnapshot? lastRetrieved = docs.isNotEmpty?await getDocument(query, docs.last.id):null;

    var a = (events.length>=(remaining??limit) || endOfList) ? events :
    [...events, ...(await _getEventsFiltered(query, filters, limit, lastRetrieved, (remaining??limit)-events.length, history))];
    return a;
  }

  Future<List<Event>> getEventsHistoryFiltered(int category, Map<String, FilterWrapper> filters, {limit, startFrom}) async {
    CollectionReference table = _collectionStoricoTerminati;
    if(category == EventStatus.Refused){
      table = _collectionStoricoRifiutati;
    }else if(category == EventStatus.Deleted){
      table = _collectionStoricoEliminati;
    }
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(table, startFrom);
    var events = await _getEventsFiltered(table, filters, limit, documentSnapshot, null, true);
    // Remove items that have isExcepeted false and isRepeated true
    events.removeWhere((e) => !e.isExcepeted && e.isRepeated);
    return events;
  }

  Future<List<Event>> getEventsActiveFiltered(Map<String, FilterWrapper> filters, {limit, startFrom}) async{
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionEventi, startFrom);
    return _getEventsFiltered(_collectionEventi, filters, limit, documentSnapshot, null, false);
  }

  Future<int> getEventCountsByStatus([int? status]) async {
    Query startQuery = _collectionEventi;

    if(status != null){
      startQuery = startQuery.where(Constants.tabellaEventi_stato, isEqualTo: status); // Filtra in base al campo e al valore
    }else{
      startQuery = startQuery.where(Constants.tabellaEventi_stato, isGreaterThanOrEqualTo: EventStatus.New); // Filtra in base al campo e al valore
    }

    final aggregateQuerySnapshot = await startQuery.count().get();

    // Restituisce il conteggio
    return aggregateQuerySnapshot.count??0;
  }

  Future<String> addEvent(Event data) async {
    var docRef = await _collectionEventi.add(data.toDocument());
    return docRef.id;
  }

  Future<int> getHistoryCountsByType( int? archives, String? category) async {
    Query table = _collectionStoricoTerminati;

    if(archives == EventStatus.Refused){
      table = _collectionStoricoRifiutati;
    }else if(archives == EventStatus.Deleted){
      table = _collectionStoricoEliminati;
    }

    if(category != null){
      table = table.where(Constants.tabellaEventi_categoria, isEqualTo: category);
    }

    final aggregateQuerySnapshot = await table.count().get();

    final excludeQuery = table
        .where(Constants.tabellaEventi_isExcepeted, isEqualTo: false)
        .where(Constants.tabellaEventi_isRepeated, isEqualTo: true);
    final excludeAggregateQuerySnapshot = await excludeQuery.count().get();

    // Restituisce il conteggio
    return (aggregateQuerySnapshot.count??0) - (excludeAggregateQuerySnapshot.count??0);
  }

  Future<List<int>> getHistoryYearsRange(int? archives) async {
    Query table = _collectionStoricoTerminati;
    if(archives == EventStatus.Refused){
      table = _collectionStoricoRifiutati;
    }else if(archives == EventStatus.Deleted){
      table = _collectionStoricoEliminati;
    }

    try {
      final ascSnapshot = await table.orderBy(Constants.tabellaEventi_dataFine, descending: false).limit(1).get();
      final descSnapshot = await table.orderBy(Constants.tabellaEventi_dataFine, descending: true).limit(1).get();

      if (ascSnapshot.docs.isEmpty || descSnapshot.docs.isEmpty) return [DateTime.now().year];

      final firstDate = (ascSnapshot.docs.first.data() as Map<String, dynamic>)[Constants.tabellaEventi_dataFine];
      final lastDate = (descSnapshot.docs.first.data() as Map<String, dynamic>)[Constants.tabellaEventi_dataFine];
      
      final firstYear = firstDate != null ? (firstDate as Timestamp).toDate().year : DateTime.now().year;
      final lastYear = lastDate != null ? (lastDate as Timestamp).toDate().year : DateTime.now().year;
      
      return [firstYear, lastYear];
    } catch (e) {
      return [DateTime.now().year];
    }
  }

  Future<int> getHistoryCountByDateRange(int? archives, DateTime start, DateTime end, {Map<String, FilterWrapper>? filters}) async {
    Map<String, FilterWrapper> mergedFilters = Map.from(filters ?? {});
    mergedFilters["startDate"] = FilterWrapper("startDate", start, null);
    mergedFilters["endDate"] = FilterWrapper("endDate", end, null);
    return getEventsHistoryFilteredCount(archives ?? EventStatus.Ended, mergedFilters);
  }

  Future<int> getEventsHistoryFilteredCount(int category, Map<String, FilterWrapper> filters) async {
    CollectionReference table = _collectionStoricoTerminati;
    if(category == EventStatus.Refused){
      table = _collectionStoricoRifiutati;
    }else if(category == EventStatus.Deleted){
      table = _collectionStoricoEliminati;
    }

    Query startQuery = table;

    if (filters.containsKey("status") && filters["status"]!.fieldValue != null){
      startQuery = startQuery.where(Constants.tabellaEventi_stato, isEqualTo: filters["status"]!.fieldValue);
    }

    bool useDataFine = filters.containsKey("startDate") || filters.containsKey("endDate");

    if (filters.containsKey("startDate") && filters["startDate"]!.fieldValue is DateTime) {
      startQuery = startQuery.where(useDataFine ? Constants.tabellaEventi_dataFine : Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: filters["startDate"]!.fieldValue);
    }
    if (filters.containsKey("endDate") && filters["endDate"]!.fieldValue is DateTime) {
      startQuery = startQuery.where(useDataFine ? Constants.tabellaEventi_dataFine : Constants.tabellaEventi_dataInizio, isLessThan: filters["endDate"]!.fieldValue);
    }

    if (filters.containsKey("suboperators") && filters["suboperators"]!.fieldValue != null) {
      List<Account> suboperators = List.from(filters["suboperators"]!.fieldValue);
      if (suboperators.isNotEmpty) {
        startQuery = startQuery.where(Constants.tabellaEventi_idOperatori, arrayContains: suboperators[0].id);
      }
    }

    if (filters.containsKey("categories") && filters["categories"]!.fieldValue != null) {
      Map<String, bool> categories = Map.from(filters["categories"]!.fieldValue);
      categories.removeWhere((key, value) => !value);
      if (categories.isNotEmpty) {
        startQuery = startQuery.where(Constants.tabellaEventi_categoria, whereIn: categories.keys.toList());
      }
    }

    try {
      final aggregateQuerySnapshot = await startQuery.count().get();

      final excludeQuery = startQuery
          .where(Constants.tabellaEventi_isExcepeted, isEqualTo: false)
          .where(Constants.tabellaEventi_isRepeated, isEqualTo: true);
      final excludeAggregateQuerySnapshot = await excludeQuery.count().get();

      return (aggregateQuerySnapshot.count ?? 0) - (excludeAggregateQuerySnapshot.count ?? 0);
    } catch (e) {
      // Fallback in case of missing index for the complex count
      final aggregateQuerySnapshot = await startQuery.count().get();
      return aggregateQuerySnapshot.count ?? 0;
    }
  }

  Future<String> addEventPast(Event e) async {
    e.status = EventStatus.Ended;
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc();
      dynamic endedDoc = _collectionStoricoTerminati.doc(doc.id);
      await tx.set(endedDoc, e.toDocument());
      await tx.set(doc,  e.toDocument());
      return doc.id;
    };
    return _cloudFirestore.runTransaction(createTransaction).then((idDoc) => idDoc);
  }

  void updateEvent(String id, Event data) {
    _collectionEventi.doc(id).update(data.toDocument());
  }

  void updateEventPast(String id, Event data) {
    data.status = EventStatus.Ended;
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(id);
      DocumentReference endedDoc = _collectionStoricoTerminati.doc(id);
      DocumentSnapshot docEnded = await endedDoc.get();
      if(docEnded.exists){
        await tx.update(endedDoc, data.toDocument());
      }else{
        await tx.set(endedDoc, data.toDocument());
      }
      await tx.update(doc, data.toDocument());
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  void updateEventField(String id, String field, dynamic data) {
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(id);
      DocumentReference endedDoc = _collectionStoricoTerminati.doc(id);
      DocumentSnapshot docEnded = await endedDoc.get();
      if(docEnded.exists){
        await tx.update(endedDoc,Map.of({field:data}));
      }
      await tx.update(doc,Map.of({field:data}));
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  void deleteEvent(Event e, bool deleteAllSeries) async {
    dynamic createTransaction;
    if(e.id.isNotEmpty && !e.isRepeatedEvent()) {
      e.status = EventStatus.Deleted;
      createTransaction = (dynamic tx) async {
        dynamic doc = _collectionEventi.doc(e.id);
        dynamic deletedDoc = _collectionStoricoEliminati.doc(e.id);
        await tx.set(deletedDoc, e.toDocument());
        await tx.delete(doc);
      };
    }else{
      if(deleteAllSeries){
        createTransaction = (dynamic tx) async {
          dynamic doc = _collectionEventi.doc(e.recurrenceId);
          Event? eventRecurrence = await getEvent(e.recurrenceId);
          eventRecurrence!.end = e.end.subtract(const Duration(days: 1));
          await tx.set(doc, eventRecurrence.toDocument());
        };
      }else{
        e.status = EventStatus.Deleted;
        createTransaction = (dynamic tx) async {
          final doc = _collectionEventi.doc();
          final deletedDoc = _collectionStoricoEliminati.doc();
          await tx.set(deletedDoc, e.toDocument());
          await tx.set(doc, e.toDocument());
        };
      }
    }
    _cloudFirestore.runTransaction(createTransaction);
  }

  void deleteEventPast(Event e, bool deleteAllSeries) async {
    dynamic createTransaction;
    if(e.id.isNotEmpty && !e.isRepeatedEvent()) {
      e.status = EventStatus.Deleted;
      createTransaction = (dynamic tx) async {
        dynamic doc = _collectionEventi.doc(e.id);
        dynamic endedDoc = _collectionStoricoTerminati.doc(e.id);
        dynamic deletedDoc = _collectionStoricoEliminati.doc(e.id);
        await tx.set(deletedDoc, e.toDocument());
        await tx.delete(endedDoc);
        await tx.delete(doc);
      };
    }else{
      if(deleteAllSeries) {
        createTransaction = (dynamic tx) async {
          dynamic doc = _collectionEventi.doc(e.recurrenceId);
          Event? eventRecurrence = await getEvent(e.recurrenceId);
          eventRecurrence!.end = e.end.subtract(const Duration(days: 1));
          await tx.set(doc, eventRecurrence.toDocument());
        };
      }else{
        e.status = EventStatus.Deleted;
        e.isExcepeted = true;
        createTransaction = (dynamic tx) async {
          final doc = _collectionEventi.doc();
          final deletedDoc = _collectionStoricoEliminati.doc();
          await tx.set(deletedDoc, e.toDocument());
          await tx.set(doc, e.toDocument());
        };
      }
    }
    _cloudFirestore.runTransaction(createTransaction);
  }

  void endEvent(Event e, {bool propagate = false}) async {
    e.status = EventStatus.Ended;
    if(e.id.isEmpty){
      e.isExcepeted = true;
      e.id = await addEvent(e);
    }
    if(propagate) {
      e.end = _.DateUtils.now();
    }
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(e.id);
      dynamic endedDoc = _collectionStoricoTerminati.doc(e.id);
      await tx.set(endedDoc, e.toDocument());
      await tx.update(doc, e.toDocument());
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  void refuseEvent(Event e) async {
    e.status = EventStatus.Refused;
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(e.id);
      dynamic refusedDoc = _collectionStoricoRifiutati.doc(e.id);
      await tx.set(refusedDoc, e.toDocument());
      await tx.update(doc, {Constants.tabellaEventi_stato:e.status});
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  String getColorByCategory(String? category) =>
    categories[category??Constants.categoryDefault]??Constants.fallbackHexColor;

  static void backgroundUpdateEventAsDelivered(String id) async {
    Event? event = await FirebaseFirestore.instance.collection(Constants.tabellaEventi).doc(id).get().then((document) => document.exists ? Event.fromMap(document.id, "", document.data()!) : null );
    if (event != null && event.isNew()) {
      FirebaseFirestore.instance.collection(Constants.tabellaEventi).doc(id).update(Map.of({Constants.tabellaEventi_stato: EventStatus.Delivered})
      );
    }
  }

  Query addPagination(Query query, [limit, startFrom]) {
    if (limit != null && startFrom != null) {
      query = query.limit(limit).startAfterDocument(startFrom as DocumentSnapshot);
    }else if (limit != null)
      query = query.limit(limit);
    else if (startFrom != null) {
      query = query.startAfterDocument(startFrom as DocumentSnapshot);
    }
    return query;
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<String> addCustomer(Customer data) async {
    var docRef = await _collectionClienti.add(data.toDocument());
    return docRef.id;
  }

  void updateCustomer(String id, Customer data) {
    _collectionClienti.doc(id).update(data.toDocument());
  }

  Future<Customer?> getCustomer(String id) async {
    return _collectionClienti.doc(id).get().then((document) => document.exists?
      Customer.fromMap(document.id, document.data()! as Map<String, dynamic>) : null);
  }

  Future<List<Customer>> getCustomers(Map<String, FilterWrapper> filters, {limit, startFrom }) async {
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionClienti, startFrom);
    return _getCustomersFiltered(_collectionClienti, filters, limit, documentSnapshot, null);
  }

  Future<List<Customer>> getCustomersByIds(List<String> idCustomers) async {
    final snapshot = await _collectionClienti
        .where(FieldPath.documentId, whereIn: idCustomers)
        .get();

    // Mappa i documenti in una lista di Customer
    final customers = snapshot.docs
        .map((document) =>
        Customer.fromMap(document.id, document.data() as Map<String, dynamic>))
        .toList();

    // Crea una mappa per accedere ai Customer in base al loro ID
    final customersMap = {for (var customer in customers) customer.id: customer};

    // Riordina i risultati secondo l'ordine originale di idCustomers
    return idCustomers
        .map((id) => customersMap[id])
        .where((customer) => customer != null) // Filtra gli ID mancanti
        .cast<Customer>() // Cast a Customer
        .toList();
  }

  void deleteCustomer(String id) {
    _collectionClienti.doc(id).delete();
  }

  Future<List<Customer>> getCustomersActiveFiltered(Map<String, FilterWrapper> filters, {limit, startFrom}) async {
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionClienti, startFrom);
    return _getCustomersFiltered(_collectionClienti, filters, limit, documentSnapshot, null);
  }


  Future<List<Customer>> _getCustomersFiltered(CollectionReference query, Map<String, FilterWrapper> filters, [limit, startFrom, remaining]) async {
    Query startQuery = query;
    filters = Map.from(filters);
    // due to firebase limitations (we can't build a query with all filters) let the repository do ALL filtering work
    // despite some fields will be handled in the firebase query and some other in code
    bool endOfList = false;

    if (filters.containsKey("typology") && filters["typology"]!.fieldValue != null){
      startQuery = startQuery.where(Constants.tabellaClienti_tipologia, isEqualTo: filters["typology"]!.fieldValue);
    }
    startQuery = startQuery.orderBy(
        Constants.tabellaClienti_cognome);
    startQuery = addPagination(startQuery, limit, startFrom);

    var docs = await startQuery.get().then((snapshot) => snapshot.docs);
    if (limit != null && docs.length < limit) endOfList = true;

    List<Customer> customer = docs.map((document) =>
        Customer.fromMap(document.id, document.data() as Map<String, dynamic>)).toList();

    DocumentSnapshot? lastRetrieved = docs.isNotEmpty?await getDocument(query, docs.last.id):null;

    customer = customer.where((customer) => filters.values.every((wrapper) =>
        customer.filter(wrapper.filterFunction, wrapper.fieldValue))
    ).toList();

    var a = (customer.length>=(remaining??limit) || endOfList) ? customer :
    [...customer, ...(await _getCustomersFiltered(query, filters, limit, lastRetrieved, limit-customer.length))];
    return a;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// CHAT METHODS

  Stream<List<ChatOverview>> subscribeChats() {
    return _collectionChats
        .orderBy(Constants.tabellaChats_lastMessageTime, descending: true)
        .snapshots()
        .map((snapshot) {
          var documents = snapshot.docs;
          return documents.map((doc) => ChatOverview.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  Stream<List<Message>> subscribeMessages(String chatId) {
    return _collectionChats
        .doc(chatId)
        .collection(Constants.tabellaMessaggi) // Ensure this subcollection name is defined in Constants
        .orderBy(Constants.tabellaMessaggi_timestamp, descending: true) // Newest first
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> sendMessage(String chatId, String text) async {
    final timestamp = Timestamp.now();
    final messageData = {
      Constants.tabellaMessaggi_text: text,
      Constants.tabellaMessaggi_timestamp: timestamp,
      Constants.tabellaMessaggi_isMe: true,
      Constants.tabellaMessaggi_isRead: true, // Read by sender obviously
    };

    // Add message to subcollection
    await _collectionChats
        .doc(chatId)
        .collection(Constants.tabellaMessaggi)
        .add(messageData);

    // Update chat overview
    await _collectionChats.doc(chatId).update({
      Constants.tabellaChats_lastMessage: text,
      Constants.tabellaChats_lastMessageTime: timestamp,
      // 'unreadCount': FieldValue.increment(1) // Usually recipient increments this
    });
  }

  Future<void> markChatAsRead(String chatId) async {
    await _collectionChats.doc(chatId).update({
      Constants.tabellaChats_unreadCount: 0,
    });
  }

  Future<List<ContactWhatsapp>> getContactWhatsapp(Map<String, FilterWrapper> filters, {limit, startFrom }) async {
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionContactsWhatsapp, startFrom);
    return _getContactWhatsappFiltered(_collectionContactsWhatsapp, filters, limit, documentSnapshot, null);
  }

  Future<List<ContactWhatsapp>> _getContactWhatsappFiltered(CollectionReference query, Map<String, FilterWrapper> filters, [limit, startFrom, remaining]) async {
    Query startQuery = query;
    filters = Map.from(filters);
    // due to firebase limitations (we can't build a query with all filters) let the repository do ALL filtering work
    // despite some fields will be handled in the firebase query and some other in code
    bool endOfList = false;

    startQuery = startQuery.orderBy(
        Constants.tabellaContattiWhatsapp_name);
    startQuery = addPagination(startQuery, limit, startFrom);

    var docs = await startQuery.get().then((snapshot) => snapshot.docs);
    if (limit != null && docs.length < limit) endOfList = true;

    List<ContactWhatsapp> contactWhatsapp = docs.map((document) =>
        ContactWhatsapp.fromMap(document.id, document.data() as Map<String, dynamic>)).toList();

    DocumentSnapshot? lastRetrieved = docs.isNotEmpty?await getDocument(query, docs.last.id):null;

    contactWhatsapp = contactWhatsapp.where((contactWhatsapp) => filters.values.every((wrapper) =>
        contactWhatsapp.filter(wrapper.filterFunction, wrapper.fieldValue))
    ).toList();

    var a = (contactWhatsapp.length>=(remaining??limit) || endOfList) ? contactWhatsapp :
    [...contactWhatsapp, ...(await _getContactWhatsappFiltered(query, filters, limit, lastRetrieved, limit-contactWhatsapp.length))];
    return a;
  }

  Future<List<ContactWhatsapp>> getContactWhatsappByIds(List<String> idContactWhatsapp) async {
    final snapshot = await _collectionContactsWhatsapp
        .where(FieldPath.documentId, whereIn: idContactWhatsapp)
        .get();

    // Mappa i documenti in una lista di Customer
    final contactWhatsapps = snapshot.docs
        .map((document) =>
        ContactWhatsapp.fromMap(document.id, document.data() as Map<String, dynamic>))
        .toList();

    // Crea una mappa per accedere ai Customer in base al loro ID
    final contactWhatsappMap = {for (var contactWhatsapp in contactWhatsapps) contactWhatsapp.id: contactWhatsapp};

    // Riordina i risultati secondo l'ordine originale di idContactWhatsapp
    return idContactWhatsapp
        .map((id) => contactWhatsappMap[id])
        .where((contactWhatsapp) => contactWhatsapp != null) // Filtra gli ID mancanti
        .cast<ContactWhatsapp>() // Cast a Customer
        .toList();
  }


  Future<int> getCustomerCountsByType( String? typology) async {

    // Query filtrata con aggregazione per il conteggio
    Query startQuery = _collectionClienti;

    if(typology != null){
      startQuery = startQuery.where(Constants.tabellaClienti_tipologia, isEqualTo: typology); // Filtra in base al campo e al valore
    }

    final aggregateQuerySnapshot = await startQuery.count().get();

    // Restituisce il conteggio
    return aggregateQuerySnapshot.count??0;
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// MESSAGE CONFIG
  Stream<MessageConfig> subscribeMessageConfig()  {
    return _collectionMessageConfig.doc("whatsapp-client").snapshots().map((messageConfig) {
      return MessageConfig.fromMap(messageConfig.data()! as Map<String, dynamic>);
    });
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTRATTI

  Future<String> addContract(Contract contract) async {
    var docRef = await _collectionContratti.add(contract.toDocument());
    return docRef.id;
  }

  void updateContract(String id, Contract contract) {
    _collectionContratti.doc(id).update(contract.toDocument());
  }

  Future<Contract?> getContract(String id) async {
    return _collectionContratti.doc(id).get().then((doc) =>
        doc.exists ? Contract.fromMap(doc.id, doc.data()! as Map<String, dynamic>) : null);
  }

  void deleteContract(String id) {
    _collectionContratti.doc(id).delete();
  }

  /// Restituisce tutti i contratti di un cliente specifico.
  Future<List<Contract>> getContractsByCustomer(String clienteId) async {
    final snapshot = await _collectionContratti
        .where(Constants.tabellaContratti_clienteId, isEqualTo: clienteId)
        .get();
    return snapshot.docs
        .map((doc) => Contract.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Restituisce contratti con filtri: anno, mese (prossimaMese), categoria.
  Future<List<Contract>> getContractsFiltered({
    int? year,
    int? month,
    String? categoria,
    String? searchText,
    int? status,
    int limit = 250,
    DocumentSnapshot? startFrom,
  }) async {
    Query query = _collectionContratti;

    if (status != null) {
      query = query.where(Constants.tabellaContratti_stato, isEqualTo: status);
    }

    if (categoria != null && categoria.isNotEmpty) {
      query = query.where(Constants.tabellaContratti_categoria, isEqualTo: categoria);
    }

    if (year != null && month != null) {
      final from = DateTime(year, month, 1);
      final to = DateTime(year, month + 1, 1);
      query = query
          .where(Constants.tabellaContratti_prossimaMese, isGreaterThanOrEqualTo: from)
          .where(Constants.tabellaContratti_prossimaMese, isLessThan: to);
    } else if (year != null) {
      final from = DateTime(year, 1, 1);
      final to = DateTime(year + 1, 1, 1);
      query = query
          .where(Constants.tabellaContratti_prossimaMese, isGreaterThanOrEqualTo: from)
          .where(Constants.tabellaContratti_prossimaMese, isLessThan: to);
    }

    query = query.orderBy(Constants.tabellaContratti_prossimaMese);

    if (startFrom != null) {
      query = query.startAfterDocument(startFrom);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    List<Contract> contracts = snapshot.docs
        .map((doc) => Contract.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Filtro testo libero lato client (su nome edificio o nome cliente)
    if (searchText != null && searchText.isNotEmpty) {
      final lower = searchText.toLowerCase();
      contracts = contracts.where((c) {
        return c.customer.displayName().toLowerCase().contains(lower) ||
            c.customer.address.address.join(' ').toLowerCase().contains(lower) ||
            c.title.toLowerCase().contains(lower) ||
            c.description.toLowerCase().contains(lower);
      }).toList();
    }

    return contracts;
  }

  /// Conta i contratti in scadenza nel mese corrente (per badge menu).
  Future<int> getContractsCurrentMonthCount() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 1);
    final snapshot = await _collectionContratti
        .where(Constants.tabellaContratti_stato, isEqualTo: ContractStatus.Active)
        .where(Constants.tabellaContratti_prossimaMese, isGreaterThanOrEqualTo: from)
        .where(Constants.tabellaContratti_prossimaMese, isLessThan: to)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Crea un set di contratti di prova realistici per testare lo scadenziario
  /// distribuiti su una finestra di 5 mesi (-2, -1, 0, +1, +2).
  Future<void> createSampleContracts() async {
    final now = DateTime.now();

    Customer makeCustomer({
      required String id,
      required String nomeEdificio,
      required String tipologiaEdificio,
      required String codiceFiscaleEdificio,
      required String nomeReferente,
      required String tipologia,
      required String email,
      required String phone,
      required List<String> indirizzo,
      required String telefonoIndirizzo,
      required String contattoNome,
      required String contattoTel,
    }) {
      final cust = Customer.empty();
      cust.id = id;
      cust.nomeEdificio = nomeEdificio;
      cust.tipologiaEdificio = tipologiaEdificio;
      cust.codiceFiscaleEdificio = codiceFiscaleEdificio;
      cust.name = nomeReferente;
      cust.surname = '';
      cust.email = email;
      cust.phone = phone;
      cust.phones = [phone, contattoTel];
      cust.typology = tipologia;
      cust.address = Address(indirizzo, telefonoIndirizzo);
      cust.addresses = [cust.address];
      cust.referral = Referrals(contattoNome, contattoTel);
      cust.referrals = [cust.referral];
      return cust;
    }

    final sampleData = [
      // Mese -2 (es. Agosto)
      {
        'customer': makeCustomer(
          id: 'sample_cust_1',
          nomeEdificio: 'Condominio Albinoni 12',
          tipologiaEdificio: Customer.EDIFICIO_CONDOMINIO,
          codiceFiscaleEdificio: '91234560371',
          nomeReferente: 'Studio Amministrazioni Rossi',
          tipologia: Customer.AMMINISTRATORE,
          email: 'rossi.amministrazioni@email.it',
          phone: '051 456789',
          indirizzo: ['Via Giuseppe Albinoni 12', 'Bologna (BO)', '40137'],
          telefonoIndirizzo: '051 456789',
          contattoNome: 'Sig. Rossi Marco (Amministratore)',
          contattoTel: '340 1234567',
        ),
        'title': 'Pulizia Fosse Biologiche e Pozzetti Condominiali',
        'desc': 'Spurgo periodico annuale fosse biologiche, pozzetti di cacciata e sifoni firenze.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': false,
        'freq': 12,
        'monthOffset': -2,
        'canone': 1250.0,
        'assi': 2,
        'note': 'Accesso carraio da cortile interno. Chiavi presso custode scala A.',
        'fattura': 'FT-2025/089',
      },
      // Mese -1 (es. Settembre)
      {
        'customer': makeCustomer(
          id: 'sample_cust_2',
          nomeEdificio: 'Residence I Girasoli',
          tipologiaEdificio: Customer.EDIFICIO_CONDOMINIO,
          codiceFiscaleEdificio: '98765430372',
          nomeReferente: 'Immobiliare Bologna Est',
          tipologia: Customer.AMMINISTRATORE,
          email: 'gestioni@bolognaest.it',
          phone: '051 6271890',
          indirizzo: ["Via dell'Artigiano 45", 'San Lazzaro di Savena (BO)', '40068'],
          telefonoIndirizzo: '051 6271890',
          contattoNome: 'Dott.ssa Girasoli Carla',
          contattoTel: '335 9876543',
        ),
        'title': 'Spurgo e Lavaggio Colonne di Scarico',
        'desc': 'Lavaggio canal-jet colonne montanti cucina e scarichi principali.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': true,
        'freq': 6,
        'monthOffset': -1,
        'canone': 890.0,
        'assi': 2,
        'note': 'Richiesto preavviso di 48h ai condomini tramite avviso bacheca.',
        'fattura': 'FT-2025/112',
      },
      // Mese 0 (Corrente - es. Ottobre) - Contratto 1
      {
        'customer': makeCustomer(
          id: 'sample_cust_3',
          nomeEdificio: 'Meccanica Padana S.p.A.',
          tipologiaEdificio: Customer.EDIFICIO_AZIENDA,
          codiceFiscaleEdificio: '02837490378',
          nomeReferente: 'Meccanica Padana S.p.A.',
          tipologia: Customer.AZIENDA,
          email: 'manutenzioni@meccanicapadana.it',
          phone: '051 723411',
          indirizzo: ["Via dell'Industria 88", 'Calderara di Reno (BO)', '40012'],
          telefonoIndirizzo: '051 723411',
          contattoNome: 'Ing. Ferri Marco (RSPP)',
          contattoTel: '333 4455667',
        ),
        'title': 'Manutenzione Periodica Vasche Decantazione e Disoleatori',
        'desc': 'Aspirazione fanghi industriali da disoleatori piazzale e vasche lavaggio pezzi.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': false,
        'freq': 3,
        'monthOffset': 0,
        'canone': 2400.0,
        'assi': 3,
        'note': 'Necessario DPI speciali, tesserino e modulo DUVRI per accesso stabilimento.',
        'fattura': 'FT-2026/045',
      },
      // Mese 0 (Corrente - es. Ottobre) - Contratto 2
      {
        'customer': makeCustomer(
          id: 'sample_cust_4',
          nomeEdificio: 'Palazzo Zamboni',
          tipologiaEdificio: Customer.EDIFICIO_PRIVATO,
          codiceFiscaleEdificio: 'ZMBLNE68L45A944B',
          nomeReferente: 'Zamboni Elena',
          tipologia: Customer.PRIVATO,
          email: 'elena.zamboni@libero.it',
          phone: '051 223344',
          indirizzo: ['Via Zamboni 34', 'Bologna (BO)', '40126'],
          telefonoIndirizzo: '051 223344',
          contattoNome: 'Dott.ssa Elena Zamboni',
          contattoTel: '348 7766554',
        ),
        'title': 'Controllo Rete Fognaria e Videoispezione Condotte',
        'desc': 'Verifica periodica reflui e videoispezione con report digitale rete antica.',
        'cat': 'Videoispezione',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': false,
        'freq': 12,
        'monthOffset': 0,
        'canone': 650.0,
        'assi': 2,
        'note': 'Centro storico ZTL. Accesso consentito solo con automezzo passo corto.',
        'fattura': 'FT-2025/198',
      },
      // Mese +1 (es. Novembre)
      {
        'customer': makeCustomer(
          id: 'sample_cust_5',
          nomeEdificio: 'Condominio San Mamolo 28',
          tipologiaEdificio: Customer.EDIFICIO_CONDOMINIO,
          codiceFiscaleEdificio: '92019380375',
          nomeReferente: 'Geom. Bianchi Roberto',
          tipologia: Customer.AMMINISTRATORE,
          email: 'studio.bianchi@gmail.com',
          phone: '051 582319',
          indirizzo: ['Via San Mamolo 28', 'Bologna (BO)', '40136'],
          telefonoIndirizzo: '051 582319',
          contattoNome: 'Geom. Roberto Bianchi',
          contattoTel: '338 1122334',
        ),
        'title': 'Esposizione Cartello e Manutenzione Preventiva Pozzetti',
        'desc': 'Cartellonistica divieto di sosta e svuotamento annuale vasche pluviali.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.ESPOSIZIONE_CARTELLO,
        'cartel': true,
        'freq': 12,
        'monthOffset': 1,
        'canone': 1100.0,
        'assi': 2,
        'note': 'Posizionare cartelli divieto di sosta 48h prima con foto protocollata vigili.',
        'fattura': 'FT-2025/240',
      },
      // Mese +2 (es. Dicembre) - Contratto 1
      {
        'customer': makeCustomer(
          id: 'sample_cust_6',
          nomeEdificio: 'Villa Reale Park',
          tipologiaEdificio: Customer.EDIFICIO_PRIVATO,
          codiceFiscaleEdificio: 'BNTALN55M12A944R',
          nomeReferente: 'Bentivoglio Alessandro',
          tipologia: Customer.PRIVATO,
          email: 'a.bentivoglio@residenzastorica.it',
          phone: '051 591204',
          indirizzo: ['Via dei Colli 15', 'Casalecchio di Reno (BO)', '40033'],
          telefonoIndirizzo: '051 591204',
          contattoNome: 'Sig. Giuseppe (Custode Tenuta)',
          contattoTel: '339 8877665',
        ),
        'title': 'Pulizia Fosse Imhoff e Pozzi Neri Parco',
        'desc': 'Manutenzione semestrale serbatoi Imhoff e pulizia pozzetti di degassamento parco.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': false,
        'freq': 6,
        'monthOffset': 2,
        'canone': 1800.0,
        'assi': 3,
        'note': 'Entrata dal cancello secondario in via della Pineta (strada sterrata).',
        'fattura': 'FT-2025/301',
      },
      // Mese +2 (es. Dicembre) - Contratto 2
      {
        'customer': makeCustomer(
          id: 'sample_cust_7',
          nomeEdificio: 'Centro Commerciale Meridiana',
          tipologiaEdificio: Customer.EDIFICIO_AZIENDA,
          codiceFiscaleEdificio: '03491820377',
          nomeReferente: 'Meridiana Gest S.r.l.',
          tipologia: Customer.AZIENDA,
          email: 'direzione@meridianashopping.it',
          phone: '051 617800',
          indirizzo: ['Via Aldo Moro 64', 'Bologna (BO)', '40127'],
          telefonoIndirizzo: '051 617800',
          contattoNome: 'Dott. Luca Moretti (Facility Manager)',
          contattoTel: '347 5566778',
        ),
        'title': 'Spurgo Rete Ristorazione e Degrassatori Food Court',
        'desc': 'Svuotamento disoleatori e separatori grassi cucine ristoranti centro commerciale.',
        'cat': 'Spurgo',
        'tipo': ContractActivityType.CONTRATTO,
        'cartel': false,
        'freq': 3,
        'monthOffset': 2,
        'canone': 3200.0,
        'assi': 4,
        'note': 'Intervento notturno o mattina presto prima delle 07:30 per non disturbare la clientela.',
        'fattura': 'FT-2026/012',
      },
    ];

    for (final item in sampleData) {
      final cust = item['customer'] as Customer;
      final int offset = item['monthOffset'] as int;
      final scadenza = DateTime(now.year, now.month + offset, 1);
      final primoIntervento = DateTime(now.year - 1, now.month + offset, 1);
      final ultimaFattura = DateTime(now.year, now.month + offset - 1, 15);

      final contract = Contract(
        id: '',
        clienteId: cust.id,
        customer: cust,
        title: item['title'] as String,
        description: item['desc'] as String,
        category: item['cat'] as String,
        typologyActivity: item['tipo'] as String,
        withCartel: item['cartel'] as bool,
        frequenzaMesi: item['freq'] as int,
        prossimaMese: scadenza,
        primoIntervento: primoIntervento,
        canoneAnnuo: (item['canone'] as double),
        ivaIncluded: false,
        fatturazioneNote: 'Fatturazione concordata da contratto',
        ultimaFatturaNr: item['fattura'] as String,
        ultimaFatturaData: ultimaFattura,
        numAssi: item['assi'] as int,
        documents: [],
        documentsMap: {},
        status: ContractStatus.Active,
        note: item['note'] as String,
      );

      await _collectionClienti.doc(cust.id).set(cust.toDocument(), SetOptions(merge: true));
      await addContract(contract);
    }
  }

}



