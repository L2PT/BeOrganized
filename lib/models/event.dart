import 'package:intl/intl.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event_response_ai.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

class Event {

  static const String RECURRENCE_MENSILE = "Mensile";
  static const String RECURRENCE_ANNO = "Anno";

  String id = "";
  String title = "";
  String description = "";
  String notaOperator = "";
  DateTime start = _.DateUtils.now();
  DateTime end = _.DateUtils.now();
  String address = "";
  List<dynamic> documents = [];
  int status = EventStatus.New;
  String category = "";
  String typology = "Intervento";
  bool withCartel = false;
  String color = "";
  String motivazione = "";
  Account? supervisor;
  Customer customer = Customer.empty();
  Account operator = Account.empty();
  List<Account> suboperators = [];

  //Attributi di trasporto
  Map<String, dynamic> documentsMap = {};
  bool isScheduled = false;

  //Attributi ripetizione
  String recurrenceId = ""; // ID della serie ricorrente
  int recurrenceIntervalInMonths = 12; // ogni quanti mesi
  int recurrenceDayOfMonth = -1; // giorno del mese (1-31)
  bool isExcepeted = false;
  bool isRepeated = false;
  String recurrenceType = RECURRENCE_MENSILE;
  DateTime recurrenceStart = _.DateUtils.now();
  DateTime recurrenceEnd = _.DateUtils.now();


  Event(this.id, this.title, this.description, this.notaOperator, this.start, this.end,
      this.address, this.documents, this.status, this.category,this.typology, this.color,
      this.supervisor, this.operator, this.suboperators, this.motivazione, this.customer,
      this.withCartel, this.isScheduled, this.recurrenceId, this.recurrenceDayOfMonth,
      this.isExcepeted, this.recurrenceIntervalInMonths, this.isRepeated,
      this.recurrenceType);
  Event.empty();

  Event.fromMap(String id, String color, Map json) :
    id = (id!="")?id:(json["id"]!=null)?json["id"]:"",
    title = json["Titolo"],
    description = json["Descrizione"],
    notaOperator = json["NotaOperatore"]??'',
    start = json["DataInizio"] is DateTime?json["DataInizio"]:_.DateUtils.firestoreToItalianTime(json["DataInizio"]),
    end = json["DataFine"] is DateTime?json["DataFine"]:_.DateUtils.firestoreToItalianTime(json["DataFine"]),
    address = json["Indirizzo"],
    documents = json["Documenti"]??[],
    status = json["Stato"],
    category = json["Categoria"],
    typology = json["Tipologia"]??"Intervento",
    color = (!string.isNullOrEmpty(color))?color:json["color"]??"",
    supervisor = json["Responsabile"]==null?Account.empty():Account.fromMap("", json["Responsabile"]),
    operator = json["Operatore"]==null?Account.empty():Account.fromMap("", json["Operatore"]),
    suboperators = (json["SubOperatori"] as List).map((subOp) => Account.fromMap("", subOp)).toList(),
    motivazione = json["Motivazione"]??"",
    customer = json["Cliente"] == null? Customer.empty(): Customer.fromMap(id, json["Cliente"]),
    isScheduled = json["isScheduled"]??false,
    withCartel = json["withCartel"]??false,
    documentsMap = json["documentsMap"] == null?{}:(json["documentsMap"] as Map<String,dynamic>),
    recurrenceId = json["recurrenceId"]??"",
    isExcepeted = json["isExcepeted"]??false,
    isRepeated = json["isRepeated"]??false,
    recurrenceDayOfMonth = json["recurrenceDayOfMonth"]??-1,
    recurrenceType = json["recurrenceType"]??RECURRENCE_MENSILE,
    recurrenceIntervalInMonths = json["recurrenceIntervalInMonths"]??-1,
    recurrenceStart = json["recurrenceStart"] is DateTime?json["recurrenceStart"]:_.DateUtils.now(),
    recurrenceEnd = json["recurrenceEnd"] is DateTime?json["recurrenceEnd"]:_.DateUtils.now();

  Map<String, dynamic> toMap() => {
      "id":this.id,
      "Titolo":this.title,
      "Descrizione":this.description,
      "NotaOperatore":this.notaOperator,
      "DataInizio":this.start,
      "DataFine":this.end,
      "Indirizzo":this.address,
      "Documenti":this.documents,
      "Stato":this.status,
      "Categoria":this.category,
      "Tipologia":this.typology,
      "color":this.color,
      "Responsabile":this.supervisor?.toMap(),
      "Cliente": this.customer.toMap(),
      "Operatore":this.operator.toMap(),
      "SubOperatori":this.suboperators.map((op)=>op.toMap()).toList(),
      "isScheduled":this.isScheduled,
      "withCartel": this.withCartel,
      "documentsMap":this.documentsMap,
      "recurrenceId": this.recurrenceId,
      "isExcepeted": this.isExcepeted,
      "isRepeated": this.isRepeated,
      "recurrenceType": this.recurrenceType,
      "recurrenceDayOfMonth": this.recurrenceDayOfMonth,
      "recurrenceIntervalInMonths": this.recurrenceIntervalInMonths,
      "recurrenceStart": this.recurrenceStart,
      "recurrenceEnd": this.recurrenceEnd,
  };
  Map<String, dynamic> toDocument(){
    return Map<String, dynamic>.of({
      "Titolo":this.title,
      "Descrizione":this.description,
      "NotaOperatore":this.notaOperator,
      "DataInizio":_.DateUtils.setLocation(this.start),
      "DataFine":_.DateUtils.setLocation(this.end),
      "Indirizzo":this.address,
      "Documenti":this.documents,
      "Stato":this.status,
      "Categoria":this.category,
      "Tipologia":this.typology,
      "Responsabile":this.supervisor?.toMap(),
      "Cliente": this.customer.toMap(),
      "Operatore":this.operator.toMap(),
      "SubOperatori": this.suboperators.map((op)=>op.toMap()).toList(),
      "Motivazione" : this.motivazione,
      "IdOperatore" : this.operator.id,
      "IdOperatori" : [...this.suboperators.map((op) => op.id),operator.id],
      "isScheduled":this.isScheduled,
      "withCartel": this.withCartel,
      "documentsMap":this.documentsMap,
      "recurrenceId": this.recurrenceId,
      "isExcepeted": this.isExcepeted,
      "isRepeated": this.isRepeated,
      "recurrenceType": this.recurrenceType,
      "recurrenceDayOfMonth": this.recurrenceDayOfMonth,
      "recurrenceIntervalInMonths": this.recurrenceIntervalInMonths,
      "recurrenceStart": _.DateUtils.setLocation(this.recurrenceStart),
      "recurrenceEnd": _.DateUtils.setLocation(this.recurrenceEnd),
    });
  }

  void fromGenerateData(EventResponseAi eventResponseAi) {
    title = '${eventResponseAi.tipo} - ${eventResponseAi.nome} ${eventResponseAi.cognome}';
    description = eventResponseAi.problematica + " - " + eventResponseAi.note;
    typology = eventResponseAi.tipo;
    category = eventResponseAi.categoria;
    color = eventResponseAi.color;
    withCartel = eventResponseAi.cartello;
    isScheduled = eventResponseAi.programmato;
    isRepeated = eventResponseAi.isRepeated;
    recurrenceIntervalInMonths = eventResponseAi.ogniQuantiMesiRipetizione;
    recurrenceDayOfMonth = eventResponseAi.giornoMeseRipetizione;

    DateTime? parseTimeOfDay(String? time, DateTime base) {
      if (time != null && time.trim().isNotEmpty && TimeUtils.isValidTimeFormat(time)) {
        final parsed = DateFormat("HH:mm").parseStrict(time.trim());
        return TimeUtils.truncateDate(base, "day").add(Duration(hours: parsed.hour, minutes: parsed.minute));
      }
      return base;
    }

    if (isRepeated) {
      if (eventResponseAi.dataInizioRipetizione.isNotEmpty) {
        final startDate = DateTime.parse(eventResponseAi.dataInizioRipetizione);
        start = TimeUtils.getStartWorkTimeSpan(from: startDate);
        end = TimeUtils.getStartWorkTimeSpan(from: start).olderBetween(end);

        final customStart = parseTimeOfDay(eventResponseAi.oraInizio, start);
        if (customStart != null) start = customStart;

        if (eventResponseAi.dataFineRipetizione.isNotEmpty) {
          final endDate = DateTime.parse(eventResponseAi.dataFineRipetizione);
          end = TimeUtils.truncateDate(endDate, "day").add(Duration(hours: end.hour, minutes: end.minute));
        }

        final customEnd = parseTimeOfDay(eventResponseAi.oraFine, end);
        if (customEnd != null) {
          end = customEnd;
        } else {
          end = TimeUtils.truncateDate(end, "day").add(
            Duration(
              hours: TimeUtils.getStartWorkTimeSpan(from: start).olderBetween(end).hour,
              minutes: TimeUtils.getStartWorkTimeSpan(from: start).olderBetween(end).minute,
            ),
          );
        }
      }
    } else {
      if (eventResponseAi.data.isNotEmpty) {
        final date = DateTime.parse(eventResponseAi.data);
        if (eventResponseAi.allDay) {
          start = TimeUtils.truncateDate(date, "day").add(Duration(hours: Constants.MIN_WORKTIME));
          end = TimeUtils.truncateDate(date, "day").add(Duration(hours: Constants.MAX_WORKTIME));
        } else {
          start = TimeUtils.getStartWorkTimeSpan(from: date);
          end = TimeUtils.getStartWorkTimeSpan(from: start);

          final customStart = parseTimeOfDay(eventResponseAi.oraInizio, start);
          if (customStart != null) {
            start = customStart;

            final customEnd = parseTimeOfDay(eventResponseAi.oraFine, end);
            if (customEnd != null) {
              end = customEnd;
            } else {
              end = TimeUtils.truncateDate(end, "day").add(
                Duration(
                  hours: TimeUtils.getStartWorkTimeSpan(from: start).olderBetween(end).hour,
                  minutes: TimeUtils.getStartWorkTimeSpan(from: start).olderBetween(end).minute,
                ),
              );
            }
          }
        }
      }
    }
  }


  List<Event> generateRecurringEvents(DateTime from, DateTime to) {
    final events = <Event>[];
    final interval = this.recurrenceIntervalInMonths;
    final day = this.recurrenceDayOfMonth;

    DateTime current = DateTime(this.start.year, this.start.month, day, this.start.hour, this.start.minute);

    while (_.DateUtils.isBefore(current,to)) {
      if (_.DateUtils.isAfter(current,from)) {
        final nextEvent = Event.fromMap('', this.color, this.toMap());
        nextEvent.id = "";
        nextEvent.start = current;
        nextEvent.end = DateTime(current.year, current.month, current.day, this.end.hour, this.end.minute,);
        nextEvent.recurrenceId = this.id;
        nextEvent.recurrenceStart = this.start;
        nextEvent.recurrenceEnd = this.end;
        events.add(nextEvent);
      }
      current = DateTime(current.year, current.month + interval, day, current.hour, current.minute);
    }

    return events;
  }


  String addresAddress(){
    return this.customer.address.address.isEmpty?this.address.isEmpty?'Nessun indirizzo indicato':this.address:this.customer.address.address.join(" ");
  }

  bool isBetweenDate(DateTime dataInizio,DateTime dataFine){
    if(((_.DateUtils.isAfter(this.start,dataInizio) || _.DateUtils.isAtSameMomentAs(this.start,dataInizio)) && _.DateUtils.isBefore(this.start,dataFine)) || (_.DateUtils.isAfter(this.end,dataInizio) && (_.DateUtils.isBefore(this.end,dataFine)) || _.DateUtils.isAtSameMomentAs(this.end,dataFine)) || (_.DateUtils.isBefore(this.start,dataInizio) && _.DateUtils.isAfter(this.end,dataFine)) || (_.DateUtils.isAtSameMomentAs(this.start,dataInizio) && _.DateUtils.isAtSameMomentAs(this.end,dataFine))){
      return true;
    }else{
      return false;
    }
  }

  void update(Event eventUpdate) {
    this.title = eventUpdate.title;
    this.description = eventUpdate.description;
    this.notaOperator = eventUpdate.notaOperator;
    this.start = eventUpdate.start;
    this.end = eventUpdate.end;
    this.address = eventUpdate.address;
    this.documents = eventUpdate.documents;
    this.status = eventUpdate.status;
    this.category = eventUpdate.category;
    this.typology = eventUpdate.typology;
    this.withCartel = eventUpdate.withCartel;
    this.color = eventUpdate.color;
    this.motivazione = eventUpdate.motivazione;
    this.supervisor = eventUpdate.supervisor;
    this.customer = eventUpdate.customer;
    this.operator = eventUpdate.operator;
    this.suboperators = eventUpdate.suboperators;
    this.documentsMap = eventUpdate.documentsMap;
    this.isScheduled = eventUpdate.isScheduled;
    this.isRepeated = eventUpdate.isRepeated;
    this.isExcepeted = eventUpdate.isExcepeted;
    this.recurrenceIntervalInMonths = eventUpdate.recurrenceIntervalInMonths;
    this.recurrenceDayOfMonth = eventUpdate.recurrenceDayOfMonth;
  }

  bool isEventsOverlap(DateTime dataInizio,DateTime dataFine) {
    return _.DateUtils.isBefore(this.start,dataFine) && _.DateUtils.isBefore(dataInizio,this.end);
  }

  bool filter(lambda, value){
    return lambda(this, value);
  }

  bool isAllDayLong() {
    final differenceInHour = this.end.difference(this.start).inHours;
    final dayDuration = Constants.MAX_WORKTIME - Constants.MIN_WORKTIME;
    return differenceInHour >= dayDuration && !isRepeated;
  }
  bool isDeleted() => this.status == EventStatus.Deleted;
  bool isNew() => this.status == EventStatus.New;
  bool isDelivered() => this.status == EventStatus.Delivered;
  bool isSeen() => this.status == EventStatus.Seen;
  bool isAccepted() => this.status == EventStatus.Accepted;
  bool isRefused() => this.status == EventStatus.Refused;
  bool isEnded() => this.status == EventStatus.Ended;
  bool isBozza() => this.status == EventStatus.Bozza;

  bool isIntervento() => this.typology == "Intervento";
  bool isContratto() => this.typology == "Contratto";

  bool isRecurrenceMensile() => this.recurrenceType == RECURRENCE_MENSILE;
  bool isRecurrenceAnno() => this.recurrenceType == RECURRENCE_ANNO;
  bool isRepeatedEvent() => this.isRepeated && !this.isExcepeted;

  @override
  String toString() => id+title+description+notaOperator+customer.toString()
      +documents.join()+start.toString()+end.toString()+address+(status).toString()
      +typology+withCartel.toString()+category+color+operator.id
      +suboperators.map((o) => o.id).join()+(motivazione)+recurrenceId+isExcepeted.toString()
      +recurrenceDayOfMonth.toString()+recurrenceIntervalInMonths.toString()+isRepeated.toString()+recurrenceType
      +recurrenceStart.toString()+recurrenceEnd.toString();
}