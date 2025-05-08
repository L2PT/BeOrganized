import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/repositories/firebase_storage_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/file_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'details_event_state.dart';

class DetailsEventCubit extends Cubit<DetailsEventState> {
  final BuildContext context;
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  final Event _event;

  DetailsEventCubit(this.context, CloudFirestoreService databaseRepository, Account account, Event event) :
      _databaseRepository = databaseRepository, _account = account, _event = event,
        super(DetailsEventState(event, event.notaOperator, event.status, event.documents.cast<String>()) ) {
    if (state.event.operator!.id == _account.id &&
        state.event.status < EventStatus.Seen) {
      emit(state.changeStatus(EventStatus.Seen));
      _databaseRepository.updateEventField(
          state.event.id, Constants.tabellaEventi_stato, EventStatus.Seen);
    }
  }

  void endEventAndNotify(bool updateEndTime) {
    _databaseRepository.endEvent(state.event, propagate: updateEndTime);
    emit(state.changeStatus(EventStatus.Ended));
    FirebaseMessagingService.sendNotifications(tokens: state.event.supervisor!.tokens,
        style: Constants.notificationInfoTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha terminato il lavoro \"${state.event.title}\"",
        eventId: state.event.id
    );
    PlatformUtils.backNavigator(context);
  }

  void acceptEventAndNotify() {
    _databaseRepository.updateEventField(state.event.id, Constants.tabellaEventi_stato, EventStatus.Accepted);
    emit(state.changeStatus(EventStatus.Accepted));
    FirebaseMessagingService.sendNotifications(tokens: state.event.supervisor!.tokens,
        style: Constants.notificationSuccessTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha accettato il lavoro \"${state.event.title}\"",
        eventId: state.event.id
    );
  }

  void refuseEventAndNotify(String justification) {
    state.event.motivazione = justification;
    _databaseRepository.refuseEvent(state.event);
    emit(state.changeStatus(EventStatus.Refused));
    FirebaseMessagingService.sendNotifications(tokens: state.event.supervisor!.tokens,
        style: Constants.notificationErrorTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha rifiutato il lavoro \"${state.event.title}\"",
        eventId: state.event.id
    );
    PlatformUtils.backNavigator(context);
  }

  void deleteEvent() {
    state.event.start.isBefore(DateTime.now())?
    _databaseRepository.deleteEventPast(state.event)
    :_databaseRepository.deleteEvent(state.event);
    PlatformUtils.backNavigator(context);
  }

  void modifyEvent() {
    //shh this is wrong, it breaks the mvvm
    PlatformUtils.backNavigator(context);
    PlatformUtils.navigator(context, Constants.createEventViewRoute, <String,dynamic>{"objectParameter" : _event, 'typeStatus' : TypeStatus.modify});
  }

  void copyEvent() {
    PlatformUtils.backNavigator(context);
    Event e = Event.fromMap("", "", _event.toMap());
    e.id = '';
    e.suboperators = List.empty();
    e.operator = Account.empty();
    e.start = TimeUtils.getNextStartWorkTimeSpan();
    e.end = e.start.add(Duration(minutes: Constants.WORKTIME_SPAN));
    PlatformUtils.navigator(context, Constants.createEventViewRoute, <String,dynamic>{"objectParameter" : e, 'typeStatus' : TypeStatus.copy});
  }

  void callClient(String phone) async {
    Uri phoneUri = Uri.parse("tel:"+phone);
    if(await canLaunchUrl(phoneUri)){
      launchUrl(phoneUri);
    }
  }

  void launchMap(String address) async {
    String query = Uri.encodeComponent(address);
    Uri googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    }
  }

  void addEventNotaOperator(String notaOperator){
    _databaseRepository.updateEventField(_event.id, Constants.tabellaEventi_notaOperatore, notaOperator);
    emit(state.changeNotaOperator(notaOperator));
  }

  void openFileExplorer() async {
    Map<String, dynamic> file = new Map();
    List<String> listDocuments = _event.documents.cast<String>();
    file = await FileUtils.openFileExplorer(file);
    file.forEach((name, file) {
      FirebaseStorageService.uploadFile(file, _event.id + "/" + name);
      listDocuments.add(name);
    });
    _databaseRepository.updateEventField(_event.id, Constants.tabellaEventi_documenti, listDocuments);
    emit(state.changeListDocuments(listDocuments));
  }

}
