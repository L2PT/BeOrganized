import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
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

  late Map<String,dynamic> categories;
  late Map<String,dynamic> typesEvent;
  late Map<String, dynamic> typesCustomer;

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
  }

  static Future<CloudFirestoreService> create() async {
    CloudFirestoreService instance = CloudFirestoreService();
    instance.categories = await instance._getCategories();
    instance.typesEvent = await instance._getTypesEvent();
    instance.typesCustomer = await instance._getTypesCustomer();
    return instance;
  }

  /// Function to retrieve from the database the information associated with the
  /// user logged in. The Firebase AuthUser uid must be the same as the id of the
  /// document in the "Utenti" [Constants.tabellaUtenti] collection.
  /// However the mail is also an unique field.
  Future<Account> getAccount(String email, {String? phoneId}) async {
    if(!string.isNullOrEmpty(email))
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
          [event.operator, ...event.suboperators].map((e) => e!.id).forEach((idOperator) {
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
    query = addPagination(query, limit, startFrom);
    return query.get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).toList());
  }

  void addOperator(Account u) {
    _collectionUtenti.doc(u.id).set(u.toDocument());
  }

  void deleteOperator(String id) {
    _collectionUtenti.doc(id).delete();
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

  Stream<Map<String, dynamic>> getInfoApp() {
    return _collectionCostanti.doc(Constants.tabellaCostanti_InfoApp).snapshots().map((document)  => document.data()! as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPhoneNumbers() async {
    return _collectionCostanti.doc(Constants.tabellaCostanti_Telefoni).get().then((document) => document.data()! as Map<String, dynamic>);
  }

  Future<Event?> getEvent(String id) async {
    return _collectionEventi.doc(id).get().then((document) => document.exists?
        Event.fromMap(document.id,  _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data()! as Map<String, dynamic>) : null);
  }

  Future<List<Event>> getEvents() async {
    return _collectionEventi.orderBy(Constants.tabellaEventi_dataInizio).get().then((snapshot) => snapshot.docs.map((document) =>
        Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList());
  }

  Future<List<Event>> getFutureEvents(DateTime date) async {
    date = date.subtract(Duration( days: 1));
    return _collectionEventi.where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo:  date).orderBy(Constants.tabellaEventi_dataInizio).get().then((snapshot) => snapshot.docs.map((document) =>
        Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<Event>> subscribeEvents() {
    return _collectionEventi.orderBy(Constants.tabellaEventi_dataInizio, descending: true).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsByOperatorWaiting(String idOperator) {
    return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContains: idOperator).where(Constants.tabellaEventi_stato, isGreaterThanOrEqualTo: EventStatus.New).where(Constants.tabellaEventi_stato, isLessThanOrEqualTo: EventStatus.Seen).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }// TODO merge subscription queries

  Stream<List<Event>> subscribeEventsByOperator(List<String> idsOperator, {required int statusEqualOrAbove, DateTime? from, DateTime? to}) {
    if(from != null && to != null)
      return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
          .where(Constants.tabellaEventi_dataInizio, isGreaterThanOrEqualTo: from)
          .where(Constants.tabellaEventi_dataInizio, isLessThan: to).snapshots().map((snapshot) {
        var documents = snapshot.docs;
        return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).where((event) => event.status>=statusEqualOrAbove).toList();
      });
    else
      return _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContainsAny: idsOperator)
          .where(Constants.tabellaEventi_stato, isGreaterThanOrEqualTo: statusEqualOrAbove).snapshots().map((snapshot) {
        var documents = snapshot.docs;
        return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
      });
  }

  Stream<List<Event>> subscribeEventsHistory() {
    return _collectionSubStoricoEventi.orderBy(Constants.tabellaEventi_dataInizio, descending: true).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsDeleted() {
    return _collectionStoricoEliminati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsRefuse() {
    return _collectionStoricoRifiutati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Event>> subscribeEventsEnded() {
    return _collectionStoricoTerminati.orderBy(Constants.tabellaEventi_dataInizio).snapshots().map((snapshot) {
      var documents = snapshot.docs;
      return documents.map((document) => Event.fromMap(document.id, _getColorByCategory(document.get(Constants.tabellaEventi_categoria)), document.data() as Map<String, dynamic>)).toList();
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
    startQuery = startQuery.orderBy(
        Constants.tabellaEventi_dataInizio, descending: true);
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
        Event.fromMap(document.id, _getColorByCategory(
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
    [...events, ...(await _getEventsFiltered(query, filters, limit, lastRetrieved, limit-events.length, history))];
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
    return _getEventsFiltered(table, filters, limit, documentSnapshot, null, true);
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

    // Restituisce il conteggio
    return aggregateQuerySnapshot.count??0;
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

  void deleteEvent(Event e) async {
    e.status = EventStatus.Deleted;
    final dynamic createTransaction = (dynamic tx) async {
        dynamic doc = _collectionEventi.doc(e.id);
        dynamic deletedDoc = _collectionStoricoEliminati.doc(e.id);
        await tx.set(deletedDoc, e.toDocument());
        await tx.delete(doc);
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  void deleteEventPast(Event e) async {
    e.status = EventStatus.Deleted;
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(e.id);
      dynamic endedDoc = _collectionStoricoTerminati.doc(e.id);
      dynamic deletedDoc = _collectionStoricoEliminati.doc(e.id);
      await tx.set(deletedDoc, e.toDocument());
      await tx.delete(endedDoc);
      await tx.delete(doc);
    };
    _cloudFirestore.runTransaction(createTransaction);
  }

  void endEvent(Event e, {bool propagate = false}) async {
    e.status = EventStatus.Ended;
    Map<String, Event> eventsMoved = Map();
    if(propagate) {
      e.end = DateTime.now();
      var eventsToPropagate = [e];
      while(eventsToPropagate.isNotEmpty) {
        Event e = eventsToPropagate.removeLast();
        for(var operator in [e.operator, ...e.suboperators]){
          if(operator != null) {
            List<Event> eventsInConflict = await _collectionEventi.where(Constants.tabellaEventi_idOperatori, arrayContains: operator.id).where(Constants.tabellaEventi_dataInizio, isGreaterThan: e.start, isLessThanOrEqualTo: e.end)
                .get().then(((snapshot) => snapshot.docs.map((document) => Event.fromMap(document.id, "", document.data() as Map<String, dynamic>)).toList()));
            eventsInConflict.sort((a,b) => a.start.compareTo(b.start));
            Event eventConflict = e;
            eventsInConflict.forEach((eventInConflict) {
              Duration d = eventInConflict.end.difference(eventInConflict.start.add(Duration(minutes: 5)));
              eventInConflict.start = TimeUtils.getStartWorkTimeSpan(from: eventConflict.end.add(new Duration(minutes: 5)), ofDuration: d);
              eventInConflict.end =  eventInConflict.start.add(d);
              eventsToPropagate.add(eventInConflict);
              eventConflict = eventInConflict;
            });
          }
        }
        if(eventsMoved[e.id] == null || eventsMoved[e.id]!.start.isBefore(e.start))
            eventsMoved[e.id] = e;

      }
    }
    final dynamic createTransaction = (dynamic tx) async {
      dynamic doc = _collectionEventi.doc(e.id);
      dynamic endedDoc = _collectionStoricoTerminati.doc(e.id);
      await tx.set(endedDoc, e.toDocument());
      await tx.update(doc, {Constants.tabellaEventi_stato: e.status});
      for (Event eventMoved in eventsMoved.values){
        dynamic doc = _collectionEventi.doc(eventMoved.id);
        await tx.update(doc, {Constants.tabellaEventi_dataInizio: eventMoved.start});
        await tx.update(doc, {Constants.tabellaEventi_dataFine: eventMoved.end});
      }
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

  String _getColorByCategory(String? category) =>
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

  Future<List<Customer>> getCustomers(Map<String, FilterWrapper> filters, {limit, startFrom }) async {
    DocumentSnapshot? documentSnapshot;
    if(startFrom != null)
      documentSnapshot = await getDocument(_collectionClienti, startFrom);
    return _getCustomersFiltered(_collectionClienti, filters, limit, documentSnapshot, null);
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

  Future<void> updateAccountField(String id, String field, dynamic data) async {
    return _collectionUtenti.doc(id).update(Map.of({field:data}));
  }

  Future<Account> getUserByPhone(String phoneNumber) async{
    return _collectionUtenti.where('Telefono', isEqualTo: phoneNumber).get().then((snapshot) => snapshot.docs.map((document) => Account.fromMap(document.id, document.data() as Map<String, dynamic>)).first);
  }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}

//  AuthUser _userFromFirebase(fb.User user) {
//
//    if (user == null) {
//      return null;
//    }
//    return AuthUser (
//      uid: user.uid,
//      email: user.email,
//      displayName: user.displayName,
//      photoUrl: user.photoURL,
//    );
//  }
//
//  Stream<AuthUser> get onAuthStateChanged {
//    return _firebaseAuth.onAuthStateChanged.map(_userFromFirebase);
//  }
